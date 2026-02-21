import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final db = FirebaseFirestore.instance;
  final docs = await db.collection('diaries').get();
  for (var doc in docs.docs) {
    print('Diary: ${doc.id} - ${doc.data()['dateKey']} - ${doc.data()['userId']}');
  }
}
