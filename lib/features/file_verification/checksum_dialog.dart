import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/formatters.dart';
import '../../services/file_verification/checksum_service.dart';

class ChecksumDialog extends StatefulWidget {
  final String filePath;
  final String? expectedChecksum;

  const ChecksumDialog({super.key, required this.filePath, this.expectedChecksum});

  @override
  State<ChecksumDialog> createState() => _ChecksumDialogState();
}

class _ChecksumDialogState extends State<ChecksumDialog> {
  final _service = ChecksumService();
  final _expectedController = TextEditingController();

  bool _isCalculating = true;
  double _calcProgress = 0.0;
  String? _calculatedSha256;
  String? _calculatedMd5;
  int _fileSize = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.expectedChecksum != null) {
      _expectedController.text = widget.expectedChecksum!;
    }
    _runCalculation();
  }

  Future<void> _runCalculation() async {
    setState(() {
      _isCalculating = true;
      _error = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'File does not exist on disk yet.';
          _isCalculating = false;
        });
        return;
      }

      _fileSize = await file.length();
      final sha = await _service.calculateSha256(
        widget.filePath,
        onProgress: (p) => setState(() => _calcProgress = p),
      );
      final md = await _service.calculateMd5(widget.filePath);

      setState(() {
        _calculatedSha256 = sha;
        _calculatedMd5 = md;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDangerous = FileUtils.isDangerousFile(widget.filePath);

    final expected = _expectedController.text.trim().toLowerCase();
    bool? matches;
    if (expected.isNotEmpty && _calculatedSha256 != null) {
      if (expected.length == 64) {
        matches = (expected == _calculatedSha256!.toLowerCase());
      } else if (expected.length == 32 && _calculatedMd5 != null) {
        matches = (expected == _calculatedMd5!.toLowerCase());
      }
    }

    return Dialog(
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.electricBlue, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'File Verification & Security',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

            const SizedBox(height: 16),

            // Warning for executable files
            if (isDangerous) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberWarning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amberWarning.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.amberWarning, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Executable File Notice: Verify the SHA-256 hash against the publisher before running this program.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.amberWarning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Text(
              'Target: ${widget.filePath}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'File Size: ${Formatters.formatBytes(_fileSize)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            if (_isCalculating) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Computing cryptographic hashes... (${Formatters.formatPercent(_calcProgress)})'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _calcProgress),
                ],
              ),
            ] else if (_error != null) ...[
              Text('Error: $_error', style: const TextStyle(color: AppColors.coralRed)),
            ] else ...[
              // Calculated SHA-256
              _buildHashBox('SHA-256 Checksum', _calculatedSha256 ?? '--', isDark),
              const SizedBox(height: 10),
              // Calculated MD5
              _buildHashBox('MD5 Checksum', _calculatedMd5 ?? '--', isDark),

              const SizedBox(height: 16),

              // Expected Checksum Field
              TextField(
                controller: _expectedController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Compare with Expected Checksum',
                  hintText: 'Paste publisher SHA-256 or MD5 hash here',
                  prefixIcon: Icon(Icons.compare_arrows_rounded, size: 18),
                ),
              ),

              if (matches != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: matches
                        ? AppColors.emeraldGreen.withOpacity(0.12)
                        : AppColors.coralRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: matches ? AppColors.emeraldGreen : AppColors.coralRed,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        matches ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: matches ? AppColors.emeraldGreen : AppColors.coralRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        matches
                            ? 'Verification Success! Hashes match perfectly.'
                            : 'Integrity Warning! Hash mismatch detected.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: matches ? AppColors.emeraldGreen : AppColors.coralRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHashBox(String label, String hash, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
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
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: hash));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checksum copied to clipboard'), duration: Duration(seconds: 1)),
                  );
                },
                child: const Text(
                  'Copy',
                  style: TextStyle(fontSize: 11, color: AppColors.electricBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            hash,
            style: const TextStyle(fontSize: 11, fontFamily: 'Consolas', letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

