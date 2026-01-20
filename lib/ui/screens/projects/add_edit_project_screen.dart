import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers.dart';
import '../../../domain/models/project.dart';

import '../../../domain/models/task.dart'; // Import Task model

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
  late TextEditingController _techStackController; // Comma separated

  DateTime? _selectedDeadline;
  int _status = 1; // Default Active
  bool _isLoading = false;

  // Template System
  String? _selectedTemplate;
  final Map<String, List<String>> _taskTemplates = {
    'Skripsi/Tesis 🎓': [
      'Judul & Proposal',
      'BAB 1 Pendahuluan',
      'BAB 2 Tinjauan Pustaka',
      'BAB 3 Metodologi',
      'Kuesioner/Data',
      'Olah Data',
      'BAB 4 Hasil',
      'BAB 5 Penutup',
      'Daftar Pustaka',
      'Revisi Dosen',
    ],
    'Desain Logo 🎨': [
      'Briefing',
      'Moodboard',
      'Sketsa Kasar',
      'Draft Digital',
      'Presentasi',
      'Revisi',
      'Final Files',
    ],
    'Joki Tugas 📝': [
      'Analisis Soal',
      'Pengerjaan',
      'Pengecekan',
      'Kirim File',
    ],
    'Website Development 💻': [
      'Requirement Analysis',
      'UI/UX Design',
      'Frontend Dev',
      'Backend Dev',
      'Integration',
      'Testing',
      'Deployment',
    ],
    'Undangan Digital 💌': [
      'Data Pengantin',
      'Pilih Tema/Musik',
      'Input Konten',
      'Revisi',
      'Sebar Link',
    ],
  };

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

      // Parse Tech Stack
      final techList = _techStackController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final techStackJson = jsonEncode(techList);

      if (widget.project == null) {
        // Create
        final newProjectId = const Uuid().v4();
        final newProject = Project(
          id: newProjectId,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          createdAt: now,
          lastUpdated: now,
          deadline: _selectedDeadline,
          // New Fields
          clientName: _clientNameController.text.trim(),
          clientContact: _clientContactController.text.trim(),
          totalBudget: totalBudget,
          techStack: techStackJson,
          status: _status,
        );
        await ref.read(projectRepositoryProvider).createProject(newProject);

        // --- Template Logic ---
        if (_selectedTemplate != null &&
            _taskTemplates.containsKey(_selectedTemplate)) {
          final tasks = _taskTemplates[_selectedTemplate]!;
          final taskRepo = ref.read(projectRepositoryProvider);

          for (var title in tasks) {
            final newTask = Task(
              id: const Uuid().v4(),
              projectId: newProjectId,
              title: title,
              isCompleted: false,
              createdAt: DateTime.now(),
              lastUpdated: DateTime.now(),
              isSynced: false,
              isDeleted: false,
              priority: 1, // Medium
            );
            await taskRepo.createTask(newTask);
          }
        }
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
          techStack: techStackJson,
          status: _status,
        );
        await ref.read(projectRepositoryProvider).updateProject(updatedProject);
      }

      // Trigger sync for new project/tasks
      ref.read(syncServiceProvider).syncUp();

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
        title: Text(widget.project == null ? 'Proyek Baru' : 'Edit Proyek'),
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
            Text(
              'Informasi Dasar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // --- Template Selector (Only for new projects) ---
            if (widget.project == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.wand2,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Gunakan Template (Opsional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTemplate,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text('Pilih Template Tugas...'),
                      items: _taskTemplates.keys
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTemplate = val;
                          // Auto-fill some fields based on template?
                          // For now just tasks.
                        });
                      },
                    ),
                    if (_selectedTemplate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Akan membuat ${_taskTemplates[_selectedTemplate]!.length} tugas otomatis.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Proyek',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Client Info
            Text('Info Klien', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Klien/Dosen',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _clientContactController,
                    decoration: const InputDecoration(
                      labelText: 'Kontak (HP/Email)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status & Deadline
            Text(
              'Status & Deadline',
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
                      DropdownMenuItem(value: 0, child: Text('Perencanaan')),
                      DropdownMenuItem(value: 1, child: Text('Aktif')),
                      DropdownMenuItem(value: 2, child: Text('Testing/Revisi')),
                      DropdownMenuItem(value: 3, child: Text('Selesai')),
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
                        labelText: 'Tenggat Waktu',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(LucideIcons.calendar),
                      ),
                      child: Text(
                        _selectedDeadline != null
                            ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                            : 'Pilih Tanggal',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Financials
            Text(
              'Keuangan (Opsional)',
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
                      labelText: 'Total Nilai (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tech Stack
            Text(
              'Kategori & Label',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _techStackController,
              decoration: const InputDecoration(
                labelText: 'Kategori/Label (Pisahkan dengan koma)',
                hintText: 'Skripsi, Desain, Website, Joki...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveProject,
              icon: const Icon(LucideIcons.save),
              label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Proyek'),
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
