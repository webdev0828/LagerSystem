module ApplicationHelper

  def menu_item(name, path)
    link_to_unless_current(name, path, :class => "menu_link") do |name|
      link_to(name, path, :class => "menu_link current")
    end
  end

  def menu_item_switch(name, path, bool)
    link_to_unless(bool, name, path, :class => "menu_link") do |name|
      link_to(name, path, :class => "menu_link current")
    end
  end

  def sep(sign = '&middot;')
    " <span class=\"sep\">#{sign}</span> ".html_safe
  end

  def highlight(s)
    " <span class=\"highlight\">#{s}</span> ".html_safe
  end

  def date_with_words(date_or_time, strict=false)
    return if date_or_time.nil?
    date = date_or_time.to_date
    now = Date.today
    words = date == now ? "idag" : "#{distance_of_time_in_words(date, now)} #{date < now ? "siden" : "til"}"
    words = "<span class=\"highlight\">#{words}</span>" if strict and date <= now
    (l(date) + sep + words).html_safe
  end

  def form_errors(record)
    %Q{<div class="form-errors">#{record.errors.full_messages.join('<br>')}</div>}.html_safe if record.errors.any?
  end

end