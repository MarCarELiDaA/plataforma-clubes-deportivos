# Furtivos Padel Club - Flutter App

Aplicación Flutter para gestión de reservas de pistas de pádel, migrada desde la aplicación Android original.

## Características

- ✅ Autenticación de usuarios con Firebase Auth
- ✅ Registro de nuevos usuarios con datos adicionales
- ✅ Sistema de reservas de pistas
- ✅ Visualización de horarios disponibles
- ✅ Gestión de reservas personales
- ✅ Cancelación de reservas (con regla de 24 horas)
- ✅ Conexión a la misma base de datos Firebase Firestore
- ✅ Validación de conexión a internet
- ✅ Multiplataforma (Android e iOS)

## Estructura del Proyecto

```
lib/
├── main.dart                  # Punto de entrada de la aplicación
├── models/                    # Modelos de datos
│   ├── usuario.dart          # Modelo de usuario
│   ├── reserva.dart          # Modelo de reserva
│   └── pista_info.dart       # Modelo de información de pista
├── services/                  # Servicios de Firebase
│   ├── firebase_service.dart # Servicio de inicialización de Firebase
│   ├── auth_service.dart     # Servicio de autenticación
│   └── reserva_service.dart  # Servicio de reservas
├── screens/                   # Pantallas de la aplicación
│   ├── login_screen.dart     # Pantalla de login
│   ├── register_screen.dart  # Pantalla de registro
│   ├── home_screen.dart      # Pantalla principal (reservas)
│   ├── confirmation_screen.dart # Pantalla de confirmación
│   └── my_reservations_screen.dart # Pantalla de mis reservas
└── utils/                     # Utilidades
    └── network_utils.dart    # Utilidades de red
```

## Configuración

### Requisitos previos

1. Flutter SDK instalado
2. Android Studio / Xcode para compilación
3. Cuenta de Firebase (ya configurada con el proyecto original)

### Configuración de Firebase

La aplicación ya está configurada con las credenciales del proyecto Firebase original:

- **Project ID**: furtivosxml
- **API Key**: AIzaSyCgzQj-l2smjxWVy4fuhx8Ju6c5K8_2BYY
- **App ID**: 1:313903258233:android:5c81898e0f2601866192a8

El archivo `google-services.json` ya está configurado en `android/app/`.

### Dependencias

Las dependencias principales ya están configuradas en `pubspec.yaml`:

- `firebase_core`: ^3.6.0
- `firebase_auth`: ^5.3.1
- `cloud_firestore`: ^5.4.4
- `connectivity_plus`: ^6.0.3
- `intl`: ^0.19.0

## Ejecución

### Instalar dependencias

```bash
cd furtivos_padel_club_flutter
flutter pub get
```

### Ejecutar en Android

```bash
flutter run
```

### Ejecutar en iOS

```bash
flutter run -d ios
```

Nota: Para iOS, necesitarás configurar additionally el proyecto en Xcode y añadir el archivo `GoogleService-Info.plist` con las credenciales de Firebase.

## Funcionalidades Implementadas

### Autenticación
- Login con email y contraseña
- Registro de nuevos usuarios
- Validación de campos (email, contraseña mínima 6 caracteres)
- Cierre de sesión

### Sistema de Reservas
- Selección de fecha (hasta 60 días en adelante)
- Visualización de horarios disponibles
- Indicación de horarios reservados y pasados
- Confirmación de reserva con detalles
- Validación de conexión a internet

### Gestión de Reservas
- Lista de reservas del usuario
- Ordenamiento por fecha (futuras primero)
- Cancelación de reservas (solo 24h antes)
- Filtro de reservas (último mes a 2 meses futuras)

### Seguridad
- Validación de conexión a internet antes de operaciones
- Manejo de errores de Firebase
- Autenticación requerida para todas las operaciones
- Validación de campos en formularios

## Base de Datos

La aplicación utiliza la misma base de datos Firebase Firestore que la aplicación original:

### Colecciones

**usuarios**
- nombre: string
- email: string
- telefono: string (opcional)
- nivelPadel: double (opcional)
- fechaRegistro: timestamp

**reservas**
- usuarioId: string
- nombreUsuario: string
- pistaId: string
- fecha: string (formato yyyy-MM-dd)
- horaInicio: string (formato HH:mm)
- duracionMinutos: int
- estadoReserva: string (CONFIRMADA, CANCELADA_POR_USUARIO, CANCELADA_POR_ADMIN)
- fechaCreacionReserva: timestamp

**pistas**
- nombrePista: string
- descripcion: string
- estadoActual: string (DISPONIBLE, MANTENIMIENTO, CERRADA_TEMPORALMENTE)
- horarioAperturaClub: string
- horarioCierreClub: string
- franjasDisponiblesPorDefecto: array of strings
- duracionPartidoMinutos: int
- reglasUso: string (opcional)

## Notas

- La aplicación comparte la misma base de datos Firebase que la versión Android
- Los datos de usuarios y reservas son compatibles entre ambas versiones
- La aplicación valida la conexión a internet antes de realizar operaciones
- El diseño es funcional pero puede mejorarse estéticamente según tus preferencias

## Problemas Conocidos

- Para iOS, se necesita configurar adicionalmente el archivo `GoogleService-Info.plist`
- Algunos widgets pueden requerir ajustes de diseño para diferentes tamaños de pantalla

## Soporte

Para cualquier problema con la configuración de Firebase, consulta la documentación oficial de Firebase:
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Firebase Auth](https://firebase.google.com/docs/auth/flutter/start)
- [Cloud Firestore](https://firebase.google.com/docs/firestore/quickstart)