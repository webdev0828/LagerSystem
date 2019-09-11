module StoragesHelper

  # def storage_type(storage)
  #   if storage.id == @department.lobby_id
  #     "Lobby"
  #   elsif storage.id == @department.transfer_id
  #     "Transfer"
  #   elsif storage.is_a?(OrganizedStorage)
  #     "Organiseret"
  #   elsif storage.is_a?(BulkStorage)
  #     "Bulk"
  #   end
  # end

  def storage_type(storage)
    if storage.id == @department.lobby_id
      "lobby"
    elsif storage.id == @department.transfer_id
      "transfer"
    end
  end

end
