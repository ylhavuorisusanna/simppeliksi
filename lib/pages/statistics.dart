import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:karsinta/database_helper.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  //muuttujia
  List<Map<String, dynamic>> _items = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _categories = [];

  //vuosittain-taulukkoa varten
  int selectedYear = DateTime.now().year;
  Map<String, int> monthlyCounts = {
    for (var i = 1; i <= 12; i++) i.toString().padLeft(2, '0'): 0
  };

  //tavoite oletuksena 100
  int targetAmount = 100;

  final TextEditingController _targetController = TextEditingController();

  Map<String, double> dataMap = {};

  @override
  void initState() {
    super.initState();
    loadItemsSt();
    _loadCategories();
    _loadTarget();
    _loadMonthlyCounts(selectedYear);
  }

  Future<void> loadItemsSt() async {
    final db = await DatabaseHelper.instance.database;

    //haetaan tavarat tietokannasta
    final result = await db.rawQuery('SELECT * FROM stuff');

    setState(() {
      _items = result; //tallennetaan haettu data _items-listaan
    });

    //päivitetään dataMap myös
    final categoryResult = await db.rawQuery('''
    SELECT categories.name, COUNT(stuff.id) as count
    FROM categories
    LEFT JOIN stuff ON categories.id = stuff.category_id
    GROUP BY categories.name
  ''');

    Map<String, double> tempDataMap = {};
    for (var row in categoryResult) {
      tempDataMap[row['name'] as String] = (row['count'] as int).toDouble();
    }

    setState(() {
      dataMap = tempDataMap;
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

  //ladataan tallennettu tavoite SharedPreferencesista
  void _loadTarget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      targetAmount = prefs.getInt('targetAmount')!;
      _targetController.text = targetAmount.toString();
    });
  }

  //tallennetaan tavoite SharedPreferencesiin
  void _saveTarget(int i) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      targetAmount = i;
      _targetController.text = targetAmount.toString();
    });
    await prefs.setInt('targetAmount', i);
  }

  //vuosittain-taulukkoa varten
  Future<void> _loadMonthlyCounts(int year) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
    SELECT strftime('%m', date) as month, COUNT(*) as count
    FROM stuff
    WHERE strftime('%Y', date) = ?
    GROUP BY month
    ORDER BY month
  ''', [year.toString()]);

    Map<String, int> tempCounts = {
      for (var i = 1; i <= 12; i++) i.toString().padLeft(2, '0'): 0
    };

    for (var row in result) {
      tempCounts[row['month'] as String] = row['count'] as int;
    }

    setState(() {
      monthlyCounts = tempCounts;
    });
  }

  String _monthName(String monthNumber) {
    const months = [
      'Tammikuu',
      'Helmikuu',
      'Maaliskuu',
      'Huhtikuu',
      'Toukokuu',
      'Kesäkuu',
      'Heinäkuu',
      'Elokuu',
      'Syyskuu',
      'Lokakuu',
      'Marraskuu',
      'Joulukuu'
    ];
    final index = int.parse(monthNumber) - 1;
    return months[index];
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

//värilista piecharttia varten
  final colorList = <Color>[
    const Color(0xfffdcb6e),
    const Color(0xff0984e3),
    const Color(0xfffd79a8),
    const Color(0xffe17055),
    const Color(0xff6c5ce7),
    const Color.fromARGB(255, 92, 231, 110),
    const Color.fromARGB(255, 92, 222, 231),
  ];

//tästä alkaa:
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
//Otsikko-rivi
            Container(
              color: Colors.pink[50],
              padding: EdgeInsets.all(30),
              alignment: Alignment.center,
              child: Text(
                'Tilastoja',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 15),

//Tavoitteesi-sisältö
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.fromLTRB(20, 7, 20, 7),
              alignment: Alignment.center,
              child: Text(
                'Tavoitteesi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 15),

//käyttäjä voi muuttaa tavoitettaan, tavoite sijaitsee textFieldissä
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tavoitteesi tällä hetkellä: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 100,
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: _targetController.text.isEmpty
                          ? targetAmount.toString()
                          : _targetController.text,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      _saveTarget(int.tryParse(value) ?? targetAmount);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

//LinearPercentIndicator:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              LinearPercentIndicator(
                width: MediaQuery.of(context).size.width * 0.9,
                lineHeight: 20.0,
                percent: _items.length / targetAmount,
                backgroundColor: Colors.grey,
                progressColor: Colors.pink.shade400,
                center: Text(
                    '${((_items.length / targetAmount) * 100).toStringAsFixed(0)} %'),
              ),
            ]),
            SizedBox(height: 15),

//karsittu yhteensä -teksti
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tavaroitu karsittu: ${_items.length} kpl',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )
              ],
            ),

            SizedBox(height: 30),

//Kategorioittain-sisältö
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.fromLTRB(20, 7, 20, 7),
              alignment: Alignment.center,
              child: Text(
                'Kategorioittain',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10),

//taulukko: tässä käytetään dataMapin tietoja, jossa on siis tietokannasta haetut tiedot
            dataMap.isNotEmpty
                //ClipRRectilla leikataan kulmat, niin saadaan kulmat pyöreiksi
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: DataTable(
                        columnSpacing: 100,
                        dataRowMaxHeight: 35,
                        dataRowMinHeight: 35,
                        headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.grey[300]!),
                        headingRowHeight: 40,
                        //otsikkorivien labelit
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Kategoria',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'Määrä',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                        //taulukon varsineinen sisältö, joka tulee dataMapista eli tietokannasta
                        rows: dataMap.entries.map((entry) {
                          return DataRow(cells: [
                            //kategorioiden nimet:
                            DataCell(
                              Text(entry.key,
                              style: TextStyle(
                                      fontSize: 16)),
                            ),
                            //tavaroiden määrät
                            DataCell(
                              Align(
                                alignment: Alignment.center,
                                child: Text(entry.value.toInt().toString(),
                                style: TextStyle(
                                      fontSize: 16)),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ))
                //latauspallura, kun tietoja haetaan
                : Center(child: CircularProgressIndicator()),

            SizedBox(height: 20),

            //PieChart
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 20, 20, 20),
              child: Center(
                child: dataMap.isNotEmpty
                    ? PieChart(
                        dataMap: dataMap,
                        animationDuration: Duration(milliseconds: 800),
                        chartLegendSpacing: 50,
                        chartRadius: MediaQuery.of(context).size.width / 2.5,
                        colorList: colorList,
                        initialAngleInDegree: 0,
                        chartType: ChartType.ring,
                        ringStrokeWidth: 50,
                        legendOptions: LegendOptions(
                          showLegendsInRow: false,
                          legendPosition: LegendPosition.right,
                          showLegends: true,
                          legendShape: BoxShape.circle,
                          legendTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        chartValuesOptions: ChartValuesOptions(
                          chartValueStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          showChartValueBackground: true,
                          showChartValues: true,
                          showChartValuesInPercentage: true,
                          showChartValuesOutside: true,
                          decimalPlaces: 0,
                        ),
                        emptyColorGradient: [
                          Color(0xff6c5ce7),
                          Colors.blue,
                        ],
                      )
                    : SizedBox(
                        //tämä on laitettu SizedBoxiin,
                        //jotta latauspallura vie saman tilan kuin itse kaavio, niin sivu ei hypi
                        height: MediaQuery.of(context).size.width / 3.2,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
            SizedBox(height: 30),

//vuosittain/kuukausittain-sisältö
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.fromLTRB(20, 7, 20, 7),
              alignment: Alignment.center,
              child: Text(
                'Vuositasolla',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Valitse vuosi: ",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<int>(
                          value: selectedYear,
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedYear = newValue;
                              });
                              _loadMonthlyCounts(selectedYear);
                            }
                          },
                          items: List.generate(10, (index) {
                            final year = DateTime.now().year - index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString(), style: TextStyle(
                                      fontSize: 16)),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: DataTable(
                          columnSpacing: 50,
                          dataRowMaxHeight: 35,
                          dataRowMinHeight: 35,
                          headingRowColor: WidgetStateColor.resolveWith(
                              (states) => Colors.grey[300]!),
                          headingRowHeight: 40,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Kuukausi',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text(
                                  'Määrä',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                          rows: monthlyCounts.entries.map((entry) {
                            return DataRow(cells: [
                              DataCell(
                                Text(
                                  _monthName(entry.key),
                                  style: TextStyle(
                                      fontSize: 16),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(entry.value.toString(),
                                  style: TextStyle(
                                      fontSize: 16)),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
