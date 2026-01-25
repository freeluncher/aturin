import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers.dart';
import '../../../domain/models/task.dart';

class AddEditTaskBottomSheet extends ConsumerStatefulWidget {
  final String? projectId; // Made optional
  final Task? task;

  const AddEditTaskBottomSheet({super.key, this.projectId, this.task});

  @override
  ConsumerState<AddEditTaskBottomSheet> createState() =>
      _AddEditTaskBottomSheetState();
}

class _AddEditTaskBottomSheetState
    extends ConsumerState<AddEditTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  int _priority = 1; // 1: Medium
  DateTime? _selectedDueDate;
  String?
  _selectedProjectId; // To store selected project if widget.projectId is null
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _priority = widget.task?.priority ?? 1;
    _selectedDueDate = widget.task?.dueDate;
    _selectedProjectId = widget.projectId ?? widget.task?.projectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      if (widget.task == null) {
        // Create
        final newTask = Task(
          id: const Uuid().v4(),
          projectId: _selectedProjectId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          createdAt: now,
          lastUpdated: now,
          priority: _priority,
          dueDate: _selectedDueDate,
        );
        await ref.read(projectRepositoryProvider).createTask(newTask);
      } else {
        // Update
        final updatedTask = Task(
          id: widget.task!.id,
          projectId:
              widget.projectId ??
              widget.task!.projectId, // Keep existing if editing
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          createdAt: widget.task!.createdAt,
          lastUpdated: now,
          isCompleted: widget.task!.isCompleted,
          serverId: widget.task!.serverId,
          priority: _priority,
          dueDate: _selectedDueDate,
          isSynced: false,
          isDeleted: widget.task!.isDeleted,
        );
        await ref.read(projectRepositoryProvider).updateTask(updatedTask);
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
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.task == null ? 'New Task' : 'Edit Task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Project Selector (Only if projectId not provided)
            if (widget.projectId == null && widget.task == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: projectsAsync.when(
                  data: (projects) => DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      prefixIcon: Icon(LucideIcons.folder),
                    ),
                    items: projects
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedProjectId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text('Error loading projects: $e'),
                ),
              ),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Priority & Due Date Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('Low'),
                            icon: Icon(LucideIcons.arrowDown),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('Med'),
                            icon: Icon(LucideIcons.minus),
                          ),
                          ButtonSegment(
                            value: 2,
                            label: Text('High'),
                            icon: Icon(LucideIcons.arrowUp),
                          ),
                        ],
                        selected: {_priority},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() {
                            _priority = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 5),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _selectedDueDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDueDate != null
                                    ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                    : 'No Deadline',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _saveTask,
              child: Text(_isLoading ? 'Saving...' : 'Save Task'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
