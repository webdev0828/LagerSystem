$ ->
  $(".reset-on-load").each -> @reset()
  $(".focus-on-load:first").focus().each -> this.select()