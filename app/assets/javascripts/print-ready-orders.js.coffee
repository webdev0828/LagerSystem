parseUrl = (url) ->
  a = document.createElement('a')
  a.href = url
  return a

generatePdfUrl = () ->
  selected = $('#print_ready .list-item.selected')

  order_ids = []
  orders = {}
  selected.each ->
    order_id = $(this).data('order-id')
    order_ids.push(order_id)
    orders[order_id] = this
    $(this).hide

  #http://localhost:3000/orders/all_order_pdfs.pdf?order_ids[]=110988&order_ids[]=140028
  link = parseUrl($("#pdf_generation_link").attr('href'))
  link = link.pathname
  order_ids_arr = []

  for order_id in order_ids
    order_id_str = 'order_ids[]='+order_id
    order_ids_arr.push(order_id_str)
  
  link = link.concat('?'+order_ids_arr.join("&"))
  $("#pdf_generation_link").attr('href', link)

$(document).ready ->
  generatePdfUrl()

$(document).on 'click', '#mark_all_ready_orders', ->
  $('#print_ready .list-item').addClass('selected')
  generatePdfUrl()

$(document).on 'click', '#unmark_all_ready_orders', ->
  $('#print_ready .list-item').removeClass('selected')

$(document).on 'click', '#print_ready .list-item', ->
  $(this).toggleClass('selected')
  generatePdfUrl()

$(document).on 'click', '#pdf_generation_link', (e) ->
  e.preventDefault()
  marked = $('#print_ready .list-item.selected')

  if marked.length == 0
    $.notify('Ingen ordre markeret')
    return

  $.ajax
    url: $(this).attr('href') # Grabs url from clicked element
    type: 'GET'

    success: (data, status) ->
      if status == 'success'
        
        blob = new Blob([ data ])
        link = document.createElement('a')
        link.href = window.URL.createObjectURL(blob)
        link.download = 'samlet_følgeseddel.pdf'
        link.click()
        marked.slideUp('fast')
        $.notify(marked.length + ' ' + (if marked.length == 1 then "ordre" else "ordrer") + ' afsluttet')
        # $.notify('Genindlæs venligst siden når PDF er genereret')
      else
        $.notify("Noget gik galt", type: 'alert')

    error: (xhr, status, error) ->
      $.notify(xhr.responseJSON.message, type: 'alert')

    complete: ->
      finishing_orders = false