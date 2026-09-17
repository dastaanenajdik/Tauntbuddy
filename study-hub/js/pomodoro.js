const MODES = { focus: 25 * 60, short: 5 * 60, long: 15 * 60 };

export function createPomodoro({ onTick, onDone }) {
  let remain = MODES.focus;
  let mode = "focus";
  let running = false;
  let last = 0;
  let raf = 0;

  function loop(ts) {
    if (!running) return;
    if (!last) last = ts;
    const dt = Math.min(1, (ts - last) / 1000);
    last = ts;
    remain -= dt;
    if (remain <= 0) {
      remain = 0;
      running = false;
      onDone?.(mode);
    }
    onTick?.(remain, mode, running);
    if (running) raf = requestAnimationFrame(loop);
  }

  return {
    setMode(m) {
      mode = m;
      remain = MODES[m];
      running = false;
      last = 0;
      cancelAnimationFrame(raf);
      onTick?.(remain, mode, running);
    },
    start() {
      if (running) return;
      running = true;
      last = 0;
      raf = requestAnimationFrame(loop);
    },
    pause() {
      running = false;
      cancelAnimationFrame(raf);
      onTick?.(remain, mode, running);
    },
    reset() {
      remain = MODES[mode];
      running = false;
      last = 0;
      cancelAnimationFrame(raf);
      onTick?.(remain, mode, running);
    }
  };
}

export function fmt(sec) {
  const s = Math.max(0, Math.ceil(sec));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return String(m).padStart(2, "0") + ":" + String(r).padStart(2, "0");
}
