// ---------------------------------------------------------------------------
// Course detail · a full Exam Hub page for one exam: pattern, runway, the
// complete subject → unit → chapter syllabus with live completion, unit
// badges, and an embedded Pomodoro — clicking any chapter starts the timer
// right here, in place. "Open full timer" jumps to the Pomodoro page with
// the same context.
// ---------------------------------------------------------------------------

import { getExam, flattenTopics } from "../../../data/exams.js";
import * as store from "../../store.js";
import { el, esc, progressBar, pomoHref } from "../../ui.js";
import { timer } from "../pomodoro/timer.js";
import { mountPomodoro } from "../pomodoro/pomodoro-widget.js";
import { navigate } from "../../router.js";

function nextUpTopic(exam) {
  const topics = flattenTopics(exam);
  return (
    topics.find((t) => !store.isTopicDone(store.topicKey(exam.id, t.subject, t.unit, t.chapter))) ||
    topics[0] || null
  );
}

function unitProgress(exam, subject, unit) {
  let done = 0;
  unit.chapters.forEach((c) => {
    if (store.isTopicDone(store.topicKey(exam.id, subject.name, unit.name, c))) done++;
  });
  const total = unit.chapters.length;
  return { done, total, pct: total ? Math.round((done / total) * 100) : 0 };
}

function render(root, exam) {
  const flat = flattenTopics(exam);
  const p = store.examProgress(flat, exam.id);
  const next = nextUpTopic(exam);

  root.replaceChildren(
    el(`
    <section class="band band-exam fade-in">
      <div class="row" style="align-items:flex-start">
        <div>
          <h1>${esc(exam.name)}</h1>
          <p class="lede">${esc(exam.blurb)}</p>
        </div>
        <a class="btn blank" href="#/courses">← All courses</a>
      </div>
      <div class="band-meta">
        <span class="chip on-dark">${esc(exam.tag)}</span>
        <span class="chip on-dark">🗓 ${esc(exam.pattern)}</span>
        <span class="chip on-dark">≈${exam.hoursPerDay} h/day · ${exam.months}-month runway</span>
        <span class="chip on-dark" data-chip-overall>${p.done}/${p.total} chapters</span>
      </div>
      ${progressBar(p.pct, { onDark: true })}
      <div class="band-actions">
        <a class="btn gold" href="#/planner/${esc(exam.id)}">📅 Day-by-day planner</a>
        <a class="btn blank" href="${pomoHref({ exam: exam.id, auto: true })}">▶ Full-screen Pomodoro</a>
      </div>
    </section>

    <div class="grid cols-2" style="align-items:start">
      <article class="card navy fade-in">
        <h3 style="text-align:center">Focus deck</h3>
        <p class="muted next-up" style="text-align:center;margin:6px 0 10px">
          ${next ? `Next up: <strong>${esc(next.chapter)}</strong><br><span>${esc(next.subject)} · ${esc(next.unit)}</span>` : "Syllabus cleared — mocks it is."}
        </p>
        <div data-widget-slot></div>
        <p style="text-align:center;margin-top:10px">
          <button class="btn gold small" data-act="start-next" type="button" ${next ? "" : "disabled"}>▶ Start next chapter</button>
        </p>
      </article>

      <article class="card fade-in">
        <h3>How this course works</h3>
        <ul class="list" style="margin-top:10px">
          <li class="check" style="align-items:center"><span class="chip ok">1</span><div><strong>Tick chapters off</strong><div class="muted">Every unit lights up “Unit complete” as you finish its chapters.</div></div></li>
          <li class="check" style="align-items:center"><span class="chip ok">2</span><div><strong>Study in Pomodoros</strong><div class="muted">Hit ▶ on any chapter — the timer starts here or full-screen.</div></div></li>
          <li class="check" style="align-items:center"><span class="chip ok">3</span><div><strong>Follow the planner</strong><div class="muted">The day-by-day plan tracks the same chapters, so both views stay in sync.</div></div></li>
        </ul>
      </article>
    </div>

    <div style="display:grid;gap:14px;margin-top:14px" data-subjects>
      ${exam.subjects
        .map((s, si) => {
          const subjFlat = flat.filter((t) => t.subject === s.name);
          const sp = store.examProgress(subjFlat, exam.id);
          return `
        <article class="card subject-card fade-in" data-subject="${si}">
          <div class="subject-head">
            <h2>${esc(s.name)}</h2>
            <span class="chip" data-subj-label="${si}">${sp.done}/${subjFlat.length} · ${sp.pct}%</span>
            <div class="progress" data-subj-bar="${si}" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${sp.pct}"><span style="width:${sp.pct}%"></span></div>
          </div>
          ${s.units
            .map((u, ui) => {
              const up = unitProgress(exam, s, u);
              return `
            <section class="unit ${up.pct === 100 ? "complete" : ""}" data-unit="${ui}">
              <div class="unit-head">
                <h3>Unit: ${esc(u.name)}</h3>
                <span class="unit-pct muted" data-unit-label="${si}:${ui}">${up.done}/${up.total} chapters · ${up.pct}%</span>
                <span class="chip ok unit-done-badge">✓ Unit complete</span>
              </div>
              <div class="progress" data-unit-bar="${si}:${ui}" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${up.pct}"><span style="width:${up.pct}%"></span></div>
              <ol class="chapters" style="padding-left:0">
                ${u.chapters
                  .map((c) => {
                    const key = store.topicKey(exam.id, s.name, u.name, c);
                    const done = store.isTopicDone(key);
                    const count = store.pomoCount(key);
                    return `
                  <li class="chapter-row ${done ? "done" : ""}" data-topic="${esc(key)}">
                    <button class="tick" data-act="toggle" type="button" aria-pressed="${done}" aria-label="Mark ${esc(c)} complete">✓</button>
                    <div style="flex:1 1 auto;min-width:0">
                      <div class="c-name">${esc(c)}</div>
                      <div class="c-meta">${count ? `🍅 ${count} focused` : "Not started"}</div>
                    </div>
                    <button class="pomochip" data-act="study" type="button" title="Start a Pomodoro on this chapter">▶ Study</button>
                  </li>`;
                  })
                  .join("")}
              </ol>
            </section>`;
            })
            .join("")}
        </article>`;
        })
        .join("")}
    </div>
  `)
  );
}

export function courseDetailView(root, params) {
  const exam = getExam(params.id) || getExam(store.getState().lastExam) || getExam("jee");
  store.getState().lastExam = exam.id;
  store.persist();

  render(root, exam);

  // Embedded Pomodoro — the "built-in timer" for this course. Don't steal
  // the context of a session that's already running elsewhere.
  const next = nextUpTopic(exam);
  if (!timer.snapshot().running) {
    timer.setContext({
      examId: exam.id,
      subject: next?.subject || null,
      unit: next?.unit || null,
      chapter: next?.chapter || null,
      taskId: null,
      topicKey: next ? store.topicKey(exam.id, next.subject, next.unit, next.chapter) : null,
      title: next ? next.chapter : `${exam.name} revision`
    });
  }
  const unmountWidget = mountPomodoro(root.querySelector("[data-widget-slot]"), { compact: true });

  const flat = flattenTopics(exam);

  /* ---- targeted live refresh (no full re-renders on state changes) -------- */
  function refreshDynamic() {
    const p = store.examProgress(flat, exam.id);
    const chip = root.querySelector("[data-chip-overall]");
    if (chip) chip.textContent = `${p.done}/${p.total} chapters`;
    const heroBar = root.querySelector(".band .progress > span");
    if (heroBar) heroBar.style.width = `${p.pct}%`;

    exam.subjects.forEach((s, si) => {
      const subjFlat = flat.filter((t) => t.subject === s.name);
      const sp = store.examProgress(subjFlat, exam.id);
      const lbl = root.querySelector(`[data-subj-label="${si}"]`);
      const bar = root.querySelector(`[data-subj-bar="${si}"] > span`);
      if (lbl) lbl.textContent = `${sp.done}/${subjFlat.length} · ${sp.pct}%`;
      if (bar) bar.style.width = `${sp.pct}%`;

      s.units.forEach((u, ui) => {
        const up = unitProgress(exam, s, u);
        const ulbl = root.querySelector(`[data-unit-label="${si}:${ui}"]`);
        const ubar = root.querySelector(`[data-unit-bar="${si}:${ui}"] > span`);
        const unitEl = root.querySelector(`[data-subject="${si}"] [data-unit="${ui}"]`);
        if (ulbl) ulbl.textContent = `${up.done}/${up.total} chapters · ${up.pct}%`;
        if (ubar) ubar.style.width = `${up.pct}%`;
        if (unitEl) unitEl.classList.toggle("complete", up.pct === 100);
      });
    });

    root.querySelectorAll("[data-topic]").forEach((row) => {
      const key = row.getAttribute("data-topic");
      const done = store.isTopicDone(key);
      row.classList.toggle("done", done);
      const tick = row.querySelector(".tick");
      if (tick) tick.setAttribute("aria-pressed", String(done));
      const meta = row.querySelector(".c-meta");
      const count = store.pomoCount(key);
      if (meta) meta.textContent = count ? `🍅 ${count} focused` : "Not started";
    });
  }

  /* ---- interactions (single delegated listener) --------------------------- */
  function onClick(e) {
    const actBtn = e.target.closest("[data-act]");
    if (!actBtn) return;
    const row = actBtn.closest("[data-topic]");

    if (actBtn.dataset.act === "toggle" && row) {
      store.toggleTopic(row.getAttribute("data-topic"));
      return;
    }
    if (actBtn.dataset.act === "study" && row) {
      const key = row.getAttribute("data-topic");
      const [, subject, unit, chapter] = key.split("|");
      // Seamless: start the embedded timer immediately on this chapter.
      timer.setContext({ examId: exam.id, subject, unit, chapter, taskId: null, topicKey: key, title: chapter });
      timer.setMode("focus");
      timer.start();
      root.querySelector(".card.navy")?.scrollIntoView({ behavior: "smooth", block: "nearest" });
      return;
    }
    if (actBtn.dataset.act === "start-next") {
      const t = nextUpTopic(exam);
      if (!t) return;
      navigate(pomoHref({
        exam: exam.id, subject: t.subject, unit: t.unit, chapter: t.chapter,
        topicKey: store.topicKey(exam.id, t.subject, t.unit, t.chapter), title: t.chapter, auto: true
      }));
    }
  }

  const unsub = store.subscribe(refreshDynamic);
  root.addEventListener("click", onClick);

  return () => {
    unmountWidget();
    unsub();
    root.removeEventListener("click", onClick);
  };
}
