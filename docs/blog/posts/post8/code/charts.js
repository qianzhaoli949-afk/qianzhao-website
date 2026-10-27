(function () {
  const selector = document.getElementById('sample-size');
  const config = {responsive: true, displaylogo: false};
  const mu = 50;
  const money = x => '$' + x.toFixed(2);
  const base = {paper_bgcolor: '#fff', plot_bgcolor: '#fff', margin: {l: 70, r: 25, t: 60, b: 65},
    font: {family: 'Arial, sans-serif'}, showlegend: false};
  function draw() {
    const s = window.simulations[selector.value];
    const ci = s.interval;
    const bootLayout = Object.assign({}, base, {
      title: 'Bootstrap means from one sample',
      xaxis: {title: 'Mean weekly spending ($)', automargin: true}, yaxis: {title: 'Number of resamples', automargin: true},
      shapes: ci.map(x => ({type:'line', x0:x, x1:x, y0:0, y1:1, yref:'paper', line:{color:'#ba643d', width:2, dash:'dash'}}))
    });
    Plotly.react('bootstrap-chart', [{type:'histogram', x:s.bootstrap, marker:{color:'#398681'}, nbinsx:30,
      hovertemplate:'Mean: %{x:.2f}<br>Resamples: %{y}<extra></extra>'}], bootLayout, config);
    document.getElementById('bootstrap-note').textContent = 'Sample mean: ' + money(s.sample_mean) +
      '. Dashed lines mark the 95% bootstrap interval: ' + money(ci[0]) + ' to ' + money(ci[1]) + '.';

    const traces = [true, false].map(hit => {
      const x = [], y = [];
      s.lower.forEach((lo, i) => {
        if ((lo <= mu && s.upper[i] >= mu) === hit) {
          x.push(lo, s.upper[i], null); y.push(i + 1, i + 1, null);
        }
      });
      return {type:'scatter', mode:'lines', x:x, y:y, name:hit ? 'Contains $50' : 'Misses $50',
        line:{color:hit ? '#398681' : '#c46b40', width:2}, hoverinfo:'skip'};
    });
    const coverageLayout = Object.assign({}, base, {title:'The first 100 of 1,000 simulated intervals', showlegend:true,
      legend:{orientation:'h', y:1.05}, xaxis:{title:'95% bootstrap interval for the mean ($)', automargin:true},
      yaxis:{title:'Simulation', automargin:true},
      shapes:[{type:'line', x0:mu,x1:mu,y0:0,y1:1,yref:'paper',line:{color:'#333',dash:'dash'}}]});
    Plotly.react('coverage-chart', traces, coverageLayout, config);
    document.getElementById('coverage-note').textContent = s.covered_count + ' of ' + s.repetitions +
      ' intervals contained the true mean of $50 (' + (100*s.coverage).toFixed(1) + '%). The chart displays the first 100.';

    const lower = mu - s.cutoff, upper = mu + s.cutoff;
    const middle = s.null_means.filter(x => x > lower && x < upper);
    const tails = s.null_means.filter(x => x <= lower || x >= upper);
    const nullLayout = Object.assign({}, base, {title:'Sample means when the null mean is $50', barmode:'overlay',
      xaxis:{title:'Simulated sample mean ($)', automargin:true}, yaxis:{title:'Number of simulations',automargin:true},
      shapes:[lower,upper].map(x => ({type:'line',x0:x,x1:x,y0:0,y1:1,yref:'paper',line:{color:'#ba643d',dash:'dash'}}))
        .concat([{type:'line',x0:s.sample_mean,x1:s.sample_mean,y0:0,y1:1,yref:'paper',line:{color:'#232d39',width:3}}])});
    // Identical bin sizes and origins keep the center and tails aligned.
    const bin = {start:Math.floor(Math.min(...s.null_means)),
      end:Math.ceil(Math.max(...s.null_means)), size:.25};
    Plotly.react('null-chart', [
      {type:'histogram', x:middle, xbins:bin, marker:{color:'#398681'}, hoverinfo:'skip'},
      {type:'histogram', x:tails, xbins:bin, marker:{color:'#c46b40'}, hoverinfo:'skip'}], nullLayout, config);
    document.getElementById('null-note').textContent = 'Observed mean: ' + money(s.sample_mean) +
      '; simulated two-sided p-value: ' + s.p_value.toFixed(3) + '. The dashed lines mark the simulated 5% rejection region; the solid line shows the observed mean.';
  }
  selector.addEventListener('change', draw);
  draw();
}());
