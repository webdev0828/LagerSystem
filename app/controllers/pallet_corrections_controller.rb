# encoding: utf-8
class PalletCorrectionsController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :customer, :through => :department
  load_and_authorize_resource :pallet, :through => :customer
  load_and_authorize_resource :through => :pallet

  def new
    @pallet_correction.pallet_type_id = @pallet.pallet_type_id
    @pallet_correction.capacity       = @pallet.capacity
    @pallet_correction.weight         = @pallet.weight
    @pallet_correction.available      = @pallet.available
  end

  def create
    # weight must be rounded to 3 decimals (as in the database)
    unchanged =   @pallet.pallet_type_id == @pallet_correction.pallet_type_id
    unchanged &&= @pallet.capacity       == @pallet_correction.capacity
    unchanged &&= @pallet.weight         == @pallet_correction.weight.try(:round, 3)
    unchanged &&= @pallet.available      == @pallet_correction.available

    if unchanged
      redirect_to [@department, @customer, @pallet], :notice => 'Korrektionen har ingen effekt da ingen af værdierne er ændret.'
    elsif @pallet_correction.save
      redirect_to [@department, @customer, @pallet], :notice => 'Pallen er nu korrigeret.'
    else
      render :action => 'new'
    end

  end

  def pallet_correction_params
    params.require(:pallet_correction).permit(:pallet_type_id, :available, :capacity, :weight)
  end

end