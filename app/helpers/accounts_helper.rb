module AccountsHelper

  def correction_label(o, prefix, sep='&rarr;', &block)
    if o["#{prefix}_from"] == o["#{prefix}_to"]
      o["#{prefix}_to"]
    else
      if block_given?
        "#{block.call(o["#{prefix}_from"])} #{sep} #{block.call(o["#{prefix}_to"])}".html_safe
      else
        "#{o["#{prefix}_from"]} #{sep} #{o["#{prefix}_to"]}".html_safe
      end
    end
  end

  def correction_relative_count(o)
    count_rel = o['count_to'] - o['count_from']
    count_rel > 0 ? "+#{count_rel}" : "#{count_rel}"
  end

end
