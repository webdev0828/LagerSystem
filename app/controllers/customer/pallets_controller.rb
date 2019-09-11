class Customer::PalletsController < Customer::BaseController
  load_and_authorize_resource :customer
  load_and_authorize_resource :through => :customer

  def index
    @pallets = @pallets.where(:deleted_at => nil).order('arrived_at DESC, created_at DESC')

    @pallets = @pallets.where('pallets.number LIKE ?', "#{params[:number]}%") unless params[:number].blank?
    @pallets = @pallets.where('pallets.batch LIKE ?',  "#{params[:batch]}%")  unless params[:batch].blank?
    @pallets = @pallets.where('pallets.trace LIKE ?',  "#{params[:trace]}%")  unless params[:trace].blank?

    @pallets = @pallets.paginate(:page => params[:page], :per_page => 30)
  end

  def show
  end

end
