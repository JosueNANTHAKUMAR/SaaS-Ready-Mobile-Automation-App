import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gamestore/pages/home/widgets/profile.dart';
import 'package:gamestore/pages/login/login_page.dart';
import 'package:gamestore/pages/home/home.dart';
import 'package:gamestore/pages/register/register.dart';
import 'package:gamestore/pages/area/area.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Centralize',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/register': (context) => const RegisterPage(),
        '/area': (context) => const CreateAreaPage()
      },
    );
  }
}
