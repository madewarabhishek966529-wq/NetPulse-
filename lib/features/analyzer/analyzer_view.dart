import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/download_repository.dart';
import '../../services/api/backend_api_client.dart';
import '../../services/notifications/notification_service.dart';
import 'analyzer_provider.dart';

class AnalyzerView extends StatefulWidget {
  const AnalyzerView({super.key});

  @override
  State<AnalyzerView> createState() => _AnalyzerViewState();
}

class _AnalyzerViewState extends State<AnalyzerView> {
  final TextEditingController _urlController = TextEditingController();
  final Set<String> _downloadedUrls = {};

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  void _triggerAnalysis() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      context.read<AnalyzerProvider>().analyzeWebpage(url);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Size unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'webm':
        return Icons.movie_outlined;
      case 'mp3':
      case 'flac':
      case 'wav':
      case 'ogg':
        return Icons.music_note_outlined;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
      case 'iso':
        return Icons.folder_zip_outlined;
      case 'exe':
      case 'msi':
      case 'bin':
        return Icons.apps_rounded;
      case 'pdf':
      case 'docx':
      case 'xlsx':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getExtensionColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'webm':
        return AppColors.neonPurple;
      case 'mp3':
      case 'flac':
      case 'wav':
        return AppColors.coralRed;
      case 'zip':
      case 'rar':
      case '7z':
      case 'iso':
        return AppColors.amberWarning;
      case 'exe':
      case 'msi':
        return AppColors.electricBlue;
      case 'pdf':
        return AppColors.emeraldGreen;
      default:
        return AppColors.cyberCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyzerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.electricBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Smart Website URL Analyzer',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.4)),
                            ),
                            child: const Text(
                              'Ad-Filter Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emeraldGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Extract downloadable files from webpage URLs while filtering ads and tracking beacons.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // URL Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          enabled: !provider.isAnalyzing,
                          decoration: InputDecoration(
                            hintText: 'Paste webpage URL (e.g. https://releases.ubuntu.com/24.04/)',
                            prefixIcon: const Icon(Icons.link_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.paste_rounded, size: 19),
                              tooltip: 'Paste from clipboard',
                              onPressed: _pasteFromClipboard,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _triggerAnalysis(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: provider.isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.travel_explore_rounded, size: 18),
                        label: Text(provider.isAnalyzing ? 'Analyzing...' : 'Analyze Page'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: provider.isAnalyzing ? null : _triggerAnalysis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Error Message
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.coralRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.coralRed.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.coralRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: AppColors.coralRed, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Analysis In Progress Card
            if (provider.isAnalyzing) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.electricBlue.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      provider.currentStepMessage ?? 'Analyzing webpage resources...',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Discovered Results or Initial Placeholder
            Expanded(
              child: provider.lastResult == null
                  ? _buildEmptyState(isDark)
                  : _buildResultsView(provider.lastResult!, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 64,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Discover Downloadable Content',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Paste any webpage URL to inspect media files, archives, and executables.\nNetPulse automatically filters intrusive ads and tracking scripts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(AnalyzerResult result, bool isDark) {
    return ListView(
      children: [
        // Summary Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Discovered ${result.totalDiscovered} downloadable ${result.totalDiscovered == 1 ? "file" : "files"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              if (result.totalFiltered > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coralRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.coralRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${result.totalFiltered} ad ${result.totalFiltered == 1 ? "link" : "links"} filtered',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.coralRed),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Discovered Files List
        if (result.discoveredFiles.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No downloadable files detected on this webpage.',
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              ),
            ),
          )
        else
          ...result.discoveredFiles.map((file) => _buildFileCard(file, isDark)),

        // Filtered Links Accordion
        if (result.filteredLinks.isNotEmpty) ...[
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                'Blocked Advertisements & Trackers (${result.filteredLinks.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark),
              ),
              leading: const Icon(Icons.shield_outlined, color: AppColors.coralRed, size: 20),
              children: result.filteredLinks
                  .map(
                    (link) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.block_rounded, color: AppColors.coralRed, size: 16),
                      title: Text(
                        link.hostname.isNotEmpty ? link.hostname : link.url,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      subtitle: Text(link.reason, style: const TextStyle(fontSize: 10.5, color: AppColors.coralRed)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileCard(DetectedResource file, bool isDark) {
    final extColor = _getExtensionColor(file.fileExtension);
    final hasStarted = _downloadedUrls.contains(file.finalUrl) || _downloadedUrls.contains(file.sourceUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: extColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: extColor.withOpacity(0.3)),
            ),
            child: Icon(_getFileIcon(file.fileExtension), color: extColor, size: 22),
          ),
          const SizedBox(width: 14),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatFileSize(file.fileSize),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.public_rounded, size: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Text(
                      file.sourceHostname,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                    ),
                    if (file.rangeSupported) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.cyberCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cyberCyan.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Multi-Thread Accelerated',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.cyberCyan),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Download Action Button
          ElevatedButton.icon(
            icon: Icon(
              hasStarted ? Icons.check_circle_rounded : Icons.download_rounded,
              size: 16,
            ),
            label: Text(hasStarted ? 'Downloading' : 'Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasStarted ? AppColors.emeraldGreen : AppColors.electricBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: hasStarted
                ? null
                : () async {
                    final repo = context.read<DownloadRepository>();
                    final notif = context.read<NotificationService>();
                    final success = await context.read<AnalyzerProvider>().startDownload(file, repo);
                    if (success) {
                      setState(() {
                        _downloadedUrls.add(file.finalUrl.isNotEmpty ? file.finalUrl : file.sourceUrl);
                      });
                      notif.notify(
                        title: 'Download Started',
                        message: 'Downloading "${file.filename}" at high speed.',
                        icon: Icons.download_rounded,
                        color: AppColors.emeraldGreen,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

