// ---------------------------------------------------------------------------
// App bootstrap · registers routes, mounts the live "running session" strip
// in the topbar, and starts the router. Views live in features/*, one screen
// per module; shared engine/state in store.js + the pomodoro singleton.
// ---------------------------------------------------------------------------

import { addRoute, startRouter, navigate } from "./router.js";
import { homeView } from "./features/home/home.view.js";
import { coursesView } from "./features/courses/courses.view.js";
import { courseDetailView } from "./features/courses/course-detail.view.js";
import { plannerView } from "./features/planner/planner.view.js";
import { pomodoroView } from "./features/pomodoro/pomodoro.view.js";
import { timer, fmtClock } from "./features/pomodoro/timer.js";

addRoute("/", homeView);
addRoute("/courses", coursesView);
addRoute("/course/:id", courseDetailView);
addRoute("/planner", plannerView);
addRoute("/planner/:id", plannerView);
addRoute("/pomodoro", pomodoroView);

/* Running-session strip — one subscription for the entire shell. */
const strip = document.getElementById("timeStrip");
const stripClock = document.getElementById("timeStripClock");
const stripLabel = document.getElementById("timeStripLabel");

timer.subscribe((snap) => {
  strip.hidden = !snap.running;
  if (snap.running) {
    stripClock.textContent = fmtClock(snap.remain);
    const c = snap.context;
    stripLabel.textContent = c.chapter || (c.title && c.title !== "Free focus" ? c.title : "Focus");
  }
});
strip.addEventListener("click", () => navigate("#/pomodoro"));

startRouter(document.getElementById("view"));
