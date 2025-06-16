import 'package:flutter/material.dart';
import 'package:karsinta/database_helper.dart';
import 'package:karsinta/backup_helper.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class StuffPage extends StatefulWidget {
  const StuffPage({super.key});

  @override
  State<StuffPage> createState() => StuffPageState();
}

class StuffPageState extends State<StuffPage> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isEditMode = false;

  @override
  void initState() {
    
    super.initState();
    loadItems();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    
    super.didChangeDependencies();
    _loadCategories();
  }

  //lataa tavarat tietokannasta
  Future<void> loadItems() async {
    final db = await DatabaseHelper.instance.database;
    final items = await db.query('stuff');
    setState(() {
      _items = items;
    });
  }

  //lataa kategoriat tietokannasta
  Future<void> _loadCategories() async {
    
    final db = await DatabaseHelper.instance.database;
    final categories = await db.query('categories');

    setState(() {
      _categories = categories;
    });
  }

  //poistetaan tavara tietokannasta
  Future<void> _deleteItem(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('stuff', where: 'id = ?', whereArgs: [id]);
    loadItems(); // Ladataan tavarat uudelleen
  }

  //kategorian nimi ID:n perusteella
  String? _getCategoryName(int categoryId) {
    final category = _categories.firstWhere((cat) => cat['id'] == categoryId,
        orElse: () => {});
    return category.isNotEmpty ? category['name'] : null;
  }

  //ikoni kategorioittain
  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vaatteet':
        return Icons.checkroom;
      case 'huonekalut':
        return Icons.chair;
      case 'sisustustavarat':
        return Icons.light_outlined;
      case 'keittiötarvikkeet':
        return Icons.food_bank_outlined;
      case 'elektroniikka':
        return Icons.devices;
      case 'kirjat':
        return Icons.menu_book;
      case 'kengät':
        return MdiIcons.shoeFormal;
      case 'muut':
        return Icons.category;
      default:
        return Icons.help_outline; // Tuntematon kategoria
    }
  }

  //syötettyjen tietojen muokkaamisen funktio
  void _openEditDialog(Map<String, dynamic> item) async {
    TextEditingController nameController =
        TextEditingController(text: item['name']);
    int? selectedCategory = item['category_id'];
    DateTime? selectedDate =
        item['date'] != null ? DateTime.tryParse(item['date']) : null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Muokkaa tavaraa'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Tavaran nimi'),
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedCategory,
                      items: _categories
                          .map((cat) => DropdownMenuItem<int>(
                                value: cat['id'] as int,
                                child: Text(cat['name'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Kategoria'),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: Icon(Icons.date_range),
                      label: Text(selectedDate != null
                          ? '${selectedDate?.day.toString().padLeft(2, '0')}.${selectedDate?.month.toString().padLeft(2, '0')}.${selectedDate?.year}'
                          : 'Valitse päivämäärä'),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Peruuta'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text('Tallenna'),
                  onPressed: () async {
                    String updatedName = nameController.text.trim();
                    if (updatedName.isEmpty || selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Nimi ja kategoria ovat pakollisia.')),
                      );
                      return;
                    }

                    final db = await DatabaseHelper.instance.database;
                    await db.update(
                      'stuff',
                      {
                        'name': updatedName,
                        'category_id': selectedCategory,
                        'date': selectedDate?.toIso8601String(),
                      },
                      where: 'id = ?',
                      whereArgs: [item['id']],
                    );
                    Navigator.pop(context);
                    loadItems();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

//tästä alkaa sivun rakenne:
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          PreferredSize(
            preferredSize: Size.fromHeight(100),
            child: Container(
              color: Colors.pink[50],
              padding: EdgeInsets.all(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Karsitut tavarat',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.settings, size: 35),
                      tooltip: 'Asetukset',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Asetukset'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text('Edit'),
                                      Spacer(),
                                      Switch(
                                        value: _isEditMode,
                                        onChanged: (value) {
                                          setState(() {
                                            _isEditMode = value;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text('Lataa tiedot tiedostoksi'),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.download, size: 30),
                                        onPressed: () async {
                                          try {
                                            await BackupHelper.exportData();
                                          } catch (e) {
                                            debugPrint('Virhe: $e');
                                          }
                                        },
                                        tooltip: 'Vie tiedot',
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 10),
                                  Row(
                                    children: [
                                      Text('Tuo tiedot sovellukseen'),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.upload, size: 30),
                                        onPressed: () async {
                                          await BackupHelper.importData();
                                          await loadItems(); // Päivitä lista heti
                                        },
                                        tooltip: 'Tuo tiedot',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                String item = _items[index]['name'] ??
                    'Tuntematon tavara'; //varmistetaan ettei ole null
                int categoryId = _items[index]['category_id'];
                String? category = _getCategoryName(categoryId);
                String? dateString = _items[index]['date'];
                DateTime? parsedDate =
                    dateString != null ? DateTime.tryParse(dateString) : null;
                String formattedDate = parsedDate != null
                    ? '${parsedDate.day}.${parsedDate.month}.${parsedDate.year}'
                    : 'Tuntematon päivä';

//jokaiselle riville tulee tavaran nimi, kategoria, päivä sekä poista- ja editointinappulat,
//mikäli syöttikin väärän tavaran tai haluaa muokata sitä
                return ListTile(
                  leading: Icon(getCategoryIcon(category?? 'default'), size: 35),
                  title: Text(
                    item,
                    style: TextStyle(fontSize: 18),
                  ),
                  subtitle: Text(
                    'Kategoria: $category\nPäivä: $formattedDate',
                  ),
                  trailing: _isEditMode
                      ? Row(
                          mainAxisSize: MainAxisSize
                              .min, // tärkeää, ettei vie koko rivin tilaa
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  semanticLabel: 'Muokkaa'),
                              color: Colors.grey,
                              onPressed: () {
                                _openEditDialog(_items[index]);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  semanticLabel: 'Poista'),
                              color: Colors.grey,
                              onPressed: () {
                                _deleteItem(_items[index]['id']);
                              },
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
