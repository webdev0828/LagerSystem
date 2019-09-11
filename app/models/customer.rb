class Customer < ActiveRecord::Base
  belongs_to :department
  acts_as_list :scope => :department
  has_many :intervals
  has_many :notes
  has_many :pallets
  has_many :orders
  has_many :arrivals

  has_many :arrangements

  scope :active, -> { where(deactivated: false) }

  validates_presence_of :name
  validates_presence_of :number
  validates_presence_of :address

  after_create :create_arrangement

  def last_count
    @last_count ||= intervals.last.try(:to) || :loaded
    @last_count == :loaded ? nil : @last_count
  end

  def current_arrangement(before=nil)
    @current_arrangement ||= {}
    unless @current_arrangement[before]
      query = arrangements
      query = query.where('created_at < ?', before) if before
      @current_arrangement[before] ||= query.order('created_at DESC').first || :loaded
    end
    @current_arrangement[before] == :loaded ? nil : @current_arrangement[before]
  end

  def build_current_interval
    intervals.build(
      :from => last_count || Time.current.at_beginning_of_week,
      :to => Time.current
    )
  end

  private

  def create_arrangement
    arrangements.create
  end

end
