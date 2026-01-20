import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../domain/models/invoice.dart';

class AddEditInvoiceSheet extends ConsumerStatefulWidget {
  final Invoice? invoice;
  final String? preselectedProjectId;

  const AddEditInvoiceSheet({
    super.key,
    this.invoice,
    this.preselectedProjectId,
  });

  @override
  ConsumerState<AddEditInvoiceSheet> createState() =>
      _AddEditInvoiceSheetState();
}

class _AddEditInvoiceSheetState extends ConsumerState<AddEditInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedProjectId;
  String _selectedStatus = 'Draft';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _titleController.text = widget.invoice!.title;
      _amountController.text = widget.invoice!.amount.toStringAsFixed(0);
      _selectedProjectId = widget.invoice!.projectId;
      _selectedStatus = widget.invoice!.status;
      _dueDate = widget.invoice!.dueDate;
    } else {
      _selectedProjectId = widget.preselectedProjectId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a project')),
        );
        return;
      }

      final title = _titleController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

      final repository = ref.read(invoiceRepositoryProvider);

      if (widget.invoice != null) {
        final updatedInvoice = widget.invoice!.copyWith(
          title: title,
          amount: amount,
          projectId: _selectedProjectId,
          status: _selectedStatus,
          dueDate: _dueDate,
          isSynced: false,
        );
        await repository.updateInvoice(updatedInvoice);
      } else {
        final newInvoice = Invoice(
          id: const Uuid().v4(),
          projectId: _selectedProjectId!,
          title: title,
          amount: amount,
          status: _selectedStatus,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
          isSynced: false,
        );
        await repository.createInvoice(newInvoice);
      }

      // Trigger sync
      ref.read(syncServiceProvider).syncUp();

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      constraints: const BoxConstraints(maxHeight: 600), // Limit height
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.invoice == null ? 'New Invoice' : 'Edit Invoice',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Project Dropdown
              projectsAsync.when(
                data: (projects) {
                  final activeProjects = projects
                      .where((p) => !p.isDeleted)
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.folder),
                    ),
                    items: activeProjects
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedProjectId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Error loading projects: $e'),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Title (e.g. DP 30%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              // Quick Tags
              Wrap(
                spacing: 8,
                children:
                    [
                          'DP 30%',
                          'DP 50%',
                          'Termin 1',
                          'Pelunasan',
                          'Reimbursement',
                        ]
                        .map(
                          (label) => ActionChip(
                            label: Text(
                              label,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              _titleController.text = label;
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.banknote),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'Sent', child: Text('Sent')),
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedStatus = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(LucideIcons.calendar),
                        ),
                        child: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Invoice'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
