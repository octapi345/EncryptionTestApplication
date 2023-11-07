import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encryptiontestapplication/CreditCardDetails.dart';

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
    var stream = FirebaseFirestore.instance.collection('users').doc("LnaCNrez4NZJXfIgcGkcGuyHjUz1").collection('requests').snapshots();
    stream.listen((event) => DatabaseManager.receive(event), onError: (error) => print("error"));
    /*
    await db.execute("INSERT INTO CardData VALUES (123456789, '11/11/2026', 'Dillon Horton', 123)");*/
    print(db.path);

  }

  static Future receive(QuerySnapshot<Map<String, dynamic>> data) async{
    for (DocumentSnapshot card in data.docs){
      try {
        CreditCardDetails details = CreditCardDetails(
            card.get('cardNumber'), card.get('expiryDate'),
            card.get('cardHolderName'), card.get('cvvCode'));
        addCard(details);
      } on Exception catch(e){
        print("$e");
      }
      var key = await getKey(1);
      List<int> bytes = await key.extractBytes();
      SecretBox box = await algorithm.encrypt(bytes, secretKey: key);
      print (box);
      print(box.concatenation());
      //SecretBox.fromConcatenation(bo, nonceLength: 16, macLength: 0)
      //add to database
      print(card.get('cardHolderName'));
    }
  }

  static Future addCard(CreditCardDetails cardDetails) async{
    List<Map<String, dynamic>> exists = await db.query('CardData',
        where: 'cardNumber = ?', // Use a parameterized query
        whereArgs: [cardDetails.cardNumber] // Pass the parameter as a list
    );
    if (exists.isEmpty) {
      await db.insert('CardData', cardDetails.toJson());
    }

  }

  static Future<SecretKey> getKey(int id) async{
    var data = await db.query("EncryptionKeys", columns: ['KeyValue'], where:'KeyID = ?', whereArgs: [id]);
    var text = data[0]['KeyValue'].toString();
    text = text.substring(1, text.length - 1);
    print(text);
    List<int> keyData = text.split(',').map(int.parse).toList();
    return SecretKeyData(keyData);
  }

  static Future updateKeys() async{
    SecretKey key1 = await algorithm.newSecretKey();
    var keybytes1 = await key1.extractBytes();
    SecretKey key2 = await algorithm.newSecretKey();
    var keybytes2 = await key2.extractBytes();
    await db.update('EncryptionKeys', {'KeyValue': keybytes1}, where: 'KeyID = ?', whereArgs: [1]);
    await db.update('EncryptionKeys', {'KeyValue': keybytes2}, where: 'KeyID = ?', whereArgs: [2]);

    //old code
    /*await db.execute('''
    UPDATE EncryptionKeys
    SET KeyValue = '$keybytes1'
    WHERE KeyID = 1 
    ''');
    await db.execute('''
    UPDATE EncryptionKeys
    SET KeyValue = '$keybytes2'
    WHERE KeyID = 2 
    ''');*/

  }
  static Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE "CardData" (
	      "cardNumber"	TEXT,
	      "expiryDate"	TEXT,
	      "cardHolderName"	TEXT,
	      "cvvCode"	INTEGER,
	      PRIMARY KEY("cardNumber")
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
    var keybytes1 = Uint8List.fromList( await key1.extractBytes());
    SecretKey key2 = await algorithm.newSecretKey();
    var keybytes2 = Uint8List.fromList( await key2.extractBytes()) ;
    print(keybytes1);
    await db.insert('EncryptionKeys', {'KeyValue': keybytes1});
    await db.insert('EncryptionKeys', {'KeyValue': keybytes2});

    //old code
    /*await db.execute('''
    INSERT INTO EncryptionKeys (KeyValue)
    Values ('$keybytes1')
    ''');
    await db.execute('''
    INSERT INTO EncryptionKeys (KeyValue)
    Values ('$keybytes2')
    ''');*/
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

