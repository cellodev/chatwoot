class CreateConversationPinnedNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_pinned_notes do |t|
      t.integer :account_id, null: false
      t.integer :conversation_id, null: false
      t.integer :user_id
      t.string :content, null: false, limit: 300

      t.timestamps
    end

    add_index :conversation_pinned_notes, :account_id
    add_index :conversation_pinned_notes, :conversation_id, unique: true
    add_index :conversation_pinned_notes, :user_id

    add_foreign_key :conversation_pinned_notes, :accounts, on_delete: :cascade
    add_foreign_key :conversation_pinned_notes, :conversations, on_delete: :cascade
    add_foreign_key :conversation_pinned_notes, :users, on_delete: :nullify
  end
end
