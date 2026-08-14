import { sb } from './supabaseClient.js';

// Redirige a login si no hay sesión. `loginPath` es la ruta relativa
// a login.html desde la página que llama (por eso cada página la pasa).
export async function requireAuth(loginPath = 'login.html') {
  const { data: { session } } = await sb.auth.getSession();
  if (!session) {
    window.location.href = loginPath;
    return null;
  }
  return session;
}

export async function getProfile() {
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return null;
  const { data, error } = await sb
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();
  if (error) {
    console.error('getProfile error', error);
    return null;
  }
  return data;
}

// Solo deja pasar si el perfil es admin; si no, redirige a homePath.
export async function requireAdmin(homePath = 'mi-semana.html', loginPath = 'login.html') {
  const session = await requireAuth(loginPath);
  if (!session) return null;
  const profile = await getProfile();
  if (!profile || profile.rol !== 'admin') {
    alert('Esta sección es solo para el administrador.');
    window.location.href = homePath;
    return null;
  }
  return profile;
}

export async function logout(loginPath = 'login.html') {
  await sb.auth.signOut();
  window.location.href = loginPath;
}
