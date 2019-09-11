class OrderHistoryController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :order, :parent => false

  def index
    @customers = @department.customers
    @customers = @customers.where(id: params[:customer_id]) unless params[:customer_id].to_i == 0

    @orders = @orders.includes(:customer, :reservations => :pallet)
    @orders = @orders.where(customer_id: @customers.pluck(:id))

    @orders = @orders.where(:state => 'finished')
    @orders = @orders.order('orders.done_at DESC')

    # @orders = @orders.where('orders.customer_id = ?',         "#{params[:customer_id]}")       unless params[:customer_id].to_i == 0
    @orders = @orders.where('orders.number LIKE ?',           "#{params[:order_number]}%")     unless params[:order_number].blank?
    @orders = @orders.where('orders.destination_name LIKE ?', "#{params[:destination_name]}%") unless params[:destination_name].blank?

    @orders = @orders.where('pallets.number LIKE ?',          "#{params[:article_number]}%").references(:pallet)   unless params[:article_number].blank?
    @orders = @orders.where('pallets.batch LIKE ?',           "#{params[:batch]}%").references(:pallet)            unless params[:batch].blank?
    @orders = @orders.where('pallets.trace LIKE ?',           "#{params[:trace]}%").references(:pallet)            unless params[:trace].blank?

    @orders = @orders.paginate(:page => params[:page], :per_page => 20)
  end

end
