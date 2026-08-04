/**
 * CYBERPUNK // NOSTROMO TELEMETRY TERMINAL ENGINE
 * High-Performance 120 FPS Matrix Rain, Weather REST API, & ICE-Breaker Terminal
 */

(function () {
  'use strict';

  // ==========================================================================
  // 1. CLOCK & DATE ENGINE
  // ==========================================================================
  const clockEl = document.getElementById('clock-time');
  const dateEl = document.getElementById('clock-date');

  function updateClock() {
    const now = new Date();
    const hrs = String(now.getHours()).padStart(2, '0');
    const mins = String(now.getMinutes()).padStart(2, '0');
    const secs = String(now.getSeconds()).padStart(2, '0');
    if (clockEl) clockEl.textContent = `${hrs}:${mins}:${secs}`;

    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    if (dateEl) dateEl.textContent = `${year}-${month}-${day} // UTC-7`;
  }
  setInterval(updateClock, 1000);
  updateClock();

  // ==========================================================================
  // 2. MATRIX PHOSPHOR RAIN ENGINE (120 FPS rAF Canvas)
  // ==========================================================================
  const canvas = document.getElementById('matrix-canvas');
  const ctx = canvas.getContext('2d');

  let width = (canvas.width = window.innerWidth);
  let height = (canvas.height = window.innerHeight);

  window.addEventListener('resize', () => {
    width = canvas.width = window.innerWidth;
    height = canvas.height = window.innerHeight;
    initMatrixColumns();
  });

  const katakana = 'アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッン';
  const latin = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890x4F0x9A0x8E';
  const alphabet = katakana + latin;

  const fontSize = 16;
  let columns = Math.floor(width / fontSize);
  let drops = [];

  function initMatrixColumns() {
    columns = Math.floor(width / fontSize);
    drops = [];
    for (let i = 0; i < columns; i++) {
      drops[i] = {
        y: Math.random() * -100,
        speed: 1 + Math.random() * 2.5,
        isAmber: Math.random() < 0.15 // 15% Amber characters for cassette-futurist contrast
      };
    }
  }
  initMatrixColumns();

  function drawMatrix() {
    // Fade existing trail
    ctx.fillStyle = 'rgba(4, 6, 9, 0.08)';
    ctx.fillRect(0, 0, width, height);

    ctx.font = `${fontSize}px 'Share Tech Mono', monospace`;

    for (let i = 0; i < drops.length; i++) {
      const drop = drops[i];
      const char = alphabet.charAt(Math.floor(Math.random() * alphabet.length));
      const x = i * fontSize;
      const y = drop.y * fontSize;

      if (drop.isAmber) {
        ctx.fillStyle = '#ffb000';
        ctx.shadowColor = '#ffb000';
      } else {
        ctx.fillStyle = '#00ff66';
        ctx.shadowColor = '#00ff66';
      }
      ctx.shadowBlur = 4;

      ctx.fillText(char, x, y);

      if (y > height && Math.random() > 0.975) {
        drop.y = 0;
        drop.speed = 1 + Math.random() * 2.5;
      }
      drop.y += drop.speed;
    }
  }

  // ==========================================================================
  // 3. TACTICAL RADAR CANVAS ENGINE
  // ==========================================================================
  const radarCanvas = document.getElementById('radar-canvas');
  const rCtx = radarCanvas ? radarCanvas.getContext('2d') : null;
  let radarAngle = 0;

  function drawRadar() {
    if (!radarCanvas || !rCtx) return;
    const rW = (radarCanvas.width = radarCanvas.clientWidth);
    const rH = (radarCanvas.height = radarCanvas.clientHeight);
    const cx = rW / 2;
    const cy = rH / 2;
    const radius = Math.min(cx, cy) - 10;

    rCtx.clearRect(0, 0, rW, rH);

    // Draw Radar Circles
    rCtx.strokeStyle = 'rgba(0, 229, 255, 0.25)';
    rCtx.lineWidth = 1;
    rCtx.beginPath();
    rCtx.arc(cx, cy, radius * 0.4, 0, Math.PI * 2);
    rCtx.arc(cx, cy, radius * 0.75, 0, Math.PI * 2);
    rCtx.arc(cx, cy, radius, 0, Math.PI * 2);
    rCtx.stroke();

    // Crosshairs
    rCtx.beginPath();
    rCtx.moveTo(cx - radius, cy); rCtx.lineTo(cx + radius, cy);
    rCtx.moveTo(cx, cy - radius); rCtx.lineTo(cx, cy + radius);
    rCtx.stroke();

    // Rotating Sweep Line
    rCtx.save();
    rCtx.translate(cx, cy);
    rCtx.rotate(radarAngle);

    const grad = rCtx.createConicGradient(0, 0, 0);
    grad.addColorStop(0, 'rgba(0, 255, 102, 0.4)');
    grad.addColorStop(0.2, 'rgba(0, 255, 102, 0.0)');
    grad.addColorStop(1, 'rgba(0, 255, 102, 0.0)');

    rCtx.fillStyle = grad;
    rCtx.beginPath();
    rCtx.moveTo(0, 0);
    rCtx.arc(0, 0, radius, 0, Math.PI / 2);
    rCtx.fill();
    rCtx.restore();

    radarAngle += 0.03;
  }

  // Master 120 FPS rAF Animation Engine Loop
  function animationLoop() {
    drawMatrix();
    drawRadar();
    requestAnimationFrame(animationLoop);
  }
  requestAnimationFrame(animationLoop);

  // ==========================================================================
  // 4. SYSTEM METRICS & SPARKLINE ENGINE
  // ==========================================================================
  const cpuFill = document.getElementById('gauge-cpu-fill');
  const ramFill = document.getElementById('gauge-ram-fill');
  const batFill = document.getElementById('gauge-bat-fill');
  const cpuVal = document.getElementById('cpu-val');
  const ramVal = document.getElementById('gauge-ram-fill'); // Fixed ref below
  const sparklineBars = document.getElementById('sparkline-bars');

  // Initialize Sparkline columns
  if (sparklineBars) {
    for (let i = 0; i < 24; i++) {
      const bar = document.createElement('div');
      bar.className = 'sparkline-col';
      bar.style.height = `${20 + Math.random() * 70}%`;
      sparklineBars.appendChild(bar);
    }
  }

  function updateGauge(fillEl, percent) {
    if (!fillEl) return;
    const maxOffset = 251.2;
    const offset = maxOffset - (maxOffset * (percent / 100));
    fillEl.style.strokeDashoffset = offset;
  }

  function simulateSystemMetrics() {
    const cpu = Math.floor(25 + Math.random() * 40);
    const ram = Math.floor(55 + Math.random() * 15);
    const bat = 98;

    updateGauge(cpuFill, cpu);
    updateGauge(ramFill, ram);
    updateGauge(batFill, bat);

    if (cpuVal) cpuVal.textContent = `${cpu}%`;
    const ramValEl = document.getElementById('ram-val');
    if (ramValEl) ramValEl.textContent = `${ram}%`;

    // Shift sparkline
    if (sparklineBars && sparklineBars.children.length > 0) {
      const bars = sparklineBars.children;
      for (let i = 0; i < bars.length - 1; i++) {
        bars[i].style.height = bars[i + 1].style.height;
      }
      bars[bars.length - 1].style.height = `${15 + Math.random() * 80}%`;
    }
  }
  setInterval(simulateSystemMetrics, 2000);
  simulateSystemMetrics();

  // macOS Host WKScriptMessageHandler Bridge Endpoint
  window.updateHostMetrics = function (metrics) {
    if (metrics.cpu !== undefined) updateGauge(cpuFill, metrics.cpu);
    if (metrics.ram !== undefined) updateGauge(ramFill, metrics.ram);
    if (metrics.bat !== undefined) updateGauge(batFill, metrics.bat);
  };

  // ==========================================================================
  // 5. PHOENIX ENVIRONMENT PANEL (OPEN-METEO REST API & NETWORK FALLBACK)
  // ==========================================================================
  const envContent = document.getElementById('env-content');
  const envFallback = document.getElementById('env-fallback');
  const envTemp = document.getElementById('env-temp');
  const envCond = document.getElementById('env-condition');
  const envAqi = document.getElementById('env-aqi');
  const envHum = document.getElementById('env-humidity');
  const envWind = document.getElementById('env-wind');
  const fallbackBar = document.getElementById('fallback-bar');
  const retryTimer = document.getElementById('retry-timer');

  const WEATHER_CODES = {
    0: 'CLEAR SKY // OPTICAL SUN',
    1: 'MAINLY CLEAR',
    2: 'PARTLY CLOUDY',
    3: 'OVERCAST // HIGH STRATUS',
    45: 'CYBER FOG // HAZE',
    48: 'DEPOSITING FOG',
    51: 'LIGHT DRIZZLE',
    61: 'SLIGHT RAIN',
    71: 'SNOW FLURRY',
    95: 'THUNDERSTORM // IONIC DISCHARGE'
  };

  async function fetchPhoenixWeather() {
    if (!navigator.onLine) {
      showEnvFallback();
      return;
    }

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);

      // Fetch Weather & AQI concurrently
      const [weatherRes, aqiRes] = await Promise.all([
        fetch(
          'https://api.open-meteo.com/v1/forecast?latitude=33.4484&longitude=-112.0740&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
          { signal: controller.signal }
        ),
        fetch(
          'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=33.4484&longitude=-112.0740&current=us_aqi',
          { signal: controller.signal }
        )
      ]);

      clearTimeout(timeoutId);

      if (!weatherRes.ok) throw new Error('Weather API Error');
      const weatherData = await weatherRes.json();
      const current = weatherData.current;

      let aqiVal = 38; // Default nominal AQI fallback if API endpoint varies
      if (aqiRes.ok) {
        const aqiData = await aqiRes.json();
        if (aqiData.current && aqiData.current.us_aqi) {
          aqiVal = Math.round(aqiData.current.us_aqi);
        }
      }

      // Update UI
      if (envTemp) envTemp.textContent = `${Math.round(current.temperature_2m)}°C`;
      if (envCond) envCond.textContent = WEATHER_CODES[current.weather_code] || 'ATMOSPHERIC STABLE';
      if (envHum) envHum.textContent = `${current.relative_humidity_2m}%`;
      if (envWind) envWind.textContent = `${current.wind_speed_10m} KM/H`;

      if (envAqi) {
        envAqi.textContent = `${aqiVal} (GOOD)`;
        envAqi.className = 'stat-val ' + (aqiVal <= 50 ? 'aqi-good' : aqiVal <= 100 ? 'aqi-moderate' : 'aqi-unhealthy');
      }

      // Hide fallback, reveal content
      if (envContent) envContent.style.display = 'block';
      if (envFallback) envFallback.classList.add('hidden');

    } catch (err) {
      console.warn('Weather Telemetry fetch failed:', err);
      showEnvFallback();
    }
  }

  let retryCount = 10;
  let retryInterval = null;

  function showEnvFallback() {
    if (envContent) envContent.style.display = 'none';
    if (envFallback) envFallback.classList.remove('hidden');

    retryCount = 10;
    if (retryTimer) retryTimer.textContent = retryCount;
    if (fallbackBar) fallbackBar.style.width = '0%';

    clearInterval(retryInterval);
    retryInterval = setInterval(() => {
      retryCount--;
      if (retryTimer) retryTimer.textContent = retryCount;
      if (fallbackBar) fallbackBar.style.width = `${((10 - retryCount) / 10) * 100}%`;

      if (retryCount <= 0) {
        clearInterval(retryInterval);
        fetchPhoenixWeather();
      }
    }, 1000);
  }

  // Poll environment data every 5 minutes
  setInterval(fetchPhoenixWeather, 300000);
  fetchPhoenixWeather();

  window.addEventListener('online', fetchPhoenixWeather);
  window.addEventListener('offline', showEnvFallback);

  // ==========================================================================
  // 6. DIAGNOSTIC TERMINAL LOG ENGINE (NEUROMANCER ICE-BREAKER)
  // ==========================================================================
  const terminalLogs = document.getElementById('terminal-logs');

  const LOG_TEMPLATES = [
    { type: 'sys', text: 'KUANG-DENG 0.9 // INITIATING NEURAL MATRIX LINK...' },
    { type: 'normal', text: 'BYPASSING CHIBA CITY BACKBONE FIREWALL [GATE 0x8F4A]' },
    { type: 'warn', text: 'ICE DETECTED: BLACK ICE DEFENSE PROTOCOL ACTIVE' },
    { type: 'normal', text: 'DEPLOYING SHIVA DISSOLUTION NODES (0x99F...0x41C)' },
    { type: 'sys', text: 'DECRYPTING SATELLITE TELEMETRY PACKETS... 100% MATCH' },
    { type: 'alert', text: 'CYBER-DEFENSE PULSE NEUTRALIZED. RETAINING ZERO-TRACE.' },
    { type: 'normal', text: 'HOST MEMORY ALLOCATION: 0x00FF8800 [BUFFER STABLE]' },
    { type: 'sys', text: 'OPEN-METEO TELEMETRY SYNCED // PHOENIX NODES RESPONDING' },
    { type: 'warn', text: 'PROMOTION 120Hz V-SYNC SYNCED // RENDER LATENCY 0.8ms' }
  ];

  function addLogLine() {
    if (!terminalLogs) return;

    const t = new Date();
    const timeStr = `[${String(t.getHours()).padStart(2, '0')}:${String(t.getMinutes()).padStart(2, '0')}:${String(t.getSeconds()).padStart(2, '0')}.${Math.floor(t.getMilliseconds() / 100)}]`;

    const item = LOG_TEMPLATES[Math.floor(Math.random() * LOG_TEMPLATES.length)];
    const div = document.createElement('div');
    div.className = 'log-line';

    let classType = '';
    if (item.type === 'warn') classType = 'log-warn';
    else if (item.type === 'alert') classType = 'log-alert';
    else if (item.type === 'sys') classType = 'log-sys';

    div.innerHTML = `<span class="log-time">${timeStr}</span><span class="${classType}">${item.text}</span>`;
    terminalLogs.appendChild(div);

    // Keep log buffer manageable
    while (terminalLogs.children.length > 25) {
      terminalLogs.removeChild(terminalLogs.firstChild);
    }

    terminalLogs.scrollTop = terminalLogs.scrollHeight;
  }

  setInterval(addLogLine, 2200);
  for (let i = 0; i < 6; i++) addLogLine();

})();
