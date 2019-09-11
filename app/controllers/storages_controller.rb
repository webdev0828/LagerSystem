class StoragesController < ApplicationController
  load_and_authorize_resource :department
  load_and_authorize_resource :through => :department, :except => [:shelfs]

  def index
    @storages.each_with_index do |c,i|
      c.set_list_position(i+1) if c.position != i+1
    end
  end

  def sort
    authorize! :update, Storage
    saved = false
    if params[:position].present?
      storage = @department.storages.find_by_id(params[:item_id])
      unless storage.nil?
        storage.insert_at(params[:position].to_i)
        saved = true
      end
    end
    render :json => { :ok => saved }
  end

  def shelfs
    @storage = @department.storages.find_by_id(params[:storage_id])
    authorize! :read, @storage || OrganizedStorage
    render :json => { :shelfs => @storage.is_a?(OrganizedStorage) ? @storage.shelf_count : 0 }
  end

end