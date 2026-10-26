# Diseño de RF-001 a RF-011 basado en el mockup

## Referencias y decisiones

Documento funcional: `doc2.pdf` (CUT & GO).
Referencia visual: `Juanjo_Marketplace_Cali_Mockup_Escalable.pptx`.
El mockup orienta la presentación; el documento de requerimientos define el alcance.

Las diapositivas 3 y 4 sirven de referencia para tarjetas, accesos y navegación.
Las diapositivas 13 a 16 presentan el enfoque adecuado de múltiples comercios:
inicio, categorías, búsqueda, registro y gestión de cada negocio.
La marca de la aplicación sigue siendo CUT & GO; no se renombra a Juanjo Marketplace.

La referencia visual posterior de diez pantallas sustituye la paleta borgoña:
fondo negro azulado, superficies azul pizarra, textos marfil y acciones doradas. Usar tipografía decorativa solo en la marca;
formularios y contenido deben seguir siendo fáciles de leer.

## Once pantallas principales

| Pantalla | RF | Adaptación del mockup |
|---|---|---|
| Login | 002 | Formulario oscuro; destino según el rol validado del usuario. |
| Registro | 001 | Datos de cliente, términos y validación; no permitir elegir un rol privilegiado. |
| Solicitar recuperación | 003 | Solicitar enlace por correo; SMS requiere acuerdo e infraestructura adicional. |
| Nueva contraseña | 003 | Contraseña y confirmación con la política acordada. |
| Mi perfil | 004 | Datos personales y modo de edición; correo mediante flujo de Auth, sin editar rol ni estado. |
| Inicio del cliente | 005 | Buscador, categorías, comercios disponibles/destacados y accesos a módulos compartidos. |
| Búsqueda y resultados | 006–007 | Buscador persistente, tarjetas y filtros en panel; limpiar búsqueda y filtros. |
| Detalle del comercio | 008 | Fotos, descripción, dirección, horarios, calificación y secciones de productos/servicios/reseñas. |
| Registrar mi comercio | 009 | Formulario y logo; confirmación de solicitud pendiente de aprobación. |
| Revisar solicitudes | 010 | Lista y detalle para administrador, observación, aprobación/rechazo y fecha de revisión. |
| Administrar mi comercio | 011 | Editar información del negocio aprobado; activar/desactivar según permisos del propietario. |

Las pantallas pueden incluir modos, pestañas y paneles. Once vistas principales
no equivalen a once requerimientos aislados ni prohíben subdividir un flujo si
resulta necesario en pruebas de usabilidad.

## Navegación

- Acceso: login ↔ registro; login → solicitud de recuperación → nueva contraseña.
- Cliente: inicio → búsqueda/resultados → detalle de comercio.
- Perfil: accesible desde la navegación del cliente; edición y cierre de sesión.
- Propietario: solicitud de comercio y administración del negocio aprobado.
- Administrador: revisión de solicitudes dentro del panel del equipo.
- Carrito, pedidos, citas y notificaciones enlazan con los módulos de sus responsables.

El ejemplo de barra inferior del mockup (Inicio, Citas, Tienda, Perfil) es una
referencia. Los destinos definitivos deben acordarse con el equipo para incluir
los accesos de RF-005 sin duplicar menús ni crear botones sin funcionamiento.

## Alcance y coordinación

- RF-006 exige buscar por nombre de comercio, categoría, producto o servicio.
- RF-007 exige categoría, barrio/zona, calificación y tipo de comercio. Filtros
  de precio, abierto ahora y cercanía del mockup son ampliaciones, no sustitutos.
- RF-010 comparte acciones con RF-032: usar el mismo modelo de solicitud y las
  mismas reglas de aprobación en el servidor, coordinadas con administración.
- Productos, precios, stock, carrito y pedidos se coordinan con el módulo de compras.
- Barberos, servicios, disponibilidad y reservas se coordinan con barberías.
- Cada propietario accede únicamente a los negocios autorizados mediante RLS;
  ocultar menús no sustituye la autorización del servidor.
- Cali, COP y retiro en comercio aparecen en el mockup: confirmar estas decisiones
  con el equipo antes de convertirlas en restricciones técnicas adicionales.
- Pagos digitales, fidelización, IA, franquicias, multisede y repartidores no se
  incorporan a este bloque por aparecer en la presentación.

## Criterios visuales y funcionales

- Contraste legible en modo oscuro, foco visible y etiquetas en todos los campos.
- Formularios desplazables con teclado abierto; tarjetas adaptadas a ancho disponible.
- Estados de carga, error, vacío y éxito; evitar solicitudes repetidas al guardar.
- No mostrar comercios, calificaciones, citas ni precios ficticios como datos reales.
- Imágenes con alternativa si faltan; no pedir geolocalización solo para mostrar Cali.
- Enlaces a módulos pendientes se integran cuando existan sus destinos.

## Entregas sugeridas

1. Validar sesión y cierre con una cuenta de pruebas.
2. Perfil: consultar, editar y comprobar validaciones y errores.
3. Recuperación completa y navegación por rol.
4. Comercios: modelo/permisos, solicitud, revisión y edición.
5. Inicio, búsqueda, filtros y detalle con datos reales.

Cada entrega debe contener commits que describan su comportamiento y pruebas.
Este documento define la referencia de diseño; no implementa las once pantallas.


## Adaptación implementada: negro y dorado

Referencia posterior: imagen con splash, acceso por rol, inicio, barberos, tienda,
citas y paneles de administración. Se toma su lenguaje visual, sin cambiar la
marca CUT & GO ni incorporar los módulos de otros integrantes.

- Login y registro: nueva paleta, emblema dorado, marca serif y campos oscuros.
- Inicio: cabecera, bloque destacado y tarjetas de categorías próximas.
- Mi cuenta: sección navegable con correo real de la sesión y cierre de sesión.
- Las categorías son informativas, no un catálogo consultado en Supabase.
- No se añadieron selección de roles, barberos ficticios, precios ni reservas.
- Los roles privilegiados deben seguir asignándose y verificándose en el servidor.
- Se mantienen los validadores y los eventos de autenticación.

Verificación local necesaria: `flutter analyze`, `flutter test` y
`flutter run -d edge`. Comprobar login, registro, cambio entre Inicio/Mi cuenta,
cierre de sesión, errores de cierre, teclado y pantallas estrechas. Las pruebas
incluyen anchos de 320 y 1200 con texto ampliado. Estas pruebas nuevas no se han
ejecutado en el entorno de edición por falta del SDK de Flutter.

## Prioridad confirmada: selección de roles

Antes del perfil, implementar el flujo de Cliente / Barbero / Administrador de
la segunda pantalla de la referencia. Consultar [roles y acceso](roles-y-acceso.md)
para el comportamiento esperado, dependencias con el equipo y criterios de prueba.
Este flujo aún no está implementado.
