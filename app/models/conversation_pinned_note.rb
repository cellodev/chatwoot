# == Schema Information
#
# Table name: conversation_pinned_notes
#
#  id              :bigint           not null, primary key
#  content         :string(300)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#  conversation_id :integer          not null
#  user_id         :integer
#
# Indexes
#
#  index_conversation_pinned_notes_on_account_id       (account_id)
#  index_conversation_pinned_notes_on_conversation_id  (conversation_id) UNIQUE
#  index_conversation_pinned_notes_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class ConversationPinnedNote < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :user, optional: true

  before_validation :strip_content

  validates :content, presence: true, length: { maximum: 300 }
  validates :conversation_id, uniqueness: true
  validate :same_account_as_conversation

  private

  def strip_content
    self.content = content.to_s.strip
  end

  def same_account_as_conversation
    return if conversation.blank? || account_id.blank?
    return if conversation.account_id == account_id

    errors.add(:account_id, 'does not match conversation')
  end
end
