import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/notification_service.dart';
import '../core/theme/theme_cubit.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/data/government_email_repository.dart';
import '../features/auth/data/login_session_store.dart';
import '../features/auth/data/auth_user_session.dart';
import '../features/auth/domain/user_session.dart';
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
import '../features/calculator/domain/services/tax_calculator.dart';
import '../features/calculator/domain/services/insurance_calculator.dart';
import '../features/calculator/domain/services/career_simulation_engine.dart';
import '../features/calculator/domain/repositories/salary_table_repository.dart';
import '../features/calculator/data/repositories/salary_table_repository_impl.dart';
import '../features/calculator/data/datasources/salary_table_remote_data_source.dart';
import '../features/calculator/data/datasources/salary_table_local_data_source.dart';
import '../features/calculator/domain/usecases/simulate_career_usecase.dart';
import '../features/pension/domain/services/pension_calculator.dart';
import '../features/pension/domain/usecases/calculate_pension_usecase.dart';
import '../features/pension/presentation/cubit/pension_calculator_cubit.dart';

import '../features/community/data/community_repository.dart';
import '../features/community/data/community_repository_impl.dart';
import '../features/community/domain/repositories/i_community_repository.dart';
import '../features/community/domain/usecases/search_community.dart';


import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/community/presentation/cubit/post_detail_cubit.dart';
import '../features/community/presentation/cubit/search_cubit.dart';
import '../features/notifications/data/notification_repository.dart';

import '../routing/app_router.dart';
import '../features/profile/data/user_profile_repository.dart';
import '../features/profile/data/follow_repository.dart';
import '../features/profile/data/paystub_verification_repository.dart';
import '../features/profile/data/user_sensitive_info_repository.dart';
import '../features/profile/presentation/cubit/profile_timeline_cubit.dart';
import '../features/profile/presentation/cubit/profile_relations_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<GoRouter>()) {
    return;
  }

  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();

  getIt
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(getIt()))
    ..registerLazySingleton<GovernmentEmailRepository>(
      GovernmentEmailRepository.new,
    )
    ..registerLazySingleton<FirebaseAuthRepository>(
      () => FirebaseAuthRepository(governmentEmailRepository: getIt()),
    )
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    ..registerLazySingleton<NotificationService>(NotificationService.new)
    ..registerLazySingleton<LoginSessionStore>(
      () => LoginSessionStore(sharedPreferences),
    )
    ..registerLazySingleton<UserProfileRepository>(UserProfileRepository.new)
    ..registerLazySingleton<UserSensitiveInfoRepository>(
      UserSensitiveInfoRepository.new,
    )
    ..registerLazySingleton<FollowRepository>(
      () => FollowRepository(userProfileRepository: getIt()),
    )
    ..registerLazySingleton<NotificationRepository>(
      () => NotificationRepository(
        notificationService: getIt(),
        preferences: getIt(),
      ),
    )
    ..registerLazySingleton<AuthCubit>(
      () => AuthCubit(
        authRepository: getIt(),
        sessionStore: getIt(),
        userProfileRepository: getIt(),
        notificationRepository: getIt(),
      ),
    )
    ..registerLazySingleton<PaystubVerificationRepository>(
      () => PaystubVerificationRepository(authCubit: getIt()),
    )
    ..registerLazySingleton<UserSession>(
      () => AuthUserSession(getIt<AuthCubit>()),
    )
    ..registerLazySingleton<CommunityRepository>(
      () => CommunityRepository(
        userSession: getIt(),
        userProfileRepository: getIt(),
        notificationRepository: getIt(),
        authCubit: getIt(),
      ),
    )
    ..registerLazySingleton<ICommunityRepository>(
      () => CommunityRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<SearchCommunity>(
      () => SearchCommunity(getIt()),
    )
    ..registerFactory<CommunityFeedCubit>(
      () => CommunityFeedCubit(
        repository: getIt(),
        authCubit: getIt(),
        notificationRepository: getIt(),
      ),
    )
    ..registerFactory<ProfileTimelineCubit>(
      () => ProfileTimelineCubit(repository: getIt(), authCubit: getIt()),
    )
    ..registerFactory<ProfileRelationsCubit>(
      () =>
          ProfileRelationsCubit(followRepository: getIt(), authCubit: getIt()),
    )
    ..registerFactory<PostDetailCubit>(() => PostDetailCubit(getIt()))
    ..registerFactory<SearchCubit>(() => SearchCubit(getIt(), getIt(), getIt()))
    ..registerLazySingleton<GoRouter>(createRouter)
    // Calculator 서비스
    ..registerLazySingleton<TaxCalculator>(() => TaxCalculator())
    ..registerLazySingleton<InsuranceCalculator>(() => InsuranceCalculator())
    // Firestore
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    // Salary Table
    ..registerLazySingleton<SalaryTableRemoteDataSource>(
      () => SalaryTableRemoteDataSource(firestore: getIt()),
    )
    ..registerLazySingleton<SalaryTableLocalDataSource>(
      () => SalaryTableLocalDataSource(sharedPreferences: getIt()),
    )
    ..registerLazySingleton<SalaryTableRepository>(
      () => SalaryTableRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
      ),
    )
    // Career Simulation
    ..registerLazySingleton<CareerSimulationEngine>(
      () => CareerSimulationEngine(
        salaryTableRepository: getIt(),
        taxCalculator: getIt(),
        insuranceCalculator: getIt(),
      ),
    )
    ..registerLazySingleton<SimulateCareerUseCase>(
      () => SimulateCareerUseCase(engine: getIt()),
    )
    // Pension
    ..registerLazySingleton<PensionCalculator>(() => PensionCalculator())
    ..registerLazySingleton<CalculatePensionUseCase>(
      () => CalculatePensionUseCase(calculator: getIt()),
    )
    ..registerFactory<PensionCalculatorCubit>(
      () => PensionCalculatorCubit(calculatePension: getIt()),
    )
    ..registerLazySingleton<SalaryCalculatorLocalDataSource>(
      () => SalaryCalculatorLocalDataSource(
        taxCalculator: getIt(),
        insuranceCalculator: getIt(),
      ),
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
