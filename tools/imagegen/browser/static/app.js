const state = {
  manifest: null,
  filtered: [],
  selectedId: null,
};

const imageExts = new Set(['.png', '.jpg', '.jpeg', '.webp', '.gif']);

function fileUrl(path) {
  return `/file?path=${encodeURIComponent(path)}`;
}

function ext(path) {
  const i = path.lastIndexOf('.');
  return i >= 0 ? path.slice(i).toLowerCase() : '';
}

function previewPath(asset) {
  const candidates = [];
  if (asset.selectedFile?.path) candidates.push(asset.selectedFile.path);
  for (const ref of asset.sourceFiles || []) candidates.push(ref.path);
  if (asset.runtimeDerivative?.path) candidates.push(asset.runtimeDerivative.path);
  for (const path of candidates) {
    if (imageExts.has(ext(path))) return path;
  }
  return null;
}

async function pathExists(path) {
  try {
    const resp = await fetch(fileUrl(path), { method: 'HEAD' });
    return resp.ok;
  } catch {
    return false;
  }
}

function fillSelect(select, values) {
  const current = select.value;
  for (const value of values) {
    const opt = document.createElement('option');
    opt.value = value;
    opt.textContent = value;
    select.appendChild(opt);
  }
  select.value = current;
}

function badge(text, cls='') {
  const span = document.createElement('span');
  span.className = `badge ${cls}`.trim();
  span.textContent = text;
  return span;
}

function matchesSearch(asset, q) {
  if (!q) return true;
  const hay = [
    asset.title,
    asset.id,
    asset.purpose?.subject,
    asset.purpose?.intent,
    asset.prompt?.text,
    ...(asset.tags || []),
  ].filter(Boolean).join(' ').toLowerCase();
  return hay.includes(q);
}

async function applyFilters() {
  const q = document.getElementById('searchInput').value.trim().toLowerCase();
  const status = document.getElementById('statusFilter').value;
  const tool = document.getElementById('toolFilter').value;
  const phase = document.getElementById('phaseFilter').value;
  const category = document.getElementById('categoryFilter').value;
  const hasSelected = document.getElementById('hasSelectedFilter').checked;
  const hasRuntime = document.getElementById('hasRuntimeFilter').checked;
  const missingOnly = document.getElementById('missingOnlyFilter').checked;

  let items = state.manifest.assets.filter(a => {
    if (!matchesSearch(a, q)) return false;
    if (status && a.status !== status) return false;
    if (tool && a.generator?.tool !== tool) return false;
    if (phase && a.purpose?.phase !== phase) return false;
    if (category && a.purpose?.category !== category) return false;
    if (hasSelected && !a.selectedFile) return false;
    if (hasRuntime && !a.runtimeDerivative) return false;
    return true;
  });

  if (missingOnly) {
    const checks = await Promise.all(items.map(async a => {
      const refs = [];
      if (a.selectedFile?.path) refs.push(a.selectedFile.path);
      if (a.runtimeDerivative?.path) refs.push(a.runtimeDerivative.path);
      for (const src of a.sourceFiles || []) refs.push(src.path);
      if (!refs.length) return true;
      const exists = await Promise.all(refs.map(pathExists));
      return exists.includes(false);
    }));
    items = items.filter((_, i) => checks[i]);
  }

  items.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
  state.filtered = items;
  renderGrid();
  renderSummary();
}

function renderSummary() {
  const panel = document.getElementById('summaryPanel');
  const all = state.manifest.assets;
  const filtered = state.filtered;
  const byStatus = {};
  for (const item of filtered) byStatus[item.status] = (byStatus[item.status] || 0) + 1;

  panel.innerHTML = '';
  const total = document.createElement('div');
  total.className = 'summaryBlock';
  total.innerHTML = `<h2>Summary</h2><p><strong>${filtered.length}</strong> / ${all.length} shown</p>`;
  panel.appendChild(total);

  const status = document.createElement('div');
  status.className = 'summaryBlock';
  status.innerHTML = '<h3>Status counts</h3>';
  for (const [k, v] of Object.entries(byStatus).sort()) {
    const p = document.createElement('p');
    p.textContent = `${k}: ${v}`;
    status.appendChild(p);
  }
  panel.appendChild(status);
}

function renderGrid() {
  const grid = document.getElementById('grid');
  const count = document.getElementById('resultCount');
  const tpl = document.getElementById('cardTemplate');
  grid.innerHTML = '';
  count.textContent = `${state.filtered.length} assets`;

  for (const asset of state.filtered) {
    const node = tpl.content.firstElementChild.cloneNode(true);
    const img = node.querySelector('.thumb');
    const preview = previewPath(asset);
    if (preview) {
      img.src = fileUrl(preview);
      img.alt = asset.title;
    } else {
      img.replaceWith(Object.assign(document.createElement('div'), { className: 'thumb placeholder', textContent: 'No preview' }));
    }
    node.querySelector('.title').textContent = asset.title;
    node.querySelector('.purpose').textContent = asset.purpose.intent;
    const badges = node.querySelector('.badges');
    badges.append(
      badge(asset.status, `status-${asset.status}`),
      badge(asset.generator.tool),
      badge(asset.purpose.phase),
      badge(asset.purpose.category),
    );
    node.addEventListener('click', () => {
      state.selectedId = asset.id;
      renderDetail(asset);
      document.querySelectorAll('.card.selected').forEach(el => el.classList.remove('selected'));
      node.classList.add('selected');
    });
    grid.appendChild(node);
  }
}

function linkList(title, refs) {
  if (!refs || !refs.length) return `<h4>${title}</h4><p class="muted">None</p>`;
  return `<h4>${title}</h4><ul>${refs.map(ref => `<li><a href="${fileUrl(ref.path)}" target="_blank">${ref.label || ref.path}</a></li>`).join('')}</ul>`;
}

function renderDetail(asset) {
  const panel = document.getElementById('detailPanel');
  const preview = previewPath(asset);
  panel.innerHTML = `
    <h2>${asset.title}</h2>
    <div class="detailBadges"></div>
    ${preview ? `<img class="detailImage" src="${fileUrl(preview)}" alt="${asset.title}">` : '<div class="detailPlaceholder">No preview file</div>'}
    <h3>Purpose</h3>
    <p><strong>Subject:</strong> ${asset.purpose.subject}</p>
    <p><strong>Intent:</strong> ${asset.purpose.intent}</p>
    <p><strong>Backlog:</strong> ${asset.purpose.backlogRef || '—'}</p>
    <h3>Prompt</h3>
    <pre class="promptBox">${asset.prompt.text}</pre>
    ${asset.prompt.negativeText ? `<h4>Negative Prompt</h4><pre class="promptBox small">${asset.prompt.negativeText}</pre>` : ''}
    <h3>Generator</h3>
    <p><strong>Tool:</strong> ${asset.generator.tool}</p>
    <p><strong>Workflow:</strong> ${asset.generator.workflow || '—'}</p>
    <p><strong>Model:</strong> ${asset.generator.model || '—'}</p>
    ${asset.generator.metadataPath ? `<p><strong>Metadata:</strong> <a href="${fileUrl(asset.generator.metadataPath)}" target="_blank">${asset.generator.metadataPath}</a></p>` : ''}
    ${linkList('Source Files', asset.sourceFiles)}
    ${asset.selectedFile ? linkList('Selected File', [asset.selectedFile]) : '<h4>Selected File</h4><p class="muted">None</p>'}
    ${asset.runtimeDerivative ? linkList('Runtime Derivative', [asset.runtimeDerivative]) : '<h4>Runtime Derivative</h4><p class="muted">None</p>'}
    <h3>Notes</h3>
    <p>${asset.notes.summary}</p>
    <h4>Works</h4>
    <ul>${(asset.notes.works || []).map(x => `<li>${x}</li>`).join('') || '<li class="muted">None recorded</li>'}</ul>
    <h4>Fixes</h4>
    <ul>${(asset.notes.fixes || []).map(x => `<li>${x}</li>`).join('') || '<li class="muted">None recorded</li>'}</ul>
  `;
  const badges = panel.querySelector('.detailBadges');
  badges.append(
    badge(asset.status, `status-${asset.status}`),
    badge(asset.generator.tool),
    badge(asset.purpose.phase),
    badge(asset.purpose.category),
    ...(asset.tags || []).map(t => badge(t))
  );
}

async function init() {
  const resp = await fetch('/api/manifest');
  state.manifest = await resp.json();
  document.getElementById('manifestMeta').textContent = `schema v${state.manifest.schemaVersion} · updated ${state.manifest.updatedAt}`;

  fillSelect(document.getElementById('statusFilter'), [...new Set(state.manifest.assets.map(a => a.status))].sort());
  fillSelect(document.getElementById('toolFilter'), [...new Set(state.manifest.assets.map(a => a.generator.tool))].sort());
  fillSelect(document.getElementById('phaseFilter'), [...new Set(state.manifest.assets.map(a => a.purpose.phase))].sort());
  fillSelect(document.getElementById('categoryFilter'), [...new Set(state.manifest.assets.map(a => a.purpose.category))].sort());

  for (const id of ['searchInput', 'statusFilter', 'toolFilter', 'phaseFilter', 'categoryFilter', 'hasSelectedFilter', 'hasRuntimeFilter', 'missingOnlyFilter']) {
    document.getElementById(id).addEventListener('input', applyFilters);
    document.getElementById(id).addEventListener('change', applyFilters);
  }

  await applyFilters();
}

init().catch(err => {
  document.getElementById('grid').innerHTML = `<pre class="promptBox">Failed to load manifest:
${String(err)}</pre>`;
});
