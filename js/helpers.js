// Utilidades compartidas: fechas, colores por supervisor, formato.

export function toISODate(d) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

// Devuelve el lunes (como Date, a medianoche local) de la semana que contiene `date`.
export function mondayOf(date) {
  const d = new Date(date);
  const day = d.getDay(); // 0=domingo .. 6=sábado
  const diff = (day === 0 ? -6 : 1 - day); // si es domingo retrocede 6 días
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function addDays(date, n) {
  const d = new Date(date);
  d.setDate(d.getDate() + n);
  return d;
}

const DIAS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

export function nombreDia(date) {
  const idx = (date.getDay() + 6) % 7; // lunes=0
  return DIAS[idx];
}

export function fechaCorta(date) {
  return `${date.getDate()}-${MESES[date.getMonth()]}`;
}

export function rangoSemanaTexto(monday) {
  const friday = addDays(monday, 4);
  return `Semana del ${fechaCorta(monday)} al ${fechaCorta(friday)}`;
}

// Lunes a viernes de la semana, como array de Date
export function diasHabiles(monday) {
  return [0, 1, 2, 3, 4].map((n) => addDays(monday, n));
}

// Ordenado de más específico a menos, y comparado con "empieza con" porque
// profiles.nombre_completo trae el nombre completo (ej. "Jose Miguel Ortega"),
// no solo el primer nombre.
const SUP_CLASS = [
  ['Jose Miguel', 'josemiguel'],
  ['Esteban', 'esteban'],
  ['Javier', 'javier'],
  ['Cesar', 'cesar'],
];

// Devuelve el sufijo de color ('esteban', 'josemiguel', 'javier', 'cesar' o 'sin')
// para un nombre completo. Se usa tanto para el badge como para chips/botones
// del planificador, así el color de cada supervisor es siempre el mismo en toda la app.
export function supervisorClase(nombre) {
  if (!nombre) return 'sin';
  const match = SUP_CLASS.find(([prefix]) => nombre.startsWith(prefix));
  return match ? match[1] : 'sin';
}

export function badgeSupervisor(nombre) {
  if (!nombre) return `<span class="badge badge-sin">Sin asignar</span>`;
  const cls = supervisorClase(nombre);
  return `<span class="badge badge-${cls}">${escapeHtml(nombre)}</span>`;
}

export function escapeHtml(s) {
  if (s === null || s === undefined) return '';
  return String(s)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}
