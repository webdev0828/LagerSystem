class Department < ActiveRecord::Base
  has_many :customers, -> { order(:position) }
  has_many :storages,  -> { order(:position) }

  has_many :bulk_storages
  has_many :organized_storages
  has_many :customer_groups

  belongs_to :lobby,    :class_name => 'BulkStorage'
  belongs_to :transfer, :class_name => 'BulkStorage'
end
