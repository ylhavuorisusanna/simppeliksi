import 'package:flutter/material.dart';
import 'package:karsinta/pages/statistics.dart';
import 'package:karsinta/pages/stuff.dart';
import 'package:karsinta/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //muuttujat yms:
  final GlobalKey<StuffPageState> _stuffPageKey = GlobalKey();
  int _selectedIndex = 0;
  int? _selectedCategoryId;
  final TextEditingController _controller = TextEditingController();
  Map<String, String> items = {};
  List<Map<String, dynamic>> _categories = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    testDatabase();
    _loadCategories();
  }

  Future<void> testDatabase() async {
  final db = await DatabaseHelper.instance.database;
  print("Tietokanta polku: ${db.path}");
  final categories = await db.query('categories');
  print('Testi kategoriat: $categories');
}

//haetaan kategoriat tietokannasta
  Future<void> _loadCategories() async {
    print('Ladataan kategoriat...');
  final db = await DatabaseHelper.instance.database;
  final categories = await db.query('categories');
  debugPrint('Ladatut kategoriat: $categories');
  setState(() {
    _categories = categories;
    if (_categories.isNotEmpty) {
      _selectedCategoryId = _categories.first['id'] as int;
    }
  });
}

  //navigaatiopalkin navigoinnin metodi
  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  //BOTTOM SHEET: metodi, jolla avataan bottom sheet
  void _openModalBottomSheet(BuildContext context) async {
    FocusNode textFieldFocus = FocusNode();
    final shouldRefresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    textCapitalization: TextCapitalization.sentences,
                    focusNode: textFieldFocus,
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      hintText: 'Syötä karsimasi tavara',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 20),
                  _buildDatePicker(context),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    //jos shouldRefresh on true, päivitä StuffPage
    if (shouldRefresh == true) {
      setState(() {}); //pakotetaan päivitys
      //tämä siksi, että lista päivittyisi heti, kun siihen syötetään uusi tavara
    } else {
      //jos bottom sheet suljettiin painamalla muualta ruudusta, 
      //niin tyhjennetään tiedot ettei ne jää sinne kummittelemaan
      _controller.clear();
      _selectedCategoryId = null;
      _selectedDate = null;
    }
  }

  //DATEPICKER
  Widget _buildDatePicker(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter localSetState) {
        return InkWell(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
              localSetState(() {}); // Päivitä paikallinen builder-näkymä
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              hintText: 'Valitse päivämäärä',
            ),
            child: Text(
              _selectedDate != null
                  ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                  : 'Valitse päivämäärä',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        );
      },
    );
  }

  //KATEGORIAVALITSIN omassa widgetissään helpottaakseni koodin lukua
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      hint: Text('Valitse kategoria'),
      items: _categories.map<DropdownMenuItem<int>>((category) {
        return DropdownMenuItem<int>(
          value: category['id'],
          child: Text(category['name']),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedCategoryId = newValue!;
        });
      },
    );
  }

  //NAPPULAT omassa widgetissään helpottamaan koodin lukua
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            label: const Text('Peruuta'),
            icon: const Icon(Icons.cancel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              fixedSize: const Size(120, 50),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            label: const Text('Tallenna'),
            icon: const Icon(Icons.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[100],
              fixedSize: const Size(120, 50),
            ),
            onPressed: () {
              _addItem();
            },
          ),
        ],
      ),
    );
  }

  void _addItem() async {
    String newItem = _controller.text.trim();
    if (newItem.isNotEmpty &&
        _selectedCategoryId != null &&
        _selectedDate != null) {
      //varmistetaan, että käyttäjä valitsee kaikki tiedot
      //varmistetaan, että valittu kategoria on olemassa ennen lisäystä
      await DatabaseHelper.instance.insert({
        'name': newItem,
        'category_id': _selectedCategoryId!, //null-tarkastus
        'date': _selectedDate!.toIso8601String(), // Tallenna ISO-muodossa
      });

      _controller.clear();
      _selectedCategoryId = null;
      _selectedDate = null;

      //StuffPage päivittyy
      _stuffPageKey.currentState?.loadItems();

      Navigator.pop(context, true); //sulkee bottom sheetin
    } else {
      //jos jokin tiedoista puuttuu, näytetään virheviesti
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Huomio!'),
            content: const Text('Kaikki tiedot ovat pakollisia.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Selvä juttu!'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  //täällä alkaa varsinainen rakenne:
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      StuffPage(key: _stuffPageKey),
      const StatisticsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () =>
                  _openModalBottomSheet(context), //avataan BottomSheet
              child: const Icon(Icons.add),
            )
          : null,

      //NavigaatioBar:
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tavarat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: 'Tilastot'),
        ],
      ),

      //sijoitetaan FAB NavBarin keskelle päälle:
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
