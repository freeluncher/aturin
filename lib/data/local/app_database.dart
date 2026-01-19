import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

// --- Tables ---

class Projects extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deadline => dateTime().nullable()();

  // New Columns (Phase 1)
  // Client Info
  TextColumn get clientName => text().nullable()();
  TextColumn get clientContact => text().nullable()();

  // Financial Info
  RealColumn get totalBudget => real().withDefault(const Constant(0.0))();
  RealColumn get amountPaid => real().withDefault(const Constant(0.0))();

  // Tech Info (JSON)
  TextColumn get techStack => text().nullable()();

  // Status (0: Planning, 1: Active, 2: Testing, 3: Completed)
  IntColumn get status => integer().withDefault(const Constant(1))();

  // Sync flags
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get serverId => text().nullable()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated =>
      dateTime().withDefault(currentDateAndTime)();

  // Sync flags
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class VaultItems extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get key => text()();
  TextColumn get value => text()(); // Encrypted Value
  TextColumn get category => text().nullable()();
  TextColumn get projectId => text().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get serverId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(tables: [Projects, Tasks, VaultItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(tasks).go();
      await delete(projects).go();
      await delete(vaultItems).go();
    });
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(projects, projects.deadline);
        }
        if (from < 3) {
          await m.createTable(vaultItems);
        }
        if (from < 4) {
          // Phase 1 Migration
          await m.addColumn(projects, projects.clientName);
          await m.addColumn(projects, projects.clientContact);
          await m.addColumn(projects, projects.totalBudget);
          await m.addColumn(projects, projects.amountPaid);
          await m.addColumn(projects, projects.techStack);
          await m.addColumn(projects, projects.status);
        }
        if (from < 5) {
          // Vault Sync & Association
          await m.addColumn(vaultItems, vaultItems.projectId);
          await m.addColumn(vaultItems, vaultItems.serverId);
          await m.addColumn(vaultItems, vaultItems.isSynced);
          await m.addColumn(vaultItems, vaultItems.isDeleted);
        }
        if (from < 6) {
          await m.addColumn(vaultItems, vaultItems.lastUpdated);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'aturin_app.sqlite'));

    // Also work around limitations on old Android versions
    if (Platform.isAndroid) {
      // ignore: deprecated_member_use
      // await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      // NOTE: modern sqlite3_flutter_libs usually handles this well,
      // but if you run into issues on Android < 8, might verify.
    }

    return NativeDatabase.createInBackground(file);
  });
}
