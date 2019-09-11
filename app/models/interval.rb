# encoding: utf-8
class Interval < ActiveRecord::Base
  include ActionView::Helpers

  belongs_to :customer

  validates_presence_of :from, :to, :customer
  validate :check_from_before_to
  validate :check_to_in_past

  attr_accessor :from_string, :to_string

  def current_customer_arrangement
    customer.current_arrangement(to)
  end

  def data
    @data ||= calculate_data
  end

  def sums
    @sums ||= calculate_sums
  end

  def corrections
    @corrections ||= corrected
  end

  def notes
    @notes ||= customer.notes.where('posted_at >= ? AND posted_at < ?', from, to)
  end

  # neet helpers
  def middle_datetime
    from + (to - from) / 2
  end

  def week_info
    { :week => to.to_date.cweek,
      :year => to.to_date.cwyear }
  end

  def week_label
    "Uge %{week} - %{year}" % week_info
  end

  def csv_counts(view)
    CSV.generate( col_sep: "\t" ) do |csv|
      wi = week_info

      csv << [ customer.name ]
      csv << ["Uge #{wi[:week]}", wi[:year]]
      csv << []

      table = []

      # Kolonner
      table << [
        'Varenr.',
        'Lot',
        'Varenavn',
        'Trace',
        "Antal pr. pll.",
        'Type',
        'M.H.T.',
        "Vægt (kg) pr. krt.",
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

      self.data.each do |row|
        line = [
          row['number'],
          row['batch'],
          row['name'],
          row['trace'],
          row['capacity'],
          row['pallet_type_name'],
          view.l(row['best_before'], :format => :special),
          view.number_with_precision(row['weight']),
          view.number_with_delimiter(row['primo']),
          view.number_with_delimiter(row['primo_pallets']),
          view.number_with_delimiter(row['incoming']),
          view.number_with_delimiter(row['incoming_pallets']),
          view.number_with_delimiter(row['outgoing']),
          view.number_with_delimiter(row['scrap']),
          view.number_with_delimiter(row['scrap_min']),
          view.number_with_delimiter(row['ultimo']),
          view.number_with_delimiter(row['ultimo_pallets'])
        ]

        # strip empty fields, since they fuck up
        table << line.map{ |v| v.blank? ? nil : v }
      end

      table << [
        'Total:',
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,

        view.number_with_delimiter(data.sum{ |r| r['primo']            || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['primo_pallets']    || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['incoming']         || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['incoming_pallets'] || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['outgoing']         || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['scrap']            || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['scrap_min']        || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['ultimo']           || 0 }),
        view.number_with_delimiter(data.sum{ |r| r['ultimo_pallets']   || 0 })
      ]

      # remove trace if not used
      if data.all?{ |v| v["trace"].blank? }
        table.each { |v| v.delete_at(3) }
      end

      # post all table
      table.each do |row|
        csv << row
      end

      csv << []

      table = []
      table << [
        'Type',
        'Lagerleje',
        'Handling',
        'Pluk (inkl. min)',
        'Min. pluk'
      ]

      sums.each do |row|
        table << [
          row['typename'],
          view.number_with_delimiter(row['primo'] + row['incoming']) + " pll.",
          view.number_with_delimiter(row['handling']) + " pll.",
          view.number_with_delimiter(row['scrap']) + " krt.",
          view.number_with_delimiter(row['scrap_min']) + " krt."
        ]
      end

      sums.each do |row|
        table << [
          row['typename'],
          view.number_with_delimiter(row['primo'] + row['incoming']) + " pll.",
          view.number_with_precision(row['primo_weight'] + row['incoming_weight']) + " kg",
          view.number_with_delimiter(row['handling']) + " pll.",
          view.number_with_precision(row['handling_weight']) + " kg"
        ]
      end

      table << [
        'Total:',
        view.number_with_delimiter(sums.inject(0){|m,n| m + n['primo'] + n['incoming'] }) + " pll.",
        view.number_with_delimiter(sums.inject(0){|m,n| m + n['handling'] })              + " pll.",
        view.number_with_delimiter(sums.inject(0){|m,n| m + n['scrap'] })                 + " krt.",
        view.number_with_delimiter(sums.inject(0){|m,n| m + n['scrap_min'] })             + " krt."
      ]

      # insert table
      table.each do |row|
        csv << row
      end

      unless corrections.empty?
        csv << []
        csv << ['Korrektioner']

        table = []
        table << [
          view.t("account_table.number"),
          view.t("account_table.batch"),
          view.t("account_table.name"),
          view.t("account_table.trace"),
          view.t("account_table.best_before"),
          view.t("account_table.pallet_type"),
          view.t("account_table.capacity"),
          view.t("account_table.weight"),
          view.t("account_table.count")
        ]


        corrections.each do |row|
          table << [
            row["number"],
            row["batch"],
            row["name"],
            row["trace"],
            view.l(row["best_before"], :format => :special),
            view.correction_label(row, "pallet_type_name", " -- "),
            view.correction_label(row, "capacity", " -- "),
            view.correction_label(row, "weight", " -- ") { |w| view.number_with_precision w },
            view.correction_relative_count(row)
          ]
        end

        table.each do |row|
          csv << row
        end
      end
    end
  end

  def csv_weights(view)
    CSV.generate( col_sep: "\t") do |csv|
      wi = week_info

      csv << [ customer.name ]
      csv << ["Uge #{wi[:week]}", wi[:year]]
      csv << []



      table = []

      # Kolonner
      table << [
        'Varenr.',
        'Lot',
        'Varenavn',
        'Trace',
        'Antal / pll.',
        'Type',
        'M.H.T.',
        'Vægt pr. krt.',
        'Primo',
        'Vægt',
        'Ind',
        'Vægt',
        'Ud',
        'Vægt',
        'Ultimo',
        'Vægt'
      ]



      data.each do |row|
        line = [
          row["number"],
          row["batch"],
          row["name"],
          row["trace"],
          row["capacity"],
          row["pallet_type_name"],
          view.l(row["best_before"], :format => :special),
          view.number_with_precision(row["weight"]),
          view.number_with_delimiter(row["primo"]),
          view.number_with_precision(row["primo_weight"]),
          view.number_with_delimiter(row["incoming"]),
          view.number_with_precision(row["incoming_weight"]),
          view.number_with_delimiter(row["outgoing"]),
          view.number_with_precision(row["outgoing_weight"]),
          view.number_with_delimiter(row["ultimo"]),
          view.number_with_precision(row["ultimo_weight"])
        ]

        # strip empty fields, since they fuck up
        table << line.map{ |v| v.blank? ? nil : v }
      end


      table << []
      table << [
        'Total:',
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        view.number_with_delimiter(data.sum{ |r| r["primo"]           || 0 }),
        view.number_with_precision(data.sum{ |r| r["primo_weight"]    || 0 }),
        view.number_with_delimiter(data.sum{ |r| r["incoming"]        || 0 }),
        view.number_with_precision(data.sum{ |r| r["incoming_weight"] || 0 }),
        view.number_with_delimiter(data.sum{ |r| r["outgoing"]        || 0 }),
        view.number_with_precision(data.sum{ |r| r["outgoing_weight"] || 0 }),
        view.number_with_delimiter(data.sum{ |r| r["ultimo"]          || 0 }),
        view.number_with_precision(data.sum{ |r| r["ultimo_weight"]   || 0 })
      ]

      # remove trace if not used
      if data.all?{ |v| v["trace"].blank? }
        table.each { |v| v.delete_at(3) }
      end

      # post all table
      table.each do |row|
        csv << row
      end

      csv << []
      csv << [
        'Type',
        'Lagerleje',
        'Vægt',
        'Handling',
        'Vægt'
      ]

      sums.each do |row|
        csv << [
          row['typename'],
          view.number_with_delimiter(row['primo'] + row['incoming']) + " pll.",
          view.number_with_precision(row['primo_weight'] + row['incoming_weight']) + " kg",
          view.number_with_delimiter(row['handling']) + " pll.",
          view.number_with_precision(row['handling_weight']) + " kg"
        ]
      end

      csv << [
        'Total:',
        view.number_with_delimiter(sums.inject(0){|m,n| m + n['primo'] + n['incoming'] })               + " pll.",
        view.number_with_precision(sums.inject(0){|m,n| m + n['primo_weight'] + n['incoming_weight'] }) + " kg",
        view.number_with_delimiter(sums.inject(0){|m,n| m + n['handling'] })                            + " pll.",
        view.number_with_precision(sums.inject(0){|m,n| m + n['handling_weight'] })                     + " kg"
      ]

      unless corrections.empty?
        csv << []
        csv << ['Korrektioner']

        table = []
        table << [
          view.t("account_table.number"),
          view.t("account_table.batch"),
          view.t("account_table.name"),
          view.t("account_table.trace"),
          view.t("account_table.best_before"),
          view.t("account_table.pallet_type"),
          view.t("account_table.capacity"),
          view.t("account_table.weight"),
          view.t("account_table.count")
        ]


        corrections.each do |row|
          table << [
            row["number"],
            row["batch"],
            row["name"],
            row["trace"],
            view.l(row["best_before"], :format => :special),
            view.correction_label(row, "pallet_type_name", " -- "),
            view.correction_label(row, "capacity", " -- "),
            view.correction_label(row, "weight", " -- ") { |w| view.number_with_precision w },
            view.correction_relative_count(row)
          ]
        end

        table.each do |row|
          csv << row
        end
      end
    end
  end

private

  def check_from_before_to
    errors[:to] = "må ikke være før Fra" if from.present? and from > to
  end

  def check_to_in_past
    errors[:to] = "må ikke være en fremtidig dato." if to.future?
  end

  def corrected
    pallet_ids = customer.pallets.select('pallets.id').joins(:pallet_corrections).where('pallet_corrections.created_at >= ? AND pallet_corrections.created_at < ?', from, to).all.map(&:id)
    return [] if pallet_ids.empty?

    res = Interval.connection.execute(<<-SQL
    SELECT
      pallets.number,
      pallets.batch,
      pallets.name,
      pallets.trace,
      pallets.best_before,

      COALESCE(corrections_from.capacity, pallets.original_capacity) AS capacity_from,
      COALESCE(corrections_from.pallet_type_id, pallets.original_pallet_type_id) AS pallet_type_id_from,
      COALESCE(corrections_from.weight, pallets.original_weight) AS weight_from,
      COALESCE(corrections_from.count, pallets.original_count) AS count_from,

      COALESCE(corrections_to.capacity, pallets.original_capacity) AS capacity_to,
      COALESCE(corrections_to.pallet_type_id, pallets.original_pallet_type_id) AS pallet_type_id_to,
      COALESCE(corrections_to.weight, pallets.original_weight) AS weight_to,
      COALESCE(corrections_to.count, pallets.original_count) AS count_to,

      pallets.id
    FROM pallets

    LEFT OUTER JOIN
      (SELECT pallet_id, count, capacity, pallet_type_id, weight, created_at FROM pallet_corrections NATURAL JOIN
      (SELECT pallet_id, MAX(created_at) AS created_at FROM pallet_corrections WHERE created_at < '#{from.to_s(:db)}' GROUP BY pallet_id) AS last_ones)
      AS corrections_from
    ON pallets.id = corrections_from.pallet_id

    LEFT OUTER JOIN
      (SELECT pallet_id, count, capacity, pallet_type_id, weight, created_at FROM pallet_corrections NATURAL JOIN
      (SELECT pallet_id, MAX(created_at) AS created_at FROM pallet_corrections WHERE created_at < '#{to.to_s(:db)}' GROUP BY pallet_id) AS last_ones)
      AS corrections_to
    ON pallets.id = corrections_to.pallet_id

    WHERE pallets.id IN (#{pallet_ids.join(", ")})

    GROUP BY pallets.id
    SQL
    )

    table = []
    res.each do |row|
      table << {
        'number'                => row[0],
        'batch'                 => row[1],
        'name'                  => row[2],
        'trace'                 => row[3],
        'best_before'           => row[4].to_date,

        'capacity_from'         => row[5].to_i,
        'pallet_type_name_from' => PalletType[row[6].to_i].name,
        'weight_from'           => row[7],
        'count_from'            => row[8].to_i,

        'capacity_to'           => row[9].to_i,
        'pallet_type_name_to'   => PalletType[row[10].to_i].name,
        'weight_to'             => row[11],
        'count_to'              => row[12].to_i
      }
    end
    table
  end

  def status(point)
    Interval.connection.execute(<<-SQL
    SELECT
      pallets.number,
      pallets.batch,
      pallets.name,
      pallets.trace,
      pallets.best_before,
      COALESCE(corrections.capacity, pallets.original_capacity) AS capacity,
      COALESCE(corrections.pallet_type_id, pallets.original_pallet_type_id) AS pallet_type_id,
      COALESCE(corrections.weight, pallets.original_weight) AS weight,

      COALESCE(corrections.count, pallets.original_count) AS count,
      SUM(reservations.count) AS taken,
      pallets.id
    FROM pallets

    LEFT OUTER JOIN
      (SELECT pallet_id, count, capacity, pallet_type_id, weight, created_at FROM pallet_corrections NATURAL JOIN
      (SELECT pallet_id, MAX(created_at) as created_at FROM pallet_corrections WHERE created_at < '#{point.to_s(:db)}' GROUP BY pallet_id) AS last_ones)
      AS corrections
    ON pallets.id = corrections.pallet_id

    LEFT OUTER JOIN reservations
    ON reservations.pallet_id = pallets.id AND (reservations.done_at < '#{point.to_s(:db)}')

    WHERE pallets.customer_id = '#{customer.id}'
      AND pallets.arrived_at < '#{point.to_s(:db)}'
      AND (pallets.deleted_at IS NULL OR pallets.deleted_at >= '#{point.to_s(:db)}')
    GROUP BY pallets.id
    SQL
    )
  end

  def incoming
    # paller er med i 'ind' hvis:
    #   de ikke er oprettet inden start_date (inklusiv) => oprettet efter start_date (eksklusiv)
    #   de er oprettet inden end_date (eksklusiv)
    Interval.connection.execute(<<-SQL
    SELECT
      pallets.number,
      pallets.batch,
      pallets.name,
      pallets.trace,
      pallets.best_before,
      COALESCE(corrections.capacity, pallets.original_capacity) AS capacity,
      COALESCE(corrections.pallet_type_id, pallets.original_pallet_type_id) AS pallet_type_id,
      COALESCE(corrections.weight, pallets.original_weight) AS weight,

      COALESCE(corrections.count, pallets.original_count) AS count,
      pallets.id
    FROM pallets

    LEFT OUTER JOIN
      (SELECT pallet_id, count, capacity, pallet_type_id, weight, created_at FROM pallet_corrections NATURAL JOIN
      (SELECT pallet_id, MAX(created_at) AS created_at FROM pallet_corrections WHERE created_at < '#{to.to_s(:db)}' GROUP BY pallet_id) AS last_ones)
      AS corrections
    ON pallets.id = corrections.pallet_id

    WHERE pallets.customer_id = '#{customer.id}'
      AND pallets.arrived_at >= '#{from.to_s(:db)}'
      AND pallets.arrived_at < '#{to.to_s(:db)}'

    GROUP BY pallets.id
    SQL
    )
  end

  def outgoing
    # paller er med i 'ud' hvis:
    #   de ikke er slettet inden start_date (inklusiv) => slettet efter start_date (eksklusiv)
    #   de er slettet inden end_date (eksklusiv)
    Interval.connection.execute(<<-SQL
      SELECT
        pallets.number,
        pallets.batch,
        pallets.name,
        pallets.trace,
        pallets.best_before,
        COALESCE(corrections.capacity, pallets.original_capacity) AS capacity,
        COALESCE(corrections.pallet_type_id, pallets.original_pallet_type_id) AS pallet_type_id,
        COALESCE(corrections.weight, pallets.original_weight) AS weight,

        reservations.count as reservation_count,
        pallets.id
      FROM
        reservations, pallets

      LEFT OUTER JOIN
        (SELECT pallet_id, capacity, pallet_type_id, weight, created_at FROM pallet_corrections NATURAL JOIN
        (SELECT pallet_id, MAX(created_at) as created_at FROM pallet_corrections WHERE created_at < '#{to.to_s(:db)}' GROUP BY pallet_id) AS last_ones)
        AS corrections
      ON pallets.id = corrections.pallet_id

      WHERE reservations.pallet_id = pallets.id
        AND pallets.customer_id = '#{customer.id}'
        AND reservations.done_at >= '#{from.to_s(:db)}'
        AND reservations.done_at < '#{to.to_s(:db)}'
    SQL
    )
  end

  def calculate_data
    table = {}

    # minimum pluk
    minimum = current_customer_arrangement && current_customer_arrangement.scrap_minimum || 1

    # calculate primo
    status(from).each do |row|
      hsh     = (table[row[0,8]] ||= Hash.new(0))
      w = row[7]
      c = row[8] - row[9].to_i # nil.to_i = 0
      # w = weight
      # c = count - taken

      hsh['primo_pallets'] += 1
      hsh['primo']         += c
      hsh['primo_weight']  += c * w
    end

    # calculate ultimo
    status(to).each do |row|
      hsh = (table[row[0,8]] ||= Hash.new(0))
      w = row[7]
      c = row[8] - row[9].to_i # nil.to_i = 0

      hsh['ultimo_pallets'] += 1
      hsh['ultimo']         += c
      hsh['ultimo_weight']  += c * w
    end

    # calculate incoming
    incoming.each do |row|
      hsh = (table[row[0,8]] ||= Hash.new(0))
      w = row[7].to_f
      o = row[8].to_i
      # o = count # ignore taken

      hsh['incoming_pallets'] += 1
      hsh['incoming']         += o
      hsh['incoming_weight']  += o * w
    end

    # calculating outgoing and scrap
    outgoing.each do |row|
      hsh = (table[row[0,8]] ||= Hash.new(0))

      m = row[5] # capacity
      c = row[8] # count # ignore taken
      w = row[7] # weight

      hsh['outgoing']        += c
      hsh['outgoing_weight'] += c * w

      unless m == c
        hsh['scrap']         += [c, minimum].max
        hsh['scrap_min']     += minimum - c if c < minimum
      end

    end

    return table.map { |k,v|
      v['number']           = k[0]
      v['batch']            = k[1]
      v['name']             = k[2]
      v['trace']            = k[3]
      v['best_before']      = k[4]
      v['capacity']         = k[5]
      v['pallet_type_name'] = PalletType[k[6].to_i].name
      v['weight']           = k[7]
      v
    }.sort_by { |e|
      "#{e['number']} #{e['batch']} #{e['name']} #{e['trace']} #{e['pallet_type_name']} #{e['capacity']} #{e['weight']*1000}"
    }
  end

  def calculate_sums
    table = []
    data.group_by { |d| d['pallet_type_name'] }.each_pair do |type, values|
      table << {
        'typename'         => type,

        'primo'            => values.sum { |v| v['primo_pallets'].to_i },
        'incoming'         => values.sum { |v| v['incoming_pallets'].to_i },
        'handling'         => values.sum { |v| v['incoming_pallets'].to_i },
        'scrap'            => values.sum { |v| v['scrap'].to_i },
        'scrap_min'        => values.sum { |v| v['scrap_min'].to_i },

        'primo_weight'     => values.sum { |v| v['primo'].to_i     * v['weight'] },
        'incoming_weight'  => values.sum { |v| v['incoming'].to_i  * v['weight'] },
        'handling_weight'  => values.sum { |v| v['incoming'].to_i  * v['weight'] },
        'scrap_weight'     => values.sum { |v| v['scrap'].to_i     * v['weight'] },
        'scrap_min_weight' => values.sum { |v| v['scrap_min'].to_i * v['weight'] }
      }
    end
    table
  end

end