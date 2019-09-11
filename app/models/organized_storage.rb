class OrganizedStorage < Storage
  has_many :placements

  def choosen_shelf=(shelf)
    @choosen_shelf = shelf.to_i
    @choosen_shelf = 1 if @choosen_shelf > shelf_count or 0 > @choosen_shelf
  end

  def choosen_shelf
    @choosen_shelf ||= 1
  end

  def max_floor(shelf = nil)
    meta_data[shelf || choosen_shelf].max_floor.to_i
  end

  def max_column(shelf = nil)
    meta_data[shelf || choosen_shelf].max_column.to_i
  end

  def shelf_count
    meta_data.size
  end

  def space_info
    placements.select("shelf, floor, COUNT(*) AS count, COUNT(pallets.id) AS pallet_count, COALESCE(corrected_pallet_type_id, original_pallet_type_id) as pallet_type_id").
      joins("LEFT OUTER JOIN pallets ON pallets.position_id = placements.id AND pallets.position_type = 'Placement'").
      group("shelf, floor, pallet_type_id").
      order("shelf, floor, pallet_type_id").
      group_by(&:shelf)
  end

  def ordered_placements
    placements.where(:shelf => choosen_shelf).includes(:pallet).order('floor DESC, `column` ASC').all
  end

  def js_id
    "storage_#{id}_#{choosen_shelf}"
  end

  def url_param
    "#{id}:#{choosen_shelf}"
  end

private

  def meta_data
    @meta_data ||= Hash[placements.select("max(`placements`.`column`) as max_column, max(floor) as max_floor, shelf").group("shelf").collect { |p| [p.shelf.to_i, p] }]
  end

end
