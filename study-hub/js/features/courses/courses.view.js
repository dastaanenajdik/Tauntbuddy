// ---------------------------------------------------------------------------
// Courses view · the Exam Hub lives here. Course/exam cards with category
// filters, live progress, and a one-tap "▶ Study now" that opens the
// built-in Pomodoro timer with that exam pre-loaded.
// ---------------------------------------------------------------------------

import { EXAMS, flattenTopics } from "../../../data/exams.js";
import * as store from "../../store.js";
import { el, esc, pomoHref } from "../../ui.js";

function card(e) {
  const p = store.examProgress(flattenTopics(e), e.id);
  return `
    <article class="card exam-card clickable" data-tag="${esc(e.tag)}" data-goto="#/course/${esc(e.id)}">
      <div class="thumb"><h3>${esc(e.name)}</h3></div>
      <div class="row">
        <span class="chip">${esc(e.tag)}</span>
        <span class="chip">${e.subjects.length} subjects · ${p.total} chapters</span>
      </div>
      <p class="muted" style="margin-top:8px">${esc(e.blurb)}</p>
      <p class="muted" style="font-size:12.5px;margin-top:6px">🗓 ${esc(e.pattern)}</p>
      <div class="progress" style="margin:10px 0 4px" data-bar="exam:${esc(e.id)}"
           role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${p.pct}">
        <span style="width:${p.pct}%"></span></div>
      <p class="muted" style="font-size:12.5px" data-barlabel="exam:${esc(e.id)}">${p.done}/${p.total} chapters · ${p.pct}%</p>
      <div class="actions">
        <a class="btn small" href="#/course/${esc(e.id)}">Open syllabus</a>
        <a class="btn small ghost" href="#/planner/${esc(e.id)}">Day plan</a>
        <a class="btn small gold" href="${pomoHref({ exam: e.id, auto: true })}">▶ Study now</a>
      </div>
    </article>`;
}

function render(root, filter) {
  const tags = ["All", ...new Set(EXAMS.map((e) => e.tag))];
  const list = EXAMS.filter((e) => filter === "All" || e.tag === filter);

  root.replaceChildren(
    el(`
    <section class="band band-courses fade-in">
      <h1>Courses & Exam Hub</h1>
      <p class="lede">Pick a track. Every course opens its full syllabus — and a
      single tap sends any chapter into the built-in Pomodoro timer.</p>
    </section>

    <div class="filterbar" role="group" aria-label="Filter courses">
      ${tags.map((t) => `<button class="chip ${t === filter ? "sel" : ""}" data-filter="${esc(t)}" type="button">${esc(t)}</button>`).join("")}
    </div>

    <div class="grid cols-3" data-grid>
      ${list.map(card).join("")}
    </div>
  `)
  );
}

export function coursesView(root) {
  let filter = "All";
  render(root, filter);

  function refreshDynamic() {
    EXAMS.forEach((e) => {
      const p = store.examProgress(flattenTopics(e), e.id);
      const bar = root.querySelector(`[data-bar="exam:${e.id}"] > span`);
      const lbl = root.querySelector(`[data-barlabel="exam:${e.id}"]`);
      if (bar) bar.style.width = `${p.pct}%`;
      if (lbl) lbl.textContent = `${p.done}/${p.total} chapters · ${p.pct}%`;
    });
  }

  function onClick(e) {
    const f = e.target.closest("[data-filter]");
    if (f) {
      filter = f.getAttribute("data-filter");
      render(root, filter);
      return;
    }
    if (e.target.closest("a, button")) return;
    const cardEl = e.target.closest("[data-goto]");
    if (cardEl) location.hash = cardEl.getAttribute("data-goto");
  }

  const unsub = store.subscribe(refreshDynamic);
  root.addEventListener("click", onClick);

  return () => {
    unsub();
    root.removeEventListener("click", onClick);
  };
}
