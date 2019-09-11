class OrderImport < ActiveRecord::Base
  belongs_to :customer_group
  has_many :orders, dependent: :destroy

  belongs_to :owner, class_name: 'User'

  mount_uploader :file, TextFileUploader

  serialize :data, Hash

  before_validation :ensure_file_presence, :parse_uploaded_file, on: :create

  validates_presence_of :number, :destination_name, :destination_address, :load_at, :deliver_at

  after_create :create_orders
  after_update :update_attached_orders

  def contents
    @contents ||= begin
      File.read(file.path, encoding: 'iso-8859-1')
          .encode('windows-1252', undef: :replace)
          .encode('utf-8')
          .lines
          .map(&:strip)
          .join("\n")
          .strip
    end
  end

  def order_lines
    data[:order_lines] ||= data[:matched_lines] ||= []
  end

  def order_lines=(lines)
    data[:order_lines] = Array(lines)
  end

  def unmatched
    data[:unmatched] ||= data[:unmatched_lines] ||= []
  end

  def unmatched=(lines)
    data[:unmatched] = Array(lines)
  end

  def delivery
    data[:delivery]
  end

  def delivery=(value)
    data[:delivery] = value
  end

  private

  def ensure_file_presence
    return unless file.file.nil?
    errors.add(:file, :blank)
    false
  end

  # Driver codes for pallets that have load at and deliver at same day
  # an exception made for pallets delivered by JN Spedition A/S
  SAME_DAY_CODES = %w(10 11)

  # @raise parse error
  def parse_uploaded_file
    parser = Parsers::LaLorraine.instance
    result = parser.parse(contents)

    order_number = dest_name = result[:address].split("\n").first
    order_number += ' - Tillæg' if result[:addition]

    deliver_at = load_at = result[:date]
    deliver_at += 1.day if SAME_DAY_CODES.exclude?(result[:driver_code])

    # Store any unmatched lines as note so they are visible on the order
    note = result[:unmatched].join("\n").gsub(/[ ]{3,}/, '  ')

    assign_attributes(
        number:               order_number,
        destination_name:     dest_name,
        destination_address:  result[:address],
        load_at:              load_at,
        deliver_at:           deliver_at,
        unmatched:            result[:unmatched],
        order_lines:          result[:order_lines],
        delivery:             result[:delivery],
        note:                 note
    )

  rescue Parslet::ParseFailed => _e
    errors.add(:base, 'Kunne ikke læse ordre korrekt. Er formatet korrekt?')
    raise ActiveRecord::Rollback, 'Could not parse supplied file'

  rescue => e
    Rails.logger.warn { "Some error happened while parsing uploaded file (#{e.message})" }
    raise e
  end

  def create_orders
    items_missing = false
    shared_order_params = extract_shared_order_params
    orders_grouped_by_customer = {}

    order_lines.each do |order_line|

      search_result = customer_group.ordered_pallets_by_number(order_line[:article_number], order_line[:count])

      if search_result[:missing] > 0
        items_missing = true
        errors.add(:base, "Mangler #{ApplicationController.helpers.pluralize(search_result[:missing], 'vare', 'varer')} af varenummer #{order_line[:article_number]}")
      end

      search_result[:selected].each do |selection|
        pallet = selection[:pallet]
        customer = pallet.customer
        order = orders_grouped_by_customer[customer] ||= customer.orders.create!(shared_order_params)
        order.reservations.create!(pallet_id: pallet.id, count: selection[:count])
      end

    end

    raise ActiveRecord::Rollback, 'Missing one or more items. Orders not created' if items_missing
  end

  # TODO: This should fail in a way where you know what is going on
  def update_attached_orders
    params = extract_shared_order_params
    orders.each do |order|
      order.update!(params)
    end
  end

  def extract_shared_order_params
    {
        order_import_id: id,
        number: number,
        destination_name: destination_name,
        destination_address: destination_address,
        deliver_at: deliver_at,
        load_at: load_at,
        delivery: delivery,
        note: note,
        owner: owner
    }
  end

end
