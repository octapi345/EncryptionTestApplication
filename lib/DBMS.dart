import 'package:cryptography/cryptography.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // Replace with actual values
    options: FirebaseOptions(
      apiKey: "AIzaSyCxH3S_oA1Cn7ANe5FIHayG0Qad_utNM2o",
      appId: "1:893923649022:android:5b086703888e79f47eccaf",
      messagingSenderId: "893923649022",
      projectId: "standardized-payment-encrypt",
    ),
  );
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseManager.init();
  runApp(MyApp());
}

class DatabaseManager {

  static Future<void> init() async{
    var db = await openDatabase('EncryptedData.db', version: 1, onCreate: _onCreate);
    /*
    await db.execute("INSERT INTO CardData VALUES (123456789, '11/11/2026', 'Dillon Horton', 123)");*/
    print(db.path);
  }
  static Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE "CardData" (
	      "CardNum"	INTEGER,
	      "ExpiryDate"	TEXT,
	      "CardHolderName"	TEXT,
	      "CVV"	INTEGER,
	      PRIMARY KEY("CardNum")
      )
    ''');
    await db.execute('''
      CREATE TABLE "EncryptionKeys" (
	      "KeyID"	INTEGER,
	      "KeyValue"	BLOB,
	      PRIMARY KEY("KeyID" AUTOINCREMENT)
      )
    ''');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(),
    );
  }
}

