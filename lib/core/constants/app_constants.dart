class AppConstants {
  static const String appName = 'NetPulse';
  static const String appTagline = 'Download Faster. Stay Connected.';
  static const String appVersion = '1.0.0';
  static const String appCategory = 'Internet / Download Manager';

  // RPC Defaults
  static const String defaultRpcHost = '127.0.0.1';
  static const int defaultRpcPort = 6800;
  static const int minRpcPort = 6800;
  static const int maxRpcPort = 6900;

  // Engine Defaults
  static const int defaultMaxConnections = 8;
  static const int maxAllowedConnections = 32;
  static const int minConnections = 1;
  static const int defaultMaxSimultaneousDownloads = 3;
  static const int defaultSplitSizeMb = 10;
  static const int defaultTimeoutSeconds = 30;
  static const int defaultMaxTries = 5;
  static const int defaultRetryWaitSeconds = 3;

  // Polling Intervals
  static const Duration progressPollingInterval = Duration(milliseconds: 750);
  static const Duration speedChartSampleInterval = Duration(seconds: 1);
  static const int speedChartMaxPoints = 60;

  // Database
  static const String databaseName = 'netpulse.db';
  static const int databaseVersion = 1;

  // Native Messaging Host
  static const String nativeHostName = 'com.netpulse.downloader';
}

