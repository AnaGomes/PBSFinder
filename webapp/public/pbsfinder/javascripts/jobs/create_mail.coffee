$(document).ready ->
  $('#mail-submit').click ->
    $('#mail-checkbox').val(true)
    $('#job-form').submit()
