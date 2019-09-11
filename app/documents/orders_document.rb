# encoding: utf-8

require 'prawn'

class OrdersDocument < Prawn::Document

  def initialize(view, pdf_options = {})
    super(pdf_options)
    @view       = view
    @department = view.instance_variable_get(:@department)
    @customer   = view.instance_variable_get(:@customer)
    @order      = view.instance_variable_get(:@order)
    @ready_orders  = view.instance_variable_get(:@ready_orders)

    @table_defaults = {
      header: true,
      width: bounds.width,
      cell_style: {
        border_width: 0.1,
        border_color: "888888",
        padding: 4,
        padding_top: 2,
        size: 8
      }
    }

    font_size = 12
  end

  def self.pallet_note(view, total)
    pdf = OrdersDocument.new(view)
    (1..total).each do |num|
      pdf.pallet_note_page(num, total)
      pdf.start_new_page unless num == total
    end
    pdf
  end

  def self.delivery_note(view)
    pdf = OrdersDocument.new(view)
    pdf.note_header
    pdf.delivery_note_table
    pdf.delivery_note_form
    pdf
  end

  def self.all_delivery_notes(view)
    pdf = OrdersDocument.new(view)
    ready_orders  = view.instance_variable_get(:@ready_orders)
    ready_orders.each do |order|
      pdf.note_header(order)
      pdf.delivery_note_table(order)
      pdf.delivery_note_form
      pdf.start_new_page unless order.equal? ready_orders.last
    end
    pdf
  end

  def self.exit_note(view)
    pdf = OrdersDocument.new(view)
    pdf.note_header
    pdf.exit_table
    pdf
  end

  def self.scrap_note(view)
    pdf = OrdersDocument.new(view)
    pdf.scrap_note_header
    pdf.scrap_note_table
    pdf
  end

  def pallet_note_page(num, total)
    move_down 200
    text "Ordre No. #{@order.number}", size: 30, align: :right, style: :bold
    move_down 40
    text @order.destination_address, size: 26
    move_down 10
    text "Læssedato: #{@view.l @order.load_at}", size: 20
    text "Levering: #{@order.delivery}", size: 20 if @order.delivery.present?
    move_down 40
    text "Afs.: #{@customer.name}", size: 20
    move_down 10
    text "c/o #{@department.address}", size: 20
    move_down 40
    text "Palle #{num} af #{total}", size: 50, align: :center
  end

  def note_header(order_param = nil)
    if (!order_param.nil?)
      order = order_param
      customer = order.customer
      department = order.customer.department
     else
      order = @order
      customer = @customer
      department = @department
    end
    
    athird = bounds.width / 3
    low = self.y
    bounding_box [0, bounds.height], :width => athird do
      text 'Afsender:', :style => :bold
      text "#{customer.name}\n#{customer.address}"
      low = self.y
    end

    bounding_box [athird, bounds.height], :width => athird do
      text 'Leveringsadresse:', :style => :bold
      text order.destination_address
      low = self.y if low > self.y
    end

    bounding_box [athird * 2, bounds.height], :width => athird do
      text "Ordre No. #{order.number}", :size => 20, :align => :right
      text "#{department.name}", :style => :italic, :align => :right
      text "Autorisationsnr.: #{department.authorization_number}", :align => :right
      text "Læssedato: #{@view.l order.load_at, :format => :short}", :align => :right
      text "Leveringsdato: #{@view.l order.deliver_at, :format => :short}", :align => :right
      low = self.y if low > self.y
    end

    self.y = low - 5
  end

  def delivery_note_table(order_param = nil)

    headers = [
      'Varenr.',
      'Lotnr.',
      'Varebeskrivelse',
      'Antal'
    ]

    if (!order_param.nil?) 
      order = order_param
     else 
      order = @order
    end 

    table_data = order.reservations.map { |reservation| [
      reservation.pallet.number,
      reservation.pallet.batch,
      reservation.pallet.name,
      @view.number_with_delimiter(reservation.count)
    ]}

    table( [headers] + table_data, @table_defaults ) do |table|
      table.row(0).font_style = :bold
      table.columns(0..2).align = :left
      table.column(3).align = :center
      table.column(0).width = 100
      table.column(1).width = 130
      table.column(3).width = 35
    end

    move_down 10

    text "Antal collie i alt: #{order.reservations.sum(:count)}", :align => :right
  end

  def delivery_note_form
    start_new_page if cursor < 120

    bounding_box [100, 100], :width => bounds.width - 200 do
      line_width = 0.2

      text "Antal paller: #{ " " * 33 } EUR #{ " " * 33 } UK"
      horizontal_rule
      stroke
      move_down 25

      text "Bilnr.:"
      horizontal_rule
      stroke
      move_down 25

      text "Chaufførens underskrift:"
      horizontal_rule
      stroke
    end
  end

  def exit_table
    headers = [
      'Varenr.',
      'Lotnr.',
      'M.H.T',
      'Varebeskrivelse',
      'Vægt/Krt.',
      'Antal',
      'Vægt'
    ]

    table_data = @order.reservations.map { |reservation| [
      reservation.pallet.number,
      reservation.pallet.batch,
      I18n.l(reservation.pallet.best_before, format: :short),
      reservation.pallet.name,
      @view.number_with_precision(reservation.pallet.weight) + " kg",
      @view.number_with_delimiter(reservation.count),
      @view.number_with_precision(reservation.pallet.weight * reservation.count) + " kg"
    ]}

    # generate table data
    table([headers] + table_data, @table_defaults) do |table|
      table.row(0).font_style = :bold
      table.columns(0..3).align = :left
      table.column(4).align = :right
      table.column(5).align = :center
      table.column(6).align = :right
      table.column(0).width = 100
      table.column(1).width = 130
      table.column(5).width = 35
    end

    move_down 10

    text "Antal collie i alt: #{@order.reservations.sum(:count)}", :align => :right
    text "Vægt i alt: #{@view.number_with_precision(@order.reservations.to_a.sum { |r| r.pallet.weight * r.count })} kg", :align => :right
  end

  def scrap_note_header
    low = self.y
    bounding_box [0, bounds.height], :width => (bounds.width / 2) do
      text "#{@order.destination_address}"
      low = self.y
    end

    bounding_box [bounds.width / 2, bounds.height], :width => (bounds.width / 2) do
      text "Ordre No. #{@order.number}", :size => 20, :align => :right
      move_up 2
      text "Afs.: #{@customer.name}", :style => :italic, :align => :right
      move_down 2
      text "Læssedato: #{@view.l @order.load_at}", :size => 10, :align => :right
      text "Leveringsdato: #{@view.l @order.deliver_at}", :size => 10, :align => :right
      text "Levering: #{@order.delivery}", size: 10, :align => :right if @order.delivery.present?
      low = self.y if low > self.y
    end
    
    self.y = low - 8

    if @order.note.present?
      text "Bemærk!", :size => 16, :style => :bold
      text @order.note
      move_down 8
    end

  end

  def scrap_note_table
    headers = [
      'Varenr, Lot og Trace',
      'Varebeskrivelse',
      'Antal',
      'Plads',
      'Tilbagemelding'
    ]

    # A mark should be put on scrap reservations, if a similar
    # scrap reservation exists (of same article number)
    marks = {}
    @order.reservations.each do |reservation|
      pallet = reservation.pallet
      marks[pallet.number] ||= { reservations: [] }
      marks[pallet.number][:reservations] << reservation if reservation.count < pallet.capacity
    end
    marks.reject! { |_,o| o[:reservations].size < 2 }
    marks.each_value.inject('a') { |m,o| o[:ref] = m; m.next }

    table_data = @order.reservations.sort_by{ |r| r.pallet.position.sort_key }.map do |reservation|
      pallet = reservation.pallet

      count_column = @view.number_with_delimiter(reservation.count)
      if marks[pallet.number] && marks[pallet.number][:reservations].include?(reservation)
        count_column += "\n(#{marks[pallet.number][:ref]})"
      end

      [
        "#{Pallet.attr_name(:number)}: #{pallet.number}\n" +
        "#{Pallet.attr_name(:batch)}: #{pallet.batch}\n" +
        (pallet.trace.present? ? "#{Pallet.attr_name(:trace)}: #{pallet.trace}\n" : "") +
        "#{Pallet.attr_name(:best_before)}: #{@view.l pallet.best_before, :format => :short}",
        pallet.name,
        count_column,
        pallet.position.position_name(false),
        ""
      ]
    end

    # generate table data
    table([headers] + table_data, @table_defaults) do |table|
      table.row(0).font_style = :bold
      table.columns(0..1).align = :left
      table.column(2).align = :center
      table.columns(3..4).align = :left
      table.columns(0).width = 100
      table.columns(1).width = 130
      table.columns(2).width = 35
      table.columns(3).width = 90
    end

  end

end