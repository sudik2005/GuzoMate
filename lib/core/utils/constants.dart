/// App-wide constants
class AppConstants {
  // App info
  static const String appName = 'GuzoMate';
  static const String appTagline = 'Walk Together, Connect Forever';
  
  // Subscription
  static const String premiumProductId = 'guzomate_plus_monthly';
  static const int freeDailyWalkInviteLimit = 1;
  
  // Location
  static const double defaultSearchRadiusKm = 10.0;
  static const double locationUpdateIntervalMeters = 10.0;
  
  // Matching
  static const double minCompatibilityScore = 0.3;
  static const int maxMatchesPerDay = 50;
  
  // Chat
  static const int maxMessageLength = 1000;
  static const int maxUnreadMessages = 99;
  
  // Profile
  static const int minAge = 18;
  static const int maxAge = 100;
  static const int maxPhotos = 6;
  static const int maxBioLength = 500;
  static const int maxInterests = 10;
  
  // Routes
  static const double minRouteDistanceKm = 0.5;
  static const double maxRouteDistanceKm = 50.0;
  
  // Safety
  static const int sosTimeoutSeconds = 30;
  
  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashScreenDuration = Duration(seconds: 2);
}

