class BulkStorage < Storage
  has_many :pallets, as: :position, dependent: :restrict_with_error

  validates_presence_of :name

  def js_id
    "storage_#{id}"
  end

  def url_param
    "#{id}"
  end

  def position_name(sep = true)
    name
  end

  def sort_key(sep = true)
    "#{"%03d" % position}"
  end
end
