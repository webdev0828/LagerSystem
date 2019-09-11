class OrderImportsController < ApplicationController

  load_and_authorize_resource :department
  load_and_authorize_resource :customer_group, through: :department
  load_and_authorize_resource through: :customer_group

  def index
    @order_imports = @order_imports.includes(orders: :reservations)
    @order_imports = @order_imports.order('id DESC')
    @order_imports = @order_imports.paginate(:page => params[:page], :per_page => 20)
  end

  def create
    @order_import.owner = current_user
    if @order_import.save
      redirect_to [@department, @customer_group, @order_import]
    else
      render 'new'
    end
  end

  def update
    @order_import.owner = current_user
    if @order_import.update(update_params)
      redirect_to [@department, @customer_group, @order_import], notice: 'Import samt ordrer er nu opdateret'
    else
      render 'edit'
    end
  end

  def approve
    flash_errors = []
    @order_import.orders.each do |order|
      order.do! :submit, current_user unless order.submitted?
      flash_errors << order.alert_errors if order.alert_errors
    end
    flash[:notice] = 'Importens ordrer blev markeret som Oprettet' unless flash_errors.present?
    redirect_to [@department, @customer_group, @order_import]
  end

  def destroy
    @order_import.destroy
    redirect_to [@department, @customer_group], notice: 'Import er nu slettet'
  end

  private

  def create_params
    params.fetch(:order_import, {}).permit(:file)
  end

  def update_params
    params.require(:order_import).permit(:number, :load_at, :deliver_at, :destination_name, :destination_address, :delivery, :note)
  end

end
