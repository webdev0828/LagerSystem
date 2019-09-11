# encoding: utf-8
class ArrivalsController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :customer, :through => :department
  load_and_authorize_resource :through => :customer, :except => [:autofill, :index]

  SEARCH_MAX = 30

  def index
    # Varerne skal stå i rækkefølgen: holdbarhedsdato, pluk + reserveret, lot nr.
    @arrivals = @customer.arrivals.order("created_at DESC")
    @arrivals = @arrivals.where('number LIKE ?', "#{params[:number]}%") unless params[:number].blank?
    @arrivals = @arrivals.where('batch LIKE ?',  "#{params[:batch]}%")  unless params[:batch].blank?
    @arrivals = @arrivals.where('trace LIKE ?',  "#{params[:trace]}%")  unless params[:trace].blank?
    @arrivals = @arrivals.paginate(:page => params[:page] || 1, :per_page => SEARCH_MAX)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        filename = "#{@customer.name} - Indgang - #{l @arrival.arrived_at.to_date}.pdf"
        pdf = ArrivalsDocument.show(view_context)
        send_data pdf.render, filename: filename, type: "application/pdf", disposition: "inline"
      end
    end
  end

  def create
    if @arrival.save      
      redirect_to([@department, @customer, @arrival], :notice => "Indgang registreret, #{ActionController::Base.helpers.pluralize(@arrival.pallets.size, 'palle', 'paller')} er nu oprettet.")
    else
      render :action => 'new'
    end
  end

  def update

    if @arrival.update_attributes(update_params)
      redirect_to([@department, @customer, @arrival], :notice => 'Alle paller i indgangen er nu redigeret.')
    else
      render :action => 'edit'
    end
  end

  def destroy
    if @arrival.deletable? and @arrival.destroy
      redirect_to([:new, @department, @customer, :arrival], :notice => 'Indgangen er nu slettet.')
    else
      redirect_to([@department, @customer, @arrival], :alert => 'Indgangen kunne ikke slettes.<br><br>Der kan enten være reservationer som blokerer for sletningen, eller også er indgangen registreret i en forhenværende status.'.html_safe)
    end
  end

  def autofill
    authorize! :read, Arrival
    arrival = @customer.arrivals.where(:number => params[:q]).last

    options_for_number_field = {
      :strip_insignificant_zeros => true,
      :precision => 3,
      :delimiter => ''
    }
    render :json => {
        '#arrival_name' => arrival.try(:name) || '',
        '#arrival_weight' => arrival ? ActionController::Base.helpers.number_with_precision(arrival.weight, options_for_number_field) : '',
        '#arrival_capacity' => arrival.try(:capacity) || '',
        '#arrival_pallet_type_id' => arrival.try(:pallet_type_id) || 1
    }
  end

  private

  def create_params
    params.require(:arrival).permit(:number, :batch, :name, :trace, :arrived_at, :best_before, :temperature, :pallet_type_id, :capacity, :count, :weight)
  end

  def update_params
    params.require(:arrival).permit(:number, :batch, :name, :trace, :arrived_at, :best_before, :temperature, :pallet_type_id, :capacity, :count, :weight)
  end

end
