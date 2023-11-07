import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:encryptiontestapplication/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encryptiontestapplication/CreditCardDetails.dart';

Future main() async {
  /*var transitAlgorithm = Ecdsa.p256(Sha256());
  var keypair = await transitAlgorithm.newKeyPair();
  var pubkey = await keypair.extractPublicKey();
  var prikey = await keypair.extract();*/
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
  static final strongPassword = "keyofkeys";
  static final salt = Uint8List.fromList([0, 2, 4, 6, 7, 5, 3, 1]);
  static final passwordToKey = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static late SecretKey masterkey;

  static Future<void> init() async {
    masterkey = await passwordToKey.deriveKeyFromPassword(password: strongPassword, nonce: salt);
    db = await openDatabase('EncryptedData.db', version: 1, onCreate: _onCreate);
    var stream = FirebaseFirestore.instance
        .collection('users')
        .doc("LnaCNrez4NZJXfIgcGkcGuyHjUz1")
        .collection('requests')
        .snapshots();
    stream.listen((event) => DatabaseManager.receive(event), onError: (error) => print("error"));
    /*
    await db.execute("INSERT INTO CardData VALUES (123456789, '11/11/2026', 'Dillon Horton', 123)");*/
    //print(db.path);
  }

  static Future receive(QuerySnapshot<Map<String, dynamic>> data) async {
    for (DocumentSnapshot card in data.docs) {
      try {
        var submissionID = card.id;
        var cardNumber = card.get('cardNumber').toString();
        var expiryDate = card.get('expiryDate').toString();
        var cardHolderName = card.get('cardHolderName').toString();
        var cvvCode = card.get('cvvCode').toString();
        List<Map<String, dynamic>> exists = await db.query('CardData',
            where: 'submissionID = ?', // Use a parameterized query
            whereArgs: [submissionID] // Pass the parameter as a list
            );
        if (exists.isEmpty) {
          var key1 = await getKey(1);
          var key2 = await getKey(2);
          List<int> bytes = utf8.encode(cardNumber);
          SecretBox numBox = await algorithm.encrypt(bytes, secretKey: key1);
          SecretBox expiryBox = await algorithm.encrypt(utf8.encode(expiryDate), secretKey: key1);
          SecretBox nameBox = await algorithm.encrypt(utf8.encode(cardHolderName), secretKey: key2);
          SecretBox cvvBox = await algorithm.encrypt(utf8.encode(cvvCode), secretKey: key2);
          CreditCardDetails encrypted = CreditCardDetails(numBox.concatenation(),
              expiryBox.concatenation(), nameBox.concatenation(), cvvBox.concatenation());
          //print(bytes);
          //print(numBox);
          //var dataAndNonce = numBox.concatenation();
          //print(dataAndNonce);
          //SecretBox get = SecretBox.fromConcatenation(dataAndNonce, nonceLength: 16, macLength: 0);
          //print(get);
          //List<int> newBytes = await algorithm.decrypt(get, secretKey: key);
          //print(newBytes);
          //add to database
          //print(card.get('cardHolderName'));
          await db.insert('CardData', encrypted.toJsonDB(submissionID));
          key1.destroy();
          key2.destroy();
          getCard(submissionID);
        }
      } on Exception catch (e) {
        print("$e");
      }
    }
  }

  static Future getCard(String id) async {
    var key1 = await getKey(1);
    var key2 = await getKey(2);
    var encrypted = await db.query('CardData', where: 'submissionID = ?', whereArgs: [id]);
    var cardNumber = encrypted[0]['cardNumber'].toString();
    cardNumber = cardNumber.substring(1, cardNumber.length - 1);
    cardNumber = utf8.decode(await algorithm.decrypt(
        SecretBox.fromConcatenation(cardNumber.split(',').map(int.parse).toList(),
            nonceLength: 16, macLength: 0),
        secretKey: key1));
    var expiryDate = encrypted[0]['expiryDate'].toString();
    expiryDate = expiryDate.substring(1, expiryDate.length - 1);
    expiryDate = utf8.decode(await algorithm.decrypt(
        SecretBox.fromConcatenation(expiryDate.split(',').map(int.parse).toList(),
            nonceLength: 16, macLength: 0),
        secretKey: key1));
    var cardHolderName = encrypted[0]['cardHolderName'].toString();
    cardHolderName = cardHolderName.substring(1, cardHolderName.length - 1);
    cardHolderName = utf8.decode(await algorithm.decrypt(
        SecretBox.fromConcatenation(cardHolderName.split(',').map(int.parse).toList(),
            nonceLength: 16, macLength: 0),
        secretKey: key2));
    var cvvCode = encrypted[0]['cvvCode'].toString();
    cvvCode = cvvCode.substring(1, cvvCode.length - 1);
    cvvCode = utf8.decode(await algorithm.decrypt(
        SecretBox.fromConcatenation(cvvCode.split(',').map(int.parse).toList(),
            nonceLength: 16, macLength: 0),
        secretKey: key2));
    print(
        "cardNumber: $cardNumber, expiryDate: $expiryDate, cardHolderName: $cardHolderName, cvvCode: $cvvCode");
  }

  static Future<SecretKey> getKey(int id) async {
    var data = await db.query("EncryptionKeys",
        columns: ['KeyValue'], where: 'KeyID = ?', whereArgs: [id]);
    var text = data[0]['KeyValue'].toString();
    text = text.substring(1, text.length - 1);
    //print(text);
    List<int> keyData = text.split(',').map(int.parse).toList();
    var decryptedKey = await algorithm.decrypt(
        SecretBox.fromConcatenation(keyData, nonceLength: 0, macLength: 0),
        secretKey: masterkey);
    return SecretKeyData(decryptedKey);
  }

  static Future updateKeys() async {
    SecretKey key1 = await algorithm.newSecretKey();
    var keybytes1 = await algorithm.encrypt(await key1.extractBytes(), secretKey: masterkey);
    SecretKey key2 = await algorithm.newSecretKey();
    var keybytes2 = await algorithm.encrypt(await key2.extractBytes(), secretKey: masterkey);
    await db.update('EncryptionKeys', {'KeyValue': keybytes1.concatenation()}, where: 'KeyID = 1');
    await db.update('EncryptionKeys', {'KeyValue': keybytes2.concatenation()}, where: 'KeyID = 2');
    //unencrypt and rencrypt all the data
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
        "submissionID" TEXT,
	      "cardNumber"	BLOB,
	      "expiryDate"	BLOB,
	      "cardHolderName"	BLOB,
	      "cvvCode"	BLOB,
	      PRIMARY KEY("submissionID")
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
    var keybytes1 = await algorithm.encrypt(await key1.extractBytes(), secretKey: masterkey);
    SecretKey key2 = await algorithm.newSecretKey();
    var keybytes2 = await algorithm.encrypt(await key2.extractBytes(), secretKey: masterkey);

    //print(keybytes1); debug
    await db.insert('EncryptionKeys', {'KeyValue': keybytes1.concatenation()});
    await db.insert('EncryptionKeys', {'KeyValue': keybytes2.concatenation()});

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
      home: MyHomePage(title: "Standardized Encrypt"),
    );
  }
}
