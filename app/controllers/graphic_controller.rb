# encoding: utf-8
class GraphicController < ApplicationController
  load_and_authorize_resource :department
  before_filter :load_storages, :only => [:index, :search]

  def index
    authorize! :read, Storage

    # store current url parts
    @current = []
    @current << @storage_a.url_param unless @storage_a.nil?
    @current << @storage_b.url_param unless @storage_b.nil?

    # store storages object
    @storages = @department.storages.map { |s| [ s.id, s.name, s.is_a?(OrganizedStorage) ? s.shelf_count : 0 ] }

    # kunder der kan søges efter paller for
    @customers = @department.customers.where( :deactivated => false )
  end

  def move
    authorize! :manage, Storage

    storage = @department.storages.find(params[:storage])
    pallet  = Pallet.find(params[:pallet])

    if pallet.position_id.to_s != params[:posid] or pallet.position_type.to_s != params[:postype]
      flash[:notice] = "Pallen er blevet flyttet af en anden bruger. Visningen er derfor blevet opdateret."
      render :json => { :status => false, :reload => true }
    elsif storage.is_a?(OrganizedStorage)
      placement = storage.placements.find_by_id_and_shelf_and_column_and_floor(params[:placement], params[:shelf], params[:column], params[:floor])
      if placement.pallet.nil?
        placement.pallet = pallet
        render :json => { :status => placement.save }
      else
        flash[:notice] = "Lokationen var optaget af en anden palle. Visningen er derfor blevet opdateret."
        render :json => { :status => false, :reload => true }
      end
    else
      if pallet.position == storage
        render :json => { :status => false, :reason => "pallet is not moved, since it is the same storage" }
      else
        pallet.position = storage
        render :json => { :status => pallet.save }
      end
    end

  end

  def info
    authorize! :read, Storage
    @pallet = Pallet.includes(:customer => :department).find(params[:pallet])
  end

  #-------------------------------------------------------------#
  #   This is for searching for pallets in the selected grids   #
  #-------------------------------------------------------------#
  def search
    authorize! :read, Storage
    query = Pallet.select('id').
            where('pallets.customer_id = ?', params[:customer_id]).
            where('pallets.number LIKE ?',   "#{params[:number]}%").
            where('pallets.batch LIKE ?',    "#{params[:batch]}%").
            where('pallets.trace LIKE ?',    "#{params[:trace]}%")

    sql = []
    sql << storage_search(query, @storage_a, @type_a)
    sql << storage_search(query, @storage_b, @type_b)
    sql.compact!

    @ids = []
    Pallet.connection.execute(sql.join(' UNION ') + " ORDER BY id").each { |r| @ids << r[0].to_i } if sql.size > 0

  end

private

  def find_storage_with_type(id, shelf)
    storage = @department.bulk_storages.includes(:pallets).find_by_id(id)
    return [storage, 'bulk'] unless storage.nil?

    storage = @department.organized_storages.find_by_id(id)
    return [nil, 'none'] if storage.nil?

    storage.choosen_shelf = shelf if storage.shelf_count >= shelf.to_i and shelf.to_i > 0
    return [storage, 'orga']
  end

  def storage_search(query, storage, type)
    if type == 'orga'
      query.where(:position_type => 'Placement').where(
        "position_id IN (SELECT id FROM placements WHERE organized_storage_id = ? AND shelf = ?)",
        storage.id,
        storage.choosen_shelf
      ).to_sql

    elsif type == 'bulk'
      query.where(
        :position_type => 'Storage',
        :position_id   => storage.id
      ).to_sql
    end
  end

  def load_storages

    # sessions to fall back on
    last_view = session[:graphic_view] || {}

    # find requested storages
    @storage_a, @type_a = find_storage_with_type(params[:id_a], params[:shelf_a])
    @storage_b, @type_b = find_storage_with_type(params[:id_b], params[:shelf_b])

    # fallback to sessions
    @storage_a, @type_a = find_storage_with_type(last_view[:id_a], last_view[:shelf_a]) if @storage_a.nil? and last_view.is_a?(Hash)
    @storage_b, @type_b = find_storage_with_type(last_view[:id_b], last_view[:shelf_b]) if @storage_b.nil? and last_view.is_a?(Hash)

    # detect identical storages
    @storage_b, @type_b = nil, 'none' if @storage_a.try(:url_param) == @storage_b.try(:url_param)

    # store selection in sessions
    @options_for_url = {
      :id_a    => @storage_a.try(:id),
      :id_b    => @storage_b.try(:id),
      :shelf_a => @type_a == 'orga' ? @storage_a.choosen_shelf : nil,
      :shelf_b => @type_b == 'orga' ? @storage_b.choosen_shelf : nil
    }

    # store selection in sessions
    session[:graphic_view] = @options_for_url

  end

end
