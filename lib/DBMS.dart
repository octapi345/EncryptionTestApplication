import 'package:cryptography/cryptography.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';


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
  Timer.periodic(Duration(minutes: 60), (Timer t) {
    DatabaseManager.updateKeys();
  });
  runApp(MyApp());
}

class DatabaseManager {

  static late Database db;
  static final algorithm = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);
  static Future<void> init() async{
    db = await openDatabase('EncryptedData.db', version: 1, onCreate: _onCreate);
    /*
    await db.execute("INSERT INTO CardData VALUES (123456789, '11/11/2026', 'Dillon Horton', 123)");*/
    print(db.path);

  }
 // static Future<SecretKey> getKey(int id) async{
  //  var data = await db.query("EncryptionKeys", columns: ['KeyValue'], where:'KeyID = $id');

 // }
  static Future updateKeys() async{
    SecretKey key1 = await algorithm.newSecretKey();
    var keybytes1 = await key1.extractBytes();
    SecretKey key2 = await algorithm.newSecretKey();
    var keybytes2 = await key2.extractBytes();
    await db.execute('''
    UPDATE EncryptionKeys
    SET KeyValue = '$keybytes1'
    WHERE KeyID = 1 
    ''');
    await db.execute('''
    UPDATE EncryptionKeys
    SET KeyValue = '$keybytes2'
    WHERE KeyID = 2 
    ''');

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
    SecretKey key1 = await algorithm.newSecretKey();
    var keybytes1 = await key1.extractBytes();
    SecretKey key2 = await algorithm.newSecretKey();
    var keybytes2 = await key2.extractBytes();
    print(keybytes1);
    await db.execute('''
    INSERT INTO EncryptionKeys (KeyValue)
    Values ('$keybytes1')
    ''');
    await db.execute('''
    INSERT INTO EncryptionKeys (KeyValue)
    Values ('$keybytes2')
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

