$(document).ready ->
  # ID toggles.
  $('.toggle-original').click ->
    $('.toggle-original').toggle()
    $('.toggle-converted').toggle()
    $('.original').toggle()
    $('.converted').toggle()
    return false
  $('.toggle-converted').click ->
    $('.toggle-original').toggle()
    $('.toggle-converted').toggle()
    $('.original').toggle()
    $('.converted').toggle()
    return false

  drawChart = ->
    values = JSON.parse($('#dataset').text())
    data = google.visualization.arrayToDataTable(values)
    if values.length > 1
      options = {
        legend: 'none'
        colors: ['#428bca'],
        fontName: 'Ubuntu',
        chartArea: {
          left: 70,
          width: 970,
          top: 40
        }
        hAxis: {
          slantedText: true,
          slantedTextAngle: 45,
          maxAlternation: 0,
          showTextEvery: 1,
        },
        vAxis: {
          minValue:0,
        }
      }
      chart = new google.visualization.ColumnChart(document.getElementById('protein-chart'))
      chart.draw(data, options)
    else
      $('.chart, .chart-name').hide()

  # Load chart.
  options = {packages: ['corechart'], callback : drawChart}
  google.load('visualization', '1', options)
