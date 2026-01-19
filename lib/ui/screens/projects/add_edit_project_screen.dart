import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(
      text: widget.project?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      if (widget.project == null) {
        // Create
        final newProject = Project(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          createdAt: now,
          lastUpdated: now,
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
          serverId: widget.project!.serverId,
          isSynced: false, // Mark as unsynced so it pushes to server
          isDeleted: widget.project!.isDeleted,
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProject,
                  child: Text(_isLoading ? 'Saving...' : 'Save Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
