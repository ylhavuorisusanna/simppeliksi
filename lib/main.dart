import 'package:flutter/material.dart';
import 'package:karsinta/pages/home.dart';

void main() {
  
  runApp(MyApp());
} // kertoo flutterille että pyöritä ohjelmaa MyApp

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //tämä on se MyApp!
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      theme: ThemeData(
          colorSchemeSeed: const Color.fromARGB(255, 255, 78, 202), useMaterial3: true),
      title: 'Simppeliksi!',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}