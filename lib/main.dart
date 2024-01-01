import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'account_info.dart';


void main() {
  runApp(MyApp());
}

class DatabaseHelper {
  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      path.join(dbPath, 'knowledge_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE knowledge(id TEXT PRIMARY KEY, title TEXT, content TEXT)',
        );
      },
      version: 1,
    );
  }

  static Future<void> createAccountTable() async {
    final db = await DatabaseHelper.getDatabase();
    await db.execute(
      'CREATE TABLE IF NOT EXISTS account_info(username TEXT PRIMARY KEY, email TEXT, favorite_genre TEXT)',
    );
  }

  static Future<void> insertKnowledge(Knowledge knowledge) async {
    final db = await DatabaseHelper.getDatabase();
    await db.insert(
      'knowledge',
      knowledge.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Knowledge>> getFavorites() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('knowledge');

    return List.generate(maps.length, (i) {
      return Knowledge(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
      );
    });
  }

  static Future<void> deleteKnowledge(String id) async {
    final db = await DatabaseHelper.getDatabase();
    await db.delete(
      'knowledge',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Knowledge>> getKnowledge() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('knowledge');

    return List.generate(maps.length, (i) {
      return Knowledge(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
      );
    });
  }

  static Future<void> insertAccountInfo(AccountInfo accountInfo) async {
    final db = await DatabaseHelper.getDatabase();
    await db.insert(
      'account_info',
      accountInfo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<AccountInfo> getAccountInfo() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('account_info');

    if (maps.isNotEmpty) {
      return AccountInfo.fromMap(maps.first);
    } else {
      return AccountInfo(username: '', email: '', favoriteGenre: '');
    }
  }
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isDarkMode', value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knowledge Stash',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MainScreen(
        toggleTheme: toggleTheme,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(bool) toggleTheme;

  MainScreen({required this.toggleTheme});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      HomeFeedPage(),
      SettingsPage(toggleTheme: widget.toggleTheme),
      FavoritesPage(), // Tambahkan FavoritesPage di sini
    ];
  }

  void navigateToAddKnowledge() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddKnowledgePage()));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: navigateToAddKnowledge,
        child: Icon(Icons.add),
      ) : null,
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Function(bool) toggleTheme;

  SettingsPage({required this.toggleTheme});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Controllers for form fields
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _favoriteGenreController = TextEditingController();

  Future<AccountInfo>? _accountInfoFuture;

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
    DatabaseHelper.createAccountTable(); // Create the account table if it doesn't exist
  }

  Future<void> _loadAccountInfo() async {
    setState(() {
      _accountInfoFuture = DatabaseHelper.getAccountInfo();
    });
  }

  Future<void> _saveAccountInfo() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final favoriteGenre = _favoriteGenreController.text;

    await DatabaseHelper.insertAccountInfo(
      AccountInfo(
        username: username,
        email: email,
        favoriteGenre: favoriteGenre,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account information saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Dark Mode'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (bool value) {
              widget.toggleTheme(value);
            },
          ),
          FutureBuilder<AccountInfo>(
            future: _accountInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final accountInfo = snapshot.data!;
                _usernameController.text = accountInfo.username;
                _emailController.text = accountInfo.email;
                _favoriteGenreController.text = accountInfo.favoriteGenre;
              }

              return Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Username'),
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextFormField(
                    controller: _favoriteGenreController,
                    decoration: InputDecoration(labelText: 'Favorite Genre'),
                  ),
                  ElevatedButton(
                    onPressed: _saveAccountInfo,
                    child: Text('Save Account Information'),
                  ),
                ],
              );
            },
          ),
          // Add more settings options as needed
        ],
      ),
    );
  }
}

class HomeFeedPage extends StatefulWidget {
  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  Future<List<Knowledge>> fetchKnowledge() async {
    final response = await http.get(Uri.parse('https://65811d473dfdd1b11c42733b.mockapi.io/tubes/knowledge'));

    if (response.statusCode == 200) {
      List<dynamic> values = json.decode(response.body);
      return values.map((e) => Knowledge.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load knowledge');
    }
  }

  void deleteKnowledge(String id) async {
    var response = await http.delete(
      Uri.parse('https://65811d473dfdd1b11c42733b.mockapi.io/tubes/knowledge/$id'),
    );

    if (response.statusCode == 200) {
      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Knowledge berhasil dihapus')),
      );

      // Muat ulang daftar knowledge
      setState(() {});
    } else {
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus knowledge')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Knowledge Stash'),
      ),
      body: FutureBuilder<List<Knowledge>>(
        future: fetchKnowledge(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return KnowledgeCard(
                  knowledge: snapshot.data![index],
                  onDelete: deleteKnowledge,
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Knowledge {
  final String id;
  final String title;
  final String content;

  Knowledge({required this.id, required this.title, required this.content});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }

  factory Knowledge.fromJson(Map<String, dynamic> json) {
    return Knowledge(
      id: json['id'],
      title: json['title'],
      content: json['content'],
    );
  }
}

class KnowledgeCard extends StatelessWidget {
  final Knowledge knowledge;
  final Function(String) onDelete;

  KnowledgeCard({required this.knowledge, required this.onDelete});

  void saveKnowledge(BuildContext context) async {
    await DatabaseHelper.insertKnowledge(knowledge);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Knowledge berhasil disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              knowledge.title,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(knowledge.content),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () => saveKnowledge(context),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(knowledge.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddKnowledgePage extends StatefulWidget {
  @override
  _AddKnowledgePageState createState() => _AddKnowledgePageState();
}

class _AddKnowledgePageState extends State<AddKnowledgePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Future<void> submitKnowledge() async {
    final String title = _titleController.text;
    final String content = _contentController.text;
    final String createdAt = DateTime.now().toIso8601String();

    var response = await http.post(
      Uri.parse('https://65811d473dfdd1b11c42733b.mockapi.io/tubes/knowledge'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'createdAt': createdAt,
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil menambahkan knowledge')),
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan knowledge')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Knowledge'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Content'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    submitKnowledge();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Knowledge>> favoriteKnowledge;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    setState(() {
      favoriteKnowledge = DatabaseHelper.getFavorites();
    });
  }

  void deleteKnowledge(String id) async {
    await DatabaseHelper.deleteKnowledge(id);
    loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadFavorites,
          ),
        ],
      ),
      body: FutureBuilder<List<Knowledge>>(
        future: favoriteKnowledge,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No favorites added'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final knowledge = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      knowledge.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(knowledge.content),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteKnowledge(knowledge.id),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}



class PlaceholderWidget extends StatelessWidget {
  final Color color;

  PlaceholderWidget(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
    );
  }
}
