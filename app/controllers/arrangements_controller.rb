class ArrangementsController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :customer, :through => :department
  load_and_authorize_resource :through => :customer

  def new
    current = @customer.current_arrangement
    @arrangement.use_scrap = current.use_scrap
    @arrangement.use_scrap_minimum = current.use_scrap_minimum
    @arrangement.scrap_minimum = current.scrap_minimum
  end

  def create
    if @arrangement.save
      redirect_to [@department, @customer], :notice => "Aftalen er nu oprettet."
    else
      render :action => 'new'
    end
  end

  private

  def arrangement_params
    params.require(:arrangement).permit(:use_scrap, :use_scrap_minimum, :scrap_minimum)
  end

end
