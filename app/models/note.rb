class Note < ActiveRecord::Base
  belongs_to :customer
  validates_presence_of :content
  attr_readonly :posted_at

  def content=(value)
    write_attribute :content, value.try(:strip)
  end

end
