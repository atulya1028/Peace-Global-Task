import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:task_peace_global_llc_atulya/screens/home_screen.dart';

 Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();
   await   Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
