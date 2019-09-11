$(document).on 'click', '.fn-overlay-close', ->
  overlay.close()
  false

createElements = ->
  $ """<div id="overlay-back"><div id="overlay-box"></div></div>"""

current = false

# Positions the current box
sizeAndPosition = ->
  return unless current

  documentWidth  = $(document).width()
  documentHeight = $(document).height()

  scrollTop  = $(window).scrollTop()
  scrollLeft = $(window).scrollLeft()

  documentHeight = current.height if documentHeight < current.height
  documentWidth  = current.width  if documentWidth  < current.width

  scrollTop  = documentHeight - current.height if scrollTop  + current.height > documentHeight
  scrollLeft = documentWidth  - current.width  if scrollLeft + current.width  > documentWidth

  # ajust background to match the size of the full page
  current.$back.css
    width:  documentWidth
    height: documentHeight

  current.$box.css
    top:  scrollTop  + Math.max(0, Math.floor(($(window).height() - current.height) / 2))
    left: scrollLeft + Math.max(0, Math.floor(($(window).width()  - current.width ) / 2))
    height: current.height
    width:  current.width

  return

overlay =
  defaults:
    label: "overlay-default"
    width: 400
    height: null


  # Renders an overlay.
  # @param content html to be inserted into the box
  # @param options.width the with of the box
  # @param options.height the height of the box
  # @param options.label a classname to be attached to #overlay-back for styling purposes
  # @param options.space The minimum space around the visible box (should be the same as #overlay-box padding)
  show: (content, options) ->
    visible = current
    current = $.extend({}, overlay.defaults, options)

    if visible
      current.$back  = $back  = visible.$back
      current.$box   = $box   = visible.$box
    else
      current.$back  = $back  = createElements()
      current.$box   = $box   = $back.find("#overlay-box")

    if current.height is null
      current.height = 0
      current.autoheight = true

    # Sets size and position of the box element acording to options
    sizeAndPosition()

    # Label the root elements (for styling purposes)
    $back.attr "class", current.label

    # Add a class to body that disables the scroll (via css) while the box is visible
    $("body").addClass "overlay-active"

    # Remove old content (if any)
    $box.empty()
    $box.html content

    # Make sure is the last element in body and make it visible (if not allready)
    if not visible
      $back.css(visibility: "hidden").appendTo("body").show()

    if current.autoheight
      current.height = $inner[0].scrollHeight
      sizeAndPosition()

    $back.css visibility: "visible"

    if current.onReady
      current.onReady()

    return

  # Helper to reajust height
  # This should be called if content is changed
  autoHeight: ->
    if current
      current.height = 1
      sizeAndPosition()
      current.height = current.$inner[0].scrollHeight
      sizeAndPosition()
    return


  # Renders only the background with a loading cursor
  # This can only be removed by calling overlay.close()
  blocker: ->
    @show "",
      width: 0
      height: 0
      label: "overlay-blocker"

  loader: ->
    @blocker()

  # Closes the current overlay (if any)
  close: ->
    if current
      # Prevent close if modal is true and overlay is clicked
      $("body").removeClass "overlay-active"
      current.$back.remove()
      current = false
    return


# Recalculate position of the current box on resize
# Fix: There is a bug with resize being triggered constantly in IE8
# So we throttle and also only do resize if size actually changed
oldHeight = $(window).height()
oldWidth  = $(window).width()
$(window).resize $.throttle(250, ->
  return unless current
  newHeight = $(window).height()
  newWidth  = $(window).width()
  return if oldWidth is newWidth and oldHeight is newHeight
  oldHeight = newHeight
  oldWidth  = newWidth
  sizeAndPosition()
  return
)

# Export and return
window.overlay = overlay

