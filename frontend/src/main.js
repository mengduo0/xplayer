const API_BASE = '';

const player = document.getElementById('player');
const playlistEl = document.getElementById('playlist');
const playlistCountEl = document.getElementById('playlist-count');
const statusEl = document.getElementById('status');
const nowPlayingEl = document.getElementById('now-playing');

let videos = [];
let activeId = null;

async function checkHealth() {
  try {
    const res = await fetch(`${API_BASE}/api/health`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    statusEl.textContent = data.status === 'ok' ? '服务正常' : '服务异常';
    statusEl.className = 'status ok';
    return true;
  } catch (e) {
    statusEl.textContent = '未连接后端';
    statusEl.className = 'status err';
    return false;
  }
}

async function loadPlaylist() {
  const res = await fetch(`${API_BASE}/api/videos`);
  if (!res.ok) {
    throw new Error(`加载列表失败: HTTP ${res.status}`);
  }
  videos = await res.json();
  updatePlaylistCount();
  renderPlaylist();
  if (videos.length > 0) {
    playVideo(videos[0].id);
  }
}

function updatePlaylistCount() {
  if (playlistCountEl) {
    playlistCountEl.textContent = videos.length ? `${videos.length} 部` : '—';
  }
}

function renderPlaylist() {
  playlistEl.innerHTML = '';
  if (!videos.length) {
    playlistEl.innerHTML = '<li class="empty">暂无视频，请检查 MySQL 数据与 G:/mv 文件</li>';
    return;
  }
  videos.forEach((item, index) => {
    const li = document.createElement('li');
    li.dataset.id = String(item.id);
    li.innerHTML = `
      <span class="item-index">${index + 1}</span>
      <div class="item-body">
        <span class="title">${escapeHtml(item.title)}</span>
        <span class="meta">${escapeHtml(item.fileName)}</span>
      </div>
    `;
    li.addEventListener('click', () => playVideo(item.id));
    if (item.id === activeId) {
      li.classList.add('active');
    }
    playlistEl.appendChild(li);
  });
}

function scrollActiveIntoView() {
  const active = playlistEl.querySelector('li.active');
  if (active) {
    active.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  }
}

function playVideo(id) {
  const item = videos.find((v) => v.id === id);
  if (!item) return;
  activeId = id;
  const url = `${API_BASE}${item.streamUrl}`;
  player.src = url;
  player.load();
  player.play().catch(() => {});
  nowPlayingEl.textContent = item.title;
  renderPlaylist();
  scrollActiveIntoView();
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text ?? '';
  return div.innerHTML;
}

async function init() {
  await checkHealth();
  try {
    await loadPlaylist();
  } catch (e) {
    playlistEl.innerHTML = `<li class="empty">${escapeHtml(e.message)}</li>`;
    statusEl.textContent = '加载失败';
    statusEl.className = 'status err';
    updatePlaylistCount();
  }
}

init();
