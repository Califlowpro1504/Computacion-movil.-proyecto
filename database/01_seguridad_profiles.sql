-- Activa seguridad a nivel de fila
alter table profiles enable row level security;

-- Cada usuario solo ve su propio perfil
create policy "ver propio perfil" on profiles
  for select using (auth.uid() = id);

-- Puede editar su perfil, pero NO cambiar su rol ni su estado activo
create policy "editar propio perfil" on profiles
  for update using (auth.uid() = id)
  with check (
    auth.uid() = id
    and rol = (select p.rol from profiles p where p.id = auth.uid())
    and activo = (select p.activo from profiles p where p.id = auth.uid())
  );

-- El perfil lo crea el servidor, con rol fijo
create function public.crear_perfil()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nombre, apellido, telefono, rol, terminos_aceptados)
  values (
    new.id,
    new.raw_user_meta_data->>'nombre',
    new.raw_user_meta_data->>'apellido',
    new.raw_user_meta_data->>'telefono',
    'cliente',
    true
  );
  return new;
end; $$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil();