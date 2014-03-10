$(document).ready ->
  t = $('#protein-table')
  t.floatThead({
    scrollContainer: (t) ->
      return $('#protein-table-wrapper')
  })
