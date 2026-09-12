# Requisitos Técnicos para iOS - Furtivos Padel Club

## 🚨 ESTADO ACTUAL PARA iPHONE: ❌ NO FUNCIONA

## 📋 REQUISITOS OBLIGATORIOS PARA iOS:

### 1. HARDWARE/SOFTWARE REQUERIDO (OBLIGATORIO)

#### Mac con Xcode
- **Mac** (iMac, MacBook Pro, Mac mini, Mac Studio)
- **macOS** 12.0 o superior
- **Xcode** 14.0 o superior (gratis desde Mac App Store)
- **Mínimo 8GB RAM** (recomendado 16GB)
- **Mínimo 20GB espacio libre**

❌ **NO se puede compilar iOS desde Windows**

### 2. CUENTA DESARROLLADOR APPLE (OBLIGATORIO)

#### Apple Developer Program
- **Costo:** $99 USD/año
- **Incluye:**
  - Certificados de desarrollo
  - Certificados de distribución
  - Acceso a TestFlight
  - Acceso a App Store
  - Soporte técnico

#### Tipos de cuenta:
- **Individual:** Para desarrolladores independientes
- **Organización:** Para empresas/ayuntamientos (requiere documentación adicional)

### 3. CONFIGURACIÓN FIREBASE PARA iOS (OBLIGATORIO)

#### Pasos requeridos:
1. **Ir a Firebase Console**
2. **Añadir app iOS** al proyecto existente
3. **Descargar GoogleService-Info.plist**
4. **Configurar Bundle ID** en Xcode
5. **Añadir permisos** en Info.plist
6. **Configurar Firebase SDK** en proyecto iOS

#### Documentación necesaria:
- Bundle ID único (ej: com.furtivos.padelclub)
- App ID específico para iOS
- Team ID de Apple Developer

### 4. CERTIFICADOS Y PERFILES (OBLIGATORIO)

#### Certificados necesarios:
- **Development Certificate:** Para pruebas en dispositivos propios
- **Distribution Certificate:** Para distribución TestFlight/App Store
- **Provisioning Profiles:** Perfiles de aprovisionamiento

#### Requisitos:
- Registro de dispositivos UDID (para desarrollo)
- App ID registrado en Apple Developer
- Perfiles de aprovisionamiento válidos

### 5. CONFIGURACIÓN ESPECÍFICA iOS

#### Archivos a modificar en Xcode:
- **Info.plist:** Permisos de la app
- **Entitlements:** Capacidades de la app
- **Build Settings:** Configuración de compilación
- **Signing & Capabilities:** Firma de la app

#### Permisos a añadir en Info.plist:
```xml
<key>NSInternetUsageDescription</key>
<string>Esta app requiere internet para reservas de pistas</string>
<key>NSNetworkUsageDescription</key>
<string>Esta app requiere acceso a red para funcionar correctamente</string>
```

## 🛠️ PROCESO DE CONFIGURACIÓN iOS (ESTIMADO 1-2 SEMANAS)

### Paso 1: Preparación del entorno (1 día)
- [ ] Obtener Mac con Xcode
- [ ] Instalar Xcode y herramientas
- [ ] Configurar cuenta Apple Developer

### Paso 2: Configuración Firebase (1 día)
- [ ] Añadir app iOS en Firebase Console
- [ ] Descargar GoogleService-Info.plist
- [ ] Configurar proyecto Xcode con Firebase

### Paso 3: Configuración de certificados (2-3 días)
- [ ] Generar CSR (Certificate Signing Request)
- [ ] Crear certificados de desarrollo
- [ ] Crear certificados de distribución
- [ ] Configurar provisioning profiles

### Paso 4: Ajustes de código iOS (2-3 días)
- [ ] Añadir permisos en Info.plist
- [ ] Configurar settings específicos iOS
- [ ] Probar en dispositivo iOS real
- [ ] Ajustar diseño para iOS

### Paso 5: Compilación y pruebas (2-3 días)
- [ ] Compilar para iOS
- [ ] Probar en diferentes dispositivos iOS
- [ ] Solucionar problemas específicos de iOS
- [ ] Optimizar rendimiento

### Paso 6: Preparación para distribución (2-3 días)
- [ ] Configurar para TestFlight
- [ ] Preparar screenshots para App Store
- [ ] Redactar descripción de la app
- [ ] Cumplir requisitos de Apple

## 💰 COSTOS TOTALES ESTIMADOS

### Hardware (si no tienes Mac):
- Mac mini M2: ~€700-900
- MacBook Pro M2: ~€1,500-2,000
- iMac: ~€1,200-1,800

### Software/Servicios:
- Cuenta Apple Developer: $99/año
- Xcode: Gratis
- Firebase: Gratis (plan suficiente)

### Desarrollo:
- Configuración inicial: 8-16 horas
- Ajustes específicos iOS: 16-32 horas
- Pruebas y optimización: 8-16 horas

## 🎯 ALTERNATIVAS PARA EVITAR REQUISITOS iOS:

### Opción 1: Usar solo Android
- Costo: €0
- Ventaja: Funciona perfectamente en Android
- Desventaja: No funciona en iPhone

### Opción 2: Contratar desarrollador iOS
- Costo: €500-2,000 (configuración)
- Ventaja: Evitas comprar Mac y aprender Xcode
- Desventaja: Dependencia de tercero

### Opción 3: Plataforma web (PWA)
- Costo: €0-100
- Ventaja: Funciona en cualquier dispositivo con navegador
- Desventaja: Experiencia de usuario inferior a app nativa

## 📝 CONCLUSIÓN

### Para que funcione en iPhone NECESITAS:
1. ✅ Mac con Xcode (OBLIGATORIO)
2. ✅ Cuenta Apple Developer ($99/año)
3. ✅ Configuración Firebase para iOS
4. ✅ Certificados y perfiles de Apple
5. ✅ Ajustes específicos de código iOS

### TIEMPO ESTIMADO: 1-2 semanas (con Mac)
### COSTO ESTIMADO: €700-2,000 (si necesitas Mac) + $99/año

### SIN ESTO: La app NO funcionará en iPhone bajo ninguna circunstancia.

---

## ⚠️ IMPORTANTE

Los requisitos de iOS son **rígidos y obligatorios**. No hay forma de evitarlos. Apple controla todo el ecosistema iOS y no permite distribución sin cumplir estos requisitos.