enum EstadoViaje { pendiente, pasado }

class Viaje {
  final String titulo;
  final String ubicacion;
  final String imagenUrl;
  final int calificacion; // de 0 a 5
  final int precioUsd;    // por persona
  final EstadoViaje estado;
  final List<String>  servicios;

  const Viaje({
    required this.titulo,
    required this.ubicacion,
    required this.imagenUrl,
    required this.calificacion,
    required this.precioUsd,
    required this.estado,
    required this.servicios,
  });
}

// Datos de ejemplo
const viajesDemo = <Viaje>[
  Viaje(
    titulo: 'Salar de Uyuni',
    ubicacion: 'Potosí, Bolivia',
    imagenUrl:
        'https://images.pexels.com/photos/17507607/pexels-photo-17507607.jpeg',
    calificacion: 5,
    precioUsd: 250,
    estado: EstadoViaje.pendiente,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Isla del Sol',
    ubicacion: 'Lago Titicaca, La Paz, Bolivia',
    imagenUrl:
        'https://images.pexels.com/photos/17895232/pexels-photo-17895232.jpeg',
    calificacion: 4,
    precioUsd: 180,
    estado: EstadoViaje.pendiente,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Tiwanaku',
    ubicacion: 'La Paz, Bolivia',
    imagenUrl:
        'https://images.pexels.com/photos/19032101/pexels-photo-19032101.jpeg',
    calificacion: 5,
    precioUsd: 90,
    estado: EstadoViaje.pasado,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Cristo de la Concordia',
    ubicacion: 'Cochabamba, Bolivia',
    imagenUrl:
        'https://images.pexels.com/photos/15013675/pexels-photo-15013675.jpeg',
    calificacion: 3,
    precioUsd: 60,
    estado: EstadoViaje.pendiente,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Laguna Colorada',
    ubicacion: 'Reserva Nacional Eduardo Avaroa, Potosí, Bolivia',
    imagenUrl:
        'https://images.pexels.com/photos/7124359/pexels-photo-7124359.jpeg',
    calificacion: 5,
    precioUsd: 210,
    estado: EstadoViaje.pendiente,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Camino de la Muerte',
    ubicacion: 'Yungas, La Paz, Bolivia',
    imagenUrl:
        'https://media.istockphoto.com/id/499536590/es/foto/viajes-de-aventura-en-carretera-de-monta%C3%B1a-en-descenso-de-la-muerte.jpg?s=612x612&w=0&k=20&c=Eo6jQdoe5n2HkXaW6z40WcWxSjRV3ODLjQqL--gYSTM=',
    calificacion: 4,
    precioUsd: 150,
    estado: EstadoViaje.pasado,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Coroico',
    ubicacion: 'Yungas, La Paz, Bolivia',
    imagenUrl:
        'https://media.istockphoto.com/id/859293544/es/foto/niebla-de-la-ma%C3%B1ana-sobre-el-camino-de-la-muerte-en-los-yungas-de-bolivia.jpg?s=612x612&w=0&k=20&c=WXPBBZhAKcy-cqtf-X8OsaaD1a0taHEB6mGRuu9E_MA=',
    calificacion: 4,
    precioUsd: 120,
    estado: EstadoViaje.pendiente,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Samaipata',
    ubicacion: 'Santa Cruz, Bolivia',
    imagenUrl:
        'https://images.pexels.com/photos/11396013/pexels-photo-11396013.jpeg',
    calificacion: 5,
    precioUsd: 170,
    estado: EstadoViaje.pendiente,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Parque Nacional Madidi',
    ubicacion: 'La Paz, Bolivia',
    imagenUrl:
        'https://media.istockphoto.com/id/2010206051/es/foto/el-parque-nacional-madidi-en-bolivia.jpg?s=612x612&w=0&k=20&c=uKx8nc5iqYQp_ygMQMqkum7l8UDyjj2RAXfcA3FVOk8=',
    calificacion: 5,
    precioUsd: 300,
    estado: EstadoViaje.pendiente,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
  Viaje(
    titulo: 'Ciudad Blanca de Sucre',
    ubicacion: 'Chuquisaca, Bolivia',
    imagenUrl:
        'https://media.istockphoto.com/id/859293856/es/foto/paisaje-de-sucre-y-san-felipe-neri-en-bolivia.jpg?b=1&s=612x612&w=0&k=20&c=JKwqJXeE1jVeKMlXNLNRGLzn8uMybShNpP4nQ3bSFiE=',
    calificacion: 4,
    precioUsd: 100,
    estado: EstadoViaje.pasado,
    servicios: ['Guía', 'Transporte', 'Hotel'],
  ),
];
