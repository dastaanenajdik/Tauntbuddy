// ---------------------------------------------------------------------------
// Pomodoro page · full-screen timer bound to the singleton engine.
// Deep-links like
//   #/pomodoro?exam=jee&subject=Physics&unit=Mechanics&chapter=Kinematics&task=p|jee|4|0&target=4&auto=1
// set the working context (and optionally auto-start). Completed focus blocks
// are logged to the store, auto-completing linked planner tasks + chapters.
// ---------------------------------------------------------------------------

import { getExam } from "../../../data/exams.js";
import * as store from "../../store.js";
import { el, esc, fmtWhen, toast } from "../../ui.js";
import { timer, MODES } from "./timer.js";
import { mountPomodoro } from "./pomodoro-widget.js";

function parseTarget(v) {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 && n <= 12 ? Math.round(n) : null;
}

export function pomodoroView(root, _params, query) {
  const exam = getExam(query.exam) || getExam(store.getState().lastExam);

  const context = {
    examId: exam?.id || null,
    subject: query.subject || null,
    unit: query.unit || null,
    chapter: query.chapter || null,
    taskId: query.task || null,
    topicKey: query.topicKey || null,
    title: query.title || query.chapter || (exam ? `${exam.name} focus` : "Free focus"),
    target: parseTarget(query.target)
  };

  const recent = [...store.getState().pomos].slice(-6).reverse();

  root.replaceChildren(
    el(`
    <section class="band band-pomodoro fade-in">
      <h1>Pomodoro</h1>
      <p class="lede">25 minutes on, 5 off. Every finished block is logged against
      the chapter or planner task you picked — hit the target and it checks
      itself off.</p>
    </section>

    <div class="pomo-wrap">
      <article class="card navy pomo-stage fade-in">
        <div data-widget-slot></div>
      </article>

      <aside style="display:grid;gap:14px">
        <article class="card fade-in">
          <h3>Now studying</h3>
          <p style="margin-top:8px"><strong>${esc(context.title)}</strong></p>
          <p class="muted" style="font-size:13.5px">
            ${context.subject ? esc(context.subject) : exam ? esc(exam.name) : "Free focus"}${context.unit ? ` · ${esc(context.unit)}` : ""}
          </p>
          <div class="band-actions" style="margin-top:12px">
            ${exam ? `<a class="btn small ghost" href="#/course/${esc(exam.id)}">Syllabus</a>
            <a class="btn small ghost" href="#/planner/${esc(exam.id)}">Planner</a>` : ""}
          </div>
        </article>

        <article class="card fade-in">
          <div class="row"><h3>Session log</h3><span class="chip" data-log-count>${store.getState().pomos.length} total</span></div>
          <ul class="session-log" data-log>
            ${recent.length
              ? recent.map((p) => `<li><span style="min-width:0;overflow:hidden;text-overflow:ellipsis">🍅 ${esc(p.title)}</span><span class="when">${fmtWhen(p.at)}</span></li>`).join("")
              : `<li><span class="muted">No sessions yet — the first 🍅 is the hardest.</span></li>`}
          </ul>
        </article>

        <article class="card teal fade-in">
          <h3>Modes</h3>
          <p class="muted" style="margin-top:6px">Focus ${Math.round(MODES.focus.seconds / 60)} min · short break ${Math.round(MODES.short.seconds / 60)} min · long break ${Math.round(MODES.long.seconds / 60)} min after every 4 rounds.</p>
        </article>
      </aside>
    </div>
  `)
  );

  // Apply the deep-linked context only when nothing is mid-run — otherwise
  // the current session keeps its context (the strip stays honest).
  if (!timer.snapshot().running) {
    timer.setContext(context);
    if (query.auto === "1") {
      timer.setMode("focus");
      timer.start();
    }
  }
  const unmountWidget = mountPomodoro(root.querySelector("[data-widget-slot]"));

  // Celebrate + refresh the log when blocks complete.
  const unsubComplete = timer.onComplete((evt) => {
    if (evt.kind === "focus") {
      if (evt.autoCompleted?.length) toast(`✅ “${evt.autoCompleted[0]}” complete — pomodoro target hit!`);
      else toast("🍅 Focus block logged. Take the break, seriously.");
      refreshLog();
    } else {
      toast("Break's over — back to it.");
    }
  });

  function refreshLog() {
    const logEl = root.querySelector("[data-log]");
    if (!logEl) return;
    const items = [...store.getState().pomos].slice(-6).reverse();
    logEl.replaceChildren(el(items
      .map((p) => `<li><span style="min-width:0;overflow:hidden;text-overflow:ellipsis">🍅 ${esc(p.title)}</span><span class="when">${fmtWhen(p.at)}</span></li>`)
      .join("")));
    const count = root.querySelector("[data-log-count]");
    if (count) count.textContent = `${store.getState().pomos.length} total`;
  }

  const unsubStore = store.subscribe(({ type }) => { if (type === "pomo") refreshLog(); });

  return () => {
    unmountWidget();
    unsubComplete();
    unsubStore();
  };
}
