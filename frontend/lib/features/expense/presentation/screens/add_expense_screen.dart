import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';

import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/shared/widgets/gradient_button.dart';
import 'dart:ui' as ui;

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;
  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late DateTime _selectedDate;
  File? _receiptImage;
  bool _isProcessingOCR = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;
    _amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    _categoryController = TextEditingController(text: expense?.category ?? '');
    _selectedDate = expense?.transactionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _receiptImage = File(pickedFile.path);
        });
        _processReceipt(pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _processReceipt(String path) async {
    setState(() {
      _isProcessingOCR = true;
    });

    try {
      // Use the provider to upload and process receipt
      // Note: We need to access the notifier, but uploadReceipt is on the notifier class
      // We can access it via ref.read(expenseListProvider.notifier)
      final expenseData = await ref
          .read(expenseListProvider.notifier)
          .uploadReceipt(path);

      setState(() {
        _amountController.text = expenseData.amount.toString();
        _descriptionController.text = expenseData.description;
        if (expenseData.ocrRawText != null) {
          // Maybe show raw text or confidence?
        }
        // Date might be extracted too
        _selectedDate = expenseData.transactionDate;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt processed successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR Failed: $e')));
    } finally {
      setState(() {
        _isProcessingOCR = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.expenseToEdit != null) {
          final updatedExpense = Expense(
            id: widget.expenseToEdit!.id,
            amount: double.parse(_amountController.text),
            description: _descriptionController.text,
            category: _categoryController.text,
            transactionDate: _selectedDate,
            createdAt: widget.expenseToEdit!.createdAt,
            source: widget
                .expenseToEdit!
                .source, // Keep original source or update if new image?
            ocrRawText: widget.expenseToEdit!.ocrRawText,
            ocrConfidence: widget.expenseToEdit!.ocrConfidence,
          );
          await ref
              .read(expenseListProvider.notifier)
              .updateExpense(widget.expenseToEdit!.id, updatedExpense);
        } else {
          await ref
              .read(expenseListProvider.notifier)
              .createExpense(
                amount: double.parse(_amountController.text),
                description: _descriptionController.text,
                category: _categoryController.text,
                transactionDate: _selectedDate,
                source: _receiptImage != null ? 'ocr' : 'manual',
              );
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseListProvider);
    final isLoading = expenseState.isLoading || _isProcessingOCR;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.expenseToEdit != null ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundPrimary.withValues(alpha: 0.9),
                AppColors.backgroundSecondary.withValues(alpha: 0.9),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt Image Section
                  GestureDetector(
                    onTap: () => _showImageSourceSheet(),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.accentStart.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _receiptImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_receiptImage!, fit: BoxFit.cover),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),
                                  const Center(
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentStart.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 32,
                                    color: AppColors.accentStart,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Scan Receipt',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to capture or upload',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Amount Field
                  _buildPremiumField(
                    label: 'Amount (RD\$)',
                    child: TextFormField(
                      key: const Key('amountField'),
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: AppColors.accentStart,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description Field
                  _buildPremiumField(
                    label: 'Description',
                    child: TextFormField(
                      key: const Key('descriptionField'),
                      controller: _descriptionController,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.description_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Field
                  _buildPremiumField(
                    label: 'Category',
                    child: TextFormField(
                      controller: _categoryController,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Food, Transport',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.accentStart,
                                onPrimary: Colors.white,
                                surface: AppColors.backgroundSecondary,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().format(_selectedDate),
                                style: AppTypography.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Submit Button
                  GradientButton(
                    key: const Key('saveExpenseButton'),
                    text: isLoading
                        ? 'Saving...'
                        : (widget.expenseToEdit != null
                              ? 'Update Expense'
                              : 'Save Expense'),
                    onPressed: isLoading ? null : _submit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentStart,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ],
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: AppColors.accentStart.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.accentStart,
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.accentEnd,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
