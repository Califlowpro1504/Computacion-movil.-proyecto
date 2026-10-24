# CUT & GO

Aplicación móvil tipo **marketplace de comercios locales y barberías**. Permite a los clientes explorar comercios, comprar productos y reservar citas, y a los comercios y administradores gestionar su operación desde la misma plataforma.

Proyecto académico de la materia **Computación Móvil**.

---

## Equipo

| Integrante | Módulo | Requerimientos |
|---|---|---|
| Jose Miguel Agredo | Usuarios, Marketplace y Comercios | RF-001 a RF-011 |
| Andres Camilon Bello | Productos, Carrito y Pedidos | RF-012 a RF-020, RF-028, RF-029 |
| Juan José Muñoz | Barberías, Citas y Administración | RF-021 a RF-027, RF-030 a RF-034 |

---

## Tecnologías

| Capa | Tecnología |
|---|---|
| App móvil | Flutter + Dart |
| Backend y base de datos | Supabase (Auth + PostgreSQL) |
| Estado (planeado) | Riverpod |
| Navegación (planeada) | go_router |
| Control de versiones | Git + GitHub (ramas y Pull Requests) |

### ¿Por qué Supabase?

Elegimos Supabase pensando en el futuro de la app: queremos poder escalar y mantener la libertad de mover nuestros datos sin quedar atados a un solo proveedor. Está construido sobre PostgreSQL (estándar abierto), su código es abierto y puede alojarse por cuenta propia. Además, el modelo relacional encaja con comercios, pedidos y citas, y la seguridad por filas (RLS) permite proteger los datos desde el servidor.

> Inicialmente se exploró Firebase. Gracias a la arquitectura por capas, la migración solo afectó la capa `data/`.

---

## Arquitectura

**Clean Architecture organizada por features.** Cada módulo se divide en tres capas:

| Capa | Responsabilidad | Ejemplo |
|---|---|---|
| `domain/` | Entidades y contratos (interfaces). No depende de Flutter ni de Supabase. | `AppUser`, `AuthRepository` |
| `data/` | Implementación real que habla con la base de datos. | `AuthRepositoryImpl` (Supabase) |
| `presentation/` | Pantallas, validadores y estado. | `LoginScreen`, `RegisterScreen` |

Esta separación permite que los tres integrantes trabajen en paralelo sin pisarse, y cumple el requerimiento de modularidad (RNF16).

### Estructura de carpetas

```
lib/
├── core/                  # Compartido: tema, router, widgets, utilidades
│   ├── constants/
│   ├── theme/
│   ├── router/
│   ├── widgets/
│   ├── utils/
│   └── errors/
├── features/              # Un módulo por funcionalidad
│   ├── auth/
│   │   ├── data/          # datasources, models, repositories
│   │   ├── domain/        # entities, repositories, usecases
│   │   └── presentation/  # providers, screens, validators, widgets
│   ├── marketplace/
│   ├── commerce_management/
│   ├── products/
│   ├── cart/
│   ├── orders/
│   ├── barbers/
│   ├── appointments/
│   ├── admin_panel/
│   └── notifications/
├── shared/                # Modelos y servicios usados por varios módulos
└── main.dart
database/                  # Scripts SQL versionados
test/                      # Pruebas automáticas
```

---

## Estado actual

| Funcionalidad | Estado |
|---|---|
| Estructura del proyecto y arquitectura | ✅ Hecho |
| Registro de usuario (RF-001) | ✅ Hecho |
| Inicio de sesión (RF-002) | ✅ Hecho |
| Seguridad de base de datos (RLS y rol en servidor) | ✅ Hecho |
| Política de contraseña robusta | 🔄 En curso |
| Recuperación de contraseña (RF-003) | ⬜ Pendiente |
| Perfil (RF-004) | ⬜ Pendiente |
| Manejo de sesión (Riverpod) y navegación por rol (go_router) | ⬜ Pendiente |
| Marketplace: inicio, búsqueda, filtros, comercios (RF-005 a RF-011) | ⬜ Pendiente |
| Módulos de Productos/Pedidos y Barberías/Citas | Ver ramas de cada integrante |

---

## Cómo ejecutar el proyecto

### Requisitos

- Flutter SDK instalado (`flutter doctor` sin errores en la parte de Android)
- Un emulador de Android o un celular con depuración USB
- Una cuenta de Supabase (y haber sido invitado al proyecto `cut-go`, o crear uno propio)

### Pasos

```bash
git clone https://github.com/Califlowpro1504/Computacion-movil.-proyecto.git
cd Computacion-movil.-proyecto
flutter pub get
```

### Configurar Supabase

1. En el panel de Supabase abre **Project Settings → API Keys** y copia la **Project URL** y la **Publishable key**.
2. Pégalas en `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: 'TU_PROJECT_URL',
     publishableKey: 'TU_PUBLISHABLE_KEY',
   );
   ```
3. En el **SQL Editor** de Supabase, crea la tabla de perfiles:
   ```sql
   create table profiles (
     id uuid references auth.users on delete cascade primary key,
     nombre text not null,
     apellido text not null,
     telefono text not null,
     rol text not null default 'cliente',
     terminos_aceptados boolean not null default false,
     activo boolean not null default true,
     fecha_registro timestamp with time zone default now()
   );
   ```
4. Ejecuta después el script `database/01_seguridad_profiles.sql`, que activa RLS y crea el trigger del perfil.

> **Importante:** usa solo la clave **publicable**. La **secret key** nunca debe ir en la app ni en el repositorio.

### Ejecutar

```bash
flutter run
```

### Pruebas

```bash
flutter test test/auth_validators_test.dart
```

---

## Seguridad

Aplicamos la seguridad desde el diseño, con controles en el servidor y no solo en la app.

| Control | Qué hace | Requerimiento |
|---|---|---|
| **RLS en `profiles`** | Cada usuario solo puede ver y editar su propio perfil. | RNF01, RNF03 |
| **Rol asignado en el servidor** | Un trigger de la base de datos crea el perfil con rol fijo `cliente`. La app no puede elegir el rol. | RNF03 |
| **Sin cambio de rol ni de estado** | La política de edición impide que un usuario se suba de rol o se reactive solo. | RNF03 |
| **Contraseña robusta** | Mínimo 8 caracteres, una mayúscula y un número. | RNF02 |
| **Mensajes genéricos en el login** | No revela si el correo existe o cuál dato falló. | RNF01 |
| **Contraseña fuera de la base** | La contraseña la gestiona Supabase Auth y nunca se guarda en `profiles`. | RNF01 |
| **Secretos fuera del repositorio** | Solo se usa la clave publicable. | RNF01 |

### Reglas del equipo

- Nunca subir claves secretas, contraseñas ni archivos de configuración con credenciales.
- Activar verificación en dos pasos en Supabase, GitHub y el correo.
- Cada miembro entra con su propia cuenta y con el rol mínimo necesario.
- Los cambios a la base de datos se guardan como scripts en `database/` y se revisan por Pull Request.
- Reactivar la confirmación de correo antes de la entrega final.

---

## Flujo de trabajo con Git

**Ramas**

- `main`: versión estable, la que se entrega.
- `develop`: integración del trabajo de los tres.
- `feature/...`, `fix/...`, `chore/...`: una rama por bloque de trabajo.

**Proceso**

1. Partir siempre de `develop` actualizado.
2. Crear una rama, hacer commits pequeños y subirla.
3. Abrir un Pull Request hacia `develop` y pedir revisión a un compañero.
4. Unir y borrar la rama.

**Formato de commits**

```
feat(auth): agrega pantalla de registro
fix(auth): acepta alias con + en el correo
security(db): activa RLS en profiles
test(auth): agrega pruebas de contraseñas
chore: ignora android/build en git
```

---

## Pendientes y deuda técnica conocida

- Las pantallas manejan su estado con `setState`. El `ViewModel` con Riverpod está planeado.
- Las pantallas crean `AuthRepositoryImpl()` directamente. Se corregirá entregando el repositorio mediante Riverpod, para que dependan de la interfaz.
- `usuarioActual` en el repositorio aún no carga el perfil.
- Recuperación de contraseña por SMS (RF-003) requiere configuración adicional.
- Configurar un servicio de correo propio (SMTP) para los correos de confirmación.

---

## Documentación de requerimientos

Los requerimientos funcionales (RF-001 a RF-034) y no funcionales (RNF01 a RNF20) están definidos en el documento de requerimientos del proyecto CUT & GO.
