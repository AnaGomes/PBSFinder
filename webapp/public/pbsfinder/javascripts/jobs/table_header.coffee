$(document).ready ->

  # Table definitions.
  s = 8
  t = $('#protein-table')
  p = true
  c = t.find('tr').size() - 1

  # Auxiliary methods.
  isFootableNeeded = () ->
    return c > s

  # Initialize footable table.
  initFootable = () ->
    p = isFootableNeeded()
    unless p
      $('#pager-div ul').hide()
    else
      $('#pager-div ul').show()
    return t.footable({
      paginate: p,
      pageSize: s,
      limitNavigation: 5,
      previousText: "← Previous",
      firstText: "⇐ First",
      nextText: "Next →",
      lastText: "Last ⇒"
    })

  # Page select change.
  $('#page-select').change((e) ->
    s = parseInt($(this).val())
    initFootable().trigger('footable_redraw')
  )

  unless isFootableNeeded()
    p = false
    $('div#pager-div #page-select').css('display', 'none')

  # Footable invocation.
  initFootable()
