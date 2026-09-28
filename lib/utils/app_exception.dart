/// Exception "métier" dont le message peut être affiché tel quel à l'utilisateur.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
