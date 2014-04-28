$(document).ready ->

  # Table definitions.
  s = 8
  t = $('#protein-table')
  p = true

  # Auxiliary methods.
  isFootableNeeded = () ->
    c = t.find('tr').size() - 1
    return c > s

  # Initialize footable table.
  initFootable = () ->
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
    initFootable().trigger('footable_initialize')
  )

  # Check pagination need.
  unless isFootableNeeded()
    p = false
    $('div#pager-div #page-select').css('display', 'none')

  # Footable invocation.
  initFootable()

  # TODO CHECK UPDATE POSSIBILITY
  # t.footable({pageSize: 500}).trigger('footable_initialize')
