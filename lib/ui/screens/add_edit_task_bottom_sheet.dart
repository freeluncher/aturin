import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../domain/models/task.dart';

class AddEditTaskBottomSheet extends ConsumerStatefulWidget {
  final String projectId;
  final Task? task;

  const AddEditTaskBottomSheet({super.key, required this.projectId, this.task});

  @override
  ConsumerState<AddEditTaskBottomSheet> createState() =>
      _AddEditTaskBottomSheetState();
}

class _AddEditTaskBottomSheetState
    extends ConsumerState<AddEditTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      if (widget.task == null) {
        // Create
        final newTask = Task(
          id: const Uuid().v4(),
          projectId: widget.projectId,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          createdAt: now,
          lastUpdated: now,
        );
        await ref.read(projectRepositoryProvider).createTask(newTask);
      } else {
        // Update
        final updatedTask = Task(
          id: widget.task!.id,
          projectId: widget.projectId,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          createdAt: widget.task!.createdAt,
          lastUpdated: now,
          isCompleted: widget.task!.isCompleted,
          serverId: widget.task!.serverId,
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
