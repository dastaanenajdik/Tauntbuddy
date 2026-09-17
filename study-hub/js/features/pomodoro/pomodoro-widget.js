// ---------------------------------------------------------------------------
// Pomodoro widget · reusable component bound to the singleton timer engine.
// Mounted by the Pomodoro page and embedded (compact) on course pages.
// mount() returns an unmount() cleanup — called by the router teardown.
// ---------------------------------------------------------------------------

import { timer, fmtClock } from "./timer.js";
import * as store from "../../store.js";
import { el, esc } from "../../ui.js";

export function mountPomodoro(container, { compact = false } = {}) {
  container.replaceChildren(
    el(`
    <div class="mini-pomo ${compact ? "compact" : ""}" data-widget>
      <div class="pomo-ctx" data-ctx></div>
      <div class="timer" data-clock>25:00</div>
      <div class="pomo-mode" data-modelabel>Focus</div>
      <div class="pomo-controls">
        <button class="btn gold" data-act="start" type="button">▶ Start</button>
        <button class="btn blank" data-act="pause" type="button">Pause</button>
        <button class="btn blank" data-act="reset" type="button">Reset</button>
      </div>
      ${compact ? "" : `
      <div class="pomo-modes" role="group" aria-label="Timer mode">
        <button class="btn blank small" data-act="mode" data-tmode="focus" type="button" aria-pressed="true">25 · Focus</button>
        <button class="btn blank small" data-act="mode" data-tmode="short" type="button" aria-pressed="false">5 · Break</button>
        <button class="btn blank small" data-act="mode" data-tmode="long" type="button" aria-pressed="false">15 · Long</button>
      </div>
      <div class="pomo-taskline" data-taskline></div>`}
    </div>
  `)
  );

  const clock = container.querySelector("[data-clock]");
  const modeLabel = container.querySelector("[data-modelabel]");
  const ctxLine = container.querySelector("[data-ctx]");
  const taskLine = container.querySelector("[data-taskline]");
  const startBtn = container.querySelector('[data-act="start"]');
  const modeBtns = [...container.querySelectorAll("[data-tmode]")];

  function ctxText(c) {
    if (c.chapter && c.subject) return `${c.subject} · ${c.chapter}`;
    if (c.title && c.title !== "Free focus") return c.title;
    return "Free focus — pick a chapter or task and deep-work it";
  }

  function renderTaskLine(c) {
    if (!taskLine) return;
    if (c.taskId && c.target) {
      const n = Math.min(store.pomoCount(c.taskId), c.target);
      taskLine.innerHTML = `Task: <strong>${esc(c.title)}</strong> · 🍅 ${n}/${c.target} focus blocks ${n >= c.target ? "· complete!" : ""}`;
    } else if (c.topicKey && c.target) {
      const n = store.pomoCount(c.topicKey);
      taskLine.innerHTML = `Chapter: <strong>${esc(c.title)}</strong> · 🍅 ${n} focus blocks logged`;
    } else {
      taskLine.innerHTML = `Rounds this run: <strong>${timer.snapshot().rounds}</strong>`;
    }
  }

  const unsubTimer = timer.subscribe((snap) => {
    clock.textContent = fmtClock(snap.remain);
    clock.classList.toggle("running", snap.running);
    modeLabel.textContent = snap.running ? snap.modeLabel : `${snap.modeLabel} · paused`;
    ctxLine.textContent = ctxText(snap.context);
    startBtn.disabled = snap.running;
    startBtn.textContent = snap.running ? "Focusing…" : "▶ Start";
    modeBtns.forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.tmode === snap.mode)));
    renderTaskLine(snap.context);
  });

  // Keep the taskline counter live when pomos complete elsewhere.
  const unsubStore = store.subscribe(() => renderTaskLine(timer.snapshot().context));

  // One delegated listener for every widget control.
  container.addEventListener("click", onClick);
  function onClick(e) {
    const btn = e.target.closest("[data-act]");
    if (!btn || !container.contains(btn)) return;
    const act = btn.dataset.act;
    if (act === "start") timer.start();
    else if (act === "pause") timer.pause();
    else if (act === "reset") timer.reset();
    else if (act === "mode") timer.setMode(btn.dataset.tmode);
  }

  return function unmount() {
    unsubTimer();
    unsubStore();
    container.removeEventListener("click", onClick);
  };
}
