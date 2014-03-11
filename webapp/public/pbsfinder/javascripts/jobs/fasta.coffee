$(document).ready ->

  # Reveal FASTA
  $('.fasta-show .btn').click ->
    $(this).parent().css('display', 'none')
    $(this).closest('.fasta-view').find('.fasta-hide').css('display', 'inline-block')
    body = $(this).closest(".trans-info .info").find('.fasta')
    h1 = body.height()
    body.css('display', 'block')
    body.css('height', 'auto')
    h2 = body.height()
    body.css('height', h1)
    body.stop().animate({height: h2}, 500, -> body.css('height', 'auto'))

  # Conceal FASTA
  $('.fasta-hide .btn').click ->
    $(this).parent().css('display', 'none')
    $(this).closest('.fasta-view').find('.fasta-show').css('display', 'inline-block')
    body = $(this).closest('.trans-info .info').find('.fasta')
    body.stop().animate({height: 0}, 500, -> 
      body.css('height', '0')
      body.css('display', 'none')
    )
