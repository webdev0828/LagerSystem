$(document).on 'input', '.autofill', $.debounce 500, ->
  $.getJSON 'autofill.js', { q: $(this).val() }, ( data ) ->
    $(selector).val(value) for selector, value of data
    return
  return