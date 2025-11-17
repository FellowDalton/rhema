<script setup>
import { ref, onMounted } from "vue";
import { usePrayerStore } from "@/stores/prayerStore";
import { storeToRefs } from "pinia";
import ModalTemplate from "@/components/templates/ModalTemplate.vue";
import Textarea from "@/components/atoms/Textarea.vue";
import Button from "@/components/atoms/Button.vue";

const props = defineProps({
  isOpen: {
    type: Boolean,
    required: true,
  },
  prayerId: {
    type: String,
    required: true,
  },
});

const emits = defineEmits(["close"]);

const prayerStore = usePrayerStore();
const prayerContent = ref("");
const copiedToClipboard = ref(false);

onMounted(async () => {
  try {
    const prayer = await prayerStore.fetchPrayer(props.prayerId);
    prayerContent.value = generatePrayerContent(prayer);
  } catch (err) {
    console.error("Error loading prayer:", err);
  }
});

const generatePrayerContent = (prayer) => {
  // This function should format the prayer content as needed
  // Including impressions, comments, etc.
  return `Prayer: ${prayer.title}\n\n${prayer.description}\n\nImpressions:\n...`;
};

const copyToClipboard = async () => {
  try {
    await navigator.clipboard.writeText(prayerContent.value);
    copiedToClipboard.value = true;
    setTimeout(() => {
      copiedToClipboard.value = false;
    }, 2000);
  } catch (err) {
    console.error("Failed to copy text: ", err);
  }
};
</script>

<template>
  <ModalTemplate :is-open="isOpen" title="Send Prayer" @close="$emit('close')">
    <div class="send-prayer-modal">
      <Textarea
        v-model="prayerContent"
        label="Prayer Content"
        readonly
        :rows="10"
      />
      <div class="send-prayer-modal__links">
        <a href="#" class="send-prayer-modal__link"
          >Ask questions or file complaints</a
        >
        <a href="#" class="send-prayer-modal__link"
          >Data protection and terms of use</a
        >
      </div>
      <p v-if="error" class="send-prayer-modal__error">{{ error }}</p>
    </div>
    <template #footer>
      <Button @click="$emit('close')" variant="secondary">Close</Button>
      <Button @click="copyToClipboard" variant="primary">
        {{ copiedToClipboard ? "Copied!" : "Copy to Clipboard" }}
      </Button>
    </template>
  </ModalTemplate>
</template>

<style lang="scss" scoped>
.send-prayer-modal {
  display: flex;
  flex-direction: column;
  gap: 1rem;

  &__links {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  &__link {
    color: var(--text-color);
    font-size: 0.875rem;
    text-decoration: none;

    &:hover {
      text-decoration: underline;
    }
  }

  &__error {
    color: var(--error-color);
    font-size: 0.875rem;
    margin: 0;
  }
}
</style>
