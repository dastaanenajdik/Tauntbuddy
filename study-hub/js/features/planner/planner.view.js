// ---------------------------------------------------------------------------
// Planner view · the detailed day-by-day exam planner.
//
//   • Week accordions (lazy-rendered on first open — DOM stays light)
//   • Each day lists the exact chapters / practice sets / revision blocks
//   • Every task shows its Pomodoro target and live 🍅 count; ▶ launches the
//     built-in timer with that task's context and auto-completes at target
//   • Completion states update dynamically everywhere (task rows, day and
//     week headers, hero bar) via targeted DOM updates — no full re-renders.
// ---------------------------------------------------------------------------

import { EXAMS, getExam } from "../../../data/exams.js";
import * as store from "../../store.js";
import { el, esc, kindChip, pomoHref, progressBar } from "../../ui.js";
import { buildPlan, continueDay, planProgress, weekProgress, PHASES } from "./plan-generator.js";

function taskRow(exam, task) {
  const done = store.isTaskDone(task.id);
  const n = Math.min(store.pomoCount(task.id), task.target);
  return `
    <li class="task ${done ? "done" : ""}" data-task="${esc(task.id)}">
      <button class="tick" data-act="toggle" type="button" aria-pressed="${done}"
              aria-label="Mark task complete">✓</button>
      <div class="t-main">
        <div class="t-title">${esc(task.title)}</div>
        <div class="t-crumb">${esc(task.subject || exam.name)}${task.unit ? ` · ${esc(task.unit)}` : ""} · ${esc(task.note)}</div>
      </div>
      ${kindChip(task.kind)}
      <button class="pomochip ${n >= task.target ? "filled" : ""}" data-act="pomo" type="button"
              title="Start Pomodoro for this task" data-pomo>🍅 ${n}/${task.target} ▶</button>
    </li>`;
}

function dayBlock(exam, day) {
  const allDone = day.taskIds.every((id) => store.isTaskDone(id));
  const sub = day.reviewDay
    ? day.phase === "revision" ? "Mock day" : "Weekly checkpoint"
    : PHASES[day.phase].label;
  return `
    <section class="day ${allDone ? "alldone" : ""}" data-day="${day.num}">
      <header>
        <span class="d-num">Day ${day.num}</span>
        <span class="d-sub">${esc(sub)} · ${day.tasks.length} task${day.tasks.length === 1 ? "" : "s"}</span>
      </header>
      <ul class="tasks">${day.tasks.map((t) => taskRow(exam, t)).join("")}</ul>
    </section>`;
}

function fillWeek(bodyEl, exam, week) {
  if (bodyEl.dataset.filled) return;
  bodyEl.dataset.filled = "1";
  bodyEl.replaceChildren(el(week.days.map((d) => dayBlock(exam, d)).join("")));
}

export function plannerView(root, params) {
  const exam =
    getExam(params.id) || getExam(store.getState().lastExam) || EXAMS[0];
  store.getState().lastExam = exam.id;
  store.persist();

  const plan = buildPlan(exam);
  const summary = planProgress(plan);
  const jumpDay = continueDay(plan);

  root.replaceChildren(
    el(`
    <section class="band band-planner plan-hero fade-in">
      <h1>Exam planner · ${esc(exam.name)}</h1>
      <p class="lede">${plan.totals.chapters} chapters spread across ${plan.totals.weeks} weeks —
      exactly what to study, day by day, with Pomodoro targets per block.
      Tick tasks off and everything stays in sync with your syllabus.</p>
      ${progressBar(summary.pct, { onDark: true })}
      <div class="band-meta">
        <span class="chip on-dark" data-chip-plan>✅ ${summary.done}/${summary.total} tasks</span>
        <span class="chip on-dark" data-chip-pomos>🍅 ${summary.pomos}/${summary.pomoTarget} focus blocks</span>
        <span class="chip on-dark">≈${plan.totals.estHours} h of deep work</span>
      </div>
      <div class="picker" role="group" aria-label="Switch exam">
        ${EXAMS.map((e) => `<a class="chip on-dark ${e.id === exam.id ? "sel" : ""}" href="#/planner/${esc(e.id)}">${esc(e.name)}</a>`).join("")}
      </div>
      <div class="band-actions">
        <button class="btn gold" data-act="continue" type="button" ${summary.done === summary.total ? "disabled" : ""}>${summary.done === summary.total ? "Plan complete 🎉" : `▶ Continue from Day ${jumpDay}`}</button>
        <a class="btn blank" href="#/course/${esc(exam.id)}">📚 Syllabus view</a>
        <a class="btn blank" href="${pomoHref({ exam: exam.id, auto: true })}">⏱ Open Pomodoro</a>
      </div>
    </section>

    <div class="plan-summary">
      ${Object.entries(PHASES).map(([k, v]) => `<span class="chip"><span class="kindchip kind-${k === "foundation" ? "learn" : k === "mastery" ? "practice" : "revision"}" style="padding:0;background:none;color:inherit">${esc(v.label)}</span> — ${esc(v.desc)}</span>`).join("")}
    </div>

    <div data-weeks>
      ${plan.weeks
        .map((w) => {
          const wp = weekProgress(w);
          const autoOpen = w.days.some((d) => d.num >= jumpDay - 3 && d.num <= jumpDay);
          return `
        <details class="week" data-week="${w.n}" ${autoOpen ? "open" : ""}>
          <summary>
            <span class="w-caret">›</span>
            <span>
              <span class="w-title">Week ${w.n} · ${esc(PHASES[w.phase].label)}</span>
              <div class="w-sub">Days ${w.days[0].num}–${w.days[w.days.length - 1].num} · ${w.days.flatMap((d) => d.taskIds).length} tasks</div>
            </span>
            <span class="w-right">
              <span class="w-pct" data-week-pct="${w.n}">${wp.pct}%</span>
              <span class="progress" data-week-bar="${w.n}"><span style="width:${wp.pct}%"></span></span>
            </span>
          </summary>
          <div class="week-body" data-week-body="${w.n}"></div>
        </details>`;
        })
        .join("")}
    </div>
  `)
  );

  // Pre-fill expanded weeks; fill the rest lazily on first open.
  root.querySelectorAll(".week[open]").forEach((dEl) => {
    const w = plan.weeks[Number(dEl.dataset.week) - 1];
    fillWeek(dEl.querySelector("[data-week-body]"), exam, w);
  });

  /* ---- targeted refresh ---------------------------------------------------- */
  function refreshDynamic() {
    // task rows
    root.querySelectorAll("[data-task]").forEach((li) => {
      const id = li.getAttribute("data-task");
      const done = store.isTaskDone(id);
      li.classList.toggle("done", done);
      li.querySelector(".tick")?.setAttribute("aria-pressed", String(done));
      const info = plan.byTaskId.get(id);
      if (info) {
        const n = Math.min(store.pomoCount(id), info.task.target);
        const chipBtn = li.querySelector("[data-pomo]");
        if (chipBtn) {
          chipBtn.textContent = `🍅 ${n}/${info.task.target} ▶`;
          chipBtn.classList.toggle("filled", n >= info.task.target);
        }
      }
    });
    // day headers
    plan.weeks.forEach((w) => {
      w.days.forEach((d) => {
        const dayEl = root.querySelector(`[data-day="${d.num}"]`);
        if (dayEl) dayEl.classList.toggle("alldone", d.taskIds.every((id) => store.isTaskDone(id)));
      });
      const wp = weekProgress(w);
      const pct = root.querySelector(`[data-week-pct="${w.n}"]`);
      const bar = root.querySelector(`[data-week-bar="${w.n}"] > span`);
      if (pct) pct.textContent = `${wp.pct}%`;
      if (bar) bar.style.width = `${wp.pct}%`;
    });
    // hero
    const s = planProgress(plan);
    const chipPlan = root.querySelector("[data-chip-plan]");
    const chipPomos = root.querySelector("[data-chip-pomos]");
    const heroBar = root.querySelector(".band .progress > span");
    if (chipPlan) chipPlan.textContent = `✅ ${s.done}/${s.total} tasks`;
    if (chipPomos) chipPomos.textContent = `🍅 ${s.pomos}/${s.pomoTarget} focus blocks`;
    if (heroBar) heroBar.style.width = `${s.pct}%`;
    // continue button always points at the real next open day
    const cont = root.querySelector('[data-act="continue"]');
    if (cont) {
      const finished = s.done === s.total;
      cont.disabled = finished;
      cont.textContent = finished ? "Plan complete 🎉" : `▶ Continue from Day ${continueDay(plan)}`;
    }
  }

  /* ---- delegated interactions ------------------------------------------------ */
  function onClick(e) {
    const actBtn = e.target.closest("[data-act]");
    if (!actBtn) return;

    if (actBtn.dataset.act === "continue") {
      const target = continueDay(plan);
      const weekN = Math.ceil(target / 7);
      const dEl = root.querySelector(`[data-week="${weekN}"]`);
      if (dEl && !dEl.open) dEl.open = true; // toggle handler fills it
      requestAnimationFrame(() => {
        root.querySelector(`[data-day="${target}"]`)?.scrollIntoView({ behavior: "smooth", block: "center" });
      });
      return;
    }

    const taskEl = actBtn.closest("[data-task]");
    if (!taskEl) return;
    const id = taskEl.getAttribute("data-task");
    const info = plan.byTaskId.get(id);
    if (!info) return;

    if (actBtn.dataset.act === "toggle") {
      store.toggleTask(id, info.task.topicKey || null);
      return;
    }
    if (actBtn.dataset.act === "pomo") {
      location.hash = pomoHref({
        exam: exam.id,
        taskId: id,
        topicKey: info.task.topicKey || null,
        title: info.task.title,
        subject: info.task.subject || null,
        target: info.task.target,
        auto: true
      });
    }
  }

  // `<details>` toggle events don't bubble — listen in the capture phase.
  function onToggleCapture(e) {
    const dEl = e.target;
    if (!(dEl instanceof HTMLDetailsElement) || !dEl.open || !dEl.dataset.week) return;
    const w = plan.weeks[Number(dEl.dataset.week) - 1];
    fillWeek(dEl.querySelector("[data-week-body]"), exam, w);
  }

  const unsub = store.subscribe(refreshDynamic);
  root.addEventListener("click", onClick);
  root.addEventListener("toggle", onToggleCapture, true);

  return () => {
    unsub();
    root.removeEventListener("click", onClick);
    root.removeEventListener("toggle", onToggleCapture, true);
  };
}
