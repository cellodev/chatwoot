<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { format, fromUnixTime } from 'date-fns';
import ConversationPinnedNotesAPI from 'dashboard/api/conversationPinnedNotes';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const MAX_LENGTH = 300;

const { t } = useI18n();
const note = ref(null);
const draft = ref('');
const editing = ref(false);
const isLoading = ref(false);
const isSaving = ref(false);
const errorMessage = ref('');

const isEditing = computed(() => editing.value || !note.value);
const trimmedDraft = computed(() => draft.value.trim());
const canSave = computed(
  () =>
    trimmedDraft.value.length > 0 &&
    trimmedDraft.value.length <= MAX_LENGTH &&
    !isSaving.value
);

const updatedLabel = computed(() => {
  if (!note.value?.updated_at) return '';
  return format(fromUnixTime(note.value.updated_at), 'MMM d, yyyy, h:mm a');
});

const counterLabel = computed(
  () => `${trimmedDraft.value.length}/${MAX_LENGTH}`
);

const metaLabel = computed(() => {
  const name = note.value?.user?.name;
  const date = updatedLabel.value;
  if (name && date) {
    return t('CONVERSATION_SIDEBAR.PINNED_NOTE.META', { name, date });
  }
  return name || date;
});

const readNote = data => {
  if (!data || !data.pinned_note) return null;
  return data.pinned_note;
};

const loadNote = async conversationId => {
  if (!conversationId) return;

  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await ConversationPinnedNotesAPI.get(conversationId);
    note.value = readNote(data);
    draft.value = note.value?.content || '';
    editing.value = false;
  } catch {
    errorMessage.value = t('CONVERSATION_SIDEBAR.PINNED_NOTE.ERROR');
  } finally {
    isLoading.value = false;
  }
};

const startEditing = () => {
  draft.value = note.value?.content || '';
  editing.value = true;
  errorMessage.value = '';
};

const cancelEditing = () => {
  editing.value = false;
  draft.value = note.value?.content || '';
  errorMessage.value = '';
};

const save = async () => {
  if (!canSave.value) return;

  isSaving.value = true;
  errorMessage.value = '';
  try {
    const { data } = await ConversationPinnedNotesAPI.update(
      props.conversationId,
      trimmedDraft.value
    );
    note.value = readNote(data);
    draft.value = note.value?.content || '';
    editing.value = false;
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.message ||
      t('CONVERSATION_SIDEBAR.PINNED_NOTE.ERROR');
  } finally {
    isSaving.value = false;
  }
};

const remove = async () => {
  if (isSaving.value) return;

  isSaving.value = true;
  errorMessage.value = '';
  try {
    await ConversationPinnedNotesAPI.delete(props.conversationId);
    note.value = null;
    draft.value = '';
    editing.value = false;
  } catch {
    errorMessage.value = t('CONVERSATION_SIDEBAR.PINNED_NOTE.ERROR');
  } finally {
    isSaving.value = false;
  }
};

watch(() => props.conversationId, loadNote, { immediate: true });
</script>

<template>
  <section class="px-4 py-3 border-b border-n-weak">
    <div class="flex items-center justify-between gap-2 mb-2">
      <h3 class="text-sm font-medium text-n-slate-12">
        {{ t('CONVERSATION_SIDEBAR.PINNED_NOTE.TITLE') }}
      </h3>
      <span v-if="isEditing" class="text-xs text-n-slate-11">
        {{ counterLabel }}
      </span>
    </div>

    <p v-if="isLoading" class="text-sm text-n-slate-11">
      {{ t('CONVERSATION_SIDEBAR.PINNED_NOTE.LOADING') }}
    </p>

    <template v-else-if="isEditing">
      <textarea
        v-model="draft"
        rows="3"
        :maxlength="MAX_LENGTH"
        class="w-full px-3 py-2 text-sm border rounded-lg outline-none resize-none bg-n-alpha-2 border-n-weak text-n-slate-12 placeholder:text-n-slate-10 focus:border-n-brand"
        :placeholder="t('CONVERSATION_SIDEBAR.PINNED_NOTE.PLACEHOLDER')"
      />
      <div class="flex items-center gap-2 mt-2">
        <NextButton
          xs
          :is-loading="isSaving"
          :disabled="!canSave"
          @click="save"
        >
          {{ t('CONVERSATION_SIDEBAR.PINNED_NOTE.SAVE') }}
        </NextButton>
        <NextButton
          v-if="note"
          xs
          ghost
          :disabled="isSaving"
          @click="cancelEditing"
        >
          {{ t('CONVERSATION_SIDEBAR.PINNED_NOTE.CANCEL') }}
        </NextButton>
      </div>
    </template>

    <div
      v-else
      class="px-3 py-2 rounded-lg bg-n-amber-3 border border-n-amber-4"
    >
      <p class="text-sm whitespace-pre-wrap break-words text-n-slate-12">
        {{ note.content }}
      </p>
      <p class="mt-2 text-xs text-n-slate-11">
        {{ metaLabel }}
      </p>
      <div class="flex items-center gap-2 mt-2">
        <NextButton xs ghost @click="startEditing">
          {{ t('CONVERSATION_SIDEBAR.PINNED_NOTE.EDIT') }}
        </NextButton>
        <NextButton
          xs
          ghost
          color="ruby"
          :is-loading="isSaving"
          :disabled="isSaving"
          @click="remove"
        >
          {{ t('CONVERSATION_SIDEBAR.PINNED_NOTE.DELETE') }}
        </NextButton>
      </div>
    </div>

    <p v-if="errorMessage" class="mt-2 text-xs text-n-ruby-11">
      {{ errorMessage }}
    </p>
  </section>
</template>
