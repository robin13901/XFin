/// Exception thrown when a DAO operation fails precondition validation.
class DaoValidationException implements Exception {
  final String message;
  const DaoValidationException(this.message);

  @override
  String toString() => message;
}
