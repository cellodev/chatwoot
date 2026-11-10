require 'rails_helper'

RSpec.describe ConversationPinnedNote do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_length_of(:content).is_at_most(300) }

    it 'allows one note per conversation' do
      pinned_note = create(:conversation_pinned_note)
      duplicate = build(:conversation_pinned_note, conversation: pinned_note.conversation, account: pinned_note.account)
      expect(duplicate).not_to be_valid
    end

    it 'rejects a note whose account does not match the conversation' do
      pinned_note = build(:conversation_pinned_note)
      pinned_note.account = create(:account)
      expect(pinned_note).not_to be_valid
    end

    it 'strips surrounding whitespace' do
      pinned_note = create(:conversation_pinned_note, content: '  recado  ')
      expect(pinned_note.content).to eq('recado')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user).optional }
  end
end
