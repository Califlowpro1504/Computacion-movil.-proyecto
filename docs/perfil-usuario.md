# Perfil del usuario — RF-004

## Funcionalidades

- Consultar nombre, apellido, correo y teléfono.
- Editar nombre, apellido y teléfono.
- Validar campos obligatorios y formato del teléfono.
- Cancelar sin guardar cambios.
- Mostrar errores y permitir reintentar.
- Bloquear envíos repetidos durante el guardado.
- Actualizar la consulta del perfil después de guardar.

El formulario de edición actualiza los datos personales. El botón **Cambiar correo** solicita confirmación mediante Supabase Auth. El rol y el estado se administran en el servidor.
El servicio utiliza la identidad autenticada en Supabase.
La autorización de los datos depende también de las políticas RLS.

## Pruebas

Las pruebas automáticas cubren consulta, carga, errores, validación,
guardado, cancelación y bloqueo de envíos repetidos.

Utilizan datos simulados y no comprueban las políticas RLS.

## Verificación manual

1. Iniciar sesión con una cuenta de prueba.
2. Abrir Mi cuenta → Ver mi perfil → Editar perfil.
3. Cambiar un dato y cancelar: debe conservarse el anterior.
4. Cambiarlo y guardar: debe mostrarse actualizado.
5. Recargar la aplicación: el cambio debe permanecer.

6. Solicitar el cambio de correo y comprobar la confirmación con la configuración de cambio seguro activa en Supabase Auth.
