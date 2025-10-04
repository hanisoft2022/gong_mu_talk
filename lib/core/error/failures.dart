import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure([super.message]);
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}
