import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';

import 'package:moneyguard/features/expense/domain/entities/expense.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt processed successfully!')),
      );
    } catch (e) {
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
              .addExpense(
                amount: double.parse(_amountController.text),
                description: _descriptionController.text,
                category: _categoryController.text,
                transactionDate: _selectedDate,
                source: _receiptImage != null ? 'ocr' : 'manual',
                // Pass OCR data if available (need to store it in state from _processReceipt)
              );
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
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
      appBar: AppBar(
        title: Text(
          widget.expenseToEdit != null ? 'Edit Expense' : 'Add Expense',
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt Image Section
                  GestureDetector(
                    onTap: () => _showImageSourceSheet(),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: _receiptImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _receiptImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Scan Receipt',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Field (Text for now, could be dropdown)
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Food, Transport',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isLoading ? 'Saving...' : 'Save Expense'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
