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

// --- Database ---

@DriftDatabase(tables: [Projects, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(tasks).go();
      await delete(projects).go();
    });
  }

  @override
  int get schemaVersion => 1;
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
