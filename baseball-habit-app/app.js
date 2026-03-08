'use strict';

// ===== Storage =====
const STORAGE_KEY = 'baseballHabitApp_v1';

function loadData() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : { goals: [] };
  } catch (_) {
    return { goals: [] };
  }
}

function saveData(data) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch (_) {}
}

// ===== State =====
let state = loadData();

// ===== Helpers =====
function today() {
  return new Date().toISOString().split('T')[0];
}

function calcStreak(records) {
  if (!records.length) return 0;
  const sorted = [...records].sort();
  let streak = 0;
  const d = new Date();
  for (let i = 0; i < 365; i++) {
    const s = d.toISOString().split('T')[0];
    if (sorted.includes(s)) {
      streak++;
      d.setDate(d.getDate() - 1);
    } else {
      break;
    }
  }
  return streak;
}

function calcRate(records, targetDays) {
  return Math.min(100, Math.round((records.length / targetDays) * 100));
}

function weeklyDoneCount() {
  const d = new Date();
  const dayOfWeek = d.getDay(); // 0=Sun
  const weekStart = new Date(d);
  weekStart.setDate(d.getDate() - dayOfWeek);
  weekStart.setHours(0, 0, 0, 0);

  let count = 0;
  state.goals.forEach(g => {
    g.records.forEach(r => {
      const rd = new Date(r);
      rd.setHours(12, 0, 0, 0);
      if (rd >= weekStart && rd <= d) count++;
    });
  });
  return count;
}

// ===== Tab switching =====
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

tabBtns.forEach(btn => {
  btn.addEventListener('click', () => {
    const target = btn.dataset.tab;
    tabBtns.forEach(b => b.classList.toggle('active', b.dataset.tab === target));
    tabContents.forEach(c => c.classList.toggle('active', c.id === 'tab-' + target));
    if (target === 'record') renderRecordTab();
    if (target === 'board') renderBoard();
  });
});

// ===== Goal Tab =====
document.getElementById('btn-add-goal').addEventListener('click', () => {
  const name    = document.getElementById('goal-name').value.trim();
  const days    = parseInt(document.getElementById('goal-days').value, 10);
  const cat     = document.getElementById('goal-cat').value;
  if (!name || !days || days < 1) return;

  state.goals.push({
    id: Date.now().toString(),
    name,
    targetDays: days,
    category: cat,
    records: [],
    createdAt: today(),
  });
  saveData(state);

  document.getElementById('goal-name').value = '';
  document.getElementById('goal-days').value = '30';
  renderGoalTab();
});

function renderGoalTab() {
  const list    = document.getElementById('goal-list');
  const section = document.getElementById('goal-list-section');
  const empty   = document.getElementById('goal-empty');

  if (!state.goals.length) {
    section.classList.add('hidden');
    empty.classList.remove('hidden');
    return;
  }
  section.classList.remove('hidden');
  empty.classList.add('hidden');

  list.innerHTML = state.goals.map(g => {
    const rate = calcRate(g.records, g.targetDays);
    const streak = calcStreak(g.records);
    return `
      <div class="goal-card">
        <div class="goal-card-top">
          <span class="cat-badge">${g.category}</span>
          <button class="del-btn" data-id="${g.id}" aria-label="削除">✕</button>
        </div>
        <div class="goal-name">${escHtml(g.name)}</div>
        <div class="goal-meta">目標: ${g.targetDays}日 ／ 🔥${streak}日連続</div>
        <div class="prog-wrap">
          <div class="prog-bg"><div class="prog-fill" style="width:${rate}%"></div></div>
          <span class="prog-text">${g.records.length} / ${g.targetDays}日</span>
        </div>
      </div>
    `;
  }).join('');

  list.querySelectorAll('.del-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      state.goals = state.goals.filter(g => g.id !== btn.dataset.id);
      saveData(state);
      renderGoalTab();
    });
  });
}

// ===== Record Tab =====
const recordDateEl = document.getElementById('record-date');
recordDateEl.value = today();
recordDateEl.addEventListener('change', renderChecklist);

document.getElementById('btn-go-goal').addEventListener('click', () => {
  document.querySelector('[data-tab="goal"]').click();
});

function renderRecordTab() {
  const hasGoals = document.getElementById('record-has-goals');
  const noGoals  = document.getElementById('record-no-goals');
  if (!state.goals.length) {
    hasGoals.classList.add('hidden');
    noGoals.classList.remove('hidden');
    return;
  }
  hasGoals.classList.remove('hidden');
  noGoals.classList.add('hidden');
  renderChecklist();
}

function renderChecklist() {
  const date     = recordDateEl.value;
  const checklist = document.getElementById('checklist');
  checklist.innerHTML = state.goals.map(g => {
    const done = g.records.includes(date);
    const streak = calcStreak(g.records);
    return `
      <div class="check-item">
        <div class="check-left">
          <input type="checkbox" id="chk-${g.id}" data-id="${g.id}" ${done ? 'checked' : ''} />
          <label class="check-label" for="chk-${g.id}">${escHtml(g.name)}</label>
        </div>
        <span class="streak-tag">🔥${streak}連続</span>
      </div>
    `;
  }).join('');
}

document.getElementById('btn-save-record').addEventListener('click', () => {
  const date = recordDateEl.value;
  const checkboxes = document.querySelectorAll('#checklist input[type="checkbox"]');

  checkboxes.forEach(cb => {
    const id = cb.dataset.id;
    const goal = state.goals.find(g => g.id === id);
    if (!goal) return;
    if (cb.checked) {
      if (!goal.records.includes(date)) goal.records.push(date);
    } else {
      goal.records = goal.records.filter(r => r !== date);
    }
  });

  saveData(state);
  renderChecklist();

  const msg = document.getElementById('save-msg');
  msg.classList.remove('hidden');
  setTimeout(() => msg.classList.add('hidden'), 3000);
});

// ===== Scoreboard Tab =====
function renderBoard() {
  // Stats
  const totalGoals = state.goals.length;
  const totalDays  = state.goals.reduce((s, g) => s + g.records.length, 0);
  const bestStreak = state.goals.length
    ? Math.max(...state.goals.map(g => calcStreak(g.records)))
    : 0;
  const avgRate = state.goals.length
    ? Math.round(state.goals.reduce((s, g) => s + calcRate(g.records, g.targetDays), 0) / state.goals.length)
    : 0;

  document.getElementById('stat-goals').textContent  = totalGoals;
  document.getElementById('stat-days').textContent   = totalDays;
  document.getElementById('stat-streak').textContent = bestStreak;
  document.getElementById('stat-rate').textContent   = avgRate + '%';

  // Diamond
  const wc = weeklyDoneCount();
  toggleBase('base-1st',  wc >= 3);
  toggleBase('base-2nd',  wc >= 6);
  toggleBase('base-3rd',  wc >= 9);
  toggleBase('base-home', wc >= 12);

  const msgs = [
    'まだ今週の記録がありません。バッターボックスへ！',
    '1塁！ナイスバッティング！',
    '2塁！もう少しで得点圏！',
    '3塁！あとひとつ！',
    'ホームイン！今週も完璧！🎉',
  ];
  const msgIdx = wc >= 12 ? 4 : wc >= 9 ? 3 : wc >= 6 ? 2 : wc >= 3 ? 1 : 0;
  document.getElementById('diamond-msg').textContent = msgs[msgIdx];

  // Per-goal list
  const boardList = document.getElementById('board-goal-list');
  if (!state.goals.length) {
    boardList.innerHTML = '';
    return;
  }
  boardList.innerHTML = state.goals.map(g => {
    const rate   = calcRate(g.records, g.targetDays);
    const streak = calcStreak(g.records);
    return `
      <div class="goal-stat-item">
        <div class="gsi-top">
          <span class="gsi-name">${escHtml(g.name)}</span>
          <span class="gsi-rate">${rate}%</span>
        </div>
        <div class="batting-bg"><div class="batting-fill" style="width:${rate}%"></div></div>
        <div class="gsi-detail">
          <span>記録: ${g.records.length}日 / ${g.targetDays}日</span>
          <span>🔥 ${streak}日連続</span>
        </div>
      </div>
    `;
  }).join('');
}

function toggleBase(id, active) {
  document.getElementById(id).classList.toggle('active', active);
}

// ===== Utility =====
function escHtml(s) {
  return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ===== Init =====
renderGoalTab();
