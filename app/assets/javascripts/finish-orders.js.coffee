$(document).on 'click', '#finish_orders .list-item', ->
  $(this).toggleClass('selected')

$(document).on 'click', '#mark_all_ready_orders', ->
  $('#finish_orders .list-item').addClass('selected')

$(document).on 'click', '#unmark_all_ready_orders', ->
  $('#finish_orders .list-item').removeClass('selected')

finishing_orders = false
$(document).on 'click', '#finish_marked_orders', ->
  return if finishing_orders
  return unless confirm "Er du sikker på at du vil afslutte de markerede ordre?\nDenne handling kan ikke fortrydes."

  selected = $('#finish_orders .list-item.selected')

  if selected.length == 0
    $.notify('Ingen ordre markeret')
    return

  finishing_orders = true

  # clean up
  selected.removeClass('selected')

  order_ids = []
  orders = {}
  selected.each ->
    order_id = $(this).data('order-id')
    order_ids.push(order_id)
    orders[order_id] = this

  # do request
  $.ajax
    url: $(this).data('url')
    type: 'put'
    data: { order_ids: order_ids }

    success: (data) ->
      if data.status
        finished = $($.map data.finished, (order_id) -> orders[order_id])
        finished.slideUp('fast')
        $.notify(finished.length + ' ' + (if finished.length == 1 then "order" else "ordre") + ' afsluttet')
      else
        $.notify('En eller flere ordre kunne ikke afsluttes', type: 'alert')

    error: ->
      $.notify('Der skete en ukendt fejl', type: 'alert')

    complete: ->
      finishing_orders = false