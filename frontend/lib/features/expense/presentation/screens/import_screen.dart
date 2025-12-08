import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/shared/widgets/gradient_button.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyguard/features/auth/presentation/providers/auth_provider.dart';

// Provider for the import service (mocked for now, should be in a separate file)
final importServiceProvider = Provider(
  (ref) => ImportService(ref.read(authBoxProvider)),
);

class ImportService {
  final Box _authBox;
  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://localhost:8000/api/v1'),
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
      appBar: AppBar(
        title: const Text('Import Transactions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accentStart.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.backgroundSecondary,
      ),
      child: Column(
        children: [
          const Icon(Icons.upload_file, size: 48, color: AppColors.accentStart),
          const SizedBox(height: 12),
          Text(
            _selectedFile != null
                ? 'Selected: ${_selectedFile!.name}'
                : 'Select Bank Statement (PDF) or PayPal Log (CSV)',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _pickFile, child: const Text('Choose File')),
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
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: AppColors.textSecondary,
                  ),
                  title: Text(tx['description'] ?? 'Unknown'),
                  subtitle: Text(
                    '${tx['date']} • ${tx['category_guess'] ?? 'Uncategorized'}',
                  ),
                  trailing: Text(
                    '\$${tx['amount']}',
                    style: TextStyle(
                      color: (tx['amount'] is num && tx['amount'] < 0)
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
