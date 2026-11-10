class Api::V1::Accounts::Conversations::PinnedNotesController < Api::V1::Accounts::Conversations::BaseController
  def show
    @pinned_note = @conversation.pinned_note
  end

  def update
    @pinned_note = find_or_build_pinned_note
    @pinned_note.update!(pinned_note_attributes)
    render :show
  end

  def destroy
    @conversation.pinned_note&.destroy!
    head :ok
  end

  private

  def find_or_build_pinned_note
    @conversation.pinned_note || @conversation.build_pinned_note(account: @conversation.account)
  end

  def pinned_note_attributes
    attributes = {
      content: pinned_note_params[:content],
      account: @conversation.account
    }
    attributes[:user] = Current.user if Current.user.is_a?(User)
    attributes
  end

  def pinned_note_params
    params.require(:pinned_note).permit(:content)
  end
end
