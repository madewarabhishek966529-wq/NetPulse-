import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../core/constants/category_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../downloads/download_provider.dart';
import '../settings/settings_provider.dart';
import 'inspect_url_service.dart';

class AddDownloadDialog extends StatefulWidget {
  final String? initialUrl;

  const AddDownloadDialog({super.key, this.initialUrl});

  @override
  State<AddDownloadDialog> createState() => _AddDownloadDialogState();
}

class _AddDownloadDialogState extends State<AddDownloadDialog> {
  int _selectedTab = 0; // 0: URL / Magnet, 1: Torrent File

  final _urlController = TextEditingController();
  final _torrentPathController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _saveDirController = TextEditingController();
  final _checksumController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _inspectService = InspectUrlService();

  Uint8List? _torrentBytes;
  int _connections = 8;
  String _selectedCategory = CategoryConstants.other;
  bool _isInspecting = false;
  bool _supportsRange = true;
  int _detectedFileSize = 0;

  bool _showAdvanced = false;
  bool _isScheduled = false;
  DateTime? _scheduledTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlController.text = widget.initialUrl!;
      if (Validators.isMagnetLink(widget.initialUrl)) {
        _fileNameController.text = 'Magnet Torrent';
      } else {
        _inspectUrl();
      }
    } else {
      _checkClipboard();
    }

    final settings = context.read<SettingsProvider>().settings;
    _connections = settings.maxConnectionsPerDownload;
    _selectedCategory = settings.defaultCategory;
    _saveDirController.text = settings.defaultDownloadFolder;
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && (Validators.isValidUrl(text) || Validators.isMagnetLink(text))) {
        setState(() {
          _urlController.text = text;
        });
        if (Validators.isMagnetLink(text)) {
          setState(() {
            _fileNameController.text = 'Magnet Torrent';
          });
        } else {
          _inspectUrl();
        }
      }
    } catch (_) {}
  }

  Future<void> _inspectUrl() async {
    final url = _urlController.text.trim();
    if (Validators.isMagnetLink(url)) {
      setState(() {
        if (_fileNameController.text.isEmpty || _fileNameController.text.startsWith('download_')) {
          _fileNameController.text = 'Magnet Torrent';
        }
      });
      return;
    }

    if (!Validators.isValidUrl(url)) return;

    setState(() {
      _isInspecting = true;
    });

    try {
      final result = await _inspectService.inspectUrl(
        url,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        if (_fileNameController.text.isEmpty || _fileNameController.text.startsWith('download_')) {
          _fileNameController.text = result.fileName;
        }
        _detectedFileSize = result.fileSize;
        _supportsRange = result.supportsRange;
        _selectedCategory = result.detectedCategory;
        if (!_supportsRange) {
          _connections = 1;
        }
        _isInspecting = false;
      });
    } catch (_) {
      setState(() {
        _isInspecting = false;
      });
    }
  }

  Future<void> _pickTorrentFile() async {
    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Add-Type -AssemblyName System.Windows.Forms; '
        r'$f = New-Object System.Windows.Forms.OpenFileDialog; '
        r'$f.Filter = "Torrent Files (*.torrent)|*.torrent|All Files (*.*)|*.*"; '
        r'$f.Title = "Select a .torrent file to download"; '
        r'if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $f.FileName }'
      ]);

      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final filePath = res.stdout.toString().trim();
        await _loadTorrentPath(filePath);
      }
    } catch (e) {
      debugPrint('[PickTorrent] Error: $e');
    }
  }

  Future<void> _loadTorrentPath(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(() {
          _torrentBytes = bytes;
          _torrentPathController.text = filePath;
          _fileNameController.text = p.basenameWithoutExtension(filePath);
        });
      }
    } catch (_) {}
  }

  void _submit({required bool startImmediately}) async {
    var targetDir = _saveDirController.text.trim();
    if (targetDir.isEmpty) {
      targetDir = await FileUtils.getDefaultDownloadDirectory();
    }

    final downloadProvider = context.read<DownloadProvider>();

    try {
      if (_selectedTab == 1) {
        // Torrent File Submission
        if (_torrentBytes == null && _torrentPathController.text.isNotEmpty) {
          final file = File(_torrentPathController.text.trim());
          if (await file.exists()) {
            _torrentBytes = await file.readAsBytes();
          }
        }

        if (_torrentBytes == null || _torrentBytes!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or browse for a valid .torrent file.')),
          );
          return;
        }

        var fileName = _fileNameController.text.trim();
        if (fileName.isEmpty) {
          fileName = 'Torrent Download';
        }

        await downloadProvider.repository.addTorrentDownload(
          torrentBytes: _torrentBytes!,
          fileName: fileName,
          targetDirectory: targetDir,
          category: _selectedCategory,
          isScheduled: _isScheduled,
          scheduledStartTime: _isScheduled ? _scheduledTime : null,
          startPaused: !startImmediately || _isScheduled,
        );
      } else {
        // URL / Magnet Submission
        final url = _urlController.text.trim();
        if (!Validators.isValidUrl(url)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid HTTP, HTTPS, FTP, or Magnet URL.')),
          );
          return;
        }

        var fileName = _fileNameController.text.trim();
        if (fileName.isEmpty) {
          fileName = Validators.isMagnetLink(url)
              ? 'Magnet Torrent'
              : 'download_${DateTime.now().millisecondsSinceEpoch}';
        }
        fileName = FileUtils.sanitizeFilename(fileName);

        await downloadProvider.repository.addDownload(
          url: url,
          fileName: fileName,
          targetDirectory: targetDir,
          connections: _connections,
          category: _selectedCategory,
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          expectedChecksum: _checksumController.text.trim().isNotEmpty
              ? _checksumController.text.trim()
              : null,
          isScheduled: _isScheduled,
          scheduledStartTime: _isScheduled ? _scheduledTime : null,
          startPaused: !startImmediately || _isScheduled,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(startImmediately ? 'Download started' : 'Added to queue'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add download: $e'), backgroundColor: AppColors.coralRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMagnet = Validators.isMagnetLink(_urlController.text);

    return Dialog(
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 740),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_link_rounded, color: AppColors.electricBlue, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Add Download / Torrent',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 16,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Mode Tabs: URL/Magnet vs Torrent File
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(0, Icons.link_rounded, 'Direct URL / Magnet Link'),
                    ),
                    Expanded(
                      child: _buildTabButton(1, Icons.bolt_rounded, 'Torrent File (.torrent)'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (_selectedTab == 0) ...[
                // URL / Magnet Input Field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        onChanged: (val) {
                          setState(() {});
                          if (!Validators.isMagnetLink(val) && Validators.isValidUrl(val)) {
                            _inspectUrl();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Download URL or Magnet Link *',
                          hintText: 'https://... or magnet:?xt=urn:btih:...',
                          prefixIcon: Icon(
                            isMagnet ? Icons.bolt_rounded : Icons.link_rounded,
                            size: 18,
                            color: isMagnet ? AppColors.emeraldGreen : null,
                          ),
                        ),
                      ),
                    ),
                    if (!isMagnet) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isInspecting ? null : _inspectUrl,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        child: _isInspecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Inspect'),
                      ),
                    ],
                  ],
                ),

                // Magnet link detected banner
                if (isMagnet) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: AppColors.emeraldGreen, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'BitTorrent P2P Magnet Detected! Accelerated with 10 public trackers, DHT & PeX peer discovery.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.emeraldGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Server Range & Size feedback for HTTP downloads
                if (!isMagnet && (_detectedFileSize > 0 || !_supportsRange)) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_detectedFileSize > 0)
                          Text(
                            'Size: ${Formatters.formatBytes(_detectedFileSize)}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        Row(
                          children: [
                            Icon(
                              _supportsRange ? Icons.bolt_rounded : Icons.info_outline_rounded,
                              size: 14,
                              color: _supportsRange ? AppColors.electricBlue : AppColors.amberWarning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _supportsRange
                                  ? 'Multi-connection segmented download supported'
                                  : 'Server does not accept range requests (single connection)',
                              style: TextStyle(
                                fontSize: 11,
                                color: _supportsRange ? AppColors.electricBlue : AppColors.amberWarning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Torrent File Picker Field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _torrentPathController,
                        onChanged: (val) => _loadTorrentPath(val.trim()),
                        decoration: const InputDecoration(
                          labelText: '.torrent File Path *',
                          hintText: 'C:\\Users\\...\\file.torrent',
                          prefixIcon: Icon(Icons.file_present_rounded, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _pickTorrentFile,
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Browse...'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Torrent optimization status banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neonPurple.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: AppColors.neonPurple, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _torrentBytes != null
                              ? 'Torrent loaded! Ready to download using peer-to-peer acceleration.'
                              : 'Select a .torrent file to initiate fast decentralized multi-peer downloading.',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.neonPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // File Name Field
              TextField(
                controller: _fileNameController,
                decoration: const InputDecoration(
                  labelText: 'Task / File Name *',
                  hintText: 'filename.ext',
                  prefixIcon: Icon(Icons.insert_drive_file_outlined, size: 18),
                ),
              ),

              const SizedBox(height: 14),

              // Save Location
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _saveDirController,
                      decoration: const InputDecoration(
                        labelText: 'Save Location *',
                        prefixIcon: Icon(Icons.folder_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final defaultDir = await FileUtils.getDefaultDownloadDirectory();
                      setState(() => _saveDirController.text = defaultDir);
                    },
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Default'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Connections Slider and Category
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTab == 1 || isMagnet ? 'Max Peers:' : 'Connections:',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _selectedTab == 1 || isMagnet ? '$_connections peers' : '$_connections threads',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricBlue,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _connections.toDouble(),
                          min: 1,
                          max: 16,
                          divisions: 15,
                          label: '$_connections',
                          onChanged: (_supportsRange || _selectedTab == 1 || isMagnet)
                              ? (val) => setState(() => _connections = val.toInt())
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Category Selector
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: CategoryConstants.defaultCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(
                                CategoryConstants.getCategoryIcon(cat),
                                size: 16,
                                color: CategoryConstants.getCategoryColor(cat),
                              ),
                              const SizedBox(width: 8),
                              Text(cat, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Toggle Advanced Options
              InkWell(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.electricBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showAdvanced ? 'Hide Advanced Options' : 'Show Advanced Options (Auth, SHA-256, Schedule)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.electricBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showAdvanced) ...[
                const SizedBox(height: 10),

                // SHA-256 Checksum Field
                TextField(
                  controller: _checksumController,
                  decoration: const InputDecoration(
                    labelText: 'Expected SHA-256 / MD5 Checksum',
                    hintText: 'Optional verification hash',
                    prefixIcon: Icon(Icons.verified_outlined, size: 18),
                  ),
                ),

                const SizedBox(height: 12),

                // Authentication Fields (for HTTP/FTP)
                if (_selectedTab == 0 && !isMagnet) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'HTTP Username',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'HTTP Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Schedule Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isScheduled,
                      onChanged: (val) {
                        setState(() {
                          _isScheduled = val ?? false;
                          if (_isScheduled && _scheduledTime == null) {
                            _scheduledTime = DateTime.now().add(const Duration(hours: 1));
                          }
                        });
                      },
                    ),
                    const Text('Schedule download for a later time', style: TextStyle(fontSize: 12)),
                  ],
                ),

                if (_isScheduled) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Scheduled Start: ${_scheduledTime != null ? Formatters.formatDate(_scheduledTime) : "--"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.neonPurple, fontWeight: FontWeight.bold),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _submit(startImmediately: false),
                    child: const Text('Add to Queue'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _submit(startImmediately: true),
                    child: Text(_selectedTab == 1 || isMagnet ? 'Download Torrent Now' : 'Download Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlue.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.electricBlue : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.electricBlue : AppColors.textMutedDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
