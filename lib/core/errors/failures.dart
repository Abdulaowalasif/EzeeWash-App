import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  /// Converts technical exceptions into user-friendly strings.
  String get userMessage {
    final msg = message.toLowerCase();

    // Handle Supabase/Connection drops (common when phone locks)
    if (msg.contains('clientexception') ||
        msg.contains('socketexception') ||
        msg.contains('connection closed')) {
      return 'Connection lost. Please check your internet and try again.';
    }

    // Handle Timeouts
    if (msg.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    // Handle Authentication issues
    if (this is AuthFailure) {
      return message; // Usually Auth messages are already user-friendly
    }

    // Default simplified message for everything else
    return 'Something went wrong. Please try again later.';
  }

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error occurred']);
}
