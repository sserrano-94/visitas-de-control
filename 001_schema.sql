-- =========================================================
-- Control de Visitas a Campo — esquema inicial
-- Ejecutar completo en: Supabase → SQL Editor → New query
-- =========================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------
-- 1. PERFILES (el jefe + los supervisores)
-- Se apoya en auth.users de Supabase (ahí vive el login);
-- esta tabla guarda los datos "de negocio" de cada persona.
-- ---------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre_completo text not null,
  rol text not null check (rol in ('admin','supervisor')) default 'supervisor',
  color_hex text,               -- color de referencia (igual que en el Excel: azul/verde/café/gris)
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.profiles is 'Datos de negocio de cada usuario (jefe o supervisor). El id coincide con auth.users.id.';

-- Crea automáticamente una fila en profiles cuando alguien se registra
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nombre_completo, rol)
  values (new.id, coalesce(new.raw_user_meta_data->>'nombre_completo', new.email), 'supervisor')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------
-- 2. CAMPOS (los predios / clientes a visitar)
-- ---------------------------------------------------------
create table public.campos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  cliente text,
  zona text,
  ubicacion text,                 -- dirección o referencia libre (se puede ampliar a lat/lng más adelante)
  superficie_ha numeric,
  meta_mensual numeric not null default 1,
  supervisor_habitual_id uuid constraint campos_supervisor_habitual_id_fkey references public.profiles(id),
  supervisor_habitual_nombre text,   -- ayuda temporal: nombre en texto, para poder cargar campos ANTES de crear los usuarios (ver 003_asignar_supervisores.sql)
  activo boolean not null default true,
  notas text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.campos.supervisor_habitual_id is
  'Supervisor que normalmente visita este campo por cercanía. Es solo una referencia/default: cada visita puntual puede asignarse a otro supervisor.';

create index campos_zona_idx on public.campos (zona);
create index campos_supervisor_habitual_idx on public.campos (supervisor_habitual_id);

-- ---------------------------------------------------------
-- 3. VISITAS — la planificación semanal Y el registro real
--    viven en la misma tabla: una fila = una visita planificada,
--    que luego se marca como completada.
-- ---------------------------------------------------------
create table public.visitas (
  id uuid primary key default gen_random_uuid(),
  campo_id uuid not null constraint visitas_campo_id_fkey references public.campos(id) on delete cascade,
  supervisor_id uuid not null constraint visitas_supervisor_id_fkey references public.profiles(id),
  fecha_planificada date not null,      -- día que el jefe asignó
  fecha_realizada date,                 -- se llena cuando el supervisor marca "visitado"
  estado text not null default 'planificada'
      check (estado in ('planificada','completada','reprogramada','cancelada')),
  notas text,
  creado_por uuid constraint visitas_creado_por_fkey references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index visitas_campo_idx on public.visitas (campo_id);
create index visitas_supervisor_idx on public.visitas (supervisor_id);
create index visitas_fecha_planificada_idx on public.visitas (fecha_planificada);

-- updated_at automático
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger campos_set_updated_at before update on public.campos
  for each row execute function public.set_updated_at();
create trigger visitas_set_updated_at before update on public.visitas
  for each row execute function public.set_updated_at();

-- Un supervisor solo puede tocar estado / fecha_realizada / notas de SU visita.
-- Cambiar a qué campo, qué supervisor o qué día planificado corresponde: solo el admin.
create or replace function public.protect_visita_fields()
returns trigger language plpgsql security definer as $$
begin
  if not public.is_admin() then
    if new.campo_id <> old.campo_id
       or new.supervisor_id <> old.supervisor_id
       or new.fecha_planificada <> old.fecha_planificada then
      raise exception 'Solo el administrador puede reasignar una visita (campo, supervisor o día planificado).';
    end if;
  end if;
  return new;
end;
$$;

-- (el trigger se crea después de definir is_admin() más abajo)

-- ---------------------------------------------------------
-- 4. VISTA: avance mensual por campo (meta vs. hecho)
-- ---------------------------------------------------------
create or replace view public.avance_mensual as
select
  c.id as campo_id,
  c.nombre as campo,
  c.zona,
  c.meta_mensual,
  date_trunc('month', v.fecha_realizada)::date as mes,
  count(*) filter (where v.estado = 'completada') as visitas_hechas
from public.campos c
left join public.visitas v
  on v.campo_id = c.id and v.fecha_realizada is not null
group by c.id, c.nombre, c.zona, c.meta_mensual, date_trunc('month', v.fecha_realizada);

comment on view public.avance_mensual is 'Meta vs. visitas completadas, agrupado por campo y por mes calendario.';

-- ---------------------------------------------------------
-- 5. FUNCIÓN DE AYUDA PARA LAS POLÍTICAS (RLS)
-- ---------------------------------------------------------
create or replace function public.is_admin()
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and rol = 'admin'
  );
$$;

create trigger visitas_protect_fields before update on public.visitas
  for each row execute function public.protect_visita_fields();

-- ---------------------------------------------------------
-- 6. ROW LEVEL SECURITY
-- ---------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.campos enable row level security;
alter table public.visitas enable row level security;

-- profiles: cualquier usuario logueado puede ver todos los perfiles (para mostrar nombres en la UI);
-- solo puede editar el propio; el admin puede editar todos.
create policy "profiles_select_all" on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "profiles_update_own_or_admin" on public.profiles for update
  using (id = auth.uid() or public.is_admin());

create policy "profiles_insert_admin" on public.profiles for insert
  with check (public.is_admin());

-- campos: todos los logueados ven todos los campos; solo el admin crea/edita/borra.
create policy "campos_select_all" on public.campos for select
  using (auth.role() = 'authenticated');

create policy "campos_insert_admin" on public.campos for insert
  with check (public.is_admin());
create policy "campos_update_admin" on public.campos for update
  using (public.is_admin());
create policy "campos_delete_admin" on public.campos for delete
  using (public.is_admin());

-- visitas: el admin ve/crea/edita/borra todo. el supervisor solo ve y
-- actualiza SUS PROPIAS visitas (y solo estado/fecha_realizada/notas, por el trigger de arriba).
create policy "visitas_select_admin" on public.visitas for select
  using (public.is_admin());
create policy "visitas_select_own" on public.visitas for select
  using (supervisor_id = auth.uid());

create policy "visitas_insert_admin" on public.visitas for insert
  with check (public.is_admin());

create policy "visitas_update_admin" on public.visitas for update
  using (public.is_admin());
create policy "visitas_update_own" on public.visitas for update
  using (supervisor_id = auth.uid())
  with check (supervisor_id = auth.uid());

create policy "visitas_delete_admin" on public.visitas for delete
  using (public.is_admin());
