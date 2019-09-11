# encoding: utf-8
class PalletCorrection < ActiveRecord::Base
  acts_as_overwrite_protected

  belongs_to :pallet

  validates_presence_of :pallet_type_id
  validates_numericality_of :available, :capacity, :greater_than => 0, :only_integer => true
  validates_numericality_of :weight, :greater_than => 0

  validate do
    errors.add(:available, :greater_than_capacity) if available.to_i > capacity
  end

  before_save :calculate_count
  after_save :update_pallet

  localize_numbers_for :weight

  def available=(value)
    @available = value.to_i
  end

  def available
    @available
  end

  def pallet_type
    PalletType[pallet_type_id]
  end

  private

  def calculate_count
    self.count = available + pallet.reserved + pallet.taken
  end

  def update_pallet
    raise ActiveRecord::Rollback unless pallet.update_attributes({
      :corrected_count          => count,
      :corrected_weight         => weight,
      :corrected_capacity       => capacity,
      :corrected_pallet_type_id => pallet_type_id
    })
  end

  def generate_lock_token
    [:count, :weight, :capacity, :pallet_type_id].inject("") { |m,s| m + pallet.send(s).to_s }.hash.to_s
  end

end
