import { logout } from './auth.js';

// basePath: '' si la página vive en la raíz de /public, '../' si vive en /public/admin
export function renderTopbar(profile, basePath = '', loginPath = 'login.html') {
  const el = document.getElementById('topbar');
  if (!el) return;
  const isAdmin = profile?.rol === 'admin';

  el.innerHTML = `
    <div class="brand">🌱 Control de Visitas</div>
    <nav>
      <a href="${basePath}mi-semana.html">Mi semana</a>
      <a href="${basePath}mis-campos.html">${isAdmin ? 'Campos por supervisor' : 'Mis campos'}</a>
      <a href="${basePath}historial.html">Historial</a>
      ${isAdmin ? `<a href="${basePath}admin/dashboard.html">Dashboard</a>` : ''}
      ${isAdmin ? `<a href="${basePath}admin/planificador.html">Planificador semanal</a>` : ''}
      ${isAdmin ? `<a href="${basePath}admin/plantilla.html">Plantilla mensual</a>` : ''}
      ${isAdmin ? `<a href="${basePath}admin/campos.html">Campos</a>` : ''}
    </nav>
    <div style="display:flex;align-items:center;gap:10px;">
      <span style="font-size:0.85rem;opacity:0.85;">${profile?.nombre_completo ?? ''}${isAdmin ? ' · admin' : ''}</span>
      <button id="logoutBtn" type="button">Salir</button>
    </div>
  `;

  document.getElementById('logoutBtn').addEventListener('click', () => logout(basePath + loginPath));
}
