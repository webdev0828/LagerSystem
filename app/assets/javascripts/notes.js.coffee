reset = ->
  $('#notes').find('.note').show()
  $('#notes').find('.note-form').hide()

showForm = ( form ) ->
  textarea = form.find('textarea')
  value = form.prev('.note').find('.content').text()
  textarea.val(value)
  form.show()
  textarea.focus()

$(document).on 'click', '.fn-note-new', ->
  reset()
  showForm $('#notes').find('.note-form-new')

$(document).on 'click', '.fn-note-cancel', ->
  reset()

$(document).on 'click', '.fn-note-edit', ->
  confirm_text = $('#notes').data('confirm-edit')
  return if confirm_text and not confirm(confirm_text)
  reset()
  note = $(this).closest('.note').hide()
  showForm note.next()