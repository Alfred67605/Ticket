# Ticket Potosí 🎫

Aplicación móvil desarrollada en **Flutter** para la compra, gestión y control de entradas para eventos en la ciudad de Potosí.

---

## 📋 Requisitos Previos

Antes de ejecutar el proyecto, asegúrate de tener instalado lo siguiente en tu sistema:

1. **Flutter SDK**: [Guía de instalación oficial](https://docs.flutter.dev/get-started/install)
2. **Android Studio** o **Visual Studio Code** con los plugins de Flutter y Dart.
3. **Git**: Para clonar el repositorio.
4. **Dispositivo Físico o Emulador**:
   - Un dispositivo Android/iOS conectado en modo desarrollador (con depuración USB activada).
   - O un emulador de Android configurado desde Android Studio.

---

## 🚀 Pasos para ejecutar el proyecto

Sigue estos pasos paso a paso para levantar el proyecto en tu entorno local:

### 1. Clonar el repositorio
Abre tu terminal y clona el proyecto desde GitHub usando el siguiente comando:
```bash
git clone https://github.com/Alfred67605/Ticket.git
```

### 2. Navegar a la carpeta del proyecto
Ingresa al directorio del proyecto:
```bash
cd Ticket/ticket_potosi
```

### 3. Instalar las dependencias
Descarga todas las librerías y paquetes necesarios que utiliza la aplicación:
```bash
flutter pub get
```

### 4. Verificar la configuración (Opcional pero recomendado)
Asegúrate de que no haya problemas con tu instalación de Flutter y que tu dispositivo sea detectado:
```bash
flutter doctor
```
*(Asegúrate de que aparezca un dispositivo conectado en la lista).*

### 5. Ejecutar la aplicación
Una vez conectado tu dispositivo o emulador, compila y ejecuta el proyecto con:
```bash
flutter run
```

---

## 🛠 Comandos Útiles

Si durante el desarrollo realizas cambios o tienes problemas de caché, estos comandos te salvarán la vida:

- **Limpiar el proyecto (borrar caché de compilación):**
  ```bash
  flutter clean
  flutter pub get
  ```
- **Actualizar dependencias a sus últimas versiones compatibles:**
  ```bash
  flutter pub upgrade
  ```

---

## 📱 Tecnologías y Librerías Principales
- **Framework:** Flutter (Dart)
- **Base de Datos Local:** SQLite (`sqflite`)
- **Manejo de Estado:** Providers o setState nativo.
- **Reproducción Multimedia:** `video_player`
