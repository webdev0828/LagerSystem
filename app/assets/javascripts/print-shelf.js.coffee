$(document).on 'click', '.fn-open-print-shelf-dialog', ->
  overlay.show $('#print-shelf-dialog').html(), width:510, height: 170, onReady: ->
    $('#shelf_select').focus()


$(document).on 'submit', '.fn-print-shelf-form', ->
  overlay.close()
  window.open $(this).attr('action') + '?' + $(this).serialize()
  false