$(document).ready ->
  t = $('#protein-table')
  t.floatThead({
    scrollContainer: (t) ->
      return t.closest('.table-container')
  })
