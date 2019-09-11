class NotesController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :customer, :through => :department
  load_and_authorize_resource :through => :customer

  def create
    # if loaded through interval route
    @interval = @customer.intervals.find_by_id(params[:interval_id])
    @interval ||= @customer.build_current_interval

    @note.posted_at = @interval.middle_datetime
    @note.save
  end

  def update
    @note.update_attributes(note_params)
  end

  def destroy
    # TODO need checks for last_count
    @note.destroy
  end

  private

  def note_params
    params.require(:note).permit(:content)
  end

end
