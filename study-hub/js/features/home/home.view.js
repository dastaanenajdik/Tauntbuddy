// ---------------------------------------------------------------------------
// Home view · photographic hero, live study stats, and the Exam Hub grid —
// every card links straight into syllabus, planner and Pomodoro.
// ---------------------------------------------------------------------------

import { EXAMS, flattenTopics } from "../../../data/exams.js";
import * as store from "../../store.js";
import { el, esc, progressBar, pomoHref } from "../../ui.js";

const metric = (value) => String(value ?? 0).padStart(2, "0");

function render(root) {
  const stats = store.totals();

  const cards = EXAMS.map((e) => {
    const p = store.examProgress(flattenTopics(e), e.id);
    return `
      <article class="card exam-card clickable" data-goto="#/course/${esc(e.id)}">
        <div class="thumb"><h3>${esc(e.name)}</h3></div>
        <div class="row">
          <span class="chip">${esc(e.tag)}</span>
          <span class="chip">${p.done}/${p.total} chapters</span>
        </div>
        <p class="muted" style="margin-top:8px">${esc(e.blurb)}</p>
        <div class="progress" style="margin:10px 0 4px" role="progressbar"
             aria-valuemin="0" aria-valuemax="100" aria-valuenow="${p.pct}"
             data-bar="exam:${esc(e.id)}"><span style="width:${p.pct}%"></span></div>
        <p class="muted" style="font-size:12.5px" data-barlabel="exam:${esc(e.id)}">${p.pct}% complete</p>
        <div class="actions">
          <a class="btn small" href="#/course/${esc(e.id)}">Syllabus</a>
          <a class="btn small ghost" href="#/planner/${esc(e.id)}">Planner</a>
          <a class="btn small gold" href="${pomoHref({ exam: e.id, auto: true })}">▶ Study</a>
        </div>
      </article>`;
  }).join("");

  root.replaceChildren(
    el(`
    <section class="band band-home fade-in">
      <h1>Apka din, sorted.</h1>
      <p class="lede">The TauntBuddy Exam Hub — full syllabi for India’s toughest
      exams, a day-by-day planner, and a Pomodoro engine welded into every
      chapter. No excuses, no shady underlines.</p>
      <div class="band-actions">
        <a class="btn gold" href="#/courses">🎓 Browse courses</a>
        <a class="btn blank" href="#/planner">📅 Open planner</a>
        <a class="btn blank" href="#/pomodoro">⏱ Start focusing</a>
      </div>
    </section>

    <section class="stats fade-in" aria-label="Your study stats">
      <div class="stat"><div class="n" data-stat="sessions">${metric(stats.sessions)}</div><div class="l">Pomodoro sessions</div></div>
      <div class="stat"><div class="n" data-stat="hours">${metric(stats.focusHours)}</div><div class="l">Focused hours logged</div></div>
      <div class="stat"><div class="n" data-stat="chapters">${metric(stats.chaptersDone)}</div><div class="l">Chapters completed</div></div>
      <div class="stat"><div class="n" data-stat="tasks">${metric(stats.tasksDone)}</div><div class="l">Planner tasks done</div></div>
    </section>

    <section aria-label="Exam hub">
      <div class="row" style="margin-bottom:12px">
        <h2>Exam Hub</h2>
        <span class="chip">${EXAMS.length} tracks</span>
      </div>
      <div class="grid cols-3">${cards}</div>
    </section>
  `)
  );
}

/** Targeted refresh — updates bars + stat numbers in place. */
function refreshDynamic(root) {
  const stats = store.totals();
  const set = (k, v) => {
    const n = root.querySelector(`[data-stat="${k}"]`);
    if (n) n.textContent = v;
  };
  set("sessions", metric(stats.sessions));
  set("hours", metric(stats.focusHours));
  set("chapters", metric(stats.chaptersDone));
  set("tasks", metric(stats.tasksDone));

  EXAMS.forEach((e) => {
    const p = store.examProgress(flattenTopics(e), e.id);
    const bar = root.querySelector(`[data-bar="exam:${e.id}"] > span`);
    const lbl = root.querySelector(`[data-barlabel="exam:${e.id}"]`);
    if (bar) bar.style.width = `${p.pct}%`;
    if (lbl) lbl.textContent = `${p.pct}% complete`;
  });
}

export function homeView(root) {
  render(root);

  const unsubStore = store.subscribe(() => refreshDynamic(root));

  // Whole card acts as a link, but real <a> children keep native behaviour.
  function onClick(e) {
    if (e.target.closest("a, button")) return;
    const card = e.target.closest("[data-goto]");
    if (card) location.hash = card.getAttribute("data-goto");
  }
  root.addEventListener("click", onClick);

  return () => {
    unsubStore();
    root.removeEventListener("click", onClick);
  };
}
