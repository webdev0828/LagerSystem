$ ->
  $(".sortable-list").each ->
    url = $(this).data('sortable-url')
    $(this).sortable(
      axis: 'y'
      handle: '.handle'
      update: (e, ui) ->
        $.ajax
          type: 'post'
          dataType: 'json'
          url: url
          data:
            item_id: ui.item.data('id')
            position: ui.item.index() + 1
    ).disableSelection()