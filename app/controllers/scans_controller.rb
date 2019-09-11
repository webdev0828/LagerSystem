class ScansController < ApplicationController
  before_filter :load_department
  before_filter :load_customer

  def show
    redirect_to :action => "new"
  end

  def new
  end

  def create

    if not @customer.barcode_format.present?
      redirect_to( { :action => "new" }, :alert => "Der er ikke indstillet et scanningsformat for denne kunde." )
      return
    end

    # FIXME hardcoded to storage 6
    @storage = OrganizedStorage.find(6)

    # gemmer ark i json
    @sheets = []

    barcode = YAML::load @customer.barcode_format

    # read file
    file = params[:datafile]
    book = Spreadsheet.open file.tempfile

    # prepare elements
    book.worksheets.each_with_index do |ws, i|

      # FIXME hardcoded max columns to 6
      rc, cc = ws.row_count, barcode["max_columns"]

      # a matrix of all values
      items = (0...rc).map { |i| { :row => (0...cc).map { |j| ws.cell(i,j) } } }
      items.reject!{ |r| r[:row].all?(&:nil?) }

      items.each do |item|

        # is any of the cells nil? => unexpected data
        if item[:row].any?(&:nil?)
          item[:error] = "empty_fields"
          next
        end

        shelf  = item[:row][ barcode["shelf" ]["column"] ].to_s[ barcode["shelf" ]["offset"], barcode["shelf" ]["length"] ]
        column = item[:row][ barcode["column"]["column"] ].to_s[ barcode["column"]["offset"], barcode["column"]["length"] ]
        floor  = item[:row][ barcode["floor" ]["column"] ].to_s[ barcode["floor" ]["offset"], barcode["floor" ]["length"] ]

        # shelf, column, floor = item[:row][2].scan(/../)

        placement = @storage.placements.find_by_shelf_and_column_and_floor(shelf, column, floor)
        item[:pallet] = pallet = placement.try(:pallet)

        # is any of the placements empty? => unexpected placement
        if pallet.nil?
          item[:error] = "empty_placement"
          next
        end

        # is any of the pallet by other customer? => unexpected placement
        if pallet.customer_id != @customer.id
          item[:error] = "wrong_customer"
          next
        end

        # is any of the pallets by different original_count => unexpected data
        if pallet.original_capacity != item[:row][ barcode["count"]["column"] ].to_i
          item[:error] = "wrong_capacity (#{pallet.original_capacity} != #{item[:row][ barcode["count"]["column"] ].to_i})"
          next
        end

        item[:pallet_id]    = pallet.id
        item[:trace]        = trace = item[:row][ barcode["trace"]["column"] ][ barcode["trace"]["offset"], barcode["trace"]["length"] ]
        item[:batch]        = batch = item[:row][ barcode["batch"]["column"] ][ barcode["batch"]["offset"], barcode["batch"]["length"] ]
        item[:in_sync]      = (pallet.trace == trace and pallet.batch == batch)

      end

      # if pallets are only a part of an arrival? (not the intire arrival) => unexpected data (missing pallets)

      pallets = items.map { |i| i[:pallet] }.reject(&:nil?)
      errors = nil

      ok = items.all?{ |item| item[:error].nil? }

      arrivals = pallets.group_by(&:arrival)
      arrivals.each_pair do |a, p|
        ok = ok and a.pallets.count == p.size
      end

      # is any of the pallets registered to the same position

      if ok
        items.each do |p|
          next if p[:in_sync]
          pallet = Pallet.find(p[:pallet_id])
          pallet.batch = p[:batch]
          pallet.trace = p[:trace]
          p[:saved] = pallet.save
          p[:errors] = !pallet.errors.empty?
        end
      end

      @sheets << {
        :name => ws.name,
        :items => items,
        :ok => (ok and errors.nil?)
      }
    end

    memory = {}

    # is any of the pallets registered to the same position
    all_items = @sheets.map { |s| s[:items] }.flatten
    all_items.each do |item|
      next if item[:pallet_id].nil?
      if memory.key?(item[:pallet_id].to_i)
        other = memory[item[:pallet_id].to_i]
        other[:ok] = false
        other[:error] = "same position as other pallet"
        item[:ok] = false
        item[:error] = "same position as other pallet"
      else
        memory[item[:pallet_id].to_i] = item
      end
    end

    render :action => "show"
  end

  def update

    objects = params[:objects]
    objects.each do |i,o|
      pallet = Pallet.find( o[:pallet_id] )
      pallet.batch = o[:batch]
      pallet.trace = o[:trace]
      o[:saved] = pallet.save
      o[:errors] = !pallet.errors.empty?
    end

    render :json => {
      :objects => objects,
      :ok      => objects.all? { |i,o| o[:saved] }
    }

  end

private

  def load_department
    @department = Department.find(params[:department_id])
  end

  def load_customer
    @customer = @department.customers.find(params[:customer_id])
  end

end
