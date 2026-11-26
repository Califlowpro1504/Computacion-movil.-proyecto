begin;

-- Keep the existing commerce IDs used by products, services and appointments.
create table public.solicitudes_comercio (
  id uuid primary key default gen_random_uuid(),
  propietario_id uuid default auth.uid() references public.profiles(id) on delete set null,
  comercio_id uuid unique references public.barberias(id) on delete set null,
  nombre text not null check (length(btrim(nombre)) between 1 and 100),
  descripcion text not null check (length(btrim(descripcion)) between 1 and 2000),
  direccion text not null check (length(btrim(direccion)) between 1 and 200),
  telefono text not null check (telefono ~ '^[0-9]{7,15}$'),
  imagen text check (imagen is null or (length(imagen) <= 500 and imagen ~ '^https://[^[:space:]]+$')),
  categoria text not null check (length(btrim(categoria)) between 1 and 80),
  zona text not null check (length(btrim(zona)) between 1 and 80),
  tipo text not null check (tipo in ('Barbería', 'Tienda', 'Servicios', 'Otro')),
  horario text not null check (length(btrim(horario)) between 1 and 250),
  estado text not null default 'pendiente' check (estado in ('pendiente', 'aprobada', 'rechazada')),
  observacion text check (length(observacion) <= 1000),
  enviada_en timestamptz not null default now(),
  revisada_en timestamptz,
  revisada_por uuid references public.profiles(id) on delete set null,
  datos_revisados jsonb,
  version integer not null default 0,
  visible boolean not null default true
);

create unique index solicitud_pendiente_por_propietario_y_nombre
  on public.solicitudes_comercio (propietario_id, lower(btrim(nombre)))
  where estado = 'pendiente';

alter table public.solicitudes_comercio enable row level security;
revoke all on public.solicitudes_comercio from public, anon, authenticated;
grant select on public.solicitudes_comercio to authenticated;
grant insert (nombre, descripcion, direccion, telefono, imagen, categoria, zona, tipo, horario)
  on public.solicitudes_comercio to authenticated;

create policy solicitudes_lectura on public.solicitudes_comercio
  for select to authenticated using (
    exists (select 1 from public.profiles p where p.id = (select auth.uid())
      and p.activo and (propietario_id = p.id or p.rol = 'admin' or to_jsonb(p)->>'es_admin' = 'true'))
  );

create policy solicitudes_envio on public.solicitudes_comercio
  for insert to authenticated with check (
    propietario_id = (select auth.uid())
    and exists (select 1 from public.profiles p where p.id = propietario_id and p.activo)
  );

-- Protect authorization attributes even when another permissive profile policy is installed.
create policy perfiles_sin_insercion_directa on public.profiles
  as restrictive for insert to anon, authenticated with check (false);

create function public.proteger_acceso_perfil() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('anon', 'authenticated') and old.id = auth.uid()
    and (new.id is distinct from old.id
      or new.rol is distinct from old.rol or new.activo is distinct from old.activo
      or (to_jsonb(new)->'es_admin') is distinct from (to_jsonb(old)->'es_admin')
      or new.terminos_aceptados is distinct from old.terminos_aceptados
      or new.fecha_registro is distinct from old.fecha_registro) then
    raise exception 'Los atributos de acceso del perfil están protegidos' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger proteger_acceso_perfil before update on public.profiles
  for each row execute function public.proteger_acceso_perfil();

create function public.revisar_solicitud_comercio(
  solicitud uuid, aprobar boolean, detalle text
) returns void language plpgsql security definer set search_path = '' as $$
declare
  datos public.solicitudes_comercio%rowtype;
  comercio uuid;
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid()
    and p.activo and (p.rol = 'admin' or to_jsonb(p)->>'es_admin' = 'true')) then
    raise exception 'Acceso denegado' using errcode = '42501';
  end if;
  if aprobar is null or length(btrim(coalesce(detalle, ''))) > 1000
    or (not aprobar and btrim(coalesce(detalle, '')) = '') then
    raise exception 'Revisión inválida' using errcode = '22023';
  end if;

  select * into datos from public.solicitudes_comercio where id = solicitud for update;
  if not found or datos.estado <> 'pendiente' then
    raise exception 'La solicitud ya no está pendiente' using errcode = '55000';
  end if;
  if aprobar then
    if not exists (select 1 from public.profiles p where p.id = datos.propietario_id and p.activo) then
      raise exception 'La cuenta solicitante está inactiva' using errcode = '55000';
    end if;
    insert into public.barberias (nombre, direccion, telefono, imagen, propietario_id, activa)
    values (datos.nombre, datos.direccion, datos.telefono, coalesce(datos.imagen, ''),
      datos.propietario_id, true)
    returning id into comercio;
  end if;
  update public.solicitudes_comercio set
    estado = case when aprobar then 'aprobada' else 'rechazada' end,
    comercio_id = comercio, observacion = nullif(btrim(detalle), ''),
    revisada_en = now(), revisada_por = auth.uid(),
    datos_revisados = to_jsonb(datos) - array['datos_revisados', 'version']
  where id = solicitud;
end;
$$;

create function public.actualizar_comercio_propio(
  solicitud uuid, cambios jsonb
) returns void language plpgsql security definer set search_path = '' as $$
declare
  comercio uuid;
  datos public.solicitudes_comercio%rowtype;
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.activo) then
    raise exception 'Acceso denegado' using errcode = '42501';
  end if;
  select s.* into datos from public.solicitudes_comercio s
    where s.id = solicitud and s.propietario_id = auth.uid()
      and s.estado = 'aprobada' and s.comercio_id is not null
    for update;
  if not found then
    raise exception 'Comercio no disponible para edición' using errcode = '42501';
  end if;

  if (cambios->>'version')::integer is distinct from datos.version then
    raise exception 'Los datos del comercio cambiaron' using errcode = '40001';
  end if;

  update public.barberias set nombre = btrim(cambios->>'nombre'),
    direccion = btrim(cambios->>'direccion'), telefono = btrim(cambios->>'telefono'),
    imagen = coalesce(nullif(btrim(cambios->>'imagen'), ''), '')
  where id = datos.comercio_id and propietario_id = auth.uid()
  returning id into comercio;

  if comercio is null then
    raise exception 'Comercio no disponible para edición' using errcode = '42501';
  end if;

  update public.solicitudes_comercio set nombre = btrim(cambios->>'nombre'),
    descripcion = btrim(cambios->>'descripcion'), direccion = btrim(cambios->>'direccion'),
    telefono = btrim(cambios->>'telefono'), imagen = nullif(btrim(cambios->>'imagen'), ''),
    categoria = btrim(cambios->>'categoria'), zona = btrim(cambios->>'zona'),
    tipo = cambios->>'tipo', horario = btrim(cambios->>'horario'),
    visible = (cambios->>'visible')::boolean, version = version + 1
  where id = solicitud;
end;
$$;

-- Import or moderate reviews with a trusted server role. App users only see approved
-- display fields through the catalog. No publishing workflow is introduced here.
create table public.resenas_marketplace (
  id uuid primary key default gen_random_uuid(),
  comercio_id uuid not null references public.barberias(id) on delete cascade,
  calificacion smallint not null check (calificacion between 1 and 5),
  comentario text not null check (length(btrim(comentario)) between 1 and 1000),
  publicada boolean not null default false,
  publicada_en timestamptz not null default now()
);
create index resenas_por_comercio on public.resenas_marketplace (comercio_id) where publicada;
alter table public.resenas_marketplace enable row level security;
revoke all on public.resenas_marketplace from public, anon, authenticated;

-- Catalog reads expose only display fields. Existing businesses remain discoverable.
create function public.buscar_comercios(
  consulta text default '', categoria_filtro text default '', zona_filtro text default '',
  tipo_filtro text default '', calificacion_min numeric default null,
  desplazamiento integer default 0, comercio_filtro uuid default null
) returns table (
  id uuid, nombre text, descripcion text, direccion text, telefono text, imagen text,
  categoria text, zona text, tipo text, horario text, calificacion numeric,
  productos text[], servicios text[], resenas jsonb
) language sql stable security definer set search_path = '' as $$
  select b.id, b.nombre, s.descripcion, b.direccion, b.telefono, b.imagen,
    coalesce(s.categoria, 'Barberías'), s.zona, coalesce(s.tipo, 'Barbería'),
    s.horario, opiniones.promedio,
    case when comercio_filtro is not null then array(
      select p.name::text from public.products p where p.comercio_id = b.id and p.is_active
      order by p.name limit 100) end,
    case when comercio_filtro is not null then array(
      select v.nombre::text from public.servicios v where v.barberia_id = b.id and v.activo
      order by v.nombre limit 100) end,
    case when comercio_filtro is not null then coalesce((
      select jsonb_agg(jsonb_build_object('calificacion', r.calificacion, 'comentario', r.comentario)
        order by r.publicada_en desc)
      from (select * from public.resenas_marketplace where comercio_id = b.id and publicada
        order by publicada_en desc limit 25) r
    ), '[]'::jsonb) end
  from public.barberias b
  left join public.solicitudes_comercio s on s.comercio_id = b.id and s.estado = 'aprobada'
  left join lateral (
    select round(avg(r.calificacion), 1) promedio from public.resenas_marketplace r
    where r.comercio_id = b.id and r.publicada
  ) opiniones on true
  where exists (select 1 from public.profiles p where p.id = auth.uid() and p.activo)
    and b.activa and coalesce(s.visible, true)
    and (comercio_filtro is null or b.id = comercio_filtro)
    and (coalesce(categoria_filtro, '') = '' or lower(coalesce(s.categoria, 'Barberías')) = lower(btrim(categoria_filtro)))
    and (coalesce(zona_filtro, '') = '' or lower(s.zona) = lower(btrim(zona_filtro)))
    and (coalesce(tipo_filtro, '') = '' or coalesce(s.tipo, 'Barbería') = tipo_filtro)
    and (calificacion_min is null or opiniones.promedio >= calificacion_min)
    and (coalesce(btrim(consulta), '') = ''
      or strpos(lower(b.nombre), lower(btrim(consulta))) > 0
      or strpos(lower(coalesce(s.categoria, 'Barberías')), lower(btrim(consulta))) > 0
      or exists (select 1 from public.products p where p.comercio_id = b.id and p.is_active
        and strpos(lower(p.name), lower(btrim(consulta))) > 0)
      or exists (select 1 from public.servicios v where v.barberia_id = b.id and v.activo
        and strpos(lower(v.nombre), lower(btrim(consulta))) > 0))
  order by lower(b.nombre), b.id
  limit 25 offset greatest(coalesce(desplazamiento, 0), 0);
$$;

revoke execute on function public.revisar_solicitud_comercio(uuid, boolean, text),
  public.actualizar_comercio_propio(uuid, jsonb),
  public.buscar_comercios(text, text, text, text, numeric, integer, uuid)
  from public, anon, authenticated;
grant execute on function public.revisar_solicitud_comercio(uuid, boolean, text),
  public.actualizar_comercio_propio(uuid, jsonb),
  public.buscar_comercios(text, text, text, text, numeric, integer, uuid)
  to authenticated;

commit;
