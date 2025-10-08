import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/notification_service.dart';
import '../core/services/profile_storage_service.dart';
import '../core/theme/theme_cubit.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/data/government_email_repository.dart';
import '../features/auth/data/login_session_store.dart';
import '../features/auth/data/auth_user_session.dart';
import '../features/auth/domain/user_session.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/calculator/domain/services/tax_calculation_service.dart';
import '../features/calculator/domain/services/salary_calculation_service.dart';
import '../features/calculator/domain/services/pension_calculation_service.dart';
import '../features/calculator/domain/services/base_income_estimation_service.dart';
import '../features/calculator/domain/services/retirement_benefit_calculation_service.dart';
import '../features/calculator/domain/services/early_retirement_calculation_service.dart';
import '../features/calculator/domain/services/monthly_breakdown_service.dart';
import '../features/calculator/domain/usecases/calculate_lifetime_salary_usecase.dart';
import '../features/calculator/domain/usecases/calculate_pension_usecase.dart';
import '../features/calculator/domain/usecases/calculate_retirement_benefit_usecase.dart';
import '../features/calculator/domain/usecases/calculate_early_retirement_usecase.dart';
import '../features/calculator/domain/usecases/calculate_after_tax_pension_usecase.dart';
import '../features/calculator/domain/usecases/calculate_monthly_breakdown_usecase.dart';
import '../features/calculator/presentation/cubit/calculator_cubit.dart';

import '../features/community/data/community_repository.dart';
import '../features/community/data/community_repository_impl.dart';
import '../features/community/domain/repositories/i_community_repository.dart';
import '../features/community/domain/usecases/search_community.dart';

import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/community/presentation/cubit/search_cubit.dart';
import '../features/community/presentation/cubit/scrap_cubit.dart';
import '../features/community/presentation/cubit/liked_posts_cubit.dart';
import '../features/community/presentation/cubit/user_comments_cubit.dart';
import '../features/notifications/data/notification_repository.dart';

import '../routing/app_router.dart';
import '../features/profile/data/user_profile_repository.dart';
import '../features/profile/data/follow_repository.dart';
import '../features/profile/data/paystub_verification_repository.dart';
import '../features/profile/data/user_sensitive_info_repository.dart';
import '../features/profile/presentation/cubit/profile_timeline_cubit.dart';
import '../features/profile/presentation/cubit/profile_relations_cubit.dart';
import '../features/profile/presentation/cubit/notification_preferences_cubit.dart';

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
    ..registerLazySingleton<ProfileStorageService>(
      () => ProfileStorageService(sharedPreferences),
    )
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
    ..registerLazySingleton<SearchCommunity>(() => SearchCommunity(getIt()))
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
    ..registerLazySingleton<NotificationPreferencesCubit>(
      NotificationPreferencesCubit.new,
    )
    ..registerFactory<SearchCubit>(() => SearchCubit(getIt(), getIt(), getIt()))
    ..registerFactory<ScrapCubit>(() => ScrapCubit(getIt()))
    ..registerFactory<LikedPostsCubit>(() => LikedPostsCubit(getIt()))
    ..registerFactory<UserCommentsCubit>(() => UserCommentsCubit(getIt()))
    // Calculator services
    ..registerLazySingleton<TaxCalculationService>(TaxCalculationService.new)
    ..registerLazySingleton<SalaryCalculationService>(
      () => SalaryCalculationService(getIt()),
    )
    ..registerLazySingleton<PensionCalculationService>(
      PensionCalculationService.new,
    )
    ..registerLazySingleton<BaseIncomeEstimationService>(
      BaseIncomeEstimationService.new,
    )
    ..registerLazySingleton<RetirementBenefitCalculationService>(
      RetirementBenefitCalculationService.new,
    )
    ..registerLazySingleton<EarlyRetirementCalculationService>(
      EarlyRetirementCalculationService.new,
    )
    ..registerLazySingleton<MonthlyBreakdownService>(
      () => MonthlyBreakdownService(getIt(), getIt()),
    )
    // Calculator usecases
    ..registerLazySingleton<CalculateLifetimeSalaryUseCase>(
      () => CalculateLifetimeSalaryUseCase(getIt()),
    )
    ..registerLazySingleton<CalculatePensionUseCase>(
      () => CalculatePensionUseCase(getIt()),
    )
    ..registerLazySingleton<CalculateRetirementBenefitUseCase>(
      () => CalculateRetirementBenefitUseCase(getIt()),
    )
    ..registerLazySingleton<CalculateEarlyRetirementUseCase>(
      () => CalculateEarlyRetirementUseCase(getIt()),
    )
    ..registerLazySingleton<CalculateAfterTaxPensionUseCase>(
      () => CalculateAfterTaxPensionUseCase(getIt()),
    )
    ..registerLazySingleton<CalculateMonthlyBreakdownUseCase>(
      () => CalculateMonthlyBreakdownUseCase(getIt()),
    )
    // Calculator cubit - LazySingleton으로 앱 전체에서 단일 인스턴스 유지
    ..registerLazySingleton<CalculatorCubit>(
      () => CalculatorCubit(
        calculateLifetimeSalaryUseCase: getIt(),
        calculatePensionUseCase: getIt(),
        calculateRetirementBenefitUseCase: getIt(),
        calculateEarlyRetirementUseCase: getIt(),
        calculateAfterTaxPensionUseCase: getIt(),
        calculateMonthlyBreakdownUseCase: getIt(),
        profileStorageService: getIt(),
      ),
    )
    ..registerLazySingleton<GoRouter>(createRouter)
    // Firestore
    ..registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
}
