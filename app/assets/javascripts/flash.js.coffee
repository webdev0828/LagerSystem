$ ->

  # Load flash messages
  # -------------------
  $("#notifications .flash.notice").notify rendered: true
  $("#notifications .flash.alert").notify rendered: true, sticky: true
