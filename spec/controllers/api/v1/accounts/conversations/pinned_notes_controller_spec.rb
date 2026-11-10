require 'rails_helper'

RSpec.describe 'Conversation Pinned Note API', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:note_url) do
    api_v1_account_conversation_pinned_note_url(account_id: account.id, conversation_id: conversation.display_id)
  end

  describe 'GET /api/v1/accounts/:account_id/conversations/:id/pinned_note' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get note_url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'returns an empty note' do
        get note_url, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['pinned_note']).to be_nil
      end

      it 'returns the note with the author and the last update' do
        pinned_note = create(:conversation_pinned_note, conversation: conversation, user: agent)

        get note_url, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body['pinned_note']
        expect(body['content']).to eq(pinned_note.content)
        expect(body['user']['name']).to eq(agent.available_name)
        expect(body['updated_at']).to eq(pinned_note.updated_at.to_i)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/conversations/:id/pinned_note' do
    before do
      create(:inbox_member, inbox: conversation.inbox, user: agent)
    end

    it 'creates the pinned note' do
      patch note_url,
            params: { pinned_note: { content: 'Cliente VIP. Sempre oferecer frete grátis.' } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      note = conversation.reload.pinned_note
      expect(note.content).to eq('Cliente VIP. Sempre oferecer frete grátis.')
      expect(note.user).to eq(agent)
      expect(note.account).to eq(account)
    end

    it 'updates the existing note and the author' do
      editor = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: conversation.inbox, user: editor)
      create(:conversation_pinned_note, conversation: conversation, user: agent, content: 'nota antiga')

      patch note_url,
            params: { pinned_note: { content: 'nota nova' } },
            headers: editor.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(conversation.reload.pinned_note.content).to eq('nota nova')
      expect(conversation.pinned_note.user).to eq(editor)
      expect(ConversationPinnedNote.where(conversation: conversation).count).to eq(1)
    end

    it 'rejects a note longer than 300 characters' do
      patch note_url,
            params: { pinned_note: { content: 'a' * 301 } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(conversation.reload.pinned_note).to be_nil
    end

    it 'rejects a blank note' do
      patch note_url,
            params: { pinned_note: { content: '   ' } },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/conversations/:id/pinned_note' do
    before do
      create(:inbox_member, inbox: conversation.inbox, user: agent)
    end

    it 'removes the pinned note' do
      create(:conversation_pinned_note, conversation: conversation, user: agent)

      delete note_url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(conversation.reload.pinned_note).to be_nil
    end
  end

  describe 'account isolation' do
    let(:other_account) { create(:account) }
    let(:other_agent) { create(:user, account: other_account, role: :agent) }
    let(:other_conversation) { create(:conversation, account: other_account) }

    before do
      create(:inbox_member, inbox: conversation.inbox, user: agent)
      create(:inbox_member, inbox: other_conversation.inbox, user: other_agent)
      create(:conversation_pinned_note, conversation: conversation, user: agent, content: 'segredo da conta')
    end

    it 'does not let an agent from another account read the note' do
      get note_url, headers: other_agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).not_to include('segredo da conta')
    end

    it 'does not let an agent from another account change the note' do
      patch note_url,
            params: { pinned_note: { content: 'invasao' } },
            headers: other_agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(conversation.reload.pinned_note.content).to eq('segredo da conta')
    end

    it 'does not return the note through another account even when the display id matches' do
      create(:account_user, account: other_account, user: agent)
      create(:inbox_member, inbox: other_conversation.inbox, user: agent)
      other_url = api_v1_account_conversation_pinned_note_url(
        account_id: other_account.id,
        conversation_id: other_conversation.display_id
      )

      get other_url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('segredo da conta')
      expect(response.parsed_body['pinned_note']).to be_nil
    end
  end
end
