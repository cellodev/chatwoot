/* global axios */
import ApiClient from './ApiClient';

class ConversationPinnedNotes extends ApiClient {
  constructor() {
    super('pinned_note', { accountScoped: true });
    this.conversationId = null;
  }

  get url() {
    return `${this.baseUrl()}/conversations/${this.conversationId}/pinned_note`;
  }

  get(conversationId) {
    this.conversationId = conversationId;
    return axios.get(this.url);
  }

  update(conversationId, content) {
    this.conversationId = conversationId;
    return axios.patch(this.url, { pinned_note: { content } });
  }

  delete(conversationId) {
    this.conversationId = conversationId;
    return axios.delete(this.url);
  }
}

export default new ConversationPinnedNotes();
