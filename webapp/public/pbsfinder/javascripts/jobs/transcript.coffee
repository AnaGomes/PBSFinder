$(document).ready ->
  # Draw chart.
  drawChart = ->
    values = JSON.parse($('#dataset').text())
    data = google.visualization.arrayToDataTable(values)
    options = {
      legend: 'none'
      colors: ['#428bca'],
      fontName: 'Ubuntu',
      chartArea: {
        left: 70,
        width: 970,
        top: 40
      },
      hAxis: {
        slantedText: true,
        slantedTextAngle: 45,
        maxAlternation: 0,
        showTextEvery: 1,
      },
      vAxis: {
        minValue:0
      }
    }
    chart = new google.visualization.ColumnChart(document.getElementById('protein-chart'))
    chart.draw(data, options)

  # Load chart.
  options = {packages: ['corechart'], callback : drawChart}
  google.load('visualization', '1', options)
