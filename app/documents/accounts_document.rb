# encoding: utf-8

require 'prawn'

class AccountsDocument < Prawn::Document

  def initialize(view, pdf_options = {})
    super(pdf_options)
    @view     = view
    @customer = view.instance_variable_get(:@customer)
    @interval = view.instance_variable_get(:@interval)

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
  end

  def self.with_counts(view)
    pdf = AccountsDocument.new(view, page_layout: :landscape)

    pdf.document_header
    pdf.status_counts
    pdf.move_down 10

    pdf.text 'Total', size: 15, style: :bold
    pdf.sum_counts

    unless view.instance_variable_get(:@interval).corrections.empty?
      pdf.move_down 10
      pdf.text "Korrektioner", size: 15, style: :bold
      pdf.corrections
    end

    pdf
  end

  def self.with_weights(view)
    pdf = AccountsDocument.new(view, page_layout: :landscape)

    pdf.document_header
    pdf.status_weights
    pdf.move_down 10

    pdf.text 'Total', size: 15, style: :bold
    pdf.sum_weights

    unless view.instance_variable_get(:@interval).corrections.empty?
      pdf.move_down 10
      pdf.text "Korrektioner", size: 15, style: :bold
      pdf.corrections
    end

    pdf
  end

  def self.summary(view)
    pdf = AccountsDocument.new(view)
    
    customer = view.instance_variable_get(:@customer)
    interval = view.instance_variable_get(:@interval)
    
    pdf.text "#{customer.name} #{"- " + customer.subname if customer.subname.present?} (#{customer.number})", size: 20, style: :bold
    pdf.text interval.week_label, font_size: 14, style: :italic
    pdf.text "#{view.l interval.from, format: :long} - #{view.l interval.to, format: :long}", font_size: 14, style: :italic
    pdf.move_down(20)

    if interval.current_customer_arrangement
      pdf.text "Kundeaftale", size: 16, style: :bold
      pdf.text "Bruger minimumspluk: #{interval.current_customer_arrangement.use_scrap_minimum ? interval.current_customer_arrangement.scrap_minimum : "Nej"}"
      pdf.move_down(20)
    end

    pdf.text "Oversigt", size: 16, style: :bold
    pdf.summary

    unless interval.notes.to_a.empty?
      pdf.move_down(20)
      pdf.text "Noter", size: 16, style: :bold
      pdf.notes
    end

    pdf
  end

  def customer_info
    
  end

  def summary
    headers = [
      'Type',
      'Lagerleje (pll.)',
      'Lagerleje (kg)',
      'Handling (pll.)',
      'Handling (kg)',
      'Pluk (inkl. min)',
      'Min. pluk'
    ]

    data = @interval.sums.map { |row| [
      row['typename'],
      @view.number_with_delimiter(row['primo'] + row['incoming']),
      @view.number_with_precision(row['primo_weight'] + row['incoming_weight']),
      @view.number_with_delimiter(row['handling']),
      @view.number_with_precision(row['handling_weight']),
      @view.number_with_delimiter(row['scrap']) + " krt.",
      @view.number_with_delimiter(row['scrap_min']) + " krt."
    ]}

    last_row = [
      'Total:',
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['primo'] + n['incoming'] }),
      @view.number_with_precision(@interval.sums.inject(0){|m,n| m + n['primo_weight'] + n['incoming_weight'] }),
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['handling'] }),
      @view.number_with_precision(@interval.sums.inject(0){|m,n| m + n['handling_weight'] }),
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['scrap'] })                 + " krt.",
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['scrap_min'] })             + " krt."
    ]

    options = {
      header: true,
      width: bounds.width,
      cell_style: {
        border_width: 0.1,
        border_color: "888888",
        padding: 8,
        padding_top: 6,
        size: 9
      }
    }

    table([headers] + data + [last_row], options) do |table|
      table.row(0).font_style = :bold
      table.columns(0).align = :left
      table.columns(1..6).align = :right
    end
  end

  def notes
    @interval.notes.each do |note|
      move_down(4)
      line_width = 0.2
      dash(4, space: 2)
      stroke_color("dddddd")
      stroke_line [bounds.left, cursor, bounds.right, cursor]
      move_down(6)
      text "#{note.content}"
    end
  end

  def document_header
    text "#{@customer.name}#{" - #{@customer.number}" unless @customer.number.blank?}#{" (#{@customer.subname})" unless @customer.subname.blank?}", size: 20, style: :bold
    cursor = self.y
    text @interval.week_label + "#{" (foreløbig)" if @interval.new_record?}"
    if @interval.new_record?
      self.y = cursor
      text "#{@view.l @interval.from, format: :long} - #{@view.l @interval.to, format: :long}", align: :right
    end
  end

  def status_counts
    headers = [
      'Varenr.',
      'Lot',
      'Varenavn',
      'Trace',
      "Antal\npr. pll.",
      'Type',
      'M.H.T.',
      "Vægt (kg)\npr. krt.",
      'Primo',
      '(pll.)',
      'Ind',
      '(pll.)',
      'Ud',
      'Pluk',
      '(heraf min.)',
      'Ultimo',
      '(pll.)'
    ]

    data = @interval.data.map { |row| [
      row['number'],
      row['batch'],
      row['name'],
      row['trace'],
      row['capacity'],
      row['pallet_type_name'],
      @view.l(row['best_before'], format: :special),
      @view.number_with_precision(row['weight']),
      @view.number_with_delimiter(row['primo']),
      @view.number_with_delimiter(row['primo_pallets']),
      @view.number_with_delimiter(row['incoming']),
      @view.number_with_delimiter(row['incoming_pallets']),
      @view.number_with_delimiter(row['outgoing']),
      @view.number_with_delimiter(row['scrap']),
      @view.number_with_delimiter(row['scrap_min']),
      @view.number_with_delimiter(row['ultimo']),
      @view.number_with_delimiter(row['ultimo_pallets'])
    ]}

    last_row = [
      'Total:',
      nil, nil, nil, nil, nil, nil, nil,
      @view.number_with_delimiter(@interval.data.sum{ |r| r['primo']            || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['primo_pallets']    || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['incoming']         || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['incoming_pallets'] || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['outgoing']         || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['scrap']            || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['scrap_min']        || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['ultimo']           || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r['ultimo_pallets']   || 0 })
    ]

    alignments = [
      :left,
      :left,
      :left,
      :left,
      :right,
      :center,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right
    ]

    # remove trace column if it is unused
    if @interval.data.all? { |v| v["trace"].blank? }
      data.each { |v| v.delete_at(3) }
      headers.delete_at(3)
      last_row.delete_at(3)
      alignments.delete_at(3)
    end

    table [headers] + data + [last_row], @table_defaults do |table|
      table.row(0).font_style = :bold
      alignments.each_with_index { |a,i| table.columns(i).align = a }
    end

  end

  def status_weights
    headers = [
      "Varenr.",
      "Lot",
      "Varenavn",
      "Trace",
      "Antal\npr. pll.",
      "Type",
      "M.H.T.",
      "Vægt (kg)\npr. krt.",
      "Primo",
      "Vægt (kg)",
      "Ind",
      "Vægt (kg)",
      "Ud",
      "Vægt (kg)",
      "Ultimo",
      "Vægt (kg)"
    ]

    data = @interval.data.map { |row| [
      row["number"],
      row["batch"],
      row["name"],
      row["trace"],
      row["capacity"],
      row["pallet_type_name"],
      @view.l(row["best_before"], :format => :special),
      @view.number_with_precision(row["weight"]),
      @view.number_with_delimiter(row["primo"]),
      @view.number_with_precision(row["primo_weight"]),
      @view.number_with_delimiter(row["incoming"]),
      @view.number_with_precision(row["incoming_weight"]),
      @view.number_with_delimiter(row["outgoing"]),
      @view.number_with_precision(row["outgoing_weight"]),
      @view.number_with_delimiter(row["ultimo"]),
      @view.number_with_precision(row["ultimo_weight"])
    ]}

    last_row = [
      'Total:',
      nil, nil, nil, nil, nil, nil, nil,
      @view.number_with_delimiter(@interval.data.sum{ |r| r["primo"]           || 0 }),
      @view.number_with_precision(@interval.data.sum{ |r| r["primo_weight"]    || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r["incoming"]        || 0 }),
      @view.number_with_precision(@interval.data.sum{ |r| r["incoming_weight"] || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r["outgoing"]        || 0 }),
      @view.number_with_precision(@interval.data.sum{ |r| r["outgoing_weight"] || 0 }),
      @view.number_with_delimiter(@interval.data.sum{ |r| r["ultimo"]          || 0 }),
      @view.number_with_precision(@interval.data.sum{ |r| r["ultimo_weight"]   || 0 }),
    ]

    alignments = [
      :left,
      :left,
      :left,
      :left,
      :right,
      :center,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right,
      :right
    ]

    # remove trace column if it is unused
    if @interval.data.all? { |v| v["trace"].blank? }
      data.each { |v| v.delete_at(3) }
      headers.delete_at(3)
      last_row.delete_at(3)
      alignments.delete_at(3)
    end

    table([headers] + data + [last_row], @table_defaults) do |table|
      table.row(0).font_style = :bold
      alignments.each_with_index { |a,i| table.columns(i).align = a }
    end
  end

  def sum_counts
    headers = [
      'Type',
      'Lagerleje',
      'Handling',
      'Pluk (inkl. min)',
      'Min. pluk'
    ]

    data = @interval.sums.map { |row| [
      row['typename'],
      @view.number_with_delimiter(row['primo'] + row['incoming']) + " pll.",
      @view.number_with_delimiter(row['handling']) + " pll.",
      @view.number_with_delimiter(row['scrap']) + " krt.",
      @view.number_with_delimiter(row['scrap_min']) + " krt."
    ]}

    last_row = [
      'Total:',
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['primo'] + n['incoming'] }) + " pll.",
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['handling'] })              + " pll.",
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['scrap'] })                 + " krt.",
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['scrap_min'] })             + " krt."
    ]

    table([headers] + data + [last_row], @table_defaults.merge( width: bounds.width / 2 )) do |table|
      table.row(0).font_style = :bold
      table.column(0).font_style = :bold
      table.columns(0).align = :left
      table.columns(1..4).align = :right
    end
  end

  def sum_weights
    headers = [
      'Type',
      'Lagerleje (pll.)',
      'Vægt (kg)',
      'Handling (pll.)',
      'Vægt (kg)'
    ]

    data = @interval.sums.map { |row| [
      row['typename'],
      @view.number_with_delimiter(row['primo'] + row['incoming']),
      @view.number_with_precision(row['primo_weight'] + row['incoming_weight']),
      @view.number_with_delimiter(row['handling']),
      @view.number_with_precision(row['handling_weight'])
    ]}

    last_row = [
      'Total:',
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['primo'] + n['incoming'] }),
      @view.number_with_precision(@interval.sums.inject(0){|m,n| m + n['primo_weight'] + n['incoming_weight'] }),
      @view.number_with_delimiter(@interval.sums.inject(0){|m,n| m + n['handling'] }),
      @view.number_with_precision(@interval.sums.inject(0){|m,n| m + n['handling_weight'] })
    ]

    table([headers] + data + [last_row], @table_defaults.merge( width: bounds.width / 2 )) do |table|
      table.row(0).font_style = :bold
      table.column(0).font_style = :bold
      table.columns(0).align = :left
      table.columns(1..4).align = :right
    end
  end

  def corrections
    headers = [
      @view.t("account_table.number"),
      @view.t("account_table.batch"),
      @view.t("account_table.name"),
      @view.t("account_table.trace"),
      @view.t("account_table.best_before"),
      @view.t("account_table.pallet_type"),
      @view.t("account_table.capacity"),
      @view.t("account_table.weight"),
      @view.t("account_table.count")
    ]

    data = @interval.corrections.map { |row| [
      row["number"],
      row["batch"],
      row["name"],
      row["trace"],
      @view.l(row["best_before"], format: :special),
      @view.correction_label(row, "pallet_type_name", ">"),
      @view.correction_label(row, "capacity", ">"),
      @view.correction_label(row, "weight", ">") { |w| @view.number_with_precision w },
      @view.correction_relative_count(row)
    ]}

    table([headers] + data, @table_defaults) do |table|
      table.row(0).font_style = :bold
      table.columns(0..8).align = :left
    end
  end

end