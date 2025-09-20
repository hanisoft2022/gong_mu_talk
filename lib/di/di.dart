import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/data/login_session_store.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/calculator/data/datasources/calculator_local_data_source.dart';
import '../features/calculator/data/datasources/salary_reference_local_data_source.dart';
import '../features/calculator/data/repositories/calculator_repository_impl.dart';
import '../features/calculator/data/repositories/salary_reference_repository_impl.dart';
import '../features/calculator/domain/repositories/calculator_repository.dart';
import '../features/calculator/domain/repositories/salary_reference_repository.dart';
import '../features/calculator/domain/usecases/calculate_salary.dart';
import '../features/calculator/domain/usecases/get_base_salary_from_reference.dart';
import '../features/calculator/domain/usecases/get_salary_grades.dart';
import '../features/calculator/presentation/bloc/salary_calculator_bloc.dart';
import '../features/payments/data/bootpay_payment_service.dart';
import '../features/matching/data/matching_repository.dart';
import '../features/community/data/community_repository.dart';
import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/blind/data/blind_repository.dart';
import '../features/blind/presentation/cubit/blind_feed_cubit.dart';
import '../features/matching/presentation/cubit/matching_cubit.dart';
import '../routing/app_router.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<GoRouter>()) {
    return;
  }

  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  getIt
    ..registerLazySingleton<ThemeCubit>(ThemeCubit.new)
    ..registerLazySingleton<BootpayPaymentService>(BootpayPaymentService.new)
    ..registerLazySingleton<FirebaseAuthRepository>(FirebaseAuthRepository.new)
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    ..registerLazySingleton<LoginSessionStore>(() => LoginSessionStore(sharedPreferences))
    ..registerLazySingleton<AuthCubit>(
      () => AuthCubit(
        paymentService: getIt(),
        authRepository: getIt(),
        sessionStore: getIt(),
      ),
    )
    ..registerLazySingleton<MatchingRepository>(MatchingRepository.new)
    ..registerLazySingleton<CommunityRepository>(CommunityRepository.new)
    ..registerLazySingleton<BlindRepository>(BlindRepository.new)
    ..registerFactory<MatchingCubit>(
      () => MatchingCubit(repository: getIt(), authCubit: getIt()),
    )
    ..registerFactory<CommunityFeedCubit>(
      () => CommunityFeedCubit(repository: getIt(), authCubit: getIt()),
    )
    ..registerFactory<BlindFeedCubit>(
      () => BlindFeedCubit(repository: getIt()),
    )
    ..registerLazySingleton<GoRouter>(createRouter)
    ..registerLazySingleton<SalaryCalculatorLocalDataSource>(
      () => SalaryCalculatorLocalDataSource(),
    )
    ..registerLazySingleton<SalaryReferenceLocalDataSource>(
      () => SalaryReferenceLocalDataSource(),
    )
    ..registerLazySingleton<SalaryCalculatorRepository>(
      () => SalaryCalculatorRepositoryImpl(dataSource: getIt()),
    )
    ..registerLazySingleton<SalaryReferenceRepository>(
      () => SalaryReferenceRepositoryImpl(dataSource: getIt()),
    )
    ..registerLazySingleton<CalculateSalaryUseCase>(
      () => CalculateSalaryUseCase(repository: getIt()),
    )
    ..registerLazySingleton<GetSalaryGradesUseCase>(
      () => GetSalaryGradesUseCase(repository: getIt()),
    )
    ..registerLazySingleton<GetBaseSalaryFromReferenceUseCase>(
      () => GetBaseSalaryFromReferenceUseCase(repository: getIt()),
    )
    ..registerFactory<SalaryCalculatorBloc>(
      () => SalaryCalculatorBloc(
        calculateSalary: getIt(),
        getSalaryGrades: getIt(),
        getBaseSalaryFromReference: getIt(),
      ),
    );
}
