updateSelectedTotal = ->
  total = 0

  $("#search_result .list-item.selected").each ->
    total += $(this).data("count")
    return

  $("#search_result .list-item.partially-selected").each ->
    total += $(this).data("scrap-count")
    return

  $("#selection_info strong").text(total)
  return


# Toggle selection of a search result item
$(document).on 'click', '#search_result .list-item', ->
  item = $(this)
  if item.hasClass('partially-selected')
    item.removeClass 'partially-selected'
    item.find('.pluk').html 'Pluk'
  else if item.hasClass('selected')
    item.removeClass 'selected'
  else
    item.addClass 'selected'
  updateSelectedTotal()
  false


# Add partial selection of a search result item
$(document).on "click", "#search_result .pluk", ->
  button = $(this)
  item = $(this).closest('.list-item');
  maxCount = item.data('count')

  scrap = parseInt prompt 'Pluk fra palle (max: ' + maxCount + ')'

  if isNaN(scrap) or scrap <= 0
    $.notify "Pluk er ikke et positivt tal.", type: "alert"

  else if scrap > item.data("count")
    $.notify "Pluk overstiger antallet af resterende kartoner.", type: "alert"

  else if scrap is item.data("count")
    item.removeClass("partially-selected").addClass "selected"
    button.html "Pluk"
    $.notify "Pluk svarer til antallet af resterende kartoner, så pallen er automatisk valgt."
    updateSelectedTotal()

  else
    item.removeClass("selected").addClass "partially-selected"
    item.data "scrap-count", scrap
    button.html "Pluk: " + scrap
    updateSelectedTotal()

  false

# Reserve selected search result items
$(document).on "click", "#add_to_order", ->

  button = $(this)
  reservations = {}
  count = 0

  $("#search_result .list-item.selected").each ->
    count += reservations[$(this).data("pallet-id")] = $(this).data("count")
    return

  $("#search_result .list-item.partially-selected").each ->
    count += reservations[$(this).data("pallet-id")] = $(this).data("scrap-count")
    return

  if count is 0
    $.notify "Der er ikke valgt nogle elementer", type: "alert"

  else
    $.ajax
      url: button.data('reserve')
      type: "put"
      dataType: "json"
      data:
        reservations: reservations

      success: (data) ->
        if data.status
          Turbolinks.visit button.data('url')
        else
          $.notify "Der skete en ukendt fejl. Prøv igen eller kontakt en administrator.", type: "alert"

        return

      error: (xhr, msg) ->
        $.notify "Der skete en ukendt fejl. Prøv igen eller kontakt en administrator.", type: "alert"

        return

  false