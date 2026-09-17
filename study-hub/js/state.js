const KEY = "tauntbuddy-study-v2";

const defaults = {
  done: {},
  pomos: [],
  lastCourse: null,
  lastExam: "jee"
};

export function load() {
  try {
    return { ...defaults, ...JSON.parse(localStorage.getItem(KEY) || "{}") };
  } catch {
    return { ...defaults };
  }
}

export function save(next) {
  localStorage.setItem(KEY, JSON.stringify(next));
}

export function toggleDone(state, id) {
  state.done[id] = !state.done[id];
  save(state);
}

export function topicId(examId, subject, unit, chapter) {
  return [examId, subject, unit, chapter].join("|");
}
