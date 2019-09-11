$(document).on 'click', '.clickable', ->
  path = $(this).data('url')
  Turbolinks.visit(path)

$(document).on 'click', '.fn-print-shelf', ->
  url = $(this).closest('#storages').data('url')
  shelf = $(this).data('shelf')
  window.open(url + '?shelf=' + shelf, '_blank')
  false

$(document).on 'click', '.fn-pallet-note', ->
  if n = prompt('Hvor mange paller?')
    this.href = this.href.split('?')[0] + '?total=' + n
  else
    false