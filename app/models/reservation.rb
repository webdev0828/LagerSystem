class Reservation < ActiveRecord::Base
  belongs_to :order, touch: true
  belongs_to :pallet

  validates_numericality_of :count, :only_integer => true, :greater_than => 0
  validates_presence_of :pallet
  validates_presence_of :order

  before_update :update_cached_sum
  before_create :add_to_cached_sum
  before_destroy :delete_from_cached_sum

  def alternatives=(alts)
    @alternatives = alts
  end

  def alternatives
    @alternatives || []
  end

  def alternative?(p)
    match_basic = [:name, :number, :batch, :trace, :best_before].all? { |attr| pallet.send(attr) == p.send(attr) }
    match_extras = [:weight, :count, :capacity, :pallet_type_id].all? { |attr| pallet.send(attr) == p.send(attr) }
    match_scrap_status = (pallet.available + count == pallet.count) == (p.count == p.capacity)
    has_enough_available = (p.available >= count)
    has_different_location = (p.position != pallet.position)

    match_basic and match_extras and match_scrap_status and has_enough_available and has_different_location
  end

  private

  def update_cached_sum

    # Only when swapping pallets
    if pallet_id_changed?

      # Add count to new pallet
      Pallet.update_counters(pallet_id, { (done_at.nil? ? :reserved : :taken) => count })

      # Remove count from old pallet
      Pallet.update_counters(pallet_id_was, { (done_at_was.nil? ? :reserved : :taken) => - count_was })

    # if it changed from reserved to taken
    elsif done_at_was.nil? != done_at.nil?
       Pallet.update_counters(pallet_id, {
        (done_at.nil? ? :taken : :reserved) => -count_was,
        (done_at.nil? ? :reserved : :taken) => count
      })

    # if count changed
    elsif count_changed?
      Pallet.update_counters(pallet_id, {
        (done_at.nil? ? :reserved : :taken) => count - count_was
      })
    end
  end

  def add_to_cached_sum
    # if new reservation, add count to appropiate column
    Pallet.update_counters(pallet_id, { (done_at.nil? ? :reserved : :taken) => count })
  end

  def delete_from_cached_sum
    # if deleted reservation, add count to appropiate column
    Pallet.update_counters(pallet_id, { (done_at_was.nil? ? :reserved : :taken) => - count_was })
  end

end