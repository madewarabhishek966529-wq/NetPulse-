import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/browser_bridge/native_host_manager.dart';
import '../downloads/download_provider.dart';

class BrowserIntegrationView extends StatefulWidget {
  const BrowserIntegrationView({super.key});

  @override
  State<BrowserIntegrationView> createState() => _BrowserIntegrationViewState();
}

class _BrowserIntegrationViewState extends State<BrowserIntegrationView> {
  late NativeHostManager _hostManager;
  bool _chromeRegistered = false;
  bool _edgeRegistered = false;
  bool _firefoxRegistered = false;

  @override
  void initState() {
    super.initState();
    final repo = context.read<DownloadProvider>().repository;
    _hostManager = NativeHostManager(repo);
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final chrome = await _hostManager.isChromeRegistered();
    final edge = await _hostManager.isEdgeRegistered();
    final firefox = await _hostManager.isFirefoxRegistered();

    setState(() {
      _chromeRegistered = chrome;
      _edgeRegistered = edge;
      _firefoxRegistered = firefox;
    });
  }

  Future<void> _registerAll() async {
    final success = await _hostManager.registerBrowsers();
    await _checkStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Successfully registered Native Messaging Host in Windows Registry!'
              : 'Failed to write registry keys.'),
          backgroundColor: success ? AppColors.emeraldGreen : AppColors.coralRed,
        ),
      );
    }
  }

  Future<void> _unregisterAll() async {
    final success = await _hostManager.unregisterBrowsers();
    await _checkStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Unregistered Native Messaging Host.' : 'Unregister completed.'),
          backgroundColor: AppColors.amberWarning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chromeExtPath = p.join(Directory.current.path, 'browser_extension', 'chrome');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.extension_rounded, size: 24, color: AppColors.electricBlue),
                const SizedBox(width: 10),
                Text(
                  'Browser Integration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Top Status Overview
            Row(
              children: [
                _buildBrowserCard('Google Chrome', _chromeRegistered, Icons.tab_rounded, isDark),
                const SizedBox(width: 12),
                _buildBrowserCard('Microsoft Edge', _edgeRegistered, Icons.language_rounded, isDark),
                const SizedBox(width: 12),
                _buildBrowserCard('Mozilla Firefox', _firefoxRegistered, Icons.public_rounded, isDark),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons Bar
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _registerAll,
                  icon: const Icon(Icons.app_registration_rounded, size: 16),
                  label: const Text('1-Click Register Native Messaging Host'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _unregisterAll,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Unregister Host'),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _checkStatus,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Refresh Status',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Installation Guide
            Text(
              'How to Install NetPulse Extension in Your Browser',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
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
                  _buildStep(
                    1,
                    'Click the "1-Click Register Native Messaging Host" button above.',
                    'This creates the Windows Registry entries so Chrome, Edge, and Firefox can talk to NetPulse directly.',
                    isDark,
                  ),
                  const SizedBox(height: 14),
                  _buildStep(
                    2,
                    'Open Chrome or Edge Extensions page.',
                    'Navigate to chrome://extensions or edge://extensions in your browser address bar.',
                    isDark,
                  ),
                  const SizedBox(height: 14),
                  _buildStep(
                    3,
                    'Enable "Developer mode" toggle switch in the top-right corner.',
                    'This enables the "Load unpacked" button in the extensions toolbar.',
                    isDark,
                  ),
                  const SizedBox(height: 14),
                  _buildStep(
                    4,
                    'Click "Load unpacked" and select the extension folder:',
                    chromeExtPath,
                    isDark,
                    isPath: true,
                  ),
                  const SizedBox(height: 14),
                  _buildStep(
                    5,
                    'Done! NetPulse is now your browser download accelerator.',
                    'Eligible browser downloads and right-click "Download with NetPulse" will be accelerated with multi-connection downloading.',
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowserCard(String name, bool isRegistered, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isRegistered
                ? AppColors.emeraldGreen.withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 22, color: isRegistered ? AppColors.emeraldGreen : AppColors.textMutedDark),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRegistered
                        ? AppColors.emeraldGreen.withOpacity(0.15)
                        : AppColors.coralRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRegistered ? 'Registered' : 'Not Registered',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isRegistered ? AppColors.emeraldGreen : AppColors.coralRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String description, bool isDark, {bool isPath = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.electricBlue,
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              if (isPath)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: SelectableText(
                    description,
                    style: const TextStyle(fontSize: 11, fontFamily: 'Consolas', color: AppColors.electricBlue),
                  ),
                )
              else
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
