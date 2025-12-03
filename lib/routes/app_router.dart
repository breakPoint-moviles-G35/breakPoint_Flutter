class AppRouter {
  // 🔹 Autenticación
  static const String login = '/login';

  // 🔹 Usuario (Estudiante)
  static const String explore = '/explore';
  static const String filters = '/filters';
  static const String reservations = '/reservations';
  static const String reservation = '/reservation';
  static const String spaceDetail = '/spaceDetail';
  static const String profile = '/profile';
  static const String map = '/map';
  static const String rate = '/rate';
  static const String history = '/history';
  static const String changePassword = '/change-password';

  static const String faq = '/faq';
  static const String faqThread = '/faq-thread';
  // 🔹 Host / Arrendador
  static const String hostSpaces = '/host-spaces';      // Lista de espacios del host
  static const String createSpace = '/create-space';    // Crear nuevo espacio
  static const String hostProfile = '/host-profile';   
}
