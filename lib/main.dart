import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:encryptiontestapplication/CreditCardDetails.dart';
import 'package:encryptiontestapplication/CreditCard.dart';
import 'package:encryptiontestapplication/DBMS.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  runApp(MyApp());
}

CreditCardDetails card1 =
    CreditCardDetails('0000-0000-0000-0000', '00-00-0000', 'Reginald Appiah', '123');

final userReference = FirebaseFirestore.instance.collection('users');

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final card1JSON = jsonEncode(card1);
    print(card1JSON);

    final cardMap = jsonDecode(card1JSON) as Map<String, dynamic>;
    final card = CreditCardDetails.fromJson(cardMap);

    print(card.cardNumber);

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(
          title:
              'Standardized Encryption Implementation For Secure Storage of Payment Information'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _incrementCounter() async {
    UserCredential anonUser = await FirebaseAuth.instance.signInAnonymously();
    DocumentReference userDocument = userReference.doc(FirebaseAuth.instance.currentUser!.uid);
    userDocument.collection('requests').add(card1.toJson());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Expanded(child: MySample())],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
