// ---------------------------------------------------------------------------
// Plan generator · turns an exam syllabus (subjects → units → chapters) into
// a fully structured, day-by-day study plan:
//
//   Phase 1  Foundation        every chapter once, in syllabus order
//   Phase 2  Mastery & PYQs    second pass — timed practice per chapter
//   Phase 3  Revision & Mocks  subject-wise rapid revision, sectional & full mocks
//
// Six study days per week; day 7 is a weekly review (foundation/mastery
// weeks) or a full mock (revision weeks). Every task carries a Pomodoro
// target so progress can be tracked per study block.
//
// Pure + deterministic — results are memoised per exam id.
// ---------------------------------------------------------------------------

import { flattenTopics, getExam } from "../../../data/exams.js";
import * as store from "../../store.js";

const cache = new Map();

export const PHASES = {
  foundation: { label: "Foundation", desc: "First pass — cover each chapter once" },
  mastery: { label: "Mastery & PYQs", desc: "Second pass — practice till it sticks" },
  revision: { label: "Revision & Mocks", desc: "Rapid revision + full-length mocks" }
};

const NOTES = {
  learn: "Concepts → NCERT/standard text → short notes + in-text examples",
  practice: "Previous-year questions + a timed problem set",
  revision: "Recall sheets, formula map, spaced recall of weak spots",
  review: "Re-read notes, self-quiz, mark weak chapters for revision",
  mock: "Attempt in one sitting, then log every mistake"
};

const TARGETS = { learn: 4, practice: 3, revision: 3, review: 4, mock: 6 };

const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, n));

function chunk(list, parts) {
  // Split list into `parts` near-equal contiguous slices (some may be empty).
  const per = Math.ceil(list.length / parts) || 1;
  const out = [];
  for (let i = 0; i < parts; i++) out.push(list.slice(i * per, (i + 1) * per));
  return out;
}

function phaseForStudyIndex(i, nF, nM) {
  if (i < nF) return "foundation";
  if (i < nF + nM) return "mastery";
  return "revision";
}

export function buildPlan(exam) {
  if (!exam) return null;
  if (cache.has(exam.id)) return cache.get(exam.id);

  const topics = flattenTopics(exam);
  const weeks = clamp(Math.round(exam.months * 1.2), 8, 16);
  const studyDays = weeks * 6;                       // day 7 = weekly review
  const nF = Math.ceil(studyDays * 0.55);
  const nM = Math.floor(studyDays * 0.30);
  const nR = studyDays - nF - nM;
  const subjectNames = exam.subjects.map((s) => s.name);
  const S = exam.subjects.length;

  /* ---- fill the 6 study-day slots of each week ---------------------------- */
  const studyDayTasks = Array.from({ length: studyDays }, () => []);

  // Phase 1 — Foundation: every chapter once.
  const foundationChunks = chunk(topics, nF);
  foundationChunks.forEach((slice, d) => {
    slice.forEach((t) => {
      studyDayTasks[d].push({
        kind: "learn",
        title: t.chapter,
        subject: t.subject,
        unit: t.unit,
        topicKey: store.topicKey(exam.id, t.subject, t.unit, t.chapter)
      });
    });
  });

  // Phase 2 — Mastery: every chapter again, as timed practice.
  const masteryChunks = chunk(topics, nM);
  masteryChunks.forEach((slice, d) => {
    slice.forEach((t) => {
      studyDayTasks[nF + d].push({
        kind: "practice",
        title: `${t.chapter} — PYQs & practice`,
        subject: t.subject,
        unit: t.unit,
        topicKey: store.topicKey(exam.id, t.subject, t.unit, t.chapter)
      });
    });
  });

  // Phase 3 — Revision & mocks: subject-cycled rapid revision, sectional
  // tests, finishing with a full mock and a final error-log pass.
  for (let j = 0; j < nR; j++) {
    const dayIdx = nF + nM + j;
    const si = j % S;
    const subject = exam.subjects[si];
    const unitWindow = subject.units
      .slice((Math.floor(j / S) * 3) % subject.units.length)
      .concat(subject.units)
      .slice(0, 3)
      .map((u) => u.name);
    const moreUnits = subject.units.length - unitWindow.length;

    if (j === nR - 2) {
      studyDayTasks[dayIdx].push({
        kind: "mock",
        title: "Full syllabus mock (timed, exam conditions)",
        subject: "All subjects",
        unit: "Full paper"
      });
      studyDayTasks[dayIdx].push({
        kind: "mock",
        title: "Mock analysis: log every error & revisit solutions",
        subject: "All subjects",
        unit: "Error log"
      });
    } else if (j === nR - 1) {
      studyDayTasks[dayIdx].push({
        kind: "revision",
        title: "Error log, formula sheet & weak-area final pass",
        subject: "All subjects",
        unit: "Final polish"
      });
    } else if (j % 2 === 1) {
      studyDayTasks[dayIdx].push({
        kind: "mock",
        title: `Sectional test: ${subject.name}`,
        subject: subject.name,
        unit: "Timed section"
      });
    } else {
      studyDayTasks[dayIdx].push({
        kind: "revision",
        title: `Rapid revision — ${subject.name}: ${unitWindow.join(", ")}${moreUnits > 0 ? ` +${moreUnits} more units` : ""}`,
        subject: subject.name,
        unit: "Spaced recall"
      });
    }
  }

  /* ---- assemble weeks (6 study days + 1 review/mock day) ------------------ */
  const planWeeks = [];
  const byTaskId = new Map();
  let totalTasks = 0;
  let totalTargetPomos = 0;

  for (let w = 1; w <= weeks; w++) {
    const days = [];
    const weekPhase = phaseForStudyIndex((w - 1) * 6, nF, nM);

    for (let d = 1; d <= 6; d++) {
      const studyIdx = (w - 1) * 6 + (d - 1);
      const dayGlobal = (w - 1) * 7 + d;
      const phase = phaseForStudyIndex(studyIdx, nF, nM);
      const taskIds = [];
      const tasks = studyDayTasks[studyIdx].map((raw, i) => {
        const task = {
          ...raw,
          id: `p|${exam.id}|${dayGlobal}|${i}`,
          target: TARGETS[raw.kind],
          note: NOTES[raw.kind]
        };
        byTaskId.set(task.id, { task, day: dayGlobal, week: w, phase });
        taskIds.push(task.id);
        totalTasks++;
        totalTargetPomos += task.target;
        return task;
      });
      days.push({ num: dayGlobal, week: w, phase, tasks, taskIds, reviewDay: false });
    }

    // Day 7 — weekly review (foundation/mastery weeks) or full mock (revision).
    const reviewDayNum = w * 7;
    const weekChapterTitles = days
      .flatMap((day) => day.tasks)
      .filter((t) => t.kind === "learn" || t.kind === "practice")
      .map((t) => t.title.replace(/ — PYQs & practice$/, ""));
    const named = weekChapterTitles.slice(0, 3);
    const rest = weekChapterTitles.length - named.length;

    const isMockWeek = weekPhase === "revision";
    const weekly = {
      kind: isMockWeek ? "mock" : "review",
      title: isMockWeek
        ? "Full-length mock (timed) + error-log session"
        : weekChapterTitles.length
          ? `Weekly review: ${named.join("; ")}${rest > 0 ? ` +${rest} more` : ""}`
          : "Weekly review: consolidated recall of the week",
      subject: isMockWeek ? "All subjects" : "This week's chapters",
      unit: isMockWeek ? "Full paper" : "Weekly checkpoint"
    };
    const weeklyTask = {
      ...weekly,
      id: `p|${exam.id}|${reviewDayNum}|0`,
      target: TARGETS[isMockWeek ? "mock" : "review"],
      note: NOTES[isMockWeek ? "mock" : "review"]
    };
    byTaskId.set(weeklyTask.id, { task: weeklyTask, day: reviewDayNum, week: w, phase: weekPhase });
    totalTasks++;
    totalTargetPomos += weeklyTask.target;
    days.push({ num: reviewDayNum, week: w, phase: weekPhase, tasks: [weeklyTask], taskIds: [weeklyTask.id], reviewDay: true });

    planWeeks.push({ n: w, phase: weekPhase, days });
  }

  const plan = {
    examId: exam.id,
    examName: exam.name,
    weeks: planWeeks,
    totals: {
      weeks,
      days: weeks * 7,
      tasks: totalTasks,
      targetPomos: totalTargetPomos,
      estHours: Math.round(((totalTargetPomos * 25) / 60) * 10) / 10,
      chapters: topics.length
    },
    byTaskId,
    flatTaskIds: [...byTaskId.keys()]
  };
  cache.set(exam.id, plan);
  return plan;
}

export function getPlanByExamId(examId) {
  const exam = getExam(examId);
  return exam ? buildPlan(exam) : null;
}

export function getTaskById(examId, taskId) {
  const plan = getPlanByExamId(examId);
  return plan ? plan.byTaskId.get(taskId) || null : null;
}

/** First day (global number) that still has unfinished tasks. */
export function continueDay(plan) {
  for (const id of plan.flatTaskIds) {
    if (!store.isTaskDone(id)) return plan.byTaskId.get(id).day;
  }
  return plan.totals.days;
}

/** Plan-level completion using live store state. */
export function planProgress(plan) {
  let done = 0;
  let pomos = 0, pomoTarget = 0;
  for (const [id, { task }] of plan.byTaskId) {
    if (store.isTaskDone(id)) done++;
    pomos += Math.min(store.pomoCount(id), task.target);
    pomoTarget += task.target;
  }
  const total = plan.totals.tasks;
  return {
    done, total,
    pct: total ? Math.round((done / total) * 100) : 0,
    pomos, pomoTarget
  };
}

/** Week-level completion using live store state. */
export function weekProgress(week) {
  const ids = week.days.flatMap((d) => d.taskIds);
  const done = ids.filter((id) => store.isTaskDone(id)).length;
  return { done, total: ids.length, pct: ids.length ? Math.round((done / ids.length) * 100) : 0 };
}
