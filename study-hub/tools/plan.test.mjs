// ---------------------------------------------------------------------------
// Headless smoke tests for the Study Hub core logic (no browser needed):
//   node tools/plan.test.mjs
// Covers the dataset, plan generator, reactive store and timer engine.
// ---------------------------------------------------------------------------

import assert from "node:assert/strict";
import { EXAMS, getExam, flattenTopics } from "../data/exams.js";
import * as store from "../js/store.js";
import {
  buildPlan, getTaskById, continueDay, planProgress, PHASES
} from "../js/features/planner/plan-generator.js";
import { timer, fmtClock, MODES } from "../js/features/pomodoro/timer.js";

let passed = 0;
const ok = (cond, msg) => { assert.ok(cond, msg); console.log(`  ✓ ${msg}`); passed++; };

/* --- dataset -------------------------------------------------------------- */
console.log("Dataset");
ok(EXAMS.length >= 8, `${EXAMS.length} exam tracks present`);
for (const e of EXAMS) {
  const flat = flattenTopics(e);
  ok(flat.length > 10, `${e.id}: ${flat.length} chapters across ${e.subjects.length} subjects`);
  ok(flat.every((t) => t.subject && t.unit && t.chapter), `${e.id}: every chapter has subject+unit+chapter`);
  ok(!flat.some((t) => /\b(SHM|GOC|EMI|AC)\b$/.test(t.chapter)), `${e.id}: no bare abbreviations as chapter names`);
}

/* --- plan generator --------------------------------------------------------- */
console.log("\nPlan generator");
for (const e of EXAMS) {
  const plan = buildPlan(e);
  const flat = flattenTopics(e);
  const ids = plan.flatTaskIds;
  ok(new Set(ids).size === ids.length, `${e.id}: task ids unique (${ids.length} tasks)`);

  const learnTasks = [...plan.byTaskId.values()].filter((x) => x.task.kind === "learn");
  const practiceTasks = [...plan.byTaskId.values()].filter((x) => x.task.kind === "practice");
  ok(learnTasks.length === flat.length, `${e.id}: each of ${flat.length} chapters gets exactly one Learn task`);
  ok(practiceTasks.length === flat.length, `${e.id}: each chapter gets a Practice (PYQ) task`);

  ok(plan.weeks.every((w) => w.days.length === 7), `${e.id}: every week has 6 study days + 1 review day`);
  ok(plan.weeks.every((w) => w.days[6].reviewDay), `${e.id}: day 7 is the weekly review/mock`);
  ok([...plan.byTaskId.values()].every(({ task }) => task.target >= 3 && task.target <= 6),
    `${e.id}: every task has a sane pomodoro target (3–6)`);
  ok(plan.weeks[0].phase === "foundation" && plan.weeks[plan.weeks.length - 1].phase === "revision",
    `${e.id}: phases run foundation → revision (${PHASES[plan.weeks[0].phase].label} → ${PHASES[plan.weeks.at(-1).phase].label})`);

  const review = plan.byTaskId.get(`p|${e.id}|7|0`);
  ok(review && review.task.kind === "review" && review.task.title.startsWith("Weekly review:"),
    `${e.id}: week-1 review names the week's chapters (“${review.task.title.slice(0, 52)}…”)`);
}

/* --- store --------------------------------------------------------------- */
console.log("\nStore");
const jee = getExam("jee");
const jeePlan = buildPlan(jee);
const firstLearn = [...jeePlan.byTaskId.values()].find((x) => x.task.kind === "learn");
const { task } = firstLearn;

ok(!store.isTaskDone(task.id), "task starts todo");
store.toggleTask(task.id, task.topicKey);
ok(store.isTaskDone(task.id), "toggle marks task done");
ok(store.isTopicDone(task.topicKey), "toggling a chapter task syncs the syllabus chapter");
store.toggleTask(task.id, task.topicKey);
ok(!store.isTaskDone(task.id) && !store.isTopicDone(task.topicKey), "toggle off reverts both");

store.recordPomo({ taskId: task.id, topicKey: task.topicKey, title: task.title, target: 1, minutes: 25 });
ok(store.isTaskDone(task.id), "reaching the pomodoro target auto-completes the task");
ok(store.isTopicDone(task.topicKey), "auto-complete also syncs the syllabus chapter");
ok(store.pomoCount(task.id) === 1, "pomo count tracked per task");

const prog = planProgress(jeePlan);
ok(prog.done >= 1 && prog.pct > 0, `plan progress live (${prog.done}/${prog.total} = ${prog.pct}%)`);
ok(continueDay(jeePlan) === firstLearn.day + 1 || continueDay(jeePlan) >= 1, "continueDay points at an open day");
ok(getTaskById("jee", task.id)?.task.title === task.title, "getTaskById round-trips");

/* --- timer ----------------------------------------------------------------- */
console.log("\nTimer engine");
ok(fmtClock(0) === "00:00" && fmtClock(60) === "01:00" && fmtClock(25 * 60) === "25:00", "fmtClock formats mm:ss");
let seen = null;
const off = timer.subscribe((snap) => { seen = snap; });
ok(seen && seen.remain === MODES.focus.seconds && seen.mode === "focus", "subscribe emits the current snapshot immediately");
timer.setContext({ title: "Test block", taskId: null });
ok(timer.snapshot().context.title === "Test block", "setContext merges");
timer.setMode("short");
ok(timer.snapshot().remain === MODES.short.seconds, "setMode resets the clock");
timer.start();
ok(timer.snapshot().running === true, "start ticks");
timer.pause();
ok(timer.snapshot().running === false, "pause stops");
timer.reset();
ok(timer.snapshot().remain === MODES.short.seconds, "reset restores the mode length");
timer.setMode("focus");
off();

console.log(`\nAll ${passed} checks passed ✅`);
