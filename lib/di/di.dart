import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/calculator/data/datasources/calculator_local_data_source.dart';
import '../features/calculator/data/repositories/calculator_repository_impl.dart';
import '../features/calculator/domain/repositories/calculator_repository.dart';
import '../features/calculator/domain/usecases/calculate_salary.dart';
import '../features/calculator/presentation/bloc/salary_calculator_bloc.dart';
import '../routing/app_router.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<GoRouter>()) {
    return;
  }

  getIt
    ..registerLazySingleton<ThemeCubit>(ThemeCubit.new)
    ..registerLazySingleton<AuthCubit>(AuthCubit.new)
    ..registerLazySingleton<GoRouter>(createRouter)
    ..registerLazySingleton<SalaryCalculatorLocalDataSource>(
      () => SalaryCalculatorLocalDataSource(),
    )
    ..registerLazySingleton<SalaryCalculatorRepository>(
      () => SalaryCalculatorRepositoryImpl(dataSource: getIt()),
    )
    ..registerLazySingleton<CalculateSalaryUseCase>(
      () => CalculateSalaryUseCase(repository: getIt()),
    )
    ..registerFactory<SalaryCalculatorBloc>(
      () => SalaryCalculatorBloc(calculateSalary: getIt()),
    );
}
