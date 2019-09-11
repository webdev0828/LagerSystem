class Customer::OrdersController < Customer::BaseController
  load_and_authorize_resource :customer
  before_filter :load_order_with_includes, :only => [:delivery_note, :exit_note]
  load_and_authorize_resource :through => :customer

  def index
    @orders = @orders.includes(:customer)
    @orders = @orders.where('orders.done_at IS NULL OR orders.done_at > ?', Time.now.yesterday.utc)
    @orders = @orders.order('orders.done_at DESC, orders.created_at DESC')

    @order_groups = @orders.group_by { |o| o.state.to_sym }
    @labels = { 'finished' => 'Afhentet sidste 24 timer' }
  end

  def finished
    @orders = @orders.includes(:reservations => :pallet)
    @orders = @orders.where(:customer => @customer)
    @orders = @orders.where(:state => 'finished')
    @orders = @orders.order('orders.done_at DESC')

    @orders = @orders.where('orders.customer_id = ?',         "#{params[:customer_id]}")       unless params[:customer_id].to_i == 0
    @orders = @orders.where('orders.number LIKE ?',           "#{params[:order_number]}%")     unless params[:order_number].blank?
    @orders = @orders.where('orders.destination_name LIKE ?', "#{params[:destination_name]}%") unless params[:destination_name].blank?

    @orders = @orders.where('pallets.number LIKE ?', "#{params[:article_number]}%").references(:pallet) unless params[:article_number].blank?
    @orders = @orders.where('pallets.batch LIKE ?',  "#{params[:batch]}%").references(:pallet)          unless params[:batch].blank?
    @orders = @orders.where('pallets.trace LIKE ?',  "#{params[:trace]}%").references(:pallet)          unless params[:trace].blank?

    @orders = @orders.paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @reservations = @order.reservations.includes(:pallet).order('pallets.number, pallets.batch, pallets.best_before DESC, pallets.trace').group_by do |r|
      { :number => r.pallet.number, :batch => r.pallet.batch, :name => r.pallet.name }
    end
  end

  def update
    # redirect_to([:customer, @customer, @order], :alert => 'Du kan ikke rette i en færdig order.')
    if @order.update_attributes(order_params)
      redirect_to([:customer, @customer, @order], :notice => 'Ordren er nu opdateret.')
    else
      render :action => "edit"
    end
  end

  def create
    # Set to customer order
    @order.owner = current_user
    if @order.save
      redirect_to([:customer, @customer, @order], :notice => 'Ordren er nu oprettet.')
    else
      render :action => "new"
    end
  end

  def destroy
    @order.destroy
    redirect_to([:customer, @customer, :orders])
  end

  def autofill
    order = @customer.orders.where(:destination_name => params[:q]).last
    render :json => { '#order_destination_address' => order.try(:destination_address) || '' }
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

  def delivery_note
    @department = @customer.department
    respond_to do |format|
      format.pdf do
        pdf = OrdersDocument.delivery_note(view_context)
        send_data pdf.render, filename: "følgeseddel.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def exit_note
    @department = @customer.department
    respond_to do |format|
      format.pdf do
        pdf = OrdersDocument.exit_note(view_context)
        send_data pdf.render, filename: "udgangsliste.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  # state change
  def submit
    @order.do! :submit, current_user
    redirect_to [:customer, @customer, @order], :alert => @order.alert_errors
  end

  def make_owner
    @order.update_attributes(owner: current_user)
    redirect_to [:customer, @customer, @order], :alert => @order.alert_errors
  end

  private

  def load_order_with_includes
    @order = @customer.orders.includes(:reservations => { :pallet => :position }).find(params[:id])
  end

  def order_params
    params.require(:order).permit(:number, :load_at, :deliver_at, :destination_name, :destination_address, :note)
  end

end
