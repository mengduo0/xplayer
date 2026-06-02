const API_BASE = '';

const player = document.getElementById('player');
const playlistEl = document.getElementById('playlist');
const playlistCountEl = document.getElementById('playlist-count');
const statusEl = document.getElementById('status');
const nowPlayingEl = document.getElementById('now-playing');
const addErrorEl = document.getElementById('add-error');
const localFileInput = document.getElementById('local-file-input');
const openLocalBtn = document.getElementById('open-local-btn');
const addLocalBtn = document.getElementById('add-local-btn');

let videos = [];
let activeId = null;
let initialLoadDone = false;
let localBlobUrl = null;
let currentLocalFile = null;

function revokeLocalBlob() {
  if (localBlobUrl) {
    URL.revokeObjectURL(localBlobUrl);
    localBlobUrl = null;
  }
}

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

async function loadPlaylist(autoPlayFirst = false) {
  const res = await fetch(`${API_BASE}/api/videos`);
  if (!res.ok) {
    throw new Error(`加载列表失败: HTTP ${res.status}`);
  }
  videos = await res.json();
  updatePlaylistCount();
  renderPlaylist();

  if (videos.length === 0) {
    if (!currentLocalFile) {
      activeId = null;
      revokeLocalBlob();
      player.removeAttribute('src');
      nowPlayingEl.textContent = '请选择列表中的视频';
    }
    return;
  }

  const stillExists = videos.some((v) => v.id === activeId);
  if (!stillExists) {
    activeId = null;
  }

  if ((autoPlayFirst || !stillExists) && !currentLocalFile) {
    playVideo(videos[0].id);
  }
}

function updatePlaylistCount() {
  if (playlistCountEl) {
    playlistCountEl.textContent = videos.length ? `${videos.length} 部` : '—';
  }
}

function showAddError(message) {
  if (!addErrorEl) return;
  if (message) {
    addErrorEl.textContent = message;
    addErrorEl.hidden = false;
  } else {
    addErrorEl.textContent = '';
    addErrorEl.hidden = true;
  }
}

function renderPlaylist() {
  playlistEl.innerHTML = '';
  if (!videos.length) {
    playlistEl.innerHTML = '<li class="empty">列表为空</li>';
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
      <button type="button" class="btn-delete" data-testid="delete-video" title="从列表移除" aria-label="删除">×</button>
    `;
    li.querySelector('.item-body').addEventListener('click', () => playVideo(item.id));
    li.querySelector('.btn-delete').addEventListener('click', (e) => {
      e.stopPropagation();
      deleteVideo(item.id);
    });
    if (item.id === activeId && !currentLocalFile) {
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

function playLocalFile(file) {
  if (!file) return;
  revokeLocalBlob();
  currentLocalFile = file;
  activeId = null;
  localBlobUrl = URL.createObjectURL(file);
  player.src = localBlobUrl;
  player.load();
  player.play().catch(() => {});
  const baseName = file.name.replace(/\.[^.]+$/, '');
  nowPlayingEl.textContent = `${baseName}（本地文件）`;
  if (addLocalBtn) {
    addLocalBtn.disabled = false;
  }
  renderPlaylist();
}

function playVideo(id) {
  const item = videos.find((v) => v.id === id);
  if (!item) return;
  currentLocalFile = null;
  if (addLocalBtn) {
    addLocalBtn.disabled = true;
  }
  revokeLocalBlob();
  activeId = id;
  const url = `${API_BASE}${item.streamUrl}`;
  player.src = url;
  player.load();
  player.play().catch(() => {});
  nowPlayingEl.textContent = item.title;
  renderPlaylist();
  scrollActiveIntoView();
}

async function addVideo(fileName, title) {
  const body = { fileName: fileName.trim() };
  if (title && title.trim()) {
    body.title = title.trim();
  }
  const res = await fetch(`${API_BASE}/api/videos`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || `添加失败: HTTP ${res.status}`);
  }
  return data;
}

async function deleteVideo(id) {
  const res = await fetch(`${API_BASE}/api/videos/${id}`, { method: 'DELETE' });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || `删除失败: HTTP ${res.status}`);
  }
  await loadPlaylist(false);
}

openLocalBtn.addEventListener('click', () => {
  showAddError('');
  localFileInput.click();
});

localFileInput.addEventListener('change', () => {
  const file = localFileInput.files && localFileInput.files[0];
  localFileInput.value = '';
  if (file) {
    playLocalFile(file);
  }
});

addLocalBtn.addEventListener('click', async () => {
  if (!currentLocalFile) return;
  showAddError('');
  const title = currentLocalFile.name.replace(/\.[^.]+$/, '');
  try {
    const created = await addVideo(currentLocalFile.name, title);
    currentLocalFile = null;
    if (addLocalBtn) {
      addLocalBtn.disabled = true;
    }
    await loadPlaylist(false);
    playVideo(created.id);
  } catch (err) {
    showAddError(
      `${err.message}（仅能将 G:/mv 目录下已存在的同名文件加入列表）`
    );
  }
});

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text ?? '';
  return div.innerHTML;
}

async function init() {
  await checkHealth();
  try {
    await loadPlaylist(!initialLoadDone);
    initialLoadDone = true;
  } catch (e) {
    playlistEl.innerHTML = `<li class="empty">${escapeHtml(e.message)}</li>`;
    statusEl.textContent = '加载失败';
    statusEl.className = 'status err';
    updatePlaylistCount();
  }
}

init();
