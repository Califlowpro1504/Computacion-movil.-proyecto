# Sesión y pantalla de inicio

La aplicación escucha los cambios de sesión de Supabase. Sin sesión muestra el
login; con sesión muestra el inicio. La persistencia la gestiona el SDK de Supabase.
Cerrar sesión afecta al dispositivo actual y devuelve al login sin dejar una
pantalla de inicio accesible con el botón Atrás. No se añadieron roles ni permisos:
las políticas RLS del servidor siguen siendo necesarias.

El inicio mantiene el tema oscuro; la sección Mi cuenta muestra el correo y el botón de cierre
que bloquea pulsaciones duplicadas y permite reintentar tras un error.
Los módulos del marketplace todavía no están implementados.

## Verificar

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run -d edge
```

1. Sin sesión, comprobar que aparece login.
2. Entrar con una cuenta de pruebas existente: aparece el inicio con su correo.
3. Recargar Edge y comprobar que el SDK restaura la sesión.
4. Abrir Mi cuenta y cerrar sesión: vuelve el login.
5. Recargar y usar Atrás: no debe aparecer información de la sesión cerrada.
6. Registrar una cuenta nueva y comprobar el comportamiento con la confirmación
   de correo configurada en Supabase. Una cuenta pendiente de confirmación no
   debe entrar hasta obtener una sesión válida.

Las pruebas de widgets usan eventos simulados: no demuestran autenticación real,
conectividad con Supabase ni persistencia del navegador. Esas comprobaciones
requieren realizar el recorrido manual anterior con una cuenta de pruebas.
