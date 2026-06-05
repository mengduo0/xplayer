const STORAGE_KEY = 'xplayer-theme';
const THEMES = ['light', 'aurora'];

export function getTheme() {
  return document.documentElement.getAttribute('data-theme') || 'light';
}

function updateToggleUI() {
  const btn = document.getElementById('theme-toggle');
  if (!btn) return;
  const isAurora = getTheme() === 'aurora';
  btn.setAttribute('aria-label', isAurora ? '切换到浅色主题' : '切换到极光主题');
  btn.title = isAurora ? '浅色模式' : '极光模式';
  btn.dataset.theme = getTheme();
}

export function setTheme(theme, { persist = true } = {}) {
  const next = THEMES.includes(theme) ? theme : 'light';
  document.documentElement.setAttribute('data-theme', next);
  if (persist) {
    localStorage.setItem(STORAGE_KEY, next);
  }
  updateToggleUI();
  document.dispatchEvent(new CustomEvent('xplayer-theme-change', { detail: { theme: next } }));
}

export function toggleTheme() {
  setTheme(getTheme() === 'light' ? 'aurora' : 'light');
}

export function initTheme() {
  const saved = localStorage.getItem(STORAGE_KEY);
  setTheme(saved === 'aurora' ? 'aurora' : 'light', { persist: false });
  const btn = document.getElementById('theme-toggle');
  if (btn) {
    btn.addEventListener('click', toggleTheme);
  }
}
