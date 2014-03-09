$(document).ready ->
  job = window.location.pathname.split('/').slice(-1)[0]
  setInterval(->
    $.post('/pbsfinder/jobs/completed', { id: job }, (data) ->
      data = $.parseJSON(data)
      if(data['result']) == true
        window.location.reload()
    )
  , 10000)
