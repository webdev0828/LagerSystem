class CustomersController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :through => :department, :except => :sort

  def index
    d2,d1 = @customers.partition(&:deactivated)
    @customers = d1 + d2
    @customers.each_with_index do |c,i|
      c.set_list_position(i + 1) if c.position != i + 1
    end

  end

  def create
    if @customer.save
      redirect_to([@department, @customer], :notice => 'Kunden er nu oprettet.')
    else
      render :action => "new"
    end
  end

  def update
    if @customer.update_attributes(customer_params)
      redirect_to([@department, @customer], :notice => 'Kunden er nu opdateret.')
    else
      render :action => "edit"
    end
  end

  def sort
    authorize! :update, Customer
    saved = false
    if params[:position].present?
      customer = @department.customers.find_by_id(params[:item_id])
      unless customer.nil?
        customer.insert_at(params[:position].to_i)
        saved = true
      end
    end
    render :json => { :ok => saved }
  end

  private

  def customer_params
    params.require(:customer).permit(:name, :number, :subname, :address, :phone, :fax, :email, :deactivated) # :barcode_format
  end

end
