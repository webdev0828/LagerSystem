module OrdersHelper

  def link_to_state(state, url, options = {})
    action = url.first
    order = url.last

    label = t("order_states.#{state}")

    confirm  = options.delete(:confirm)
    classes = Array(options.delete(:class))
    classes << 'current' if order.state.to_sym == state

    if order.may? action, current_user
      link_to label, url, method: :put, class: classes.join(' '), data: { confirm: confirm }
    else
      classes << 'disabled'
      content_tag :span, label, class: classes.join(' ')
    end
  end
end
