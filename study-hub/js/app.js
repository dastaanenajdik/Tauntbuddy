import { renderHome, renderCourses, renderCourse, renderPlanner, renderPomodoro } from "./views.js";

const root = document.getElementById("view");
const nav = document.querySelectorAll("[data-nav]");

function setActive(hash) {
  nav.forEach((a) => {
    const h = a.getAttribute("href");
    a.classList.toggle("active", hash.startsWith(h.replace("#", "")) || (h === "#/" && (hash === "/" || hash === "")));
  });
}

function route() {
  const raw = location.hash.slice(1) || "/";
  const [path, qs] = raw.split("?");
  setActive(path);
  if (path === "/" || path === "") return renderHome(root);
  if (path === "/courses") return renderCourses(root);
  if (path.startsWith("/course/")) return renderCourse(root, path.split("/")[2]);
  if (path.startsWith("/planner")) return renderPlanner(root, path.split("/")[2]);
  if (path.startsWith("/pomodoro")) return renderPomodoro(root, qs || "");
  renderHome(root);
}

window.addEventListener("hashchange", route);
route();
