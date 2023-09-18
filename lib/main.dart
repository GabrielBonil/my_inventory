import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tg/views/item_list.dart';
import 'package:tg/views/user_login.dart';
import 'package:firebase_auth/firebase_auth.dart';

const firebaseConfig = FirebaseOptions(
    apiKey: "AIzaSyBojilYeoEiydixh9BZDE6BOlVqY0IBrUA",
    authDomain: "my-inventory-tg.firebaseapp.com",
    projectId: "my-inventory-tg",
    storageBucket: "my-inventory-tg.appspot.com",
    messagingSenderId: "244281114732",
    appId: "1:244281114732:web:7e6d5be4db13f15787d849");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "MyInventory",
      home: LoginState(),
    );
  }
}

class LoginState extends StatelessWidget {
  const LoginState({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) => snapshot.hasError ||
              snapshot.connectionState == ConnectionState.active &&
                  !snapshot.hasData
          ? const UserLoginPage()
          : const ItemListPage(),
    );
  }
}