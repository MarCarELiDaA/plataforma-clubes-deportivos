# 01 — ANÁLISIS TÉCNICO DE LA BASE

## Plataforma Clubes Deportivos

**Estado:** Análisis técnico inicial completado
**Base:** Copia funcional de Pádel Navales
**Tecnología:** Flutter / Dart / Firebase
**Fecha:** septiembre de 2026

---

# 1. OBJETIVO DEL DOCUMENTO

Este documento recoge el análisis técnico inicial realizado sobre la copia independiente utilizada como base para **Plataforma Clubes Deportivos**.

Su objetivo es determinar:

* qué existe actualmente;
* qué funcionalidad se puede reutilizar;
* qué elementos siguen siendo específicos de Pádel Navales;
* qué problemas deben corregirse;
* qué partes requieren refactorización;
* qué aspectos deben mantenerse temporalmente;
* y cuál debe ser el orden de evolución del proyecto.

Este documento describe el estado actual y no pretende cerrar todavía la arquitectura definitiva de la plataforma.

---

# 2. UBICACIÓN DE LA BASE

La copia analizada se encuentra en:

```text
C:\Users\marti\Desktop\ClubesDeportivos\extraido
```

El proyecto es independiente del proyecto original de Pádel Navales.

El proyecto original no debe modificarse como consecuencia de este desarrollo.

---

# 3. ESTADO GENERAL

La base actual es una aplicación Flutter funcional procedente de Pádel Navales.

La transformación hacia Plataforma Clubes Deportivos ya ha comenzado.

Actualmente existe una primera capa de configuración del cliente y parte de la lógica ya utiliza conceptos genéricos como:

```text
ClubConfig
Instalacion
AppConfig
instalacionId
```

Por tanto, la base no parte de cero.

La situación actual puede resumirse así:

```text
Base funcional
      ↓
Configuración del cliente iniciada
      ↓
Modelos parcialmente generalizados
      ↓
Servicios reutilizables parcialmente
      ↓
Pantallas funcionales
      ↓
Firebase propio de la nueva plataforma
      ↓
Reglas Firestore todavía heredadas
```

---

# 4. ESTRUCTURA ACTUAL

La carpeta `lib/` contiene actualmente 29 archivos Dart.

Estructura detectada:

```text
lib/
├── config/
├── models/
├── screens/
├── services/
├── theme/
└── utils/
```

No existe todavía una estructura completa de:

```text
core/
repositories/
providers/
widgets/
integrations/
```

No se considera necesario crear toda esa estructura inmediatamente.

La reorganización deberá realizarse progresivamente cuando exista una necesidad real.

---

# 5. CONFIGURACIÓN

Actualmente existe:

```text
lib/config/app_config.dart
lib/config/legal_config.dart
lib/config/club/club_config_actual.dart
lib/config/club/legal_config.dart
lib/config/club/legal_config_actual.dart
```

También existen:

```text
lib/models/club/club_config.dart
lib/models/club/instalacion.dart
```

La configuración ya permite centralizar parte de la identidad y de la estructura del cliente.

## Elementos actualmente configurables

`ClubConfig` contiene actualmente:

```text
nombre
deporte
logo
telefono
email
direccion
horario
fondo
instalaciones
administradores
```

`Instalacion` contiene actualmente:

```text
id
nombre
tipo
descripcion
imagen
activa
horarios
duracionReservaMinutos
maxReservasPorDia
maxMinutosPorDia
maxDiasAntelacion
normas
reservasActivas
pagosActivos
accesoDigitalActivo
```

Esto constituye una base útil para la futura configuración por cliente.

## Problema actual

`ClubConfigActual` sigue conteniendo directamente datos de Pádel Navales.

Ejemplos:

```text
Pádel Navales
923 30 01 83
aytonavales@yahoo.es
Pista de Pádel Municipal de Navales
horarios concretos
normas concretas
administrador concreto
```

Estos valores deben mantenerse como configuración del cliente de prueba mientras sean necesarios, pero no deben convertirse en arquitectura estructural de la plataforma.

---

# 6. MODELOS

## Usuario

El modelo actual contiene:

```text
nombre
email
telefono
nivelPadel
fechaRegistro
role
status
aceptaCondiciones
aceptaPrivacidad
fechaAceptaciones
versionCondiciones
versionPrivacidad
```

### Punto pendiente

`nivelPadel` es específico del dominio del pádel.

No debe asumirse que todos los clientes o deportes tengan un nivel de pádel.

Debe estudiarse posteriormente si:

```text
nivelPadel
```

permanece como propiedad específica del módulo de pádel o si se abstrae mediante otra estructura.

No debe eliminarse todavía.

---

## Reserva

El modelo `Reserva` ya utiliza:

```text
usuarioId
nombreUsuario
instalacionId
fecha
horaInicio
duracionMinutos
estadoReserva
fechaCreacionReserva
```

El uso de:

```text
instalacionId
```

es coherente con la evolución hacia un sistema genérico de instalaciones.

El modelo de estados actual es:

```text
confirmada
canceladaPorUsuario
canceladaPorAdmin
```

Es reutilizable como base, aunque deberá revisarse posteriormente cuando se definan definitivamente los módulos y estados de reservas.

---

## Instalacion

`Instalacion` es actualmente uno de los elementos mejor orientados hacia la futura plataforma.

Permite representar diferentes recursos mediante:

```text
id
nombre
tipo
deporte indirectamente mediante configuración superior
horarios
duración
límites
normas
precio/módulos futuros
reservas
pagos
acceso
```

El concepto debe mantenerse y evolucionar progresivamente.

---

# 7. SERVICIOS

## AuthService

El servicio de autenticación utiliza:

```text
Firebase Authentication
Cloud Firestore
Google Sign-In
```

Las funciones principales son reutilizables:

```text
login
registro
logout
verificación de email
cambio de contraseña
lectura de perfil
lectura de rol
lectura de estado
Google Sign-In
```

### Problema

La asignación automática del administrador depende todavía de:

```text
AppConfig.esAdministrador(email)
```

Y la configuración actual contiene un email concreto.

Esto significa que la autenticación y la autorización todavía están parcialmente mezcladas.

### Evolución prevista

La plataforma deberá evolucionar hacia:

```text
Usuario
   ↓
Rol
   ↓
Permisos
   ↓
Cliente
```

La identificación del administrador no debería depender permanentemente de emails escritos en el código.

---

## ReservaService

Actualmente gestiona:

```text
horarios reservados
creación de reservas
verificación de disponibilidad
reservas del usuario
cancelación
límites diarios
tiempo reservado
reservas consecutivas
antelación máxima
límite de cancelación
```

Es una de las partes más reutilizables de la aplicación.

Además, ya recibe un objeto `Instalacion`, lo que permite utilizar parte de la configuración del recurso:

```text
maxDiasAntelacion
maxReservasPorDia
maxMinutosPorDia
duracionReservaMinutos
```

### Problemas pendientes

Todavía existen textos y supuestos heredados del caso concreto de Pádel Navales.

También debe revisarse posteriormente:

* formato de fechas;
* reglas de cancelación;
* reglas de reservas consecutivas;
* límites;
* comportamiento para instalaciones con reglas diferentes.

No se debe reescribir este servicio todavía.

---

## AdminService

Actualmente permite:

```text
consultar usuarios pendientes
aprobar usuarios
rechazar usuarios
```

La funcionalidad es reutilizable.

La principal evolución futura será separar:

```text
administración
```

de:

```text
usuario administrador concreto
```

La autorización real deberá acabar respaldándose en reglas/backend y no solo en la interfaz.

---

## NotificationService

Actualmente gestiona:

```text
notificaciones locales
confirmación
recordatorios
cancelaciones
cancelación de recordatorios
timezone
```

No contiene referencias directas a Pádel Navales.

Por tanto, es un componente bastante reutilizable.

### Punto pendiente

Se ha detectado una posible inconsistencia de formatos de fecha.

El servicio de notificaciones interpreta:

```text
dd/MM/yyyy
```

mientras que `ReservaService` utiliza:

```text
yyyy-MM-dd
```

Esto debe normalizarse posteriormente.

No se debe corregir de forma aislada sin revisar primero cómo generan y consumen las fechas las pantallas.

---

# 8. FIREBASE

La plataforma utiliza actualmente el proyecto:

```text
clubes-deportivos-a07c9
```

Identificadores detectados:

```text
Android:
com.clubesdeportivos.app

iOS:
com.clubesdeportivos.app

Web:
Clubes Deportivos
```

El Firebase actual ya no corresponde al proyecto original de Pádel Navales.

Esto constituye un avance importante en la separación técnica.

---

# 9. FIRESTORE

Las colecciones utilizadas actualmente por el código son:

```text
usuarios
reservas
```

No se ha detectado uso desde el código Dart de una colección:

```text
pistas
```

Sin embargo, las reglas de Firestore todavía contienen:

```text
match /pistas/{pistaId}
```

Existe por tanto una diferencia entre:

```text
MODELO ACTUAL DEL CÓDIGO
    ↓
instalaciones
```

y:

```text
MODELO HEREDADO DE LAS REGLAS
    ↓
pistas
```

Esta incompatibilidad debe resolverse durante la fase de seguridad/refactorización.

---

# 10. REGLAS FIRESTORE

Las reglas actuales son heredadas de la aplicación original.

Se han identificado varios problemas.

## 10.1 Administrador hardcodeado

Las reglas contienen un email concreto:

```text
martin.bautista.sanchez@gmail.com
```

No debe mantenerse como mecanismo definitivo de autorización de la plataforma.

---

## 10.2 Ruta de comprobación administrativa

Las reglas contienen una comprobación de usuario administrador mediante un `get()` cuya ruta aparece incompleta en el estado actual.

Esto requiere revisión antes de considerar las reglas preparadas para producción.

---

## 10.3 Modelo de pistas heredado

Las reglas todavía incluyen:

```text
/pistas/{pistaId}
```

mientras que la aplicación actual utiliza:

```text
Instalacion
instalacionId
```

---

## 10.4 Reservas

Las reglas actuales permiten consultar reservas a usuarios autenticados y restringen parcialmente la creación y actualización.

El modelo debe revisarse antes de utilizar la plataforma comercialmente.

Especialmente deberán protegerse:

```text
usuarioId
estadoReserva
instalacionId
fecha
horaInicio
duracionMinutos
```

La seguridad no debe depender únicamente de los controles de la interfaz.

---

# 11. PANTALLAS

Se han identificado 12 pantallas:

```text
admin_screen.dart
confirmation_screen.dart
home_screen.dart
info_screen.dart
login_screen.dart
my_reservations_screen.dart
privacy_screen.dart
profile_screen.dart
register_screen.dart
reserva_screen.dart
splash_screen.dart
terms_screen.dart
```

## Flujo actual

El flujo principal es aproximadamente:

```text
Login
  ↓
Home
  ├── Reserva
  ├── Mis reservas
  ├── Perfil
  ├── Información
  └── Administración
```

También existe:

```text
Login
  ↓
Registro
```

y el flujo de arranque pasa por:

```text
Splash
  ↓
Login
```

según el estado correspondiente.

---

# 12. RESPONSABILIDADES DE LAS PANTALLAS

## AdminScreen

Gestiona usuarios pendientes y acciones administrativas.

Muy ligada actualmente al modelo heredado de usuarios pendientes.

Reutilizable como base.

---

## ConfirmationScreen

Participa en la creación y confirmación de reservas y utiliza:

```text
AppConfig
ReservaService
AuthService
NotificationService
Firestore
```

Tiene una elevada concentración de responsabilidades.

Deberá simplificarse progresivamente.

---

## HomeScreen

Actúa como pantalla principal y punto de acceso a los módulos actuales.

Utiliza `AppConfig`.

Es una pieza importante para el futuro sistema modular.

---

## InfoScreen

Principalmente informativa.

Ya utiliza configuración del club.

Es fácilmente reutilizable.

---

## LoginScreen

Gestiona:

```text
autenticación
persistencia local
errores de acceso
Google Sign-In
navegación
```

Es reutilizable.

---

## MyReservationsScreen

Gestiona:

```text
reservas del usuario
cancelaciones
notificaciones
navegación
```

Debe mantenerse como módulo de reservas.

---

## PrivacyScreen / TermsScreen

Actualmente consumen configuración.

Los contenidos legales deberán evolucionar para que cada cliente tenga su propia documentación.

---

## ProfileScreen

Gestiona datos del usuario y cambio de contraseña.

Actualmente tiene dependencia específica de:

```text
nivelPadel
```

Es uno de los puntos que deberá adaptarse para evitar asumir que todos los usuarios pertenecen al pádel.

---

## RegisterScreen

Gestiona:

```text
registro
datos personales
nivelPadel
aceptaciones legales
Firebase
navegación
```

Es una pantalla con bastante lógica y deberá revisarse posteriormente para distinguir:

```text
campos generales
```

de:

```text
campos específicos de un módulo
```

---

## ReservaScreen

Es actualmente una de las pantallas mejor orientadas a la nueva plataforma.

Ya utiliza:

```text
List<Instalacion>
AppConfig.club.instalaciones
instalacionId
horarios
duración
límites
```

Esto permite seleccionar entre diferentes instalaciones.

Debe conservarse como base del módulo de reservas.

---

## SplashScreen

Inicializa Firebase y notificaciones y gestiona el arranque.

Reutilizable.

---

# 13. NAVEGACIÓN

La aplicación utiliza navegación tradicional de Flutter mediante:

```text
Navigator.push
Navigator.pushReplacement
Navigator.pushAndRemoveUntil
```

No se utiliza:

```text
GoRouter
```

ni se ha detectado un sistema de rutas centralizado mediante `routes:`.

No existe necesidad inmediata de sustituir este sistema.

La navegación puede refactorizarse posteriormente cuando la arquitectura de módulos esté definida.

---

# 14. DEPENDENCIAS

Dependencias principales detectadas:

```text
firebase_core
firebase_auth
cloud_firestore
google_sign_in
connectivity_plus
intl
shared_preferences
flutter_local_notifications
timezone
url_launcher
flutter_localizations
```

Dependencias de desarrollo:

```text
flutter_test
flutter_launcher_icons
flutter_lints
```

No se ha identificado la necesidad inmediata de incorporar nuevas dependencias.

La prioridad debe ser reutilizar las existentes y evitar complejidad innecesaria.

---

# 15. VERSIONES

El `pubspec.yaml` declara:

```text
Dart SDK:
^3.10.7
```

El entorno local utilizado actualmente devuelve:

```text
Flutter 3.47.1
Dart 3.13.1
```

Anteriormente la documentación del proyecto recogía:

```text
Flutter 3.38.6
Dart 3.10.7
```

Esta diferencia debe considerarse una cuestión documental/de entorno.

No se debe realizar una actualización de Flutter o Dart como parte de este diagnóstico.

---

# 16. RECURSOS

Actualmente existen:

```text
assets/images/fondo.png
assets/images/logofinal1.png
assets/images/pistanavales.png
```

Los recursos deben clasificarse como:

```text
identidad del cliente
```

o:

```text
recurso funcional genérico
```

Actualmente:

```text
logofinal1.png
fondo.png
```

están asociados a la identidad visual del cliente actual.

```text
pistanavales.png
```

es un recurso claramente específico de la instalación de Navales.

No se deben eliminar hasta comprobar todos sus usos.

---

# 17. IDENTIDAD DE LAS PLATAFORMAS

## Android

Actualmente:

```text
namespace:
com.clubesdeportivos.app

applicationId:
com.clubesdeportivos.app
```

## iOS

Actualmente:

```text
PRODUCT_BUNDLE_IDENTIFIER:
com.clubesdeportivos.app

MARKETING_VERSION:
1.0
```

## Web

Actualmente:

```text
Título:
Clubes Deportivos

Nombre PWA:
Clubes Deportivos
```

La identidad técnica de Android, iOS y Web está correctamente orientada hacia la nueva plataforma.

---

# 18. CÓDIGO HEREDADO IDENTIFICADO

Los principales elementos heredados o específicos detectados son:

```text
Pádel Navales
Pista de Pádel Municipal de Navales
Ayuntamiento de Navales
horarios concretos
normas concretas
administrador concreto
nivelPadel
pistas en Firestore Rules
assets específicos de Navales
```

Estos elementos no deben convertirse en arquitectura general de la plataforma.

---

# 19. ELEMENTOS QUE CONVIENE CONSERVAR

Como base reutilizable destacan:

```text
Firebase Authentication
Cloud Firestore
Google Sign-In
AuthService
ReservaService
NotificationService
AdminService
Reserva
Instalacion
ClubConfig
AppConfig
flujo de autenticación
flujo de reservas
pantalla de reservas
gestión de reservas del usuario
sistema legal
soporte Android/iOS/Web
```

La reutilización deberá realizarse progresivamente.

---

# 20. ELEMENTOS QUE REQUIEREN REFACTORIZACIÓN

Prioridades identificadas:

```text
1. Roles y permisos
2. Reglas Firestore
3. Configuración del cliente
4. Modelo Usuario
5. Reglas de reservas
6. Normalización de fechas
7. Modularidad
8. Pantallas con demasiada lógica
9. Identidad y recursos
10. Documentación
```

---

# 21. ELEMENTOS QUE NO DEBEN TOCARSE TODAVÍA

No se recomienda todavía:

```text
reescribir todas las pantallas
crear la web completa
crear pagos
integrar control de acceso
cambiar nuevamente Firebase
reorganizar todo lib/
eliminar código heredado sin comprobar sus usos
eliminar assets sin revisar referencias
introducir nuevos frameworks
```

La transformación debe ser incremental.

---

# 22. ORDEN RECOMENDADO DE EVOLUCIÓN

El orden recomendado es:

```text
ANÁLISIS
   ↓
SEPARACIÓN PLATAFORMA / CLIENTE
   ↓
CONFIGURACIÓN CENTRAL
   ↓
MODULARIDAD
   ↓
SEGURIDAD
   ↓
FIREBASE DE DESARROLLO
   ↓
CLUB DEMO
   ↓
REFACTORIZACIÓN PROGRESIVA
   ↓
DISEÑO PROFESIONAL
   ↓
WEB
   ↓
INTEGRACIONES
   ↓
PRODUCTO COMERCIAL
```

No se debe intentar ejecutar todas las fases simultáneamente.

---

# 23. PRÓXIMAS PRIORIDADES

Una vez cerrado este diagnóstico, las prioridades técnicas son:

### Prioridad 1 — Separación de cliente

Reducir progresivamente la dependencia directa de:

```text
Pádel Navales
```

y concentrar la identidad del cliente en configuración.

### Prioridad 2 — Modelo de roles

Eliminar progresivamente la dependencia de:

```text
email → administrador
```

y evolucionar hacia:

```text
usuario → rol → permisos
```

### Prioridad 3 — Firestore

Rediseñar las reglas para que coincidan con el modelo actual:

```text
usuarios
reservas
instalaciones/configuración
```

y preparar el aislamiento y la autorización correctamente.

### Prioridad 4 — Modularidad

Separar conceptualmente:

```text
Reservas
Usuarios
Administración
Notificaciones
Legal
Pádel
```

para que los módulos puedan activarse o desactivarse.

### Prioridad 5 — Cliente Demo

Crear posteriormente un cliente genérico:

```text
Club Deportivo Demo
```

que permita demostrar que la plataforma funciona sin depender de Navales.

---

# 24. RIESGOS

Los principales riesgos identificados son:

```text
Reglas Firestore incorrectas
Autorización basada en email
Dependencia de datos de Navales
Suposiciones específicas de pádel
Duplicación de configuración
Lógica excesiva dentro de pantallas
Inconsistencia de fechas
Uso accidental de infraestructura de producción
Eliminación prematura de código heredado
Complejidad arquitectónica innecesaria
```

La seguridad de Firestore debe considerarse especialmente prioritaria antes de un uso comercial.

---

# 25. CONCLUSIÓN

La base actual es válida para continuar el desarrollo de Plataforma Clubes Deportivos.

No es todavía una plataforma comercial genérica, pero ya dispone de varias piezas correctamente orientadas hacia esa finalidad.

Los mayores avances realizados hasta este punto son:

```text
Firebase propio
identidad técnica propia
configuración de club
modelo Instalacion
reservas basadas en instalacionId
soporte Android/iOS/Web
separación inicial respecto a Navales
```

Los principales trabajos pendientes son:

```text
roles
permisos
Firestore Rules
configuración definitiva
modularidad
modelo de usuario
separación de características específicas de pádel
cliente demo
```

La estrategia recomendada continúa siendo incremental:

```text
comprender
proteger
inventariar
diseñar
separar
configurar
modularizar
asegurar
probar
mejorar
integrar
comercializar
```

---

# 26. ESTADO DE ESTE DOCUMENTO

Este documento representa el diagnóstico técnico de la base en septiembre de 2026.

No sustituye al código fuente.

La fuente de verdad de la implementación continúa siendo el repositorio Git.

Las decisiones arquitectónicas definitivas deberán tomarse después de contrastar este diagnóstico con las necesidades reales del producto.
