$(document).on 'change', '#arrangement_use_scrap_minimum', ->
  $("#arrangement_scrap_minimum_row").toggle($(@).is(":checked"))