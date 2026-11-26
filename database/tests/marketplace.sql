-- Run with psql on an empty, disposable PostgreSQL database as its owner.
\set ON_ERROR_STOP on
create role anon;
create role authenticated;
create schema auth;
create table auth.users (id uuid primary key, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to authenticated, anon;
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  nombre text not null, apellido text not null, telefono text not null,
  rol text not null default 'cliente', activo boolean not null default true,
  terminos_aceptados boolean not null default false, fecha_registro timestamptz default now(),
  es_admin boolean not null default false
);
create table public.barberias (
  id uuid primary key default gen_random_uuid(), nombre text not null, direccion text,
  telefono text, imagen text, propietario_id uuid references public.profiles(id), activa boolean not null
);
create table public.products (
  comercio_id uuid references public.barberias(id), name text, is_active boolean
);
create table public.servicios (
  barberia_id uuid references public.barberias(id), nombre text, activo boolean
);
grant select, update, insert on public.profiles to authenticated;
\ir ../01_seguridad_profiles.sql

insert into auth.users
select format('00000000-0000-0000-0000-%s', lpad(id::text, 12, '0'))::uuid,
  '{"nombre":"Prueba","apellido":"Local","telefono":"3001234567","rol":"admin"}'
from generate_series(1, 4) id;
update public.profiles set es_admin = true where id = '00000000-0000-0000-0000-000000000003';
update public.profiles set activo = false where id = '00000000-0000-0000-0000-000000000004';
insert into public.barberias (id, nombre, propietario_id, activa)
values ('10000000-0000-0000-0000-000000000001', 'Legado', '00000000-0000-0000-0000-000000000001', true);
insert into public.products values
  ('10000000-0000-0000-0000-000000000001', 'Champú de coco', true),
  ('10000000-0000-0000-0000-000000000001', 'Champú retirado', false);
insert into public.servicios values ('10000000-0000-0000-0000-000000000001', 'Masaje', true);
\ir ../02_marketplace_comercios.sql

insert into public.resenas_marketplace (comercio_id, calificacion, comentario, publicada)
values ('10000000-0000-0000-0000-000000000001', 4, 'Publicada', true),
       ('10000000-0000-0000-0000-000000000001', 1, 'En revisión', false);

do $$
begin
  assert not has_function_privilege('anon', 'public.buscar_comercios(text,text,text,text,numeric,integer,uuid)', 'EXECUTE');
  assert not has_table_privilege('authenticated', 'public.resenas_marketplace', 'SELECT');
end $$;

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
begin
  assert (select rol from public.profiles) = 'cliente';
  update public.profiles set nombre = 'Nuevo';
  begin
    update public.profiles set es_admin = true;
    raise exception 'Cambio de privilegios permitido';
  exception when insufficient_privilege then null;
  end;
  assert (select count(*) from public.buscar_comercios(consulta => 'coco')) = 1;
  assert (select count(*) from public.buscar_comercios(consulta => 'masaje')) = 1;
  assert (select count(*) from public.buscar_comercios(consulta => 'retirado')) = 0;
  assert (select count(*) from public.buscar_comercios(calificacion_min => 4)) = 1;
  assert (select count(*) from public.buscar_comercios(calificacion_min => 5)) = 0;
  assert (select jsonb_array_length(resenas) from public.buscar_comercios(
    comercio_filtro => '10000000-0000-0000-0000-000000000001')) = 1;
end $$;

insert into public.solicitudes_comercio
(nombre, descripcion, direccion, telefono, categoria, zona, tipo, horario)
values ('Tienda Uno', 'Productos locales', 'Calle 1', '3001234567', 'Belleza', 'Centro', 'Tienda', 'Lun–Vie'),
       ('Tienda Dos', 'Venta al detalle', 'Calle 2', '3009876543', 'Belleza', 'Centro', 'Tienda', 'Lun–Vie');
select id as solicitud from public.solicitudes_comercio where nombre = 'Tienda Uno' \gset
select id as rechazo from public.solicitudes_comercio where nombre = 'Tienda Dos' \gset
select set_config('test.solicitud', :'solicitud', false);
do $$
begin
  assert (select count(*) from public.solicitudes_comercio) = 2;
  assert (select count(*) from public.buscar_comercios(consulta => 'Tienda')) = 0;
  begin
    update public.solicitudes_comercio set estado = 'aprobada';
    raise exception 'Se permitió una transición directa';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.revisar_solicitud_comercio(current_setting('test.solicitud')::uuid, true, '');
    raise exception 'Se permitió una revisión sin permiso';
  exception when insufficient_privilege then null;
  end;
end $$;

set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
do $$ begin
  assert (select count(*) from public.solicitudes_comercio) = 0;
  begin
    perform public.actualizar_comercio_propio(current_setting('test.solicitud')::uuid, '{}');
    raise exception 'Edición no autorizada';
  exception when insufficient_privilege then null;
  end;
end $$;

set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
do $$ begin
  assert (select count(*) from public.buscar_comercios()) = 0;
  begin
    insert into public.solicitudes_comercio
    (nombre, descripcion, direccion, telefono, categoria, zona, tipo, horario)
    values ('Suspendida', 'Descripción', 'Calle 3', '3001234567', 'Belleza', 'Centro', 'Tienda', 'Lunes');
    raise exception 'Se permitió una solicitud de cuenta inactiva';
  exception when insufficient_privilege then null;
  end;
end $$;

set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
select public.revisar_solicitud_comercio(:'solicitud', true, 'Aprobada');
select public.revisar_solicitud_comercio(:'rechazo', false, 'Faltan datos');
do $$ begin
  begin
    perform public.revisar_solicitud_comercio(current_setting('test.solicitud')::uuid, true, '');
    raise exception 'Se permitió repetir una aprobación';
  exception when object_not_in_prerequisite_state then null;
  end;
  assert (select count(*) from public.solicitudes_comercio where revisada_en is not null) = 2;
end $$;

set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$
declare
  cambios jsonb := '{"nombre":"Tienda editada","descripcion":"Descripción","direccion":"Calle 4","telefono":"3001234567","categoria":"Belleza","zona":"Centro","tipo":"Tienda","horario":"Lunes","visible":false,"version":0}';
  solicitud uuid := current_setting('test.solicitud')::uuid;
begin
  assert (select count(*) from public.buscar_comercios(categoria_filtro => 'belleza', zona_filtro => 'centro', tipo_filtro => 'Tienda')) = 1;
  perform public.actualizar_comercio_propio(solicitud, cambios);
  assert (select count(*) from public.buscar_comercios(consulta => 'Tienda')) = 0;
  assert (select datos_revisados->>'nombre' from public.solicitudes_comercio where id = solicitud) = 'Tienda Uno';
  begin
    perform public.actualizar_comercio_propio(solicitud, cambios);
    raise exception 'Una edición obsoleta sobrescribió los datos';
  exception when serialization_failure then null;
  end;
  perform public.actualizar_comercio_propio(solicitud, cambios || '{"visible":true,"version":1}');
  assert (select count(*) from public.buscar_comercios(consulta => 'Tienda editada')) = 1;
end $$;

reset role;
update public.barberias set activa = false where nombre = 'Tienda editada';
set role authenticated;
do $$ begin
  assert (select count(*) from public.buscar_comercios(consulta => 'Tienda')) = 0;
  assert (select count(*) from public.buscar_comercios(consulta => 'Legado')) = 1;
end $$;
reset role;
