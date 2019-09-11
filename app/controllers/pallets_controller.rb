class PalletsController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :customer, :through => :department
  load_and_authorize_resource :through => :customer

  def index
    @pallets = @pallets.includes(:position)
    @pallets = @pallets.where(:deleted_at => nil).order("best_before, taken + reserved DESC, batch")

    @pallets = @pallets.where('pallets.number LIKE ?', "#{params[:number]}%") unless params[:number].blank?
    @pallets = @pallets.where('pallets.batch LIKE ?',  "#{params[:batch]}%")  unless params[:batch].blank?
    @pallets = @pallets.where('pallets.trace LIKE ?',  "#{params[:trace]}%")  unless params[:trace].blank?

    @pallets = @pallets.paginate(:page => params[:page], :per_page => 30)

    flash.now[:notice] = "#{total = @pallets.total_entries} palle#{'r' if total != 1} fundet."
  end

end