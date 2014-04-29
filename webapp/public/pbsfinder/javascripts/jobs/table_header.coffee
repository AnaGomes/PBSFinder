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
    })

  # Page select change.
  $('#page-select').change((e) ->
    s = parseInt($(this).val())
    initFootable().trigger('footable_initialize')
  )

  unless isFootableNeeded()
    p = false
    $('div#pager-div #page-select').css('display', 'none')
    t.footable({
      paginate: false,
      previousText: "← Previous",
      firstText: "⇐ First",
      nextText: "Next →",
      lastText: "Last ⇒"
    })

  # Footable invocation.
  initFootable()
