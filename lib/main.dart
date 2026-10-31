import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/add_download/add_download_dialog.dart';
import 'features/browser/browser_integration_view.dart';
import 'features/dashboard/dashboard_view.dart';
import 'features/downloads/download_provider.dart';
import 'features/downloads/downloads_view.dart';
import 'features/history/history_view.dart';
import 'features/network/network_monitor_provider.dart';
import 'features/network/network_monitor_view.dart';
import 'features/scheduler/scheduler_service.dart';
import 'features/scheduler/scheduler_view.dart';
import 'features/settings/settings_provider.dart';
import 'features/settings/settings_view.dart';
import 'repositories/download_repository.dart';
import 'services/browser_bridge/native_host_manager.dart';
import 'services/database/database_service.dart';
import 'services/notifications/notification_service.dart';
import 'services/system_tray/system_tray_service.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/custom_title_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI
  DatabaseService.ensureInitialized();

  // Create repository & core services
  final repository = DownloadRepository();
  final notificationService = NotificationService();
  final systemTrayService = SystemTrayService(repository);
  final schedulerService = SchedulerService(repository);
  final nativeHostManager = NativeHostManager(repository);

  // Initialize engine and background recovery
  try {
    await repository.initialize();
  } catch (e) {
    debugPrint('[Main] Engine startup warning: $e');
  }

  // Start scheduler
  schedulerService.startScheduler();

  // Start watching for incoming browser extension downloads
  nativeHostManager.startIncomingWatcher(
    onDownloadAdded: (item) {
      notificationService.notify(
        title: 'Browser Download Added',
        message: 'Accelerating: "${item.fileName}"',
        icon: Icons.extension_rounded,
        color: AppColors.electricBlue,
      );
    },
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notificationService),
        Provider.value(value: repository),
        Provider.value(value: systemTrayService),
        ChangeNotifierProvider(
          create: (ctx) => DownloadProvider(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => NetworkMonitorProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SettingsProvider(repository: repository),
        ),
      ],
      child: const NetPulseApp(),
    ),
  );
}

class NetPulseApp extends StatelessWidget {
  const NetPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = settingsProvider.settings.darkMode;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: const MainShellView(),
    );
  }
}

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  NavPage _currentPage = NavPage.overview;
  bool _showNotificationsFlyout = false;

  void _openAddDownloadDialog([String? url]) {
    showDialog(
      context: context,
      builder: (ctx) => AddDownloadDialog(initialUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationService = context.watch<NotificationService>();

    return Scaffold(
      body: Column(
        children: [
          // Custom Windows Modern Title Bar
          CustomTitleBar(
            onAddDownload: () => _openAddDownloadDialog(),
            onOpenSettings: () => setState(() => _currentPage = NavPage.settings),
            onToggleNotifications: () {
              setState(() => _showNotificationsFlyout = !_showNotificationsFlyout);
            },
          ),

          // Main Workspace Row (Sidebar + Content + Optional Notifications Flyout)
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    // Sidebar
                    AppSidebar(
                      selectedPage: _currentPage,
                      onPageSelected: (page) {
                        setState(() {
                          _currentPage = page;
                          _showNotificationsFlyout = false;
                        });
                      },
                    ),

                    // Active View
                    Expanded(
                      child: _buildCurrentView(),
                    ),
                  ],
                ),

                // Notifications Flyout
                if (_showNotificationsFlyout)
                  Positioned(
                    top: 10,
                    right: 20,
                    width: 320,
                    bottom: 20,
                    child: _buildNotificationsFlyout(notificationService, isDark),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentPage) {
      case NavPage.overview:
        return DashboardView(onAddDownload: () => _openAddDownloadDialog());
      case NavPage.allDownloads:
        return const DownloadsView(initialFilter: DownloadFilterStatus.all);
      case NavPage.activeDownloads:
        return const DownloadsView(initialFilter: DownloadFilterStatus.active);
      case NavPage.queuedDownloads:
        return const DownloadsView(initialFilter: DownloadFilterStatus.queued);
      case NavPage.completed:
        return const DownloadsView(initialFilter: DownloadFilterStatus.completed);
      case NavPage.failed:
        return const DownloadsView(initialFilter: DownloadFilterStatus.failed);
      case NavPage.scheduled:
        return const SchedulerView();
      case NavPage.browserIntegration:
        return const BrowserIntegrationView();
      case NavPage.networkMonitor:
        return const NetworkMonitorView();
      case NavPage.settings:
        return const SettingsView();
    }
  }

  Widget _buildNotificationsFlyout(NotificationService service, bool isDark) {
    final items = service.notifications;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_rounded, size: 18, color: AppColors.electricBlue),
                    SizedBox(width: 8),
                    Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: () => service.clearAll(),
                  child: const Text('Clear All', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final n = items[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(n.icon, color: n.color, size: 20),
                          title: Text(n.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(n.message, style: const TextStyle(fontSize: 11)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
