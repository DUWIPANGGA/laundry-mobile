import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'screens/login_screen.dart';
import 'screens/register.dart';
import 'screens/dashboard.dart';
import 'screens/forgot.dart';
import 'screens/order.dart';
import 'screens/profile.dart';
import 'screens/confirmorder.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await initializeDateFormatting('id_ID',"");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laundry App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(username: "User"),
        '/profile': (context) => const ProfilePage(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/order': (context) => OrderScreen(username: "User"),
        '/confirmorder': (context) => const ConfirmOrderScreen(),
      },
    );
  }
}
