module PalletsHelper

  # position must be Placement or Storage
  def link_to_position(position, anchor = nil)
    link_to position.position_name, url_for_position(@department, anchor)
  end

  def url_for_position(position, anchor = nil)
    o = { :id_a => @department.lobby_id, :anchor => anchor }
    if position.is_a?(Placement)
      o[:id_b] = position.organized_storage_id
      o[:shelf_b] = position.shelf
    elsif position.id != @department.lobby_id
      o[:id_b] = position.id
    end
    department_graphic_path(@department, o)
  end

end
