# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_pinned_note do
    content { 'Cliente VIP. Sempre oferecer frete grátis.' }
    conversation
    user

    after(:build) do |pinned_note|
      pinned_note.account = pinned_note.conversation.account
    end
  end
end
