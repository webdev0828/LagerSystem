class Storage < ActiveRecord::Base
  belongs_to :department
  acts_as_list :scope => :department
end
