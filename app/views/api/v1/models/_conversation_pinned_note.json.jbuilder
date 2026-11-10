json.id resource.id
json.content resource.content
json.account_id resource.account_id
json.conversation_id resource.conversation.display_id
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
if resource.user.present?
  json.user do
    json.id resource.user.id
    json.name resource.user.available_name
  end
end
