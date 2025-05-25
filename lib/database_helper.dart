import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'stuff.db';
  static const _databaseVersion = 3;

  //tavarat-taulu
  static const stuffTable = 'stuff';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnCategoryId = 'category_id';

  //kategoriat-taulu
  static const categoryTable = 'categories';
  static const categoryId = '_id';
  static const categoryName = 'name';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE stuff ADD COLUMN date TEXT');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var dbPath = await getDatabasesPath();
    var path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  //luodaan tietokanta ja taulut
  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL UNIQUE
    )
  ''');

    await db.execute('''
    CREATE TABLE stuff (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    category_id INTEGER,
    date TEXT,
    FOREIGN KEY (category_id) REFERENCES categories (id)
  )
''');

    //valmiit kategoriat käyttäjälle
    await db.insert('categories', {'name': 'Elektroniikka'});
    await db.insert('categories', {'name': 'Huonekalut'});
    await db.insert('categories', {'name': 'Keittiötarvikkeet'});
    await db.insert('categories', {'name': 'Kengät'});
    await db.insert('categories', {'name': 'Kirjat'});
    await db.insert('categories', {'name': 'Sisustustavarat'});
    await db.insert('categories', {'name': 'Vaatteet'});
    await db.insert('categories', {'name': 'Muu'});
  }

  //haetaan kategoriat
  Future<List<Map<String, dynamic>>> queryAllCategories() async {
    Database db = await database;
    return await db.query(categoryTable);
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('stuff', row);
  }

  //hae kaikki tavarat (liitetään kategoriat mukaan)
  Future<List<Map<String, dynamic>>> queryAllItems() async {
    Database db = await database;
    return await db.rawQuery('''
    SELECT $stuffTable.$columnId, $stuffTable.$columnName, $categoryTable.$categoryName, $stuffTable.date
    FROM $stuffTable
    JOIN $categoryTable ON $stuffTable.$columnCategoryId = $categoryTable.$categoryId
    ''');
  }

  //poista tavara
  Future<int> deleteItem(int id) async {
    Database db = await database;
    return await db.delete(stuffTable, where: '$columnId = ?', whereArgs: [id]);
  }
}
