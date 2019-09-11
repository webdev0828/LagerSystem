# encoding: utf-8
class Pallet < ActiveRecord::Base

  belongs_to :customer

  belongs_to :position, :polymorphic => true
  belongs_to :arrival

  # If an Arrival is deleted, so is all the pallets, and their corrections
  has_many :pallet_corrections, :dependent => :delete_all

  # You cannot delete a pallet with reservations.
  # TODO: This should trigger an error instead
  has_many :reservations, :dependent => :restrict_with_exception

  validates_presence_of :name
  validates_presence_of :number
  validates_presence_of :batch
  validates_presence_of :arrival
  validates_presence_of :customer
  validates_presence_of :position
  validates_presence_of :original_pallet_type_id
  validates_numericality_of :original_capacity, :greater_than => 0, :only_integer => true
  validates_numericality_of :original_count,    :greater_than => 0, :only_integer => true
  validates_numericality_of :original_weight,   :greater_than => 0

  #----------------------#
  #   Corrected values   #
  #----------------------#

  def count
    corrected_count || original_count
  end

  def capacity
    corrected_capacity || original_capacity
  end

  def weight
    corrected_weight || original_weight
  end

  def pallet_type_id
    corrected_pallet_type_id || original_pallet_type_id
  end

  def pallet_type
    PalletType[pallet_type_id]
  end

  def original_pallet_type
    PalletType[original_pallet_type_id]
  end

  #-------------#
  #   Helpers   #
  #-------------#
  def available
    count - taken - reserved
  end

  def remains
    count - taken
  end

  #--------------------------------#
  #   Helpers (only for graphic)   #
  #--------------------------------#
  def wide?
    pallet_type.wide?
  end

  def scrap?
    available < capacity
  end

  #----------------------------#
  #   Correction since start   #
  #----------------------------#
  def difference_count
    corrected_count.nil? ? 0 : corrected_count - original_count
  end


  def compatible?(pallet)
    [:name, :number, :batch, :trace, :best_before, :weight, :count, :capacity, :pallet_type_id].all? do |attr|
      send(attr) == pallet.send(attr)
    end
  end

end