import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../downloads/download_provider.dart';
import 'settings_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _dirController = TextEditingController();
  final _extController = TextEditingController();

  String _ariaVersion = 'Detecting...';
  String _ariaPath = 'Detecting...';

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _dirController.text = settings.defaultDownloadFolder;
    _extController.text = settings.interceptedExtensions;
    _fetchEngineInfo();
  }

  Future<void> _fetchEngineInfo() async {
    final repo = context.read<DownloadProvider>().repository;
    try {
      final client = repo.client;
      if (client != null) {
        final ver = await client.getVersion();
        final path = await repo.engineManager.findAria2Executable();
        setState(() {
          _ariaVersion = 'aria2 v${ver['version']}';
          _ariaPath = path;
        });
      }
    } catch (_) {
      setState(() {
        _ariaVersion = 'aria2c (Local process)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.settings_rounded, size: 24, color: AppColors.electricBlue),
                const SizedBox(width: 10),
                Text(
                  'Settings & Engine Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // General Settings Card
            _buildSection(
              title: 'General & Appearance',
              icon: Icons.tune_rounded,
              isDark: isDark,
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ultra-luxurious obsidian slate & soft lavender theme', style: TextStyle(fontSize: 11)),
                  value: settings.darkMode,
                  onChanged: (val) => settingsProvider.toggleDarkMode(val),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Minimize to System Tray', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Keep active downloads running when closing the main window', style: TextStyle(fontSize: 11)),
                  value: settings.minimizeToTray,
                  onChanged: (val) => settingsProvider.updateSettings(settings.copyWith(minimizeToTray: val)),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Compact Density Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Display more download cards with compact spacing', style: TextStyle(fontSize: 11)),
                  value: settings.compactMode,
                  onChanged: (val) => settingsProvider.setCompactMode(val),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dirController,
                          decoration: const InputDecoration(
                            labelText: 'Default Download Directory',
                            prefixIcon: Icon(Icons.folder_outlined, size: 18),
                          ),
                          onChanged: (val) => settingsProvider.setDefaultDownloadFolder(val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final dir = await FileUtils.getDefaultDownloadDirectory();
                          _dirController.text = dir;
                          settingsProvider.setDefaultDownloadFolder(dir);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Download Engine Settings Card
            _buildSection(
              title: 'Download Acceleration Parameters',
              icon: Icons.speed_rounded,
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Default Connections per Server:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '${settings.maxConnectionsPerDownload} connections',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.electricBlue),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.maxConnectionsPerDownload.toDouble(),
                        min: 1,
                        max: 16,
                        divisions: 15,
                        label: '${settings.maxConnectionsPerDownload}',
                        onChanged: (val) {
                          settingsProvider.updateSettings(
                            settings.copyWith(maxConnectionsPerDownload: val.toInt()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Connection Retry Attempts:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${settings.retryCount} tries', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: settings.retryCount.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '${settings.retryCount}',
                        onChanged: (val) {
                          settingsProvider.updateSettings(
                            settings.copyWith(retryCount: val.toInt()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Advanced aria2 Engine Status
            _buildSection(
              title: 'Aria2 Background Engine Status',
              icon: Icons.memory_rounded,
              isDark: isDark,
              children: [
                ListTile(
                  title: const Text('Engine Binary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: SelectableText(_ariaPath, style: const TextStyle(fontSize: 11, fontFamily: 'Consolas')),
                  leading: const Icon(Icons.terminal_rounded, color: AppColors.electricBlue),
                ),
                ListTile(
                  title: const Text('Engine Version', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(_ariaVersion, style: const TextStyle(fontSize: 11)),
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.emeraldGreen),
                ),
                ListTile(
                  title: const Text('RPC Host & Port', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('127.0.0.1:6800 (Localhost only, token secured)', style: TextStyle(fontSize: 11)),
                  leading: const Icon(Icons.security_rounded, color: AppColors.neonPurple),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await settingsProvider.resetToDefaults();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings reset to defaults')),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Reset All Settings to Defaults'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.electricBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

