# encoding: utf-8

require 'prawn'

class ShelfDocument < Prawn::Document

  def initialize(organized_storage, view)
    super({
      top_margin:    56, # space for header
      left_margin:   36,
      right_margin:  36,
      bottom_margin: 36
    })

    @organized_storage = organized_storage
    @view = view

    # collect data
    data = []
    @organized_storage.placements.where(shelf: @organized_storage.choosen_shelf).includes(:pallet).order('floor, `column`').group_by(&:column).each_pair do |column, placements|
      data << [ "#{column}" ] + placements.map { |placement|
        p = placement.pallet
        p.nil? ? " " : "v: #{p.number}\nmht: #{p.best_before}\na: #{p.available} #{"(#{p.reserved} res.)" if p.reserved > 0}"
      }
    end

    max_col = @organized_storage.max_floor

    # generate header labels
    headers = [ "" ]
    headers += (1..max_col).map { |n| "Sal: #{n}" }

    # calculate column widths
    cell_width = (bounds.width - 20) / max_col

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

    table( [headers] + data, options) do |table|
      table.row(0).font_style = :bold
      table.column(0).font_style = :bold
      table.column(0).width = 20
      table.columns(1..max_col).width = cell_width
    end

    # draw headers
    (1..page_count).each do |i|
      go_to_page(i)
      pos = bounds.top - (self.cursor - self.y) + 20
      self.y = pos
      text "#{@organized_storage.name} - Reol #{@organized_storage.choosen_shelf}", :size => 18
      self.y = pos
      text "#{@view.l Time.current}", size: 18, align: :right
      self.y = pos - 3
      text "side #{i} af #{page_count}", :size => 12, :align => :center
    end

  end

end