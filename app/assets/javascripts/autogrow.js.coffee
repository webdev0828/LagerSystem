getShadow = (textarea) ->
  shadow = $(textarea).data('shadow')
  unless shadow
    shadow = $("<div>").css({
      whiteSpace: 'pre-wrap',
      wordWrap:		'break-word',
      width:			$(textarea).css('width'),
      fontSize:		$(textarea).css('font-size'),
      lineHeight: $(textarea).css('line-height'),
      fontFamily: $(textarea).css('font-family')
    }).appendTo('body');
    $(textarea).data('shadow', shadow)
  shadow

$(document).on 'focus blur keyup', 'textarea.autogrow', ->
  shadow = getShadow(this)
  shadow.text $(this).val() + "\n "
  height = shadow.height()
  $(this).stop().animate({ height: height }, 'fast') unless height == $(this).height()
