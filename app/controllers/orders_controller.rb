# encoding: utf-8
class OrdersController < ApplicationController
  include ActionView::Helpers::TextHelper
  load_and_authorize_resource :department
  load_and_authorize_resource :customer, :through => :department
  before_filter :load_order_with_includes, :only => [:scrap_note, :delivery_note, :exit_note]
  load_and_authorize_resource :through => :customer, except: [:ready, :all_order_pdfs]

  def index
    @orders = @orders.recent
    @order_groups = @orders.group_by { |o| o.state.to_sym }
    @labels = { 'finished' => 'Afhentet sidste 24 timer' }
  end

  def show
    if @order.submitted?
      @order.reservation_groups.each do |key, reservations|
        alternatives = @customer.pallets.order('number, batch, best_before DESC, trace').where(key)
        reservations.each do |reservation|
          reservation.alternatives = alternatives.select { |p| reservation.alternative?(p) }
        end
      end
    end
  end

  def edit
    redirect_to([@department, @customer, @order], :alert => 'Du kan ikke rette i en færdig order.') if @order.finished?
  end

  def create
    @order.owner = current_user
    if @order.save
      redirect_to([@department, @customer, @order], :notice => 'Order was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    redirect_to([@department, @customer, @order], :alert => 'Du kan ikke rette i en færdig order.') if @order.finished?
    if @order.update_attributes(order_params)
      redirect_to([@department, @customer, @order], :notice => 'Order was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    redirect_to([@department, @customer, @order], :alert => 'Du kan ikke slette en færdig order.') if @order.finished?
    @order.destroy
    redirect_to([@department, @customer, :orders])
  end

  def autofill
    order = @customer.orders.where(:destination_name => params[:q]).last
    render :json => { '#order_destination_address' => order.try(:destination_address) || '' }
  end

  def swap
    @reservation = @order.reservations.find(params[:reservation_id])
    @pallet = @customer.pallets.find(params[:pallet_id])
    @reservation.pallet = @pallet
    if @reservation.save
      redirect_to [@department, @customer, @order], notice: 'Reservationen er nu gemt'
    else
      redirect_to [@department, @customer, @order], alert: 'Reservationen kunne ikke ændres. Prøv igen, eller kontakt en administrator.'
    end
  end

  def mark
    @orders = @orders.where(state: :ready)
  end

  def ready
    @orders = Order.where(state: [:editing, :submitted, :processing], customer: params[:customer_id])
  end

  def finish_marked
    order_ids = params.require(:order_ids)
    @orders = @orders.where(state: :ready, id: order_ids)

    if @orders.all? { |order| order.may? :finish, current_user }
      @orders.each { |order| order.do! :finish, current_user }
      render json: {
                 status: true,
                 finished: @orders.map(&:id),
                 notice: pluralize(@orders.size, 'order', 'ordre') + ' afsluttet'
             }
    else
      render json: {
                 status: false,
                 alert: 'En eller flere ordre kunne ikke afsluttes'
             }
    end
  end

  def all_order_pdfs
    order_ids = params[:order_ids]
    @allorders = Order.where(id: order_ids)
    unready_orders = []
    @ready_orders = []

    @allorders.each do |order|
      # Replicate of make_owner without the redirect. We have to take control of order, to submit it
      if order.update_attributes(owner: current_user)
        case order.state
        when 'editing'
          order.do! :submit, current_user 
          order.do! :carry_out, current_user 
        when 'submitted'
          order.do! :carry_out, current_user 
        end
        
        # All orders should be in :processing at this point, where they can be marked ready
        if order.may? :mark_ready, current_user
          @ready_orders.push order # Adds order to list of ready orders
        else
          # Make sure to rollback order state 
          unready_orders.push order
          # render(json: { message:  "Ordre #{order.number} kan ikke markeres som klar" }, status: 422) and return 
        end
      else
        # Make sure to rollback order state 
        unready_orders.push order
        # render(json: { message:  "Bruger kunne ikke overtage ordren #{order.number}" }, status: 422) and return
      end
    end

    if unready_orders.empty?
      # If all goes well
      if @ready_orders.any?
        # Mark all orders as ready
        @ready_orders.each { |order| order.do! :mark_ready, current_user } 

        respond_to do |format|
          format.pdf do
            pdf = OrdersDocument.all_delivery_notes(view_context)
            send_data pdf.render, filename: "samlet_følgeseddel.pdf", type: "application/pdf", disposition: "inline"
          end
        end

      else 
        # Handle what should happen if we can't print
        render(json: { message: "Noget gik galt med print af PDF" }, status: 422) and return
      end
    else 
      # Hvis der er nogle ordrer der fejler
      errors = []
      
      unready_orders.each do |uorder|
        errors.push uorder.number
      end

      render(json: { message:  "Fejl på ordrer #{errors.join(', ')}" }, status: 422) and return
    end
  end

  #------------#
  #   Lister   #
  #------------#

  def scrap_note
    respond_to do |format|
      format.pdf do
        pdf = OrdersDocument.scrap_note(view_context)
        send_data pdf.render, filename: "pluk_seddel.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def delivery_note
    respond_to do |format|
      format.pdf do
        pdf = OrdersDocument.delivery_note(view_context)
        send_data pdf.render, filename: "følgeseddel.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def exit_note
    respond_to do |format|
      format.pdf do
        pdf = OrdersDocument.exit_note(view_context)
        send_data pdf.render, filename: "udgangsliste.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def pallet_note
    respond_to do |format|
      format.pdf do
        pdf = OrdersDocument.pallet_note(view_context, params[:total].to_i)
        send_data pdf.render, filename: "palle_sedler.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end


  #-------------------#
  #   Change states   #
  #-------------------#

  def change
    @order.owner = current_user
    @order.do! :change, current_user unless @order.editing?
    redirect_to [@department, @customer, @order], :alert => @order.alert_errors
  end

  def submit
    @order.do! :submit, current_user unless @order.submitted?
    redirect_to [@department, @customer, @order], :alert => @order.alert_errors
  end

  def reject
    # TODO: Send en mail til brugeren
    @order.do! :reject, current_user unless @order.editing?
    redirect_to [@department, @customer, @order], :alert => @order.alert_errors
  end

  def carry_out
    @order.do! :carry_out, current_user unless @order.processing?
    redirect_to [@department, @customer, @order], :alert => @order.alert_errors
  end

  def mark_ready
    @order.do! :mark_ready, current_user unless @order.ready?
    redirect_to [@department, @customer, @order], :alert => @order.alert_errors
  end

  def finish
    @order.do! :finish, current_user unless @order.finished?
    redirect_to [@department, @customer, @order], :alert => @order.alert_errors
  end

  def make_owner
    @order.update_attributes(owner: current_user)
    redirect_to [@department, @customer, @order], :alert => @order.alert_errors
  end

  # used by orders - returns json
  # max: 50
  def search_pallets
    search_max = 50

    @pallets = @customer.pallets.
      where('(corrected_count IS NULL AND original_count - taken - reserved > 0) OR (corrected_count IS NOT NULL AND corrected_count - taken - reserved > 0)').
      where('number LIKE ?', params[:pallet][:number]+'%').
      where('batch LIKE ?', params[:pallet][:batch]+'%').
      where('trace LIKE ?', params[:pallet][:trace]+'%').
      limit(search_max + 1).
      order('number, best_before, batch, original_capacity - original_count + taken + reserved DESC').
      all

    @more    = @pallets.size > search_max
    @pallets = @pallets.slice(0, search_max)
  end

  def reserve
    status = false
    reservations = params[:reservations]

    if not reservations.is_a? Hash
      render :json => { :status => status }
      return
    end

    @order.transaction do

      reservations.each_pair do |pallet_id, count_string|

        # the pallet is in this department
        pallet = @customer.pallets.find(pallet_id)
        count  = count_string.to_i

        # sanity checks
        if count_string.nil? or count <= 0 or pallet.nil? or pallet.available < count
          raise ActiveRecord::Rollback
        end

        reservation = @order.reservations.find_or_initialize_by(:pallet_id => pallet.id) { |r| r.count = 0 }
        reservation.count += count
        reservation.save!
      end

      status = true
    end

    render :json => { :status => status }
  end


  def cancel_reservation
    @reservation = @order.reservations.find(params[:reservation_id])
    @reservation.destroy
  end

  private

  def load_order_with_includes
    @order = @customer.orders.includes(:reservations => { :pallet => :position }).find(params[:id])
  end

  def order_params
    params.require(:order).permit(:number, :load_at, :deliver_at, :destination_name, :destination_address, :delivery, :note)
  end

end