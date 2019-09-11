window.ga or= ->
  console?.log?(arguments)
  return

# Track pageview when js loads the first time
do trackPageview = ->
  ga 'set', 'page', location.pathname
  ga 'send', 'pageview'

# Track pageview when turbolinks reloads a page
$(document).on 'page:load', trackPageview

# Track when a pallet is dropped in a grid (moved)
$(document).on 'drop', '.bulk_storage_grid,.placement', ( e, ui ) ->
  {storage,shelf} = $(e.target).closest('.storage_panel').data()
  ga 'send', 'event', 'drop', storage + ':' + shelf, ui.draggable.parent().data("position-id") + "->" + $(e.target).data("position-id")

# Track whenever the page is scrolled
$(window).on 'scroll', $.debounce 150, ->
  ga 'send', 'event', 'scroll', 'window scroll ended', Math.max(0, $(this).scrollTop())

# Track whenever a sortable list is updated
$(document).on 'sortupdate', (e, ui) ->
  type = ui.item.parent().attr 'id'
  ga 'send', 'event', 'sortupdate', type, ui.item.data('id') + " moved to index " + ui.item.index()

# Universal tracker
$(document).on 'click', '[data-track]', ->
  ga 'send', 'event', 'click', $(this).data('track')

# Track grid searches
$(document).on 'submit', '#search_grids', ->
  ga 'send', 'event', 'submit', 'searching grids'

# Track pagination
$(document).on 'click', '.pagination a', ->
  ga 'send', 'event', 'pagination', $(this).text()

$(document).on 'submit', '.fn-print-shelf-form', ->
  ga 'send', 'pageview', page: $(this).attr('action') + '?' + $(this).serialize()

$(document).on 'click', '.fn-track-pageviews a', ->
  ga 'send', 'pageview', page: $(this).attr 'href'