# encoding: utf-8
class Order < ActiveRecord::Base
  include AASM

  belongs_to :customer
  belongs_to :owner, class_name: 'User'
  belongs_to :order_import

  has_many :reservations, dependent: :destroy
  has_many :pallets, through: :reservations

  scope :recent, -> { where('done_at IS NULL OR done_at > ?', Time.now - 1.day) }

  validate do

    if reservations.empty? and not editing?
      errors.add :base, 'Ordren har ingen reservationer.'
    end

    if ready? and reservations.includes(:pallet).any? { |r| r.pallet.remains < r.count or r.count < 0 }
      errors.add :base, 'Ordren har ugyldige reservationer.'
    end

    if load_at.present? and deliver_at.present? and load_at > deliver_at
      errors.add :load_at, 'må ikke være senere end leveringsdato'
    end

  end

  validates_presence_of :number
  validates_presence_of :destination_name
  validates_presence_of :destination_address
  validates_presence_of :customer
  validates_presence_of :load_at
  validates_presence_of :deliver_at

  # NOTE: Historic orders should be able to be updated without an owner
  validates_presence_of :owner, on: :create

  aasm :column => 'state', :create_scopes => false, :requires_new_transaction => false do

    # Order is being created by owner (worker or customer)
    state :editing, :initial => true

    # Order is marked as ready by customer
    state :submitted

    # Order is being carried out
    state :processing

    # Order is ready to be shipped out
    state :ready

    # Order is finished (cannot be undone)
    state :finished

    # For workers
    event :change do
      # Workers can change processing and ready orders (unless a customer owns them)
      transitions from: [:submitted, :processing, :ready], to: :editing, guard: :non_customer?
    end

    # Submitted
    event :submit do
      transitions from: :editing, to: :submitted, guard: :is_owner?
      transitions from: [:processing, :ready], to: :submitted, guard: :non_customer?
    end

    event :reject do
      # Worker can send order back to customer during submitted, processing and ready
      transitions from: [:submitted, :processing, :ready], to: :editing, guard: :can_reject?
    end

    event :carry_out do
      transitions from: [:submitted, :ready], to: :processing
      transitions from: :editing, to: :processing, guards: [:is_owner?, :non_customer?]
    end

    event :mark_ready do
      transitions from: :processing, to: :ready, guard: :non_customer?
    end

    event :finish do
      transitions from: :ready, to: :finished, guard: :non_customer?
      before do

        all_reservations = reservations.includes(:pallet).all

        if all_reservations.any? { |r| r.pallet.remains < r.count or r.count < 0 }
          errors.add :base, 'Ordren har ugyldige reservationer.'
          raise ActiveRecord::Rollback, 'Ordren har ugyldige reservationer.'
        end

        # det slettede lager (er ikke synligt for nogen)
        deleted_storage = BulkStorage.find(1)

        all_reservations.each do |reservation|

          # "delete" pallet if empty
          pallet = reservation.pallet
          if pallet.remains == reservation.count
            pallet.deleted_at = Time.current
            pallet.position = deleted_storage
            pallet.save(:validate => false)
          end

          reservation.done_at = Time.current
          reservation.save
        end

        self.done_at = Time.current
      end
    end

  end

  def may?(event, user)
    @current_user = user
    aasm.may_fire_event?(event)
  end

  def do!(event, user)
    @current_user = user
    send("#{event}!".to_sym)
  end

  def locked_for?(user)
    owner_id.present? and owner_id != user.id and owner.present?
  end

  def alert_errors
    ('<b>Ordren kunne ikke opdateres</b><br>' + errors.full_messages.join('<br>')).html_safe unless errors.empty?
  end

  def customer_order?
    owner.present? and owner.is? :customer
  end

  def reservation_groups
    @reservation_groups ||= reservations.includes(:pallet).order('pallets.number, pallets.batch, pallets.best_before DESC, pallets.trace').group_by do |r|
      { :number => r.pallet.number, :batch => r.pallet.batch, :name => r.pallet.name }
    end
  end

  def destination_address=(value)
    self[:destination_address] = value.to_s.strip
  end

  private

  def can_reject?
    customer_order? and non_customer?
  end

  def non_customer?
    not @current_user.is? :customer
  end

  def is_owner?
    owner_id == @current_user.id
  end

end