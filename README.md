# 🌍 Aplicación de Turismo - Bolivia

Aplicación **Web y Móvil** para la gestión de turismo en Bolivia.  
Incluye reservas, ventas, pagos, servicios de operadores, cotizaciones y recomendaciones inteligentes para mejorar la experiencia de viaje de los usuarios.

---

## 🚀 Tecnologías principales
- **Frontend Web**: React (para panel administrativo)
- **Frontend Móvil**: Flutter (Android & iOS)
- **Backend**: Django + Django REST Framework
- **Base de Datos**: PostgreSQL
- **Servicios Extra**: Integración con pasarelas de pago, geolocalización, notificaciones push

---

## 📂 Estructura del proyecto (Flutter App)

```bash
lib/
│── main.dart                # Punto de entrada
│
├── core/                    # Configuración global
│   ├── constants.dart       # Constantes (colores, rutas, textos)
│   ├── themes.dart          # Estilos y temas
│
├── models/                  # Modelos de datos
│   └── reserva.dart
│   └── usuario.dart
│
├── services/                # Servicios externos (API, DB)
│   └── api_service.dart
│
├── views/                   # Vistas (pantallas)
│   ├── home/
│   │   └── home_view.dart
│   ├── login/
│   │   └── login_view.dart
│   └── reservas/
│       └── reservas_view.dart
│
├── widgets/                 # Widgets reutilizables
│   ├── custom_button.dart
│   └── navbar.dart
│
└── utils/                   # Funciones helper
    └── formatters.dart
