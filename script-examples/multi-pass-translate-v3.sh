#!/bin/bash

# Multi-Pass Translation Script v3 - Improved Output Handling
# This script orchestrates a 5-stage translation process using Claude CLI

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/Users/dalton/projects/novenco-content-creator"
SYSTEM_PROMPTS_DIR="$PROJECT_ROOT/.claude/system-prompt"
TEMP_DIR="$PROJECT_ROOT/temp/translation-stages"
OUTPUT_BASE_DIR="$PROJECT_ROOT/translations"

# Default language
LANGUAGE="nl"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print stage header
print_stage_header() {
    local stage_num=$1
    local stage_name=$2
    echo ""
    print_message "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$BLUE" "Stage $stage_num: $stage_name"
    print_message "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to extract actual translation content (remove Claude's meta text)
extract_translation_content() {
    local input_file=$1
    local output_file=$2

    # Common patterns to skip at the beginning of translations
    # This will skip lines until we find actual translated content
    awk '
    BEGIN { found = 0 }
    # Skip common English preambles from Claude
    /^I.ll translate/ { next }
    /^I.ll review/ { next }
    /^I.ll refine/ { next }
    /^I.ll adapt/ { next }
    /^I.ll provide/ { next }
    /^Let me/ { next }
    /^I need to/ { next }
    /^Here is/ { next }
    /^Here.s/ { next }

    # Skip markdown code fence markers that wrap content
    /^```markdown$/ { next }
    /^```$/ { next }

    # Skip lines that start with "---BEGIN" or "---END"
    /^---BEGIN/ { next }
    /^---END/ { next }

    # Skip quality check headers in English
    /^## QUALITY CHECK:/ { next }
    /^QUALITY CHECK:/ { next }

    # Once we find actual content, print everything
    /^---$/ { found = 1 }  # YAML frontmatter start
    /^#/ { found = 1 }      # Markdown heading
    /^## / { found = 1 }    # Subheading
    /^[A-Z]/ { if (length($0) > 20) found = 1 }  # Substantial content line

    found == 1 { print }
    ' "$input_file" > "$output_file"
}

# Function to run a translation stage
run_stage() {
    local stage_num=$1
    local stage_name=$2
    local system_prompt_file=$3
    local input_file=$4
    local output_file=$5
    local instruction=$6

    print_stage_header "$stage_num" "$stage_name"

    # Check if system prompt exists
    if [ ! -f "$system_prompt_file" ]; then
        print_message "$RED" "Error: System prompt not found: $system_prompt_file"
        exit 1
    fi

    # Read system prompt
    local system_prompt=$(cat "$system_prompt_file")

    # Create prompt combining content and instruction
    local full_prompt="Please process the following content according to your system instructions:

---BEGIN CONTENT---
$(cat "$input_file")
---END CONTENT---

$instruction

Provide the complete processed text."

    print_message "$YELLOW" "Processing with: $(basename $system_prompt_file)"

    # Run Claude and save raw output
    local raw_output="${output_file}.raw"
    echo "$full_prompt" | claude -p --system-prompt "$system_prompt" > "$raw_output" 2>/dev/null

    if [ $? -eq 0 ]; then
        # Extract actual content, removing Claude's commentary
        extract_translation_content "$raw_output" "$output_file"
        rm "$raw_output"  # Clean up raw file

        print_message "$GREEN" "✓ Stage $stage_num completed"

        # Show preview
        print_message "$YELLOW" "Preview (first 3 lines):"
        head -n 3 "$output_file" | sed 's/^/  /'
        echo "  ..."
    else
        print_message "$RED" "✗ Stage $stage_num failed"
        exit 1
    fi

    sleep 2
}

# Function to show usage
show_usage() {
    cat << EOF
Multi-Pass Translation Script v3

Usage: $(basename $0) [OPTIONS] <input-file>

Options:
    -l, --language LANG    Target language (nl, de)
                          Default: nl (Dutch)
    -o, --output DIR      Output directory (default: translations/[lang])
    -h, --help            Show this help message

Supported Languages:
    nl, dutch   - Dutch/Nederlands
    de, german  - German/Deutsch

Examples:
    # Translate to Dutch (default)
    $(basename $0) content/products/fans.md

    # Translate to German
    $(basename $0) -l de content/products/fans.md

    # Custom output directory
    $(basename $0) -l de -o /custom/path content/products/fans.md

Output:
    Final translation will preserve the original directory structure
    e.g., phase9-final/cases/file.md → translations/de/phase9-final/cases/file.md

The script runs 7 sequential stages:
    1. Initial Translation
    2. Terminology Refinement
    3. Cultural Adaptation
    4. Tone & Style Refinement
    5. Quality Analysis (identifies issues)
    6. Apply Corrections (implements fixes from stage 5)
    7. Final Validation (verifies corrections)
EOF
}

# Main execution
main() {
    # Initialize variables
    INPUT_FILE=""
    CUSTOM_OUTPUT=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--language)
                LANGUAGE="$2"
                shift 2
                ;;
            -o|--output)
                CUSTOM_OUTPUT="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                print_message "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                INPUT_FILE="$1"
                shift
                ;;
        esac
    done

    # Validate input
    if [ -z "$INPUT_FILE" ] || [ ! -f "$INPUT_FILE" ]; then
        print_message "$RED" "Error: Please provide a valid input file"
        show_usage
        exit 1
    fi

    # Normalize language code
    case $LANGUAGE in
        nl|dutch|nederlands)
            LANG_CODE="nl"
            LANG_NAME="Dutch"
            ;;
        de|german|deutsch)
            LANG_CODE="de"
            LANG_NAME="German"
            ;;
        *)
            print_message "$RED" "Error: Unsupported language: $LANGUAGE"
            print_message "$YELLOW" "Supported languages: nl (Dutch), de (German)"
            exit 1
            ;;
    esac

    # Check if language prompts directory exists
    LANG_PROMPTS_DIR="$SYSTEM_PROMPTS_DIR/$LANG_CODE"
    if [ ! -d "$LANG_PROMPTS_DIR" ]; then
        print_message "$RED" "Error: Language prompts not found for $LANG_NAME"
        print_message "$YELLOW" "Expected directory: $LANG_PROMPTS_DIR"
        exit 1
    fi

    # Create directories
    mkdir -p "$TEMP_DIR"

    # Setup session
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SESSION_DIR="$TEMP_DIR/session_${LANG_CODE}_${TIMESTAMP}"
    mkdir -p "$SESSION_DIR"

    # Get base filename and relative path
    BASE_NAME=$(basename "$INPUT_FILE" .md)

    # Get the absolute path of the input file
    INPUT_FILE_ABS=$(cd "$(dirname "$INPUT_FILE")" && pwd)/$(basename "$INPUT_FILE")

    # Get the relative path from project root (macOS compatible)
    # Strip the PROJECT_ROOT prefix from the absolute path
    if [[ "$INPUT_FILE_ABS" == "$PROJECT_ROOT"* ]]; then
        RELATIVE_PATH="${INPUT_FILE_ABS#$PROJECT_ROOT/}"
    else
        # File is outside project root, use just the filename
        RELATIVE_PATH=$(basename "$INPUT_FILE")
    fi
    RELATIVE_DIR=$(dirname "$RELATIVE_PATH")

    # Determine output directory preserving structure
    if [ -n "$CUSTOM_OUTPUT" ]; then
        OUTPUT_DIR="$CUSTOM_OUTPUT"
    else
        OUTPUT_DIR="$OUTPUT_BASE_DIR/$LANG_CODE/$RELATIVE_DIR"
    fi

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    print_message "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$GREEN" "Multi-Pass Translation to $LANG_NAME"
    print_message "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$MAGENTA" "Input: $INPUT_FILE"
    print_message "$MAGENTA" "Language: $LANG_NAME ($LANG_CODE)"
    print_message "$MAGENTA" "Output Dir: $OUTPUT_DIR"
    print_message "$MAGENTA" "Session: ${LANG_CODE}_${TIMESTAMP}"

    # Copy source
    cp "$INPUT_FILE" "$SESSION_DIR/stage0_source.txt"

    # Define stage files based on language
    # Check which stage files exist for the language
    if [ -f "$LANG_PROMPTS_DIR/stage1-initial.md" ]; then
        # New naming convention (de/)
        STAGE1_PROMPT="$LANG_PROMPTS_DIR/stage1-initial.md"
        STAGE2_PROMPT="$LANG_PROMPTS_DIR/stage2-terminology.md"
        STAGE3_PROMPT="$LANG_PROMPTS_DIR/stage3-cultural.md"
        STAGE4_PROMPT="$LANG_PROMPTS_DIR/stage4-tone.md"
        STAGE5_PROMPT="$LANG_PROMPTS_DIR/stage5-quality.md"
        STAGE6_PROMPT="$LANG_PROMPTS_DIR/stage6-correction.md"
        STAGE7_PROMPT="$LANG_PROMPTS_DIR/stage7-final-validation.md"
    else
        # Old naming convention (nl/)
        STAGE1_PROMPT="$LANG_PROMPTS_DIR/translation-stage1-initial.md"
        STAGE2_PROMPT="$LANG_PROMPTS_DIR/translation-stage2-terminology.md"
        STAGE3_PROMPT="$LANG_PROMPTS_DIR/translation-stage3-cultural.md"
        STAGE4_PROMPT="$LANG_PROMPTS_DIR/translation-stage4-tone.md"
        STAGE5_PROMPT="$LANG_PROMPTS_DIR/translation-stage5-quality.md"
        STAGE6_PROMPT="$LANG_PROMPTS_DIR/translation-stage6-correction.md"
        STAGE7_PROMPT="$LANG_PROMPTS_DIR/translation-stage7-final-validation.md"
    fi

    # Language-specific instructions
    if [ "$LANG_CODE" = "de" ]; then
        INSTRUCTION_1="ultrathink. Translate this English content to German. Output only the translation, no commentary."
        INSTRUCTION_2="ultrathink. Review and refine all technical terminology. Output only the refined translation."
        INSTRUCTION_3="ultrathink. Adapt for German business culture. Output only the adapted translation."
        INSTRUCTION_4="ultrathink. Refine tone for NOVENCO brand voice. Output only the final translation."
    else
        INSTRUCTION_1="ultrathink. Translate this English content to Dutch. Output only the translation, no commentary."
        INSTRUCTION_2="ultrathink. Review and refine all technical terminology. Output only the refined translation."
        INSTRUCTION_3="ultrathink. Adapt for Dutch business culture. Output only the adapted translation."
        INSTRUCTION_4="ultrathink. Refine tone for NOVENCO brand voice. Output only the final translation."
    fi

    # Stage 1: Initial Translation
    run_stage 1 "Initial Translation" \
        "$STAGE1_PROMPT" \
        "$SESSION_DIR/stage0_source.txt" \
        "$SESSION_DIR/stage1.txt" \
        "$INSTRUCTION_1"

    # Stage 2: Terminology Refinement
    run_stage 2 "Terminology Refinement" \
        "$STAGE2_PROMPT" \
        "$SESSION_DIR/stage1.txt" \
        "$SESSION_DIR/stage2.txt" \
        "$INSTRUCTION_2"

    # Stage 3: Cultural Adaptation
    run_stage 3 "Cultural Adaptation" \
        "$STAGE3_PROMPT" \
        "$SESSION_DIR/stage2.txt" \
        "$SESSION_DIR/stage3.txt" \
        "$INSTRUCTION_3"

    # Stage 4: Tone Refinement
    run_stage 4 "Tone & Style Refinement" \
        "$STAGE4_PROMPT" \
        "$SESSION_DIR/stage3.txt" \
        "$SESSION_DIR/stage4.txt" \
        "$INSTRUCTION_4"

    # Stage 5: Quality Check - Special handling
    # Create combined input for quality check
    cat > "$SESSION_DIR/stage5_input.txt" << EOF
ORIGINAL ENGLISH SOURCE:
$(cat "$SESSION_DIR/stage0_source.txt")

FINAL $LANG_NAME TRANSLATION:
$(cat "$SESSION_DIR/stage4.txt")
EOF

    # Run quality check but don't save to final output
    print_stage_header 5 "Quality Check"

    # Read system prompt
    QUALITY_PROMPT=$(cat "$STAGE5_PROMPT")

    # Create quality check prompt
    QUALITY_CHECK_PROMPT="Compare the translation against the original and provide quality assessment.

---BEGIN CONTENT---
$(cat "$SESSION_DIR/stage5_input.txt")
---END CONTENT---

Provide your quality assessment."

    print_message "$YELLOW" "Running quality check..."

    # Run quality check and save to log
    echo "$QUALITY_CHECK_PROMPT" | claude -p --system-prompt "$QUALITY_PROMPT" > "$SESSION_DIR/quality_check.log" 2>/dev/null

    # Check if quality check passed (look for FREIGEGEBEN or APPROVED)
    if grep -q -E "(FREIGEGEBEN|APPROVED)" "$SESSION_DIR/quality_check.log"; then
        print_message "$GREEN" "✓ Quality check PASSED"
    else
        print_message "$YELLOW" "⚠ Quality check found issues - continuing to correction stage"
    fi

    # Stage 6: Apply Corrections
    # Create combined input for correction stage
    cat > "$SESSION_DIR/stage6_input.txt" << EOF
QUALITY CHECK FEEDBACK:
$(cat "$SESSION_DIR/quality_check.log")

---

TRANSLATION TO CORRECT:
$(cat "$SESSION_DIR/stage4.txt")
EOF

    INSTRUCTION_6="Apply all corrections from the quality check feedback. Output ONLY the complete corrected $LANG_NAME markdown translation. Do NOT include commentary or summaries. Start directly with --- (YAML frontmatter) or the first heading."

    run_stage 6 "Apply Corrections" \
        "$STAGE6_PROMPT" \
        "$SESSION_DIR/stage6_input.txt" \
        "$SESSION_DIR/stage6.txt" \
        "$INSTRUCTION_6"

    # Stage 7: Final Validation - Quick check
    # Create combined input for final validation
    cat > "$SESSION_DIR/stage7_input.txt" << EOF
ORIGINAL QUALITY CHECK FEEDBACK (Stage 5):
$(cat "$SESSION_DIR/quality_check.log")

---

CORRECTED TRANSLATION (Stage 6 Output):
$(cat "$SESSION_DIR/stage6.txt")
EOF

    print_stage_header 7 "Final Validation"

    # Read system prompt
    VALIDATION_PROMPT=$(cat "$STAGE7_PROMPT")

    # Create validation prompt
    VALIDATION_CHECK_PROMPT="Validate that corrections were applied properly.

---BEGIN CONTENT---
$(cat "$SESSION_DIR/stage7_input.txt")
---END CONTENT---

Provide your brief validation assessment."

    print_message "$YELLOW" "Running final validation..."

    # Run validation and save to log
    echo "$VALIDATION_CHECK_PROMPT" | claude -p --system-prompt "$VALIDATION_PROMPT" > "$SESSION_DIR/final_validation.log" 2>/dev/null

    # Check if validation passed
    if grep -q -E "(FREIGEGEBEN|APPROVED|GOEDGEKEURD)" "$SESSION_DIR/final_validation.log"; then
        print_message "$GREEN" "✓ Final validation PASSED"
    else
        print_message "$YELLOW" "⚠ Final validation completed - review log for details"
    fi

    # Save final output (Stage 6, which is the corrected translation)
    FINAL_OUTPUT="$OUTPUT_DIR/${BASE_NAME}.md"
    cp "$SESSION_DIR/stage6.txt" "$FINAL_OUTPUT"

    # Clean up the final output one more time to ensure no English preamble
    extract_translation_content "$FINAL_OUTPUT" "${FINAL_OUTPUT}.cleaned"
    mv "${FINAL_OUTPUT}.cleaned" "$FINAL_OUTPUT"

    # Generate report
    REPORT_FILE="$OUTPUT_DIR/${BASE_NAME}_report.txt"
    cat > "$REPORT_FILE" << EOF
Multi-Pass Translation Report (7-Stage Process)
Language: $LANG_NAME ($LANG_CODE)
Generated: $(date)

Input: $INPUT_FILE
Output: $FINAL_OUTPUT
Relative Path: $RELATIVE_PATH

Quality Check Summary (Stage 5):
$(grep -E "(FREIGEGEBEN|APPROVED|ÜBERARBEITUNG|REVISION|GOEDGEKEURD)" "$SESSION_DIR/quality_check.log" | head -5)

Final Validation Summary (Stage 7):
$(grep -E "(FREIGEGEBEN|APPROVED|GOEDGEKEURD|ENDURTEIL|ABSCHLUSSVALIDIERUNG|EINDVALIDATIE)" "$SESSION_DIR/final_validation.log" | head -3)

Session Files:
- Initial Translation: $SESSION_DIR/stage1.txt
- Terminology Refinement: $SESSION_DIR/stage2.txt
- Cultural Adaptation: $SESSION_DIR/stage3.txt
- Tone & Style Refinement: $SESSION_DIR/stage4.txt
- Quality Analysis: $SESSION_DIR/quality_check.log
- Corrected Translation: $SESSION_DIR/stage6.txt (FINAL OUTPUT)
- Final Validation: $SESSION_DIR/final_validation.log

All intermediate files preserved in: $SESSION_DIR
EOF

    print_message "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$GREEN" "✓ Translation Complete!"
    print_message "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$MAGENTA" "Final: $FINAL_OUTPUT"
    print_message "$MAGENTA" "Report: $REPORT_FILE"
    print_message "$MAGENTA" "Quality Log: $SESSION_DIR/quality_check.log"
}

# Run
main "$@"