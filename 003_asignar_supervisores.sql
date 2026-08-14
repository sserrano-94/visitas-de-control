-- =========================================================
-- Ejecutar SOLO DESPUÉS de que existan los usuarios reales
-- (ver README, paso "Crear los usuarios").
--
-- Este script:
--  1) marca como 'admin' a Sergio, Pablo y Andrés, y les pone su nombre
--  2) les pone el nombre completo a los 4 supervisores
--  3) rellena supervisor_habitual_id en campos, cruzando por nombre
-- =========================================================

-- 1) Administradores (mismo acceso completo que Sergio).
update public.profiles
set rol = 'admin', nombre_completo = 'Sergio Serrano'
where id = (select id from auth.users where email = 's.serrano@baumsystem.com');

update public.profiles
set rol = 'admin', nombre_completo = 'Pablo Valdes'
where id = (select id from auth.users where email = 'p.valdes@baumsystem.com');

update public.profiles
set rol = 'admin', nombre_completo = 'Andrés Tocornal'
where id = (select id from auth.users where email = 'a.tocornal@baumsystem.com');

-- 2) Supervisores (quedan con rol 'supervisor', que es el que les da
--    el trigger automático al crear la cuenta; solo les completamos el nombre).
update public.profiles
set nombre_completo = 'Esteban Rojas'
where id = (select id from auth.users where email = 'e.rojas@baumsystem.com');

update public.profiles
set nombre_completo = 'Jose Miguel Ortega'
where id = (select id from auth.users where email = 'jm.ortega@baumsystem.com');

update public.profiles
set nombre_completo = 'Javier Figueroa'
where id = (select id from auth.users where email = 'j.figueroa@baumsystem.com');

update public.profiles
set nombre_completo = 'Cesar Tapia'
where id = (select id from auth.users where email = 'c.tapia@baumsystem.com');

-- 3) Asignar supervisor_habitual_id en campos. Los campos importados del
--    Excel solo traen el primer nombre (ej. 'Esteban'), así que aquí
--    cruzamos tanto por coincidencia exacta como por "empieza con".
update public.campos c
set supervisor_habitual_id = p.id
from public.profiles p
where c.supervisor_habitual_nombre = p.nombre_completo
   or p.nombre_completo like c.supervisor_habitual_nombre || ' %';

-- Verifica cuántos quedaron sin coincidencia (deberían ser los ya
-- marcados con nota "confirmar supervisor habitual", más cualquier
-- typo de nombre entre esta lista y profiles.nombre_completo):
select nombre, zona, supervisor_habitual_nombre
from public.campos
where supervisor_habitual_id is null;
