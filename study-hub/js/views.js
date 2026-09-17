import { EXAMS, flattenTopics } from "../data/exams.js";
import { load, save, toggleDone, topicId } from "./state.js";
import { createPomodoro, fmt } from "./pomodoro.js";

function el(html) {
  const t = document.createElement("template");
  t.innerHTML = html.trim();
  return t.content;
}

function progressFor(exam, state) {
  const topics = flattenTopics(exam);
  const done = topics.filter((t) => state.done[topicId(exam.id, t.subject, t.unit, t.chapter)]).length;
  return { done, total: topics.length, pct: topics.length ? Math.round((done / topics.length) * 100) : 0 };
}

function buildPlan(exam) {
  const topics = flattenTopics(exam);
  const days = Math.max(21, exam.months * 30);
  const perDay = Math.max(1, Math.ceil(topics.length / days));
  const plan = [];
  let i = 0;
  let day = 1;
  while (i < topics.length) {
    plan.push({ day, items: topics.slice(i, i + perDay) });
    i += perDay;
    day += 1;
  }
  return plan;
}

export function renderHome(root) {
  const state = load();
  root.replaceChildren(el(`
    <section class="hero">
      <h1>Exam Hub</h1>
      <p class="muted">Courses, day-wise planner, and Pomodoro — same syllabus, no yellow underlines, high contrast.</p>
    </section>
    <div class="grid cols-3">
      <article class="card navy">
        <h3>Focus now</h3>
        <p class="muted">25-minute blocks. Pick a chapter from any course.</p>
        <p><a class="btn gold" href="#/pomodoro">Open Pomodoro</a></p>
      </article>
      <article class="card teal">
        <h3>Courses</h3>
        <p class="muted">JEE, NEET, UPSC, GATE, CAT, Boards, SSC, CLAT.</p>
        <p><a class="btn gold" href="#/courses">Browse courses</a></p>
      </article>
      <article class="card accent">
        <h3>Planner</h3>
        <p class="muted">Per-day topics with complete checkboxes.</p>
        <p><a class="btn gold" href="#/planner">Open planner</a></p>
      </article>
    </div>
    <div class="grid cols-2" style="margin-top:14px">
      ${EXAMS.map((e) => {
        const p = progressFor(e, state);
        return `<article class="card">
          <div class="row"><strong>${e.name}</strong><span class="chip">${e.tag}</span></div>
          <p class="muted">${p.done}/${p.total} chapters · ${p.pct}%</p>
          <div class="progress"><span style="width:${p.pct}%"></span></div>
          <p style="margin-top:10px"><a class="btn" href="#/course/${e.id}">Study</a>
          <a class="btn ghost" href="#/planner/${e.id}">Plan</a></p>
        </article>`;
      }).join("")}
    </div>
  `));
}

export function renderCourses(root) {
  root.replaceChildren(el(`
    <section class="hero"><h1>Courses</h1><p class="muted">Click a course to open units, chapters, and start Pomodoro on any topic.</p></section>
    <div class="grid cols-3">
      ${EXAMS.map((e) => `<article class="card">
        <h3>${e.name}</h3>
        <p class="muted">${e.subjects.length} subjects · ${flattenTopics(e).length} chapters</p>
        <p><a class="btn" href="#/course/${e.id}">Open syllabus</a></p>
      </article>`).join("")}
    </div>
  `));
}

export function renderCourse(root, id) {
  const exam = EXAMS.find((e) => e.id === id) || EXAMS[0];
  const state = load();
  state.lastExam = exam.id;
  save(state);
  const p = progressFor(exam, state);
  root.replaceChildren(el(`
    <section class="hero">
      <h1>${exam.name}</h1>
      <p class="muted">${p.pct}% complete · ${exam.hoursPerDay}h/day suggested · ${exam.months} month runway</p>
      <div class="progress"><span style="width:${p.pct}%"></span></div>
    </section>
    ${exam.subjects.map((s) => `
      <article class="card" style="margin-bottom:12px">
        <h2>${s.name}</h2>
        ${s.units.map((u) => `
          <div style="margin:12px 0">
            <h3>${u.name}</h3>
            <p class="muted">Unit chapters: ${u.chapters.join(" · ")}</p>
            <ul class="list" style="margin-top:8px">
              ${u.chapters.map((c) => {
                const tid = topicId(exam.id, s.name, u.name, c);
                const done = !!state.done[tid];
                return `<li class="check ${done ? "done" : ""}">
                  <button class="btn ${done ? "ok" : "ghost"}" data-toggle="${tid}">${done ? "Complete" : "Mark done"}</button>
                  <div>
                    <strong>${c}</strong>
                    <div class="muted">${s.name} · ${u.name}</div>
                    <a class="btn gold" href="#/pomodoro?exam=${exam.id}&topic=${encodeURIComponent(c)}">Pomodoro</a>
                  </div>
                </li>`;
              }).join("")}
            </ul>
          </div>
        `).join("")}
      </article>
    `).join("")}
  `));
  root.querySelectorAll("[data-toggle]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const st = load();
      toggleDone(st, btn.getAttribute("data-toggle"));
      renderCourse(root, id);
    });
  });
}

export function renderPlanner(root, id) {
  const exam = EXAMS.find((e) => e.id === id) || EXAMS.find((e) => e.id === load().lastExam) || EXAMS[0];
  const state = load();
  const plan = buildPlan(exam);
  root.replaceChildren(el(`
    <section class="hero">
      <h1>Exam planner · ${exam.name}</h1>
      <p class="muted">Each day lists exact chapters. Tick complete, then run Pomodoro on that topic.</p>
      <div class="row">${EXAMS.map((e) => `<a class="chip" href="#/planner/${e.id}">${e.name}</a>`).join("")}</div>
    </section>
    <div class="grid">
      ${plan.map((d) => `
        <article class="card">
          <div class="row"><h3>Day ${d.day}</h3><span class="chip">${d.items.length} topics</span></div>
          <ul class="list">
            ${d.items.map((t) => {
              const tid = topicId(exam.id, t.subject, t.unit, t.chapter);
              const done = !!state.done[tid];
              return `<li class="check ${done ? "done" : ""}">
                <button class="btn ${done ? "ok" : "ghost"}" data-toggle="${tid}">${done ? "Complete" : "Todo"}</button>
                <div>
                  <strong>${t.chapter}</strong>
                  <div class="muted">${t.subject} · Unit: ${t.unit}</div>
                  <a class="btn gold" href="#/pomodoro?exam=${exam.id}&topic=${encodeURIComponent(t.chapter)}">Start Pomodoro</a>
                </div>
              </li>`;
            }).join("")}
          </ul>
        </article>
      `).join("")}
    </div>
  `));
  root.querySelectorAll("[data-toggle]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const st = load();
      toggleDone(st, btn.getAttribute("data-toggle"));
      renderPlanner(root, id);
    });
  });
}

let pomo;

export function renderPomodoro(root, query) {
  const params = new URLSearchParams(query);
  const topic = params.get("topic") || "Mixed revision";
  const examId = params.get("exam") || load().lastExam;
  const exam = EXAMS.find((e) => e.id === examId);
  root.replaceChildren(el(`
    <section class="hero">
      <h1>Pomodoro</h1>
      <p class="muted">${exam ? exam.name : "Study"} · ${topic}</p>
    </section>
    <article class="card navy" style="text-align:center">
      <div class="timer" id="clock">25:00</div>
      <p class="muted" id="modeLabel">Focus</p>
      <div class="row" style="justify-content:center;margin-top:12px">
        <button class="btn gold" data-mode="focus">25 focus</button>
        <button class="btn gold" data-mode="short">5 break</button>
        <button class="btn gold" data-mode="long">15 long</button>
      </div>
      <div class="row" style="justify-content:center;margin-top:12px">
        <button class="btn" id="start">Start</button>
        <button class="btn ghost" id="pause">Pause</button>
        <button class="btn ghost" id="reset">Reset</button>
      </div>
    </article>
  `));
  const clock = root.querySelector("#clock");
  const modeLabel = root.querySelector("#modeLabel");
  pomo = createPomodoro({
    onTick(remain, mode) {
      clock.textContent = fmt(remain);
      modeLabel.textContent = mode === "focus" ? "Focus" : mode === "short" ? "Short break" : "Long break";
    },
    onDone(mode) {
      if (mode === "focus") {
        const st = load();
        st.pomos.push({ topic, at: Date.now() });
        save(st);
      }
    }
  });
  root.querySelectorAll("[data-mode]").forEach((b) => b.addEventListener("click", () => pomo.setMode(b.dataset.mode)));
  root.querySelector("#start").addEventListener("click", () => pomo.start());
  root.querySelector("#pause").addEventListener("click", () => pomo.pause());
  root.querySelector("#reset").addEventListener("click", () => pomo.reset());
}
