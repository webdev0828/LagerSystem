# encoding: utf-8

require 'prawn'

class ArrivalsDocument < Prawn::Document

  def initialize(view)
    super()
    @view = view
    @department = view.instance_variable_get(:@department)
    @customer   = view.instance_variable_get(:@customer)
    @arrival    = view.instance_variable_get(:@arrival)

    # Calculate count and weight for entire arrival
    @total_count = 0
    @total_weight = 0.0
    @arrival.pallets.each do |pallet|
      @total_count += pallet.count
      @total_weight += pallet.weight * pallet.count
    end
  end

  def self.show(view)
    pdf = ArrivalsDocument.new(view)
    pdf.header
    pdf.move_down 5
    pdf.info
    pdf.move_down 10
    pdf.list
    pdf
  end

  def header
    text "Indgang - #{@customer.name}", size: 14, style: :bold
  end

  def info
    table([
      ["Indgangsdato:",       "#{@view.l @arrival.arrived_at.to_date}"],
      ["Indgangstemperatur:", "#{@view.number_with_precision @arrival.temperature}"],
      ["Paller i alt:",       "#{@arrival.pallets.to_a.size}"],
      ["Antal:",              "#{@view.number_with_delimiter @total_count} krt."],
      ["Vægt:",               "#{@view.number_with_precision @total_weight} kg"]
    ], {
      cell_style: {
        padding: [2, 10, 2, 0],
        size: 12,
        border_width: 0
      }
    })
  end

  def list
    headers = [
      "Varenr.",
      "Lot",
      "Varenavn",
      "Trace",
      "Type",
      "M.H.T.",
      "Vægt (kg)\npr. krt.",
      "Antal krt.",
      "Vægt (kg)"
    ]

    data = @arrival.pallets.map { |pallet| [
      pallet.number,
      pallet.batch,
      pallet.name,
      pallet.trace,
      pallet.pallet_type.name,
      @view.l(pallet.best_before, :format => :special),
      @view.number_with_precision(pallet.weight),
      pallet.count,
      @view.number_with_precision(pallet.weight * (pallet.count))
    ]}

    last_row = [
      "Total:",
      "",
      "",
      "",
      "",
      "",
      "",
      "#{@view.number_with_delimiter @total_count}",
      "#{@view.number_with_precision @total_weight}"
    ]

    options = {
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

    table([headers] + data + [last_row], options) do |table|
      table.rows(0).font_style = :bold
      table.columns(0..3).align = :left
      table.columns(4).align = :center
      table.columns(5..8).align = :right
    end
  end
end