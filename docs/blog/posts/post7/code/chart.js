(function () {
  const data = window.countyData;
  const graph = document.getElementById('county-chart');
  const measure = document.getElementById('measure');
  const county = document.getElementById('county');
  data.forEach(d => county.add(new Option(d.county, d.GEOID)));

  function draw() {
    const percent = measure.value === 'percent';
    const selected = county.value;
    const traces = ['Gain', 'Loss'].map(group => {
      const rows = data.filter(d => (d.change >= 0 ? 'Gain' : 'Loss') === group);
      return {
        type: 'scatter', mode: 'markers', name: group,
        x: rows.map(d => d.base2020),
        y: rows.map(d => percent ? d.change_pct : d.change),
        customdata: rows.map(d => [d.county, d.base2020, d.population2024, d.change, d.change_pct]),
        marker: {color: group === 'Gain' ? '#267d78' : '#c76f43',
          size: rows.map(d => selected === d.GEOID ? 15 : 9),
          opacity: rows.map(d => !selected || selected === d.GEOID ? 0.9 : 0.25),
          line: {color: '#ffffff', width: 1}},
        hovertemplate: '<b>%{customdata[0]} County</b><br>2020 base: %{customdata[1]:,}' +
          '<br>2024 population: %{customdata[2]:,}<br>Change: %{customdata[3]:+,}' +
          '<br>Change: %{customdata[4]:+.2f}%<extra></extra>'
      };
    });
    Plotly.react(graph, traces, {
      title: {text: 'Pennsylvania county population change, 2020–2024', font: {size: 17}},
      xaxis: {title: '2020 population base (log scale)', type: 'log', tickformat: '~s', automargin: true},
      yaxis: {title: percent ? 'Population change (%)' : 'Population change (people)',
        zeroline: true, zerolinecolor: '#666', automargin: true},
      legend: {orientation: 'h', y: 1.04},
      margin: {l: 80, r: 25, t: 90, b: 75},
      hovermode: 'closest', paper_bgcolor: '#ffffff', plot_bgcolor: '#ffffff'
    }, {responsive: true, displaylogo: false});
  }
  measure.addEventListener('change', draw);
  county.addEventListener('change', draw);
  draw();
}());
