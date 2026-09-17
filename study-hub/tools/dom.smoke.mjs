// ---------------------------------------------------------------------------
// DOM smoke test · boots the real Study Hub SPA in jsdom and walks every
// route + the key interactions (filters, chapter ticks, embedded Pomodoro,
// planner lazy weeks, planner→pomodoro deep links, persistence).
//
//   cd study-hub && npm install --no-save jsdom && node tools/dom.smoke.mjs
// ---------------------------------------------------------------------------

import { JSDOM, VirtualConsole } from "jsdom";

const BASE = new URL("../js/", import.meta.url).href;

const shell = `<!DOCTYPE html><html><head></head><body>
  <div class="app">
    <header class="topbar">
      <a class="brand" href="#/">TauntBuddy</a>
      <button class="timestrip" id="timeStrip" type="button" hidden>
        <span class="dot"></span><span id="timeStripClock">25:00</span><span id="timeStripLabel">Focus</span>
      </button>
      <nav class="nav">
        <a data-nav href="#/">Home</a>
        <a data-nav href="#/courses">Courses</a>
        <a data-nav href="#/planner">Planner</a>
        <a data-nav href="#/pomodoro">Pomodoro</a>
      </nav>
    </header>
    <main id="view" class="view"></main>
  </div>
  <div id="toastRoot" class="toast-root"></div>
</body></html>`;

const vc = new VirtualConsole();
const pageErrors = [];
vc.on("jsdomError", (e) => {
  if (!String(e.message).startsWith("Not implemented")) pageErrors.push(e.message);
});
vc.on("error", (m) => pageErrors.push(m));

const dom = new JSDOM(shell, {
  url: "https://tb.test/study-hub/index.html",
  pretendToBeVisual: true,
  runScripts: "outside-only",
  virtualConsole: vc
});
const { window } = dom;

// Bind the jsdom realm classes (Node ships its own Event/CustomEvent).
for (const k of ["window", "document", "localStorage", "CustomEvent", "Event",
  "HTMLDetailsElement", "HTMLElement", "Element", "Node"]) {
  globalThis[k] = window[k];
}
globalThis.requestAnimationFrame = window.requestAnimationFrame?.bind(window) || ((f) => setTimeout(f, 0));
window.HTMLElement.prototype.scrollIntoView = function () {};
globalThis.location = window.location;

let passed = 0;
const ok = (cond, msg) => {
  if (!cond) { console.error(`  ✗ ${msg}`); process.exitCode = 1; }
  else { console.log(`  ✓ ${msg}`); passed++; }
};

const store = await import(BASE + "store.js");
const { timer } = await import(BASE + "features/pomodoro/timer.js");
const exams = await import(new URL("../data/exams.js", import.meta.url).href);
await import(BASE + "app.js"); // boots router + renders home

const view = window.document.getElementById("view");
const tick = (ms = 320) => new Promise((r) => setTimeout(r, ms));
// jsdom fires hashchange asynchronously exactly like a browser — let it flow.
const nav = async (h) => { window.location.hash = h; await tick(50); };

console.log("Home");
ok(view.innerHTML.includes("Apka din"), "home hero rendered");
ok(view.querySelectorAll(".exam-card").length === exams.EXAMS.length, `${exams.EXAMS.length} exam cards on home`);
ok(view.querySelector('[data-stat="sessions"]').textContent === "0", "stats strip live");
ok([...window.document.querySelectorAll("[data-nav]")][0].classList.contains("active"), "Home nav active");

console.log("Courses");
await nav("#/courses");
ok(view.querySelectorAll(".filterbar .chip").length === new Set(exams.EXAMS.map((e) => e.tag)).size + 1, "filter chips rendered");
ok(view.querySelectorAll(".exam-card").length === exams.EXAMS.length, "courses grid shows all exams");
view.querySelector('[data-filter="Engineering"]').click();
ok(view.querySelectorAll(".exam-card").length === exams.EXAMS.filter((e) => e.tag === "Engineering").length, "tag filter narrows the grid");
view.querySelector('[data-filter="All"]').click();
ok(view.querySelectorAll(".exam-card").length === exams.EXAMS.length, "/All/ restores the grid");

console.log("Course detail (Exam Hub)");
await nav("#/course/jee");
const jee = exams.getExam("jee");
const jeeFlat = exams.flattenTopics(jee);
ok(view.querySelectorAll(".subject-card").length === jee.subjects.length, `JEE shows ${jee.subjects.length} subjects`);
const rows = view.querySelectorAll(".chapter-row");
ok(rows.length === jeeFlat.length, `all ${jeeFlat.length} JEE chapters listed with full names (got ${rows.length})`);
ok(view.textContent.includes("General Organic Chemistry (Isomerism & Resonance)"), "full unit/chapter naming");
ok(view.querySelector("[data-widget] .timer"), "embedded pomodoro widget mounted");
const firstRow = rows[0];
firstRow.querySelector('[data-act="toggle"]').click();
ok(firstRow.classList.contains("done"), "chapter tick marks row done live");
ok(store.isTopicDone(firstRow.getAttribute("data-topic")), "store topic marked");
const studyBtn = rows[1].querySelector('[data-act="study"]');
const studyChapter = rows[1].getAttribute("data-topic").split("|")[3];
studyBtn.click();
ok(timer.snapshot().running === true, "▶ Study starts the embedded timer immediately");
ok(timer.snapshot().context.chapter === studyChapter, `timer context = clicked chapter (“${studyChapter}”)`);
ok(window.document.getElementById("timeStrip").hidden === false, "topbar running strip visible");
timer.pause();
ok(window.document.getElementById("timeStrip").hidden === true, "strip hides on pause");

console.log("Planner");
await nav("#/planner/jee");
ok(view.textContent.includes("Exam planner · JEE Main + Advanced"), "planner hero");
const weeks = view.querySelectorAll(".week");
ok(weeks.length === 14, `${weeks.length} week accordions`);
ok(view.querySelectorAll(".week[open]").length >= 1, "current week auto-opens");
ok(view.querySelector('[data-day="1"]'), "week body lazy-filled with Day 1");
const day1Tasks = view.querySelectorAll('[data-day="1"] [data-task]');
ok(day1Tasks.length >= 1, `${day1Tasks.length} tasks on Day 1`);
ok(view.querySelector('[data-day="7"] .kindchip.kind-review'), "Day 7 is a Weekly Review task");
const taskLi = day1Tasks[0];
taskLi.querySelector('[data-act="toggle"]').click();
ok(store.isTaskDone(taskLi.getAttribute("data-task")), "task toggle persisted");
ok(taskLi.classList.contains("done"), "task row updates dynamically");
const w5 = view.querySelector('[data-week="5"]');
w5.open = true;
w5.dispatchEvent(new window.Event("toggle"));
ok(w5.querySelector('[data-day="29"]'), "closed weeks lazy-render on open");

console.log("Planner → Pomodoro deep link");
const chip = taskLi.querySelector("[data-pomo]");
const expectedTask = taskLi.getAttribute("data-task");
chip.click();
await tick(60); // async hashchange → router → pomodoro view
ok(window.location.hash.includes("#/pomodoro"), "pomochip routes to pomodoro");
ok(window.location.hash.includes(`task=${encodeURIComponent(expectedTask)}`), "task id carried in URL");
ok(timer.snapshot().running === true, "auto=1 starts the timer");
ok(timer.snapshot().context.taskId === expectedTask, "timer bound to the planner task");
ok(timer.snapshot().context.target > 0, "pomodoro target attached");
const clockEl = view.querySelector("[data-clock]");
await tick(1400); // display is ceil-based, flips to 24:59 after the first full second
ok(clockEl.textContent === "24:59", `clock ticking (${clockEl.textContent})`);
ok(timer.snapshot().remain < 25 * 60, "engine remaining time decreasing");
ok(view.querySelectorAll(".session-log li").length >= 1, "session log present");

console.log("Persistence");
timer.pause();
const raw = window.localStorage.getItem("tauntbuddy-study-v3");
ok(!!raw && JSON.parse(raw).planDone[expectedTask] === true, "state persisted to localStorage v3");

ok(pageErrors.length === 0, `no page errors (${pageErrors.length})${pageErrors.length ? " → " + pageErrors[0] : ""}`);
console.log(`\n${passed} DOM smoke checks passed${process.exitCode ? " (with failures)" : " ✅"}`);
process.exit(process.exitCode || 0);
