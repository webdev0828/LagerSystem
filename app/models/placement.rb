class Placement < ActiveRecord::Base
  belongs_to :organized_storage
  has_one :pallet, :as => :position

  def position_name(sep = true)
    "[ #{shelf}, #{column}, #{floor} ] #{sep ? "<span class=\"sep\">&middot;</span>" : "-"} #{organized_storage.name}".html_safe
  end

  def sort_key(sep = true)
    "#{"%03d" % organized_storage.position}_#{"%03d" % shelf}_#{"%03d" % column}_#{"%03d" % floor}"
  end

end
