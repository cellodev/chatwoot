if @pinned_note
  json.pinned_note do
    json.partial! 'api/v1/models/conversation_pinned_note', formats: [:json], resource: @pinned_note
  end
else
  json.pinned_note nil
end
