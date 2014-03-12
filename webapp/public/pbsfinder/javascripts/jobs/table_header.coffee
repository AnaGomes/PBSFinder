$(document).ready ->
  msieversion = () ->
    ua = window.navigator.userAgent
    msie = ua.indexOf ( "MSIE " )
    return msie

  if msieversion() < 0
    t = $('#protein-table')
    t.floatThead({
      scrollContainer: (t) ->
        return $('#protein-table-wrapper')
    })
