class CustomerGroup < ActiveRecord::Base
  belongs_to :department
  has_many :order_imports

  serialize :data, Hash

  def customers
    department.customers.where(id: customer_ids)
  end

  def pallets
    Pallet.where(customer_id: customer_ids)
  end

  def ordered_pallets_by_number(number, count)

    all_pallets = Pallet.
        where(customer_id: customer_ids, number: number).
        where('(corrected_count IS NULL AND original_count - taken - reserved > 0) OR (corrected_count IS NOT NULL AND corrected_count - taken - reserved > 0)').
        order('best_before, original_capacity - original_count + taken + reserved DESC').
        all.to_a

    # Ignore pallets from the lobby
    lobby_pallets, other_pallets = all_pallets.partition do |pallet|
      pallet.position_id == department.lobby_id && pallet.position_type == 'Storage'
    end

    obj = { selected: [], missing: count, lobby: lobby_pallets.size }

    # Always take from pallets in order of best_before
    pallet_groups = other_pallets.group_by(&:best_before)
    pallet_groups.keys.sort.each do |best_before|
      pallets = pallet_groups[best_before]

      # Try to get full pallets first
      pallets.delete_if do |pallet|
        next if pallet.scrap?
        next if obj[:missing] < pallet.available

        obj[:selected] << { count: pallet.available, pallet: pallet }
        obj[:missing] -= pallet.available
        true
      end

      # ... then take from all pallets (in order) until we have what we need
      pallets.each do |pallet|
        return obj if obj[:missing] == 0

        if obj[:missing] <= pallet.available
          obj[:selected] << { count: obj[:missing], pallet: pallet }
          obj[:missing] = 0

        else
          obj[:selected] << { count: pallet.available, pallet: pallet }
          obj[:missing] -= pallet.available
        end

      end

      return obj if obj[:missing] == 0
    end

    obj
  end

  def customer_ids
    data[:customer_ids] || []
  end

  def customer_ids=( ids = [] )
    data[:customer_ids] = Array(ids).map { |x| Integer(x) rescue nil }.compact
  end

end
