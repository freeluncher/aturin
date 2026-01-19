import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers.dart';
import '../../../domain/models/project.dart';

class AddEditProjectScreen extends ConsumerStatefulWidget {
  final Project? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  ConsumerState<AddEditProjectScreen> createState() =>
      _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends ConsumerState<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  // Phase 1 Fields
  late TextEditingController _clientNameController;
  late TextEditingController _clientContactController;
  late TextEditingController _budgetController;
  late TextEditingController _paidController;
  late TextEditingController _techStackController; // Comma separated

  DateTime? _selectedDeadline;
  int _status = 1; // Default Active
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');

    _clientNameController = TextEditingController(text: p?.clientName ?? '');
    _clientContactController = TextEditingController(
      text: p?.clientContact ?? '',
    );
    _budgetController = TextEditingController(
      text: p?.totalBudget.toString() ?? '0',
    );
    _paidController = TextEditingController(
      text: p?.amountPaid.toString() ?? '0',
    );

    // Convert JSON list to comma separated string for editing
    String techText = '';
    if (p?.techStack != null) {
      try {
        final List<dynamic> list = jsonDecode(p!.techStack!);
        techText = list.join(', ');
      } catch (_) {}
    }
    _techStackController = TextEditingController(text: techText);

    _selectedDeadline = p?.deadline;
    _status = p?.status ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _clientNameController.dispose();
    _clientContactController.dispose();
    _budgetController.dispose();
    _paidController.dispose();
    _techStackController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // Parse inputs
      final totalBudget =
          double.tryParse(
            _budgetController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;
      final amountPaid =
          double.tryParse(
            _paidController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;

      // Parse Tech Stack
      final techList = _techStackController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final techStackJson = jsonEncode(techList);

      if (widget.project == null) {
        // Create
        final newProject = Project(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          createdAt: now,
          lastUpdated: now,
          deadline: _selectedDeadline,
          // New Fields
          clientName: _clientNameController.text.trim(),
          clientContact: _clientContactController.text.trim(),
          totalBudget: totalBudget,
          amountPaid: amountPaid,
          techStack: techStackJson,
          status: _status,
        );
        await ref.read(projectRepositoryProvider).createProject(newProject);
      } else {
        // Update
        final updatedProject = Project(
          id: widget.project!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          createdAt: widget.project!.createdAt,
          lastUpdated: now,
          deadline: _selectedDeadline,
          serverId: widget.project!.serverId,
          isSynced: false,
          isDeleted: widget.project!.isDeleted,
          // New Fields
          clientName: _clientNameController.text.trim(),
          clientContact: _clientContactController.text.trim(),
          totalBudget: totalBudget,
          amountPaid: amountPaid,
          techStack: techStackJson,
          status: _status,
        );
        await ref.read(projectRepositoryProvider).updateProject(updatedProject);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'New Project' : 'Edit Project'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save),
            onPressed: _isLoading ? null : _saveProject,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Basic Info
            Text('Basic Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Client Info
            Text('Client Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _clientContactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact (Email/Phone)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status & Deadline
            Text(
              'Status & Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Planning')),
                      DropdownMenuItem(value: 1, child: Text('Active')),
                      DropdownMenuItem(value: 2, child: Text('Testing')),
                      DropdownMenuItem(value: 3, child: Text('Completed')),
                    ],
                    onChanged: (val) => setState(() => _status = val ?? 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDeadline ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDeadline = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Deadline',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(LucideIcons.calendar),
                      ),
                      child: Text(
                        _selectedDeadline != null
                            ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                            : 'Set Deadline',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Financials
            Text(
              'Financials (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Budget (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _paidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tech Stack
            Text('Technical', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _techStackController,
              decoration: const InputDecoration(
                labelText: 'Tech Stack (Comma separated)',
                hintText: 'Flutter, Supabase, Riverpod...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveProject,
              icon: const Icon(LucideIcons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Project'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
