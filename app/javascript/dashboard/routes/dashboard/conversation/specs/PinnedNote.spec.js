import { mount, flushPromises } from '@vue/test-utils';
import PinnedNote from '../PinnedNote.vue';
import ConversationPinnedNotesAPI from 'dashboard/api/conversationPinnedNotes';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params) =>
      [key, ...(params ? Object.values(params) : [])].join(' '),
  }),
}));

vi.mock('dashboard/api/conversationPinnedNotes', () => ({
  default: {
    get: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
}));

const savedNote = {
  id: 1,
  content: 'Cliente VIP. Sempre oferecer frete grátis.',
  updated_at: 1_762_800_000,
  user: { id: 4, name: 'Ana' },
};

const mountNote = () =>
  mount(PinnedNote, {
    props: { conversationId: 7 },
  });

describe('PinnedNote', () => {
  beforeEach(() => {
    ConversationPinnedNotesAPI.get.mockResolvedValue({
      data: { pinned_note: null },
    });
    ConversationPinnedNotesAPI.update.mockResolvedValue({
      data: { pinned_note: savedNote },
    });
    ConversationPinnedNotesAPI.delete.mockResolvedValue({});
  });

  it('shows the editor when the conversation has no pinned note', async () => {
    const wrapper = mountNote();
    await flushPromises();

    expect(wrapper.find('textarea').exists()).toBe(true);
    expect(ConversationPinnedNotesAPI.get).toHaveBeenCalledWith(7);
  });

  it('shows the note with the author and the last update', async () => {
    ConversationPinnedNotesAPI.get.mockResolvedValue({
      data: { pinned_note: savedNote },
    });

    const wrapper = mountNote();
    await flushPromises();

    expect(wrapper.text()).toContain(savedNote.content);
    expect(wrapper.text()).toContain('Ana');
    expect(wrapper.text()).toContain('2025');
  });

  it('creates a pinned note', async () => {
    const wrapper = mountNote();
    await flushPromises();

    await wrapper.find('textarea').setValue('  Novo recado  ');
    const saveButton = wrapper
      .findAll('button')
      .find(button => button.text().includes('SAVE'));
    await saveButton.trigger('click');
    await flushPromises();

    expect(ConversationPinnedNotesAPI.update).toHaveBeenCalledWith(
      7,
      'Novo recado'
    );
    expect(wrapper.text()).toContain(savedNote.content);
  });

  it('removes the pinned note', async () => {
    ConversationPinnedNotesAPI.get.mockResolvedValue({
      data: { pinned_note: savedNote },
    });

    const wrapper = mountNote();
    await flushPromises();

    const deleteButton = wrapper
      .findAll('button')
      .find(button => button.text().includes('DELETE'));
    await deleteButton.trigger('click');
    await flushPromises();

    expect(ConversationPinnedNotesAPI.delete).toHaveBeenCalledWith(7);
    expect(wrapper.find('textarea').exists()).toBe(true);
  });
});
