// ---------------------------------------------------------------------------
// Tiny DOM helpers shared by every view. No framework, no innerHTML of raw
// user/data strings — everything interpolated passes through esc().
// ---------------------------------------------------------------------------

export function el(html) {
  const t = document.createElement("template");
  t.innerHTML = html.trim();
  return t.content;
}

export function esc(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export function progressBar(pct, { onDark = false } = {}) {
  const clamped = Math.max(0, Math.min(100, pct));
  return `<div class="progress ${onDark ? "on-dark" : ""}" role="progressbar"
    aria-valuemin="0" aria-valuemax="100" aria-valuenow="${clamped}">
    <span style="width:${clamped}%"></span></div>`;
}

export function chip(text, cls = "") {
  return `<span class="chip ${cls}">${esc(text)}</span>`;
}

export const KIND_LABEL = {
  learn: "Learn",
  practice: "Practice",
  revision: "Revision",
  review: "Wk Review",
  mock: "Mock"
};

export function kindChip(kind) {
  return `<span class="kindchip kind-${esc(kind)}">${esc(KIND_LABEL[kind] || kind)}</span>`;
}

export function pomoHref({ exam, subject = null, unit = null, chapter = null, taskId = null, topicKey = null, title = null, target = null, auto = false }) {
  const q = new URLSearchParams();
  if (exam) q.set("exam", exam);
  if (subject) q.set("subject", subject);
  if (unit) q.set("unit", unit);
  if (chapter) q.set("chapter", chapter);
  if (taskId) q.set("task", taskId);
  if (topicKey) q.set("topicKey", topicKey);
  if (title) q.set("title", title);
  if (target) q.set("target", String(target));
  if (auto) q.set("auto", "1");
  return `#/pomodoro?${q.toString()}`;
}

let toastTimer = new Map();

export function toast(message, ms = 2600) {
  const root = document.getElementById("toastRoot");
  if (!root) return;
  const node = document.createElement("div");
  node.className = "toast";
  node.textContent = message;
  root.appendChild(node);
  const t = setTimeout(() => {
    node.classList.add("leaving");
    setTimeout(() => node.remove(), 320);
    toastTimer.delete(node);
  }, ms);
  toastTimer.set(node, t);
}

const TIME_FMT = new Intl.DateTimeFormat("en-IN", { hour: "numeric", minute: "2-digit" });
const DATE_FMT = new Intl.DateTimeFormat("en-IN", { day: "numeric", month: "short" });

export function fmtWhen(ts) {
  const d = new Date(ts);
  const today = new Date();
  const sameDay = d.toDateString() === today.toDateString();
  return `${sameDay ? "Today" : DATE_FMT.format(d)} · ${TIME_FMT.format(d)}`;
}
