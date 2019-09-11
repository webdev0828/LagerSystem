class Customer::HomeController < Customer::BaseController
  load_and_authorize_resource :customer, :parent => false

  def index
    @customers = @customers.includes(:department)
  end

end
