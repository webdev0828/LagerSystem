class OrderTrayController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :order, :parent => false

  def index
    @orders = @orders.includes(:customer).where('customers.department_id' => @department.id)
    @orders = @orders.where('orders.done_at IS NULL OR orders.done_at > ?', Time.now.yesterday.utc)
    @orders = @orders.order('orders.done_at DESC, orders.created_at DESC')
    @order_groups = @orders.group_by { |o| o.state.to_sym }
    @labels = { 'finished' => 'Afhentet sidste 24 timer' }
  end

end