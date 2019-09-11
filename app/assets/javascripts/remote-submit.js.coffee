$(document).on 'click', '.fn-remote-submit', ->

  $(this).addClass('loading')

  $.ajax
    dataType: 'script'
    url: $(this).data('url')
    data: $(this).closest('form').serialize()
  .fail ->
    $.notify("Der skete en ukendt fejl", {type:'alert'})
  .complete =>
    $(this).removeClass('loading')

  # stop event propagation
  false

