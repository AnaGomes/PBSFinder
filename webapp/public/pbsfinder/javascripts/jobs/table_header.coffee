$(document).ready ->

  # Table definitions.
  s = 8
  t = $('#protein-table')
  c = t.find('tr').size() - 1
  show_popover = null

  # Auxiliary methods.
  isFootableNeeded = () ->
    return c > s

  # Initialize footable table.
  initFootable = () ->
    p = isFootableNeeded()
    if p
      $('#pager-div ul').show()
    else
      $('#pager-div ul').hide()
    return t.footable({
      paginate: true,
      pageSize: s,
      limitNavigation: 5,
      previousText: "← Previous",
      firstText: "⇐ First",
      nextText: "Next →",
      lastText: "Last ⇒"
    }).bind({'footable_sorting': (e) ->
      if(show_popover?)
        $(show_popover).popover('hide')
    })

  # Page select change.
  $('#page-select').change((e) ->
    s = parseInt($(this).val())
    initFootable().trigger('footable_initialize')
  )

  # Initialize popovers.
  for grp in [1..4] by 1
    for cls in [1..10] by 1
      cont = $('.grp' + grp + '.cls' + cls)
      if cont.length > 0
        $('.cluster-popover-' + grp + '.cluster-' + cls).popover({
          container:'body',
          placement: 'right',
          title: 'Cluster ' + cls,
          html: true,
          content: cont.html()
        }).on("show.bs.popover", ->
          $(this).data("bs.popover").tip().css(maxWidth: "600px")
          if(show_popover? && !$(show_popover).is($(this)))
            $(show_popover).popover('hide')
          show_popover = this
        )

  # Disable multiple popovers.
  $('html').on('click', (e) ->
    if(show_popover? && !$(show_popover).is($(e.target)))
      $(show_popover).popover('hide')
  )

  # Disable popovers on scroll.
  $('.table-container').scroll( ->
    if(show_popover?)
      $(show_popover).popover('hide')
  )

  # Enable header tooltips.
  $('.cluster-header').tooltip({placement: 'bottom', container: 'body'})

  unless isFootableNeeded()
    p = false
    $('div#pager-div #page-select').css('display', 'none')
    t.footable({
      paginate: false
    })
  else
    s = parseInt($('div#pager-div #page-select').val())
    initFootable()
