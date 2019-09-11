# encoding: utf-8
class Arrival < ActiveRecord::Base
  belongs_to :customer

  has_many :pallets, :dependent => :destroy

  validates_presence_of :customer, :name, :number, :batch, :pallet_type_id, :arrived_at
  validates_numericality_of :capacity, :count, :greater_than => 0, :only_integer => true
  validates_numericality_of :weight, :greater_than_or_equal_to => 0
  validates_numericality_of :temperature, :allow_nil => true

  # attr_readonly :count, :capacity, :pallet_type_id, :weight

  localize_numbers_for :weight, :temperature

  before_validation :check_arrived_at
  before_create :calculate_pallet_count
  before_update :calculate_pallet_count
  after_create :create_pallets
  after_update :update_pallets

  def pallet_type
    PalletType[pallet_type_id]
  end

  # check if it can be destroyed
  # is the pallet older than last status?
  # does any of the pallets have reservations?
  def deletable?
    return pallets.includes(:reservations).all.all? do |pallet|
      (customer.last_count.nil? or pallet.arrived_at > customer.last_count) and pallet.reservations.empty?
    end
  end

private

  def check_arrived_at

    # if arrival is old and arrived_at is not changed, exit early
    unless self.new_record? or self.arrived_at_changed?
      return
    end

    if self.arrived_at and self.customer.last_count

      if self.arrived_at == self.customer.last_count.at_beginning_of_day
        self.arrived_at = self.customer.last_count

      elsif self.arrived_at < self.customer.last_count.at_beginning_of_day
        errors[:arrived_at] = "skal være efter sidste optællingsperiode (#{ActionController::Base.helpers.l self.customer.last_count})."

      end

    end
  end

  def calculate_pallet_count
    print "about to update"
    self.pallet_count = (count / capacity.to_f).ceil
  end

  def create_pallets
    left = count
    while left > 0
      pallets.create({
        :name                    => name,
        :number                  => number,
        :batch                   => batch,
        :trace                   => trace,
        :best_before             => best_before,
        :taken                   => 0,
        :reserved                => 0,
        :original_weight         => weight,
        :original_count          => [capacity, left].min,
        :original_capacity       => capacity,
        :original_pallet_type_id => pallet_type_id,
        :arrived_at              => arrived_at,
        :customer                => customer,
        :position                => customer.department.lobby
      })
      left -= capacity
    end
  end

  def update_pallets
    print "updating pallets"
    if pallets.count == 0
      create_pallets
    end

    pallets.all? do |pallet|
      pallet.update_attributes({
        :number => number,
        :batch => batch,
        :name => name,
        :trace => trace,
        :arrived_at => arrived_at,
        :best_before => best_before
      })
    end
  end
end
