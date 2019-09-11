$(document).on 'click', '.fn-toggle-deactivated-customers', ->
  button = $(this)
  target = $(button.data('selector'))
  show   = target.hasClass('hide-deactivated')
  target.toggleClass('hide-deactivated', not show)
  button.text(button.data(if show then 'on' else 'off'))