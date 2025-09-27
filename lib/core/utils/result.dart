import 'package:dartz/dartz.dart';

/// 공통 오류 타입 정의
abstract class AppError {
  const AppError();
  String get message;
}

/// 네트워크 오류
class NetworkError extends AppError {
  const NetworkError([this.details = '네트워크 연결을 확인해주세요.']);
  final String details;

  @override
  String get message => details;
}

/// 서버 오류
class ServerError extends AppError {
  const ServerError([this.details = '서버에 문제가 발생했습니다.']);
  final String details;

  @override
  String get message => details;
}

/// 인증 오류
class AuthError extends AppError {
  const AuthError([this.details = '로그인이 필요합니다.']);
  final String details;

  @override
  String get message => details;
}

/// 유효성 검사 오류
class ValidationError extends AppError {
  const ValidationError(this.details);
  final String details;

  @override
  String get message => details;
}

/// 알 수 없는 오류
class UnknownError extends AppError {
  const UnknownError([this.details = '알 수 없는 오류가 발생했습니다.']);
  final String details;

  @override
  String get message => details;
}

/// Result 타입 별칭 정의
typedef AppResult<T> = Either<AppError, T>;

/// Result 확장 메서드들
extension AppResultExtensions<T> on AppResult<T> {
  /// 성공 여부 확인
  bool get isSuccess => isRight();

  /// 실패 여부 확인
  bool get isFailure => isLeft();

  /// 성공 데이터 반환 (null 가능)
  T? get data => fold((error) => null, (data) => data);

  /// 오류 반환 (null 가능)
  AppError? get error => fold((error) => error, (data) => null);

  /// 성공 시 실행할 콜백
  AppResult<T> onSuccess(void Function(T data) callback) {
    return fold(
      (error) => this,
      (data) {
        callback(data);
        return this;
      },
    );
  }

  /// 실패 시 실행할 콜백
  AppResult<T> onFailure(void Function(AppError error) callback) {
    return fold(
      (error) {
        callback(error);
        return this;
      },
      (data) => this,
    );
  }

  /// 다른 타입으로 변환
  AppResult<R> map<R>(R Function(T data) mapper) {
    return fold(
      (error) => Left(error),
      (data) => Right(mapper(data)),
    );
  }

  /// 비동기 변환
  Future<AppResult<R>> mapAsync<R>(Future<R> Function(T data) mapper) async {
    return fold(
      (error) => Left(error),
      (data) async => Right(await mapper(data)),
    );
  }
}

/// Result 생성 헬퍼 함수들
class AppResultHelpers {
  AppResultHelpers._();

  /// 성공 결과 생성
  static AppResult<T> success<T>(T data) => Right(data);

  /// 실패 결과 생성
  static AppResult<T> failure<T>(AppError error) => Left(error);

  /// try-catch를 Result로 변환
  static AppResult<T> tryCall<T>(T Function() callback) {
    try {
      return Right(callback());
    } catch (e) {
      return Left(UnknownError(e.toString()));
    }
  }

  /// 비동기 try-catch를 Result로 변환
  static Future<AppResult<T>> tryCallAsync<T>(Future<T> Function() callback) async {
    try {
      return Right(await callback());
    } catch (e) {
      return Left(UnknownError(e.toString()));
    }
  }
}