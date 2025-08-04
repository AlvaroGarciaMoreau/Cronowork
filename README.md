# 🕒 CronoWork

**Aplicación de seguimiento de tiempo de trabajo desarrollada en Flutter**

CronoWork es una aplicación móvil intuitiva y profesional para el seguimiento y gestión del tiempo de trabajo. Permite a los usuarios registrar sesiones de trabajo, categorizarlas y generar informes detallados con exportación a PDF.

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?style=flat&logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=flat&logo=firebase)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-3.7.2+-0175C2?style=flat&logo=dart)](https://dart.dev/)

## ✨ Características Principales

### 🎯 Gestión de Tiempo
- **Cronómetro en tiempo real** con inicio/pausa/detención de sesiones
- **Registro manual de sesiones** con fecha y hora personalizadas
- **Seguimiento de tiempo acumulado** por categoría y período

### 📂 Organización por Categorías
- **Creación y gestión de categorías** personalizadas
- **Clasificación automática** de sesiones de trabajo
- **Vista organizada** por tipo de actividad

### 📊 Informes y Análisis
- **Informes detallados** con filtros por fecha y categoría
- **Estadísticas de tiempo** trabajado por período
- **Exportación a PDF** con formato profesional
- **Visualización clara** del tiempo invertido en cada proyecto

### 🔐 Autenticación Segura
- **Sistema de login/registro** con Firebase Authentication
- **Datos sincronizados** en la nube
- **Acceso seguro** a información personal

## 🚀 Tecnologías Utilizadas

- **Flutter 3.7.2+** - Framework de desarrollo multiplataforma
- **Firebase Core** - Servicios backend en la nube
- **Firebase Auth** - Autenticación de usuarios
- **Cloud Firestore** - Base de datos NoSQL en tiempo real
- **Google Fonts** - Tipografías personalizadas
- **PDF Generation** - Exportación de informes
- **Intl** - Internacionalización y localización

## 📱 Capturas de Pantalla

### Pantallas Principales
- **Inicio**: Cronómetro principal y resumen de actividad
- **Categorías**: Gestión de categorías de trabajo
- **Informes**: Análisis detallado y exportación de datos

## ⚙️ Instalación y Configuración

### Prerrequisitos
- Flutter SDK 3.7.2 o superior
- Dart 3.7.2 o superior
- Android Studio / VS Code
- Cuenta de Firebase

### Configuración del Proyecto

1. **Clona el repositorio:**
   ```bash
   git clone https://github.com/AlvaroGarciaMoreau/Cronowork.git
   cd Cronowork
   ```

2. **Instala las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configura Firebase:**
   - Crea un proyecto en [Firebase Console](https://console.firebase.google.com/)
   - Habilita Authentication y Firestore Database
   - Descarga el archivo de configuración (`google-services.json` para Android)
   - Coloca el archivo en `android/app/`

4. **Ejecuta la aplicación:**
   ```bash
   flutter run
   ```

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.2
  cloud_firestore: ^5.6.6
  google_fonts: ^6.1.0
  intl: ^0.20.2
  pdf: ^3.10.8
  printing: ^5.12.0
  flutter_localizations:
    sdk: flutter
```

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── firebase_options.dart     # Configuración de Firebase
├── models/                   # Modelos de datos
│   ├── category.dart         # Modelo de categoría
│   └── session.dart          # Modelo de sesión de trabajo
└── screens/                  # Pantallas de la aplicación
    ├── home_screen.dart      # Pantalla principal con cronómetro
    ├── login_screen.dart     # Pantalla de inicio de sesión
    ├── register_screen.dart  # Pantalla de registro
    ├── categories_screen.dart # Gestión de categorías
    └── reports_screen.dart   # Informes y estadísticas
```

## 🎯 Funcionalidades Detalladas

### Seguimiento de Tiempo
- Cronómetro en tiempo real con precisión de segundos
- Persistencia de sesiones en Firestore
- Cálculo automático de duración de sesiones
- Soporte para sesiones manuales con fecha/hora personalizada

### Gestión de Categorías
- CRUD completo de categorías personalizadas
- Asignación de categorías a sesiones
- Filtrado de informes por categoría

### Sistema de Informes
- Filtros por rango de fechas
- Filtros por categoría específica
- Exportación automática a PDF
- Formato profesional de documentos

## 🌐 Localización

La aplicación soporta:
- **Español (ES)** - Idioma principal
- **Inglés (EN)** - Soporte secundario

## 🔧 Desarrollo

### Comandos Útiles

```bash
# Limpiar proyecto
flutter clean

# Actualizar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Compilar para release
flutter build apk --release
```

### Estructura de Datos

#### Sesión de Trabajo
```dart
{
  userId: String,
  categoryId: String,
  description: String,
  startTime: Timestamp,
  endTime: Timestamp?,
  duration: int (seconds)
}
```

#### Categoría
```dart
{
  name: String,
  userId: String,
  createdAt: Timestamp
}
```

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 Desarrollador

**Álvaro García Moreau**
- GitHub: [@AlvaroGarciaMoreau](https://github.com/AlvaroGarciaMoreau)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Si tienes alguna pregunta o sugerencia, no dudes en abrir un [issue](https://github.com/AlvaroGarciaMoreau/Cronowork/issues) en el repositorio.

---

⭐ ¡Si te gusta este proyecto, dale una estrella en GitHub!
