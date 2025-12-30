import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // For ImageFilter
import 'package:moneyguard/core/config/config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/shared/widgets/gradient_button.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyguard/features/auth/presentation/providers/auth_provider.dart';
import 'package:moneyguard/features/expense/domain/entities/expense_category.dart';

// Provider for the import service (mocked for now, should be in a separate file)
final importServiceProvider = Provider(
  (ref) => ImportService(ref.read(authBoxProvider)),
);

class ImportService {
  final Box _authBox;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 600),
    ),
  ); // Adjust URL as needed

  ImportService(this._authBox);

  Future<List<Map<String, dynamic>>> uploadFile(PlatformFile file) async {
    MultipartFile multipartFile;
    if (kIsWeb) {
      multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else {
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    }

    FormData formData = FormData.fromMap({"file": multipartFile});

    // Add auth token
    final token = _authBox.get('access_token');
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await _dio.post(
        '/import/upload',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> confirmImport(List<Map<String, dynamic>> transactions) async {
    final token = _authBox.get('access_token');
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      await _dio.post(
        '/import/confirm',
        data: transactions,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to confirm import: $e');
    }
  }
}

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  List<Map<String, dynamic>> _parsedTransactions = [];
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
          _errorMessage = null;
          _parsedTransactions = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _uploadAndParse() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await ref
          .read(importServiceProvider)
          .uploadFile(_selectedFile!);
      setState(() {
        _parsedTransactions = transactions;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_parsedTransactions.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(importServiceProvider).confirmImport(_parsedTransactions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions imported successfully!')),
        );
        Navigator.pop(context); // Go back to previous screen
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Import Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundPrimary.withValues(alpha: 0.8),
                AppColors.backgroundSecondary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.backgroundPrimary,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileSelection(),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_parsedTransactions.isNotEmpty)
              Expanded(child: _buildTransactionList())
            else if (_selectedFile != null)
              GradientButton(text: 'Parse File', onPressed: _uploadAndParse),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentStart.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accentStart.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedFile != null
                  ? Icons.check_circle
                  : Icons.cloud_upload_rounded,
              size: 64,
              color: _selectedFile != null
                  ? AppColors.success
                  : AppColors.accentStart,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFile != null
                ? _selectedFile!.name
                : 'Upload Bank Statement',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFile != null
                ? '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB'
                : 'Supports PDF & CSV files',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_selectedFile == null)
            OutlinedButton(
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(
                  color: AppColors.accentStart.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Choose File'),
            )
          else
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Change File'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: [
        Text(
          'Review Transactions (${_parsedTransactions.length})',
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _parsedTransactions.length,
            itemBuilder: (context, index) {
              final tx = _parsedTransactions[index];

              // Helper to find matching category from defaults
              final String currentCat = tx['category'] ?? 'Other';
              final matchingCat = ExpenseCategory.defaults
                  .firstWhere(
                    (c) => c.name.toLowerCase() == currentCat.toLowerCase(),
                    orElse: () => ExpenseCategory.defaults.firstWhere(
                      (c) => c.id == 'other',
                    ),
                  )
                  .name;

              // Ensure we have a valid value for the dropdown, defaulting to "Other" if completely unknown
              final dropdownValue =
                  ExpenseCategory.defaults.any((c) => c.name == matchingCat)
                  ? matchingCat
                  : ExpenseCategory.defaults.first.name;

              final isCredit = tx['type'] == 'credit';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCredit
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.accentStart.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward
                                : Icons.receipt_long,
                            color: isCredit
                                ? AppColors.success
                                : AppColors.accentStart,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx['description'] ?? 'Unknown',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                // Show raw date
                                tx['date']?.toString().split('T')[0] ??
                                    'No Date',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${tx['amount']}',
                          style: AppTypography.titleMedium.copyWith(
                            color: isCredit
                                ? AppColors.success
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Editing Row
                    Row(
                      children: [
                        // Category Dropdown
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundPrimary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: dropdownValue,
                                isDense: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textSecondary,
                                ),
                                style: AppTypography.bodyMedium,
                                dropdownColor: AppColors.backgroundSecondary,
                                items: ExpenseCategory.defaults.map((c) {
                                  return DropdownMenuItem(
                                    value: c.name,
                                    child: Row(
                                      children: [
                                        Text(c.emoji),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    tx['category'] = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Type Dropdown (Credit/Debit)
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundPrimary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: tx['type'] == 'credit'
                                    ? 'Credit'
                                    : 'Debit',
                                isDense: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textSecondary,
                                ),
                                style: AppTypography.bodyMedium,
                                dropdownColor: AppColors.backgroundSecondary,
                                items: ['Debit', 'Credit'].map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        color: t == 'Credit'
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    tx['type'] = val?.toLowerCase();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(text: 'Confirm Import', onPressed: _confirmImport),
      ],
    );
  }
}
