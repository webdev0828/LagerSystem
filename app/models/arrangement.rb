class Arrangement < ActiveRecord::Base
  belongs_to :customer

  validates_numericality_of :scrap_minimum, :greater_than => 1, :only_integer => true, :if => Proc.new { |a| a.use_scrap_minimum }

  def scrap_minimum
    use_scrap_minimum ? self.read_attribute(:scrap_minimum) : nil
  end

end
