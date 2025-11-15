#!/bin/bash

# Batch Translation Script for German
# Translates all markdown files in phase9-final/ to German
# using multi-pass-translate-v3.sh with 5 concurrent workers
#
# Usage: ./scripts/batch-translate-german.sh

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_ROOT="/Users/dalton/projects/novenco-content-creator"
SOURCE_DIR="$PROJECT_ROOT/phase9-final"
TRANSLATION_SCRIPT="$PROJECT_ROOT/scripts/multi-pass-translate-v3.sh"
LANGUAGE="de"
MAX_CONCURRENT=5

# Log directory
LOG_DIR="$PROJECT_ROOT/logs/translation"
mkdir -p "$LOG_DIR"

# State files
FILE_LIST="$LOG_DIR/german_batch_files.txt"
COMPLETED_LOG="$LOG_DIR/german_batch_completed.txt"
FAILED_LOG="$LOG_DIR/german_batch_failed.txt"
PROGRESS_LOG="$LOG_DIR/german_batch_progress.log"
ACTIVE_JOBS="$LOG_DIR/german_batch_active.txt"
PID_MAP="$LOG_DIR/german_batch_pids.txt"
REPORT_FILE="$LOG_DIR/german_batch_report.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global counters (will be updated from files)
TOTAL_FILES=0
COMPLETED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
START_TIME=$(date +%s)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

log_info() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $message" | tee -a "$PROGRESS_LOG"
}

log_error() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" | tee -a "$PROGRESS_LOG"
}

log_success() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $message" | tee -a "$PROGRESS_LOG"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

init_workspace() {
    print_message "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$BLUE" "Batch German Translation - Initialization"
    print_message "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if translation script exists
    if [ ! -f "$TRANSLATION_SCRIPT" ]; then
        print_message "$RED" "Error: Translation script not found: $TRANSLATION_SCRIPT"
        exit 1
    fi

    # Make translation script executable
    chmod +x "$TRANSLATION_SCRIPT"

    # Create fresh file list if not exists or regenerate
    if [ ! -f "$FILE_LIST" ]; then
        log_info "Generating file list from $SOURCE_DIR"
        find "$SOURCE_DIR" -type f -name "*.md" | sort > "$FILE_LIST"
        TOTAL_FILES=$(wc -l < "$FILE_LIST")
        log_info "Found $TOTAL_FILES markdown files"
    else
        TOTAL_FILES=$(wc -l < "$FILE_LIST")
        log_info "Using existing file list: $TOTAL_FILES files"
    fi

    # Create state files if they don't exist
    touch "$COMPLETED_LOG"
    touch "$FAILED_LOG"
    touch "$ACTIVE_JOBS"
    touch "$PID_MAP"

    # Load counts
    COMPLETED_COUNT=$(wc -l < "$COMPLETED_LOG" 2>/dev/null || echo 0)
    FAILED_COUNT=$(wc -l < "$FAILED_LOG" 2>/dev/null || echo 0)

    print_message "$CYAN" "Status:"
    print_message "$CYAN" "  Total files: $TOTAL_FILES"
    print_message "$CYAN" "  Already completed: $COMPLETED_COUNT"
    print_message "$CYAN" "  Previously failed: $FAILED_COUNT"
    print_message "$CYAN" "  Remaining: $((TOTAL_FILES - COMPLETED_COUNT))"
    print_message "$CYAN" "  Max concurrent: $MAX_CONCURRENT"
    echo ""
}

# ============================================================================
# FILE PROCESSING CHECKS
# ============================================================================

get_output_path() {
    local input_file=$1
    # Get relative path from project root
    local rel_path="${input_file#$PROJECT_ROOT/}"
    # Construct output path
    echo "$PROJECT_ROOT/translations/$LANGUAGE/$rel_path"
}

is_already_done() {
    local input_file=$1

    # Check completed log
    if grep -Fxq "$input_file" "$COMPLETED_LOG" 2>/dev/null; then
        return 0
    fi

    # Check if output file exists and has content
    local output_file=$(get_output_path "$input_file")
    if [ -f "$output_file" ]; then
        local size=$(stat -f%z "$output_file" 2>/dev/null || echo 0)
        if [ "$size" -gt 100 ]; then
            # Add to completed log if not already there
            echo "$input_file" >> "$COMPLETED_LOG"
            return 0
        fi
    fi

    return 1
}

is_failed() {
    local input_file=$1
    grep -Fxq "$input_file" "$FAILED_LOG" 2>/dev/null
}

# ============================================================================
# WORKER MANAGEMENT
# ============================================================================

translate_worker() {
    local input_file=$1
    local worker_id=$2
    local log_file="$LOG_DIR/worker_${worker_id}.log"

    # Log start
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Worker $worker_id] Starting: $input_file" >> "$PROGRESS_LOG"

    # Run translation
    if "$TRANSLATION_SCRIPT" -l "$LANGUAGE" "$input_file" > "$log_file" 2>&1; then
        # Success
        echo "$input_file" >> "$COMPLETED_LOG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Worker $worker_id] ✓ Completed: $input_file" >> "$PROGRESS_LOG"
        rm -f "$log_file"
        exit 0
    else
        # Failure
        echo "$input_file|Error: Translation failed (see worker_${worker_id}.log)" >> "$FAILED_LOG"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Worker $worker_id] ✗ Failed: $input_file" >> "$PROGRESS_LOG"
        exit 1
    fi
}

get_active_count() {
    local count=0
    if [ -f "$PID_MAP" ]; then
        while read -r line; do
            local pid=$(echo "$line" | cut -d'|' -f1)
            if kill -0 "$pid" 2>/dev/null; then
                ((count++))
            fi
        done < "$PID_MAP"
    fi
    echo "$count"
}

cleanup_finished_workers() {
    if [ ! -f "$PID_MAP" ]; then
        return
    fi

    local temp_file="${PID_MAP}.tmp"
    : > "$temp_file"

    while read -r line; do
        local pid=$(echo "$line" | cut -d'|' -f1)
        local file=$(echo "$line" | cut -d'|' -f2)

        if kill -0 "$pid" 2>/dev/null; then
            # Still running
            echo "$line" >> "$temp_file"
        fi
    done < "$PID_MAP"

    mv "$temp_file" "$PID_MAP"
}

get_next_worker_id() {
    local max_id=0
    if [ -f "$PID_MAP" ]; then
        while read -r line; do
            local id=$(echo "$line" | cut -d'|' -f3)
            if [ "$id" -gt "$max_id" ]; then
                max_id=$id
            fi
        done < "$PID_MAP"
    fi
    echo $((max_id + 1))
}

start_worker() {
    local input_file=$1
    local worker_id=$(get_next_worker_id)

    # Start worker in background
    (translate_worker "$input_file" "$worker_id") &
    local pid=$!

    # Record PID and file
    echo "${pid}|${input_file}|${worker_id}" >> "$PID_MAP"

    log_info "Started worker $worker_id (PID $pid) for: $(basename "$input_file")"
}

# ============================================================================
# PROGRESS DISPLAY
# ============================================================================

show_dashboard() {
    clear

    # Update counts
    COMPLETED_COUNT=$(wc -l < "$COMPLETED_LOG" 2>/dev/null || echo 0)
    FAILED_COUNT=$(wc -l < "$FAILED_LOG" 2>/dev/null || echo 0)

    local active_count=$(get_active_count)
    local remaining=$((TOTAL_FILES - COMPLETED_COUNT - SKIPPED_COUNT))
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))

    # Calculate ETA
    local eta="calculating..."
    if [ "$COMPLETED_COUNT" -gt 0 ]; then
        local avg_time=$((elapsed / COMPLETED_COUNT))
        local eta_seconds=$((remaining * avg_time / MAX_CONCURRENT))
        local eta_hours=$((eta_seconds / 3600))
        local eta_mins=$(((eta_seconds % 3600) / 60))
        eta="${eta_hours}h ${eta_mins}m"
    fi

    # Calculate elapsed time
    local elapsed_hours=$((elapsed / 3600))
    local elapsed_mins=$(((elapsed % 3600) / 60))
    local elapsed_secs=$((elapsed % 60))

    # Progress percentage
    local progress=$((COMPLETED_COUNT * 100 / TOTAL_FILES))

    print_message "$GREEN" "╔════════════════════════════════════════════════════════════════╗"
    print_message "$GREEN" "║        German Translation Progress - 5 Concurrent Workers      ║"
    print_message "$GREEN" "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    print_message "$CYAN" "📊 Overall Progress: [$progress%]"
    printf "${GREEN}"
    printf '█%.0s' $(seq 1 $((progress / 2)))
    printf "${NC}\n\n"

    print_message "$BLUE" "📈 Statistics:"
    echo "   Total files:    $TOTAL_FILES"
    echo "   ✓ Completed:    $COMPLETED_COUNT"
    echo "   ✗ Failed:       $FAILED_COUNT"
    echo "   ⏭ Skipped:      $SKIPPED_COUNT"
    echo "   ⏳ Active:       $active_count"
    echo "   📋 Remaining:   $remaining"
    echo ""

    print_message "$MAGENTA" "⏱ Timing:"
    echo "   Elapsed:        ${elapsed_hours}h ${elapsed_mins}m ${elapsed_secs}s"
    echo "   Estimated ETA:  $eta"
    echo ""

    # Show active workers
    if [ -f "$PID_MAP" ] && [ -s "$PID_MAP" ]; then
        print_message "$YELLOW" "🔧 Active Workers:"
        while read -r line; do
            local pid=$(echo "$line" | cut -d'|' -f1)
            local file=$(echo "$line" | cut -d'|' -f2)
            local worker_id=$(echo "$line" | cut -d'|' -f3)
            if kill -0 "$pid" 2>/dev/null; then
                local basename=$(basename "$file")
                echo "   Worker $worker_id: $basename"
            fi
        done < "$PID_MAP"
        echo ""
    fi

    print_message "$CYAN" "Press Ctrl+C to stop gracefully..."
}

# ============================================================================
# CLEANUP AND SHUTDOWN
# ============================================================================

cleanup() {
    echo ""
    print_message "$YELLOW" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$YELLOW" "Shutting down gracefully..."
    print_message "$YELLOW" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Kill all active workers
    if [ -f "$PID_MAP" ]; then
        while read -r line; do
            local pid=$(echo "$line" | cut -d'|' -f1)
            if kill -0 "$pid" 2>/dev/null; then
                log_info "Stopping worker PID $pid"
                kill "$pid" 2>/dev/null || true
            fi
        done < "$PID_MAP"
    fi

    # Clean up PID map
    : > "$PID_MAP"

    log_info "Shutdown complete. Progress saved. Run again to resume."
    generate_report
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGINT SIGTERM

# ============================================================================
# REPORTING
# ============================================================================

generate_report() {
    local end_time=$(date +%s)
    local total_elapsed=$((end_time - START_TIME))
    local hours=$((total_elapsed / 3600))
    local mins=$(((total_elapsed % 3600) / 60))
    local secs=$((total_elapsed % 60))

    COMPLETED_COUNT=$(wc -l < "$COMPLETED_LOG" 2>/dev/null || echo 0)
    FAILED_COUNT=$(wc -l < "$FAILED_LOG" 2>/dev/null || echo 0)

    cat > "$REPORT_FILE" << EOF
═══════════════════════════════════════════════════════════════
German Batch Translation Report
═══════════════════════════════════════════════════════════════

Generated: $(date)
Duration: ${hours}h ${mins}m ${secs}s

SUMMARY
-------
Total Files:      $TOTAL_FILES
Completed:        $COMPLETED_COUNT
Failed:           $FAILED_COUNT
Skipped:          $SKIPPED_COUNT
Success Rate:     $((COMPLETED_COUNT * 100 / TOTAL_FILES))%

CONFIGURATION
-------------
Source:           $SOURCE_DIR
Language:         German (de)
Concurrency:      $MAX_CONCURRENT workers
Translation Mode: 7-stage multi-pass refinement

OUTPUT LOCATION
---------------
Translations:     $PROJECT_ROOT/translations/de/
Reports:          Each file has a _report.txt companion

LOGS
----
Progress Log:     $PROGRESS_LOG
Completed Files:  $COMPLETED_LOG
Failed Files:     $FAILED_LOG

EOF

    if [ "$FAILED_COUNT" -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF

FAILED FILES
------------
EOF
        cat "$FAILED_LOG" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

═══════════════════════════════════════════════════════════════
To retry failed files, remove them from:
  $FAILED_LOG

Then run this script again to process them.
═══════════════════════════════════════════════════════════════
EOF

    print_message "$GREEN" "\n📄 Report saved to: $REPORT_FILE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    init_workspace

    log_info "Starting batch translation with $MAX_CONCURRENT concurrent workers"
    log_info "Language: German (de)"

    # Initial dashboard display
    show_dashboard

    # Process files
    while true; do
        # Cleanup finished workers
        cleanup_finished_workers

        # Get current active count
        local active_count=$(get_active_count)

        # Check if we can start more workers
        if [ "$active_count" -lt "$MAX_CONCURRENT" ]; then
            # Find next file to process
            local found_file=""
            while IFS= read -r file; do
                # Skip if already completed
                if is_already_done "$file"; then
                    if ! grep -Fxq "$file" "$COMPLETED_LOG" 2>/dev/null; then
                        ((SKIPPED_COUNT++))
                    fi
                    continue
                fi

                # Skip if currently being processed
                if [ -f "$PID_MAP" ] && grep -F "|${file}|" "$PID_MAP" >/dev/null 2>&1; then
                    continue
                fi

                # Skip if failed (unless you want to retry)
                if is_failed "$file"; then
                    continue
                fi

                # Found a file to process
                found_file="$file"
                break
            done < "$FILE_LIST"

            if [ -n "$found_file" ]; then
                start_worker "$found_file"
                sleep 1  # Brief pause before starting next worker
            else
                # No more files to process
                if [ "$active_count" -eq 0 ]; then
                    # All done
                    break
                fi
            fi
        fi

        # Update dashboard
        show_dashboard

        # Wait before next check
        sleep 3
    done

    # Final dashboard
    show_dashboard

    # All workers completed
    print_message "$GREEN" "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$GREEN" "✓ Batch Translation Complete!"
    print_message "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    generate_report

    print_message "$CYAN" "\nTranslated files are in: $PROJECT_ROOT/translations/de/"

    if [ "$FAILED_COUNT" -gt 0 ]; then
        print_message "$YELLOW" "\n⚠ Warning: $FAILED_COUNT files failed. See report for details."
    fi
}

# Run main
main
