class DepartmentsController < ApplicationController
  before_filter :redirect_customer_users
  load_and_authorize_resource

  def index
    if @departments.size == 1
      redirect_to [@departments.first, :customers]
    elsif @departments.size == 0
      sign_out current_user
      redirect_to new_user_session_path, :alert => "Kontoen har ikke nogen rettigheder.<br>Kontakt en adminstrator for mere information.".html_safe
    end
  end

  private

  def redirect_customer_users
    redirect_to customer_root_path if current_user.role == 'customer'
  end

end
