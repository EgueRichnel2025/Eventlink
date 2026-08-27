/// Exception réseau porteuse d'un message déjà adapté à l'affichage utilisateur
/// (jamais une trace technique brute comme "SocketException").
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  bool get estNonAutorise => statusCode == 401;
  bool get estInterdit => statusCode == 403;
  bool get estIntrouvable => statusCode == 404;

  @override
  String toString() => message;
}
