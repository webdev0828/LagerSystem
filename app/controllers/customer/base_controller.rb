class Customer::BaseController < ApplicationController

  layout 'customer'

  def current_ability
    @current_ability ||= CustomerAbility.new(current_user)
  end



end