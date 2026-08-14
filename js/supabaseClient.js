// Requiere que la página haya cargado antes el script clásico:
// <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
// (así evitamos depender de imports ESM desde un CDN, que algunas redes bloquean).
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

export const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
