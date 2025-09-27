enum AppEnvironment { dev, staging, prod }

class AppConfig {
  AppConfig._(this.environment);

  final AppEnvironment environment;

  static AppConfig? _instance;

  static AppConfig get instance =>
      _instance ?? const AppConfig._internalDefault();

  static void initialize({AppEnvironment environment = AppEnvironment.dev}) {
    _instance = AppConfig._(environment);
  }

  const AppConfig._internalDefault() : environment = AppEnvironment.dev;

  bool get isDev => environment == AppEnvironment.dev;

  bool get isStaging => environment == AppEnvironment.staging;

  bool get isProd => environment == AppEnvironment.prod;
}
