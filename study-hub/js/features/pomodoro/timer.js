// ---------------------------------------------------------------------------
// Pomodoro engine · app-wide singleton.
// Lives outside the router so the timer keeps running while you navigate.
// Wall-clock based (Date.now + 250 ms interval) — stays accurate even when
// the tab is throttled in the background. Subscribers re-render on every
// tick; nothing else in the app touches document timers.
// ---------------------------------------------------------------------------

import * as store from "../../store.js";

export const MODES = {
  focus: { seconds: 25 * 60, label: "Focus" },
  short: { seconds: 5 * 60, label: "Short break" },
  long: { seconds: 15 * 60, label: "Long break" }
};

let mode = "focus";
let remain = MODES.focus.seconds;
let running = false;
let rounds = 0;
let endAt = 0;
let intervalId = 0;

let context = {
  examId: null,
  subject: null,
  unit: null,
  chapter: null,
  taskId: null,
  topicKey: null,
  title: "Free focus",
  target: null
};

const subscribers = new Set();
const completionListeners = new Set();

function snapshot() {
  return {
    mode,
    modeLabel: MODES[mode].label,
    remain: Math.max(0, remain),
    running,
    rounds,
    context: { ...context },
    total: MODES[mode].seconds
  };
}

function emit() {
  const snap = snapshot();
  subscribers.forEach((fn) => fn(snap));
}

function tick() {
  if (!running) return;
  remain = (endAt - Date.now()) / 1000;
  if (remain <= 0) {
    remain = 0;
    running = false;
    clearInterval(intervalId);
    finish();
  }
  emit();
}

function finish() {
  if (mode === "focus") {
    rounds += 1;
    const auto = store.recordPomo({
      taskId: context.taskId,
      topicKey: context.topicKey,
      examId: context.examId,
      title: context.title,
      target: context.target,
      minutes: Math.round(MODES.focus.seconds / 60)
    });
    completionListeners.forEach((fn) => fn({ kind: "focus", autoCompleted: auto, context: { ...context }, rounds }));
    // Suggest the right next mode without auto-starting.
    mode = rounds % 4 === 0 ? "long" : "short";
    remain = MODES[mode].seconds;
  } else {
    completionListeners.forEach((fn) => fn({ kind: "break", context: { ...context }, rounds }));
    mode = "focus";
    remain = MODES.focus.seconds;
  }
}

export const timer = {
  subscribe(fn) {
    subscribers.add(fn);
    fn(snapshot());
    return () => subscribers.delete(fn);
  },
  onComplete(fn) {
    completionListeners.add(fn);
    return () => completionListeners.delete(fn);
  },
  setContext(next) {
    context = { ...context, ...next };
    emit();
  },
  setMode(nextMode) {
    if (!MODES[nextMode]) return;
    mode = nextMode;
    remain = MODES[nextMode].seconds;
    running = false;
    clearInterval(intervalId);
    emit();
  },
  start() {
    if (running || remain <= 0) return;
    running = true;
    endAt = Date.now() + remain * 1000;
    clearInterval(intervalId);
    intervalId = setInterval(tick, 250);
    emit();
  },
  pause() {
    if (!running) return;
    remain = (endAt - Date.now()) / 1000;
    running = false;
    clearInterval(intervalId);
    emit();
  },
  reset() {
    running = false;
    clearInterval(intervalId);
    remain = MODES[mode].seconds;
    emit();
  },
  snapshot
};

export function fmtClock(seconds) {
  const s = Math.max(0, Math.ceil(seconds));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${String(m).padStart(2, "0")}:${String(r).padStart(2, "0")}`;
}
