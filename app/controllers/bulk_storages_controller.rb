class BulkStoragesController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :through => :department

  def update
    if @bulk_storage.update_attributes(bulk_storage_params)
      redirect_to([@department, @bulk_storage], :notice => 'Lagret er nu opdateret.')
    else
      render :action => "edit"
    end
  end

  def create
    if @bulk_storage.save
      redirect_to([@department, @bulk_storage], :notice => 'Lagret er nu oprettet.')
    else
      render :action => "new"
    end
  end

  def destroy
    if @department.transfer_id == @bulk_storage.id
      redirect_to [@department, @bulk_storage], alert: 'Du kan ikke slette afdelingens transferlager.'
    elsif @department.lobby_id == @bulk_storage.id
      redirect_to [@department, @bulk_storage], alert: 'Du kan ikke slette afdelingens lobbylager.'
    elsif @bulk_storage.destroy
      redirect_to([@department, :storages], notice: 'Lageret er nu slettet.')
    else
      redirect_to([@department, @bulk_storage], alert: 'Du kan kun slette tomme lagre.')
    end
  end

  def bulk_storage_params
    params.require(:bulk_storage).permit(:name)
  end

end
