# Selected pallets (via anchor)
$.highlight = (palletIds) ->
  if palletIds is `undefined`
    window.location.hash = null
  else unless $.isArray(palletIds)
    return
  else
    window.location.hash = palletIds.join(",")
    $.highlight.handle palletIds
  return

$.extend $.highlight,
  init: ->
    @handle (window.location.hash or "#").substr(1).split(",")
    return

  handle: (palletIds) ->
    $('.storage_grid .pallet.selected').removeClass('selected')
    if palletIds.length
      $('#pallet_' + palletIds.join(',#pallet_')).addClass('selected')

$(document).on 'click', '.reset-grid-search', ->
  $.highlight []
  $("#search_grids").find("input[type=text]").val ""
  $("#show_pallet").empty()
  false

$(document).on 'mouseenter', '.organized_storage_grid .placement', updateCursorPosition = ->
  pos = $(this).closest('.storage_panel').find('.cursor_position')
  pos.find(".column").text $(this).data("column")
  pos.find(".floor").text $(this).data("floor")
  pos.show()

$(document).on 'mouseleave', '.organized_storage_grid', ->
  $(this).closest('.storage_panel').find('.cursor_position').hide()

$(document).on 'dblclick', '.storage_grid .pallet', ->
  $.ajax
    url: $(this).closest('#graphic-storage-panels').data('info-url')
    dataType: "script"
    data:
      pallet: $(this).data("pallet-id")
    error: ->
      $.notify "some error with pallet info", type: "alert"



selections = []
clicked = 0

$(document).on 'click', '.switch_button', ->
  clicked = $('.switch_button').index(this)

  # read current setting
  $('.storage_panel').each (i) ->
    selections[i] =
      storage: $(this).data('storage')
      shelf: $(this).data('shelf')

  overlay.show $('#change-graphic-storage-dialog').html(), width: 510, height:230, onReady: ->
    storage_select = $('#storage_select').focus()
    storage_select.val selections[clicked].storage if selections[clicked].storage
    storage_select.change()

$(document).on 'submit', '.fn-change-storage', ->
  url = $('#graphic-storage-panels').data('graphic-url')

  selections[clicked] =
    storage: $(this).find('#storage_select').val()
    shelf: $(this).find('#shelf_select:visible').val()

  for s in selections
    if s.storage
      url += "/" + s.storage
      url += ":" + s.shelf if s.shelf

  url += location.hash if location.hash

  # Dont use turbolinks.. We need to refresh the page
  location.href = url
  false

$(document).on 'change', '#storage_select', ->
  shelf_select = $('#shelf_select')
  shelf_row    = $('#shelf_row')
  shelf_row.hide()
  max = parseInt($(this).find("option:selected").attr("rel"))
  if max
    shelf_select.empty()
    shelf_select.append "<option value='#{s}'>#{s}</option>" for s in [1..max]
    shelf_select.val selections[clicked].shelf if $(this).val() is "" + selections[clicked].storage
    shelf_row.show()

  return


$ ->
  # The following is only executed on load while in graphic view
  return unless $('#graphic-storage-panels').length


  # make sure we cannot select anything in the drag and drop areas
  $('.storage_panel').disableSelection()


  # remove all highlighting
  $.highlight.init()


  # make pallets draggable
  $(".storage_grid .pallet").draggable
    revert: "invalid"
    revertDuration: 200
    scope: "pallets"
    addClasses: false
    start: (_, ui) ->
      $(ui.helper).css "zIndex", 4000


  # make bulk storage droppable
  $(".bulk_storage_grid").droppable
    scope: "pallets"
    hoverClass: "bulk_accepts"
    addClasses: false

    accept: (draggable) ->
      draggable and draggable.parent().get(0) isnt this

    drop: (_, ui) ->
      target = $(this)
      $.ajax
        url: $(this).closest('#graphic-storage-panels').data('move-url')
        type: "POST"
        data:
          posid: ui.draggable.parent().data("position-id")
          postype: ui.draggable.parent().data("position-type")
          pallet: ui.draggable.data("pallet-id")
          storage: $(this).data("position-id")

        success: (data) ->
          if data.status
            ui.draggable.appendTo(target).css top: 0, left: 0
            rows = Math.ceil(target.children(".pallet").length / 30.0) + 1
            target.css "height", Math.max(rows, 5) * 26 + 1
          else
            $(ui.draggable).animate { top: 0, left: 0 }, 200
            $.notify data.reason  if data.reason
            location.reload() if data.reload
          return

        error: ->
          $(ui.draggable).animate { top: 0, left: 0 }, 200
          $.notify "some server error", type: "alert"

        complete: ->
          $(ui.helper).css "zIndex", null


  # make placements droppable
  $(".organized_storage_grid").each ->
    storage_grid = $(this)
    storage_grid.find('.placement').droppable
      over: updateCursorPosition
      addClasses: false
      scope: "pallets"
      hoverClass: "placement_accepts"

      accept: ->
        $(this).children().size() is 0

      drop: (_, ui) ->

        overlay.loader()
        target = $(this)
        $.ajax
          url: $(this).closest('#graphic-storage-panels').data('move-url')
          type: "POST"
          dataType: "json"

          # inform server of pallet position change
          # revert if feedback says problem.
          # send a timestamp and receive the latest changes
          # if changes are more than just something removed from lobby, change
          data:
            pallet:    ui.draggable.data("pallet-id")
            posid:     ui.draggable.parent().data("position-id")
            postype:   ui.draggable.parent().data("position-type")
            storage:   storage_grid.data("storage")
            shelf:     storage_grid.data("shelf")
            column:    $(this).data("column")
            floor:     $(this).data("floor")
            placement: $(this).data("placement-id")

          success: (data) ->
            if data.status
              ui.draggable.appendTo(target).css { top: 0, left: 0 }
            else
              ui.draggable.animate { top: 0, left: 0 }, 200
              $.notify data.reason if data.reason
              location.reload() if data.reload

          error: ->
            $.notify "some server error", type: "alert"

          complete: ->
            overlay.close()
            $(ui.helper).css "zIndex", "auto"