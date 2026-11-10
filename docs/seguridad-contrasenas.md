# Contraseñas: implementación y verificación

## Qué cambió

El registro exige al menos 12 caracteres Unicode, permite frases largas y espacios,
y rechaza una lista local limitada de contraseñas comunes, entradas solo de espacios
y un único carácter repetido. No exige una combinación de mayúsculas, números y símbolos.
La lista no detecta todas las contraseñas débiles ni comprueba filtraciones.

La contraseña se envía tal como se escribe: no se recorta ni se cambia de mayúsculas.
La confirmación exige coincidencia exacta y se vuelve a validar si cambia la contraseña.
Los errores aparecen después de interactuar con los campos.
El inicio de sesión solo exige un valor no vacío para no bloquear cuentas antiguas.
Una futura pantalla de cambio de contraseña debe usar `validarPassword` y
`validarConfirmacion`; esa pantalla todavía no está implementada.

## 1. Revisar y probar en Flutter

Desde la raíz del proyecto, con Flutter compatible con Dart >=3.13 y Flutter >=3.47:

```sh
flutter pub get --enforce-lockfile
flutter test test/auth_validators_test.dart
flutter analyze
flutter run
```

Las pruebas cubren longitud, frases, espacios, patrones comunes, confirmación y
compatibilidad del inicio de sesión. El test original `test/widget_test.dart`
sigue siendo una prueba de contador que no corresponde a la aplicación actual;
no se incluye en la ejecución específica anterior. Debe actualizarse en otra tarea.

En registro, prueba una contraseña corta, `password1234` y una frase de 12 o más
caracteres. Escribe una confirmación correcta y cambia después la contraseña:
debe aparecer el error de coincidencia. No uses contraseñas reales para demostrarlo.

## 2. Configurar Supabase

1. Abre el proyecto correcto en el panel de Supabase.
2. En Authentication, busca la configuración del proveedor Email y de seguridad
   de contraseñas. Los nombres exactos pueden variar según la versión del panel.
3. Configura la longitud mínima en 12 y guarda.
4. Si está disponible en tu plan, activa el rechazo de contraseñas filtradas.
5. Conserva la aceptación de frases con espacios; las reglas obligatorias de tipos
   de caracteres deben coincidir con lo que anuncia el formulario.
6. Verifica en un proyecto de pruebas que una solicitud directa a Auth con menos
   de 12 caracteres sea rechazada. Usa una cuenta de prueba, sin incluir claves
   administrativas ni contraseñas en capturas, commits o terminal compartida.
7. Comprueba el registro con una frase válida y el login de una cuenta anterior.

Esta configuración se realiza en el servidor y no se aplica por cambiar Flutter.
La lista local de contraseñas comunes no se sincroniza automáticamente con Supabase.
No incluyas una clave `service_role` en la aplicación.

## 3. Hacer commits que puedas explicar

Revisa primero `git status` y `git diff`. Si también tienes cambios personales,
usa `git add -p` para seleccionar solo los fragmentos de esta tarea.

Primer commit: validación y pruebas.

```sh
git add lib/features/auth/presentation/validators/auth_validators.dart test/auth_validators_test.dart
git diff --cached
git commit -m "feat(auth): reforzar validación de contraseñas y añadir pruebas"
```

Segundo commit: integración en los formularios.

```sh
git add lib/features/auth/presentation/screens/register_screen.dart lib/features/auth/presentation/screens/login_screen.dart
git diff --cached
git commit -m "feat(auth): mostrar requisitos y validar confirmación en registro"
```

Tercer commit: documentación.

```sh
git add docs/seguridad-contrasenas.md
git diff --cached
git commit -m "docs(auth): documentar política de contraseñas y configuración de Supabase"
```

Comprueba tu rama con `git branch --show-current`, revisa `git log -3 --oneline`
y ejecuta `git push` si tiene seguimiento remoto. Si es una rama nueva, usa
`git push -u origin NOMBRE_DE_TU_RAMA` sustituyendo el nombre.
No publiques hasta revisar los cambios y los resultados de las pruebas.
Explica la asistencia utilizada según las reglas del curso.

Para la evaluación, distingue los cambios de código registrados en Git de la
configuración externa de Supabase. Documenta qué configuraste y cuándo, sin secretos.
No presentes comandos sin ejecutar como pruebas superadas.
