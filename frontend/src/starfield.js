/** 星空背景：闪烁、漂移、偶发流星；尊重 prefers-reduced-motion */
export function initStarfield(canvas) {
  if (!canvas) return;

  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const ctx = canvas.getContext('2d');
  let width = 0;
  let height = 0;
  let stars = [];
  let shooting = null;
  let lastShoot = 0;
  let frameId = 0;

  function resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    width = window.innerWidth;
    height = window.innerHeight;
    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function seedStars() {
    const count = reduced ? 140 : 300;
    stars = Array.from({ length: count }, () => ({
      x: Math.random() * width,
      y: Math.random() * height,
      r: Math.random() * 1.3 + 0.25,
      alpha: Math.random() * 0.45 + 0.25,
      phase: Math.random() * Math.PI * 2,
      twinkle: Math.random() * 0.025 + 0.008,
      vx: (Math.random() - 0.5) * (reduced ? 0 : 0.06),
      vy: (Math.random() - 0.5) * (reduced ? 0 : 0.04),
      tint:
        Math.random() > 0.88 ? 'cool' : Math.random() > 0.76 ? 'warm' : 'white',
    }));
  }

  function wrapStar(s) {
    if (s.x < 0) s.x += width;
    if (s.x > width) s.x -= width;
    if (s.y < 0) s.y += height;
    if (s.y > height) s.y -= height;
  }

  function spawnShootingStar(now) {
    if (reduced || shooting || now - lastShoot < 5000 || Math.random() > 0.003) {
      return;
    }
    lastShoot = now;
    shooting = {
      x: Math.random() * width * 0.7,
      y: Math.random() * height * 0.35,
      vx: 10 + Math.random() * 6,
      vy: 5 + Math.random() * 4,
      life: 1,
    };
  }

  function drawStar(s, t) {
    if (!reduced) {
      s.x += s.vx;
      s.y += s.vy;
      wrapStar(s);
      s.phase += s.twinkle;
    }
    const pulse = reduced ? 1 : 0.5 + 0.5 * Math.sin(s.phase + t * 0.4);
    const a = s.alpha * pulse;
    const radius = s.r * (reduced ? 1 : 0.8 + 0.2 * pulse);

    let fill = `rgba(255,255,255,${a})`;
    if (s.tint === 'cool') fill = `rgba(170,210,255,${a})`;
    if (s.tint === 'warm') fill = `rgba(255,210,230,${a})`;

    ctx.beginPath();
    ctx.arc(s.x, s.y, radius, 0, Math.PI * 2);
    ctx.fillStyle = fill;
    ctx.fill();

    if (!reduced && pulse > 0.85 && s.r > 1) {
      const glowA = a * 0.15;
      const glow =
        s.tint === 'cool'
          ? `rgba(170,210,255,${glowA})`
          : s.tint === 'warm'
            ? `rgba(255,210,230,${glowA})`
            : `rgba(255,255,255,${glowA})`;
      ctx.beginPath();
      ctx.arc(s.x, s.y, radius * 2.5, 0, Math.PI * 2);
      ctx.fillStyle = glow;
      ctx.fill();
    }
  }

  function drawShootingStar() {
    if (!shooting) return;
    const { x, y, vx, vy, life } = shooting;
    const len = 90 * life;
    const ex = x - vx * 3;
    const ey = y - vy * 3;
    const grad = ctx.createLinearGradient(x, y, ex, ey);
    grad.addColorStop(0, `rgba(255,255,255,${0.9 * life})`);
    grad.addColorStop(0.4, `rgba(200,230,255,${0.5 * life})`);
    grad.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.strokeStyle = grad;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(ex, ey);
    ctx.stroke();

    shooting.x += vx;
    shooting.y += vy;
    shooting.life -= 0.035;
    if (shooting.life <= 0) shooting = null;
  }

  function frame(now) {
    ctx.clearRect(0, 0, width, height);
    const t = now * 0.001;
    stars.forEach((s) => drawStar(s, t));
    drawShootingStar();
    spawnShootingStar(now);
    frameId = requestAnimationFrame(frame);
  }

  function onResize() {
    resize();
    seedStars();
    if (reduced) {
      ctx.clearRect(0, 0, width, height);
      stars.forEach((s) => drawStar(s, 0));
    }
  }

  onResize();
  window.addEventListener('resize', onResize);

  if (reduced) {
    return;
  }
  frameId = requestAnimationFrame(frame);

  return () => {
    cancelAnimationFrame(frameId);
    window.removeEventListener('resize', onResize);
  };
}
