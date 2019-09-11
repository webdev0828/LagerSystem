class OrganizedStoragesController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :through => :department

  def show

    @data = @organized_storage.space_info.map do |shelf, info|

      max_floor  = @organized_storage.max_floor(shelf)
      other      = info.reject { |i| i.floor == max_floor }

      # FIXME: Check that other is only rejecting the hidden placements (use partition and check for all organized storages)

      total      = other.sum    { |i| i.count.to_i }
      #Rails.logger.debug "shelf: " + other.map { |i| i.pallet_type_id }.inspect
      normal     = other.reject { |i| i.pallet_type_id && PalletType[i.pallet_type_id].wide? }.sum { |i| i.pallet_count.to_i }
      wide       = other.select { |i| i.pallet_type_id && PalletType[i.pallet_type_id].wide? }.sum { |i| i.pallet_count.to_i }

      free       = (total - wide * 1.333 - normal).floor

      {
        :shelf     => shelf,
        :max_floor => max_floor,
        :total     => total,
        :normal    => normal,
        :wide      => wide,
        :free      => free
      }

    end

    @full_total = @data.inject(0){ |m,n| m + n[:total] }
    @full_free  = @data.inject(0){ |m,n| m + n[:free]  }

  end

  def update
    if @organized_storage.update_attributes(organized_storage_params)
      redirect_to([@department, @organized_storage], :notice => 'Lagret er nu opdateret.')
    else
      render :action => "edit"
    end
  end

  def print_shelf
    @organized_storage.choosen_shelf = params[:shelf] || "1"
    respond_to do |format|
      format.pdf do
        pdf = ShelfDocument.new(@organized_storage, view_context)
        send_data pdf.render, filename: "print_shelf_#{@organized_storage.id}_#{@organized_storage.choosen_shelf}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def organized_storage_params
    params.require(:organized_storage).permit(:name)
  end

end
