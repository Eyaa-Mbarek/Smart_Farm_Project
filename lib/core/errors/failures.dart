// Define abstract class Failure to represent different types of failures
abstract class Failure {
  final String message;

  Failure(this.message);
}

// Example concrete failures
class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  CacheFailure(String message) : super(message);
}

// Add more specific failure types as needed
