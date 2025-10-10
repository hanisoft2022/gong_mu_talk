import '../../profile/domain/career_track.dart';
import '../domain/user_session.dart';
import '../presentation/cubit/auth_cubit.dart';

/// Adapts [AuthCubit] state into the lightweight [UserSession] interface.
class AuthUserSession implements UserSession {
  AuthUserSession(AuthCubit authCubit)
    : _stateProvider = (() => authCubit.state);

  AuthUserSession.fromStateProvider(AuthState Function() stateProvider)
    : _stateProvider = stateProvider;

  final AuthState Function() _stateProvider;

  AuthState get _state => _stateProvider();

  @override
  CareerTrack get careerTrack => _state.careerTrack;

  @override
  String? get specificCareer => _state.careerHierarchy?.specificCareer;

  @override
  bool get serialVisible => _state.serialVisible;

  @override
  String get userId => _state.userId ?? 'anonymous';
}
