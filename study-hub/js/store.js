// ---------------------------------------------------------------------------
// Reactive store · persisted to localStorage, emits "tb:state" CustomEvents.
// Views subscribe once and update the DOM in place (no full re-renders).
// ---------------------------------------------------------------------------

export const KEY = "tauntbuddy-study-v3";
const LEGACY_KEY = "tauntbuddy-study-v2";
export const EVENT = "tb:state";

const defaults = () => ({
  done: {},        // syllabus chapter completion   key: exam|subject|unit|chapter
  planDone: {},    // planner task completion       key: p|exam|day|i
  pomoCounts: {},  // pomodoros logged per task-key or topic-key
  pomos: [],       // session log (newest last)
  lastExam: "jee"
});

const hasStorage = typeof localStorage !== "undefined";

let state = loadInitial();

function loadInitial() {
  let saved = {};
  if (!hasStorage) return defaults(); // Node/headless test runs
  try { saved = JSON.parse(localStorage.getItem(KEY) || "{}"); } catch { saved = {}; }
  // Migrate the v2 state (same topic-key shape) so nobody loses progress.
  try {
    const legacy = JSON.parse(localStorage.getItem(LEGACY_KEY) || "null");
    if (legacy && !localStorage.getItem(KEY)) {
      saved = {
        done: legacy.done || {},
        pomos: legacy.pomos || [],
        lastExam: legacy.lastExam || "jee"
      };
      localStorage.removeItem(LEGACY_KEY);
    }
  } catch { /* ignore legacy parse errors */ }
  const s = { ...defaults(), ...saved };
  return s;
}

export function getState() {
  return state;
}

export function persist() {
  if (!hasStorage) return;
  try { localStorage.setItem(KEY, JSON.stringify(state)); } catch { /* storage full/blocked */ }
}

export function notify(detail = { type: "change" }) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(EVENT, { detail }));
}

export function subscribe(fn) {
  if (typeof window === "undefined") return () => {};
  const h = (e) => fn(e.detail || {});
  window.addEventListener(EVENT, h);
  return () => window.removeEventListener(EVENT, h);
}

/* --- topic / syllabus helpers ----------------------------------------------- */

export function topicKey(examId, subject, unit, chapter) {
  return [examId, subject, unit, chapter].join("|");
}

export function isTopicDone(key) {
  return !!state.done[key];
}

export function setTopicDone(key, val, { silent = false } = {}) {
  state.done[key] = !!val;
  persist();
  if (!silent) notify({ type: "topic", key });
}

export function toggleTopic(key) {
  setTopicDone(key, !state.done[key]);
  return state.done[key];
}

/* --- planner task helpers ----------------------------------------------------- */

export function isTaskDone(id) {
  return !!state.planDone[id];
}

export function toggleTask(id, topicLinkedKey = null) {
  state.planDone[id] = !state.planDone[id];
  if (topicLinkedKey) state.done[topicLinkedKey] = state.planDone[id];
  persist();
  notify({ type: "task", id });
  return state.planDone[id];
}

export function pomoCount(key) {
  return state.pomoCounts[key] || 0;
}

/**
 * Log a finished focus block. If it reaches the task's target, the task (and
 * its linked syllabus chapter) auto-completes — completion states update
 * dynamically across the planner, course page and progress bars.
 */
export function recordPomo({ taskId = null, topicKey: topic = null, examId = null, title = "Focus session", target = null, minutes = 25 }) {
  state.pomos.push({ at: Date.now(), title, examId, taskId, topicKey: topic, minutes });
  if (state.pomos.length > 600) state.pomos = state.pomos.slice(-600);

  const autoCompleted = [];
  const bump = (key, tgt, markDone) => {
    state.pomoCounts[key] = (state.pomoCounts[key] || 0) + 1;
    if (tgt && state.pomoCounts[key] >= tgt && markDone && !markDone.check()) {
      markDone.set();
      autoCompleted.push(title);
    }
  };

  if (taskId) {
    bump(taskId, target, {
      check: () => !!state.planDone[taskId],
      set: () => {
        state.planDone[taskId] = true;
        if (topic) state.done[topic] = true;
      }
    });
  } else if (topic) {
    bump(topic, target, null);
  }

  persist();
  notify({ type: "pomo", taskId, topicKey: topic, autoCompleted });
  return autoCompleted;
}

/* --- derived selectors -------------------------------------------------------- */

export function examProgress(flatTopics, examId) {
  let done = 0;
  for (const t of flatTopics) {
    if (state.done[topicKey(examId, t.subject, t.unit, t.chapter)]) done++;
  }
  const total = flatTopics.length;
  return { done, total, pct: total ? Math.round((done / total) * 100) : 0 };
}

export function totals() {
  const focusMinutes = state.pomos.reduce((a, p) => a + (p.minutes || 25), 0);
  return {
    sessions: state.pomos.length,
    focusMinutes,
    focusHours: Math.round((focusMinutes / 60) * 10) / 10,
    chaptersDone: Object.values(state.done).filter(Boolean).length,
    tasksDone: Object.values(state.planDone).filter(Boolean).length
  };
}
