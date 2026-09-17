// ---------------------------------------------------------------------------
// Hash router · pattern routes ("/course/:id"), per-view cleanup hooks,
// nav highlighting. Views return an optional cleanup() used to unsubscribe
// listeners and unmount widgets between screens.
// ---------------------------------------------------------------------------

const routes = [];
let rootEl = null;
let cleanup = null;

export function addRoute(pattern, handler) {
  const keys = [];
  // Split on ":param" (captured names land at odd indices), escape only the
  // literal segments, then splice capture groups back in.
  const parts = pattern.split(/:([A-Za-z]+)/g);
  let source = "^";
  parts.forEach((seg, i) => {
    if (i % 2 === 0) {
      source += seg.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    } else {
      keys.push(seg);
      source += "([^/]+)";
    }
  });
  source += "$";
  routes.push({ rx: new RegExp(source), keys, handler, pattern });
}

function setActiveNav(path) {
  document.querySelectorAll("[data-nav]").forEach((a) => {
    const hrefPath = (a.getAttribute("href") || "#/").replace("#", "");
    const active =
      hrefPath === "/" ? path === "/" : path === hrefPath || path.startsWith(hrefPath + "/");
    a.classList.toggle("active", active);
  });
}

function dispatch() {
  const raw = location.hash.slice(1) || "/";
  const [path = "/", qs = ""] = raw.split("?");
  const query = Object.fromEntries(new URLSearchParams(qs));

  for (const r of routes) {
    const m = r.rx.exec(path);
    if (!m) continue;
    const params = {};
    r.keys.forEach((k, i) => (params[k] = decodeURIComponent(m[i + 1] || "")));

    try { cleanup?.(); } catch { /* never let one view block navigation */ }
    cleanup = r.handler(rootEl, params, query) || null;
    // Keep the landing page's visual treatment untouched while giving every
    // routed detail page one reliable styling hook. This also covers nested
    // routes such as course/:id and planner/:exam without maintaining a list.
    rootEl.classList.toggle("view-home", path === "/");
    rootEl.classList.toggle("view-inner", path !== "/");
    rootEl.dataset.route = path;
    setActiveNav(path);
    window.scrollTo({ top: 0, behavior: "instant" in window ? "instant" : "auto" });
    return;
  }
  // Unknown route → home.
  if (path !== "/") location.hash = "#/";
}

export function startRouter(root) {
  rootEl = root;
  window.addEventListener("hashchange", dispatch);
  dispatch();
}

export function navigate(hash) {
  if (location.hash === hash) dispatch();
  else location.hash = hash;
}
