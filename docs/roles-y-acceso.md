# Próximo bloque: selección y verificación de roles

Estado: pendiente de implementación. Este documento no concede permisos ni crea
las pantallas. El inicio actual es común a toda sesión autenticada.

## Referencia visual

La segunda pantalla de la referencia muestra tres tarjetas: Cliente, Barbero y
Administrador. Adaptar ese flujo a CUT & GO con la paleta negro azulado y dorado,
iconos legibles y retorno para cambiar la selección.

## Flujo esperado

1. Sin sesión: mostrar selección de acceso (Cliente / Barbero / Administrador).
2. La selección conduce al formulario de login y solo expresa la intención de acceso.
3. Autenticar con Supabase y consultar el perfil del usuario autenticado.
4. Comprobar el rol real y el estado activo desde información administrada en el servidor.
5. Mostrar exclusivamente el panel autorizado. Si la selección no corresponde,
   explicar que la cuenta no tiene ese acceso y permitir cambiar de selección o
   cerrar sesión. No mostrar el panel solicitado mientras se verifica el perfil.
6. Al restaurar una sesión, comprobar nuevamente perfil y permisos antes de abrir
   el panel; no confiar en un rol guardado en el navegador.
7. El registro público continúa creando cuentas Cliente. Elegir Barbero o
   Administrador no crea ni modifica esos privilegios.

Las políticas RLS son necesarias aunque la interfaz oculte destinos.
Un perfil ausente, suspendido, con rol desconocido o cuya consulta falle no debe
obtener acceso por defecto a un panel privilegiado.

## Acuerdos necesarios con el equipo

- El modelo actual comenta los valores cliente/comercio/admin; la nueva referencia
  también requiere barbero. Revisar el esquema real y acordar sus valores antes
  de implementar comparaciones y migraciones.
- Propietario de comercio y barbero no son necesariamente el mismo rol. Mantener
  el acceso de comercios requerido por RF-009 a RF-011.
- Los paneles de barbero y administrador se conectan con los módulos de sus
  responsables; no crear copias de sus pantallas ni simular permisos.
- Usar un mecanismo administrativo autorizado para asignar roles; nunca hacerlo
  desde el formulario público o los metadatos editables del usuario.

## Entregas y commits sugeridos

- `feat(auth): añadir selección visual de acceso por rol`
- `feat(auth): verificar perfil y rol antes de abrir el panel`
- `test(auth): cubrir roles incorrectos, perfiles suspendidos y sesión restaurada`

## Criterios de aceptación

- Una cuenta Cliente no entra al panel Administrador seleccionando esa tarjeta.
- La misma protección se aplica a enlaces directos y sesiones restauradas.
- El registro no acepta un rol privilegiado enviado por el cliente.
- Se puede volver atrás y corregir la selección sin perder el control de la sesión.
- Carga y errores de verificación son visibles; no hay redirecciones prematuras.

La selección es un paso adicional del recorrido de autenticación. El número de
pantallas puede aumentar respecto a la propuesta inicial de once; se mantiene
la cobertura de RF-001 a RF-011 como prioridad.
