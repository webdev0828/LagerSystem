class CustomerGroupsController < ApplicationController

  LATEST_COUNT = 5

  load_and_authorize_resource :department
  load_and_authorize_resource through: :department

  def index
    # show a list of all importers
  end

  def show
    # show form to create new importer
    @order_import = @customer_group.order_imports.build

    @order_imports = @customer_group.order_imports.order('id DESC').limit(LATEST_COUNT + 1).all
    @more = @order_imports.size > LATEST_COUNT
    @order_imports = @order_imports.first(LATEST_COUNT)
  end

  # new, create, edit, update, destroy is not for users

  def pallets
    @pallets = @customer_group.pallets
    @pallets = @pallets.includes(:position, :customer)
    @pallets = @pallets.where(:deleted_at => nil).order("best_before, taken + reserved DESC, batch")

    @pallets = @pallets.where('pallets.number LIKE ?', "#{params[:number]}%") unless params[:number].blank?
    @pallets = @pallets.where('pallets.batch LIKE ?',  "#{params[:batch]}%")  unless params[:batch].blank?
    @pallets = @pallets.where('pallets.trace LIKE ?',  "#{params[:trace]}%")  unless params[:trace].blank?

    @pallets = @pallets.paginate(:page => params[:page], :per_page => 30)

    flash.now[:notice] = "#{total = @pallets.total_entries} palle#{'r' if total != 1} fundet."
  end

end
