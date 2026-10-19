import 'package:donation_app/screens/donor_new/donor_main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:donation_app/providers/donation_provider.dart';
import 'package:donation_app/providers/user_provider.dart';
import 'package:donation_app/providers/drive_provider.dart';
import 'package:donation_app/providers/admin_provider.dart';
import 'package:donation_app/screens/auth/login_page.dart';
import 'package:donation_app/screens/auth/signup_page.dart';
import 'package:donation_app/screens/org/org_main.dart';
import 'package:donation_app/screens/admin/admin_home.dart';
import 'package:donation_app/providers/donor_provider.dart';
import 'package:donation_app/providers/donate_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ((context) => DonationProvider())),
        ChangeNotifierProvider(create: ((context) => DriveProvider())),
        ChangeNotifierProvider(create: ((context) => MyAuthProvider())),
        ChangeNotifierProvider(create: ((context) => AdminProvider())),
        ChangeNotifierProvider(create: ((context) => DonorProvider())),
        ChangeNotifierProvider(create: ((context) => DonateDataProvider())),
      ],
      child: const MyApp(),
    ),
    // MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // https://stackoverflow.com/a/62989332
  final ColorScheme colorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color.fromRGBO(245, 71, 65, 1),
    onPrimary: Color.fromRGBO(255, 255, 255, 1),
    secondary: Color.fromRGBO(255, 255, 255, 1),
    onSecondary: Color.fromRGBO(21, 26, 38, 1),
    error: Colors.redAccent,
    onError: Colors.redAccent,
    background: Color.fromRGBO(250, 250, 250, 1), // Eggshell white
    onBackground: Color.fromRGBO(21, 26, 38, 1),
    surface: Color.fromRGBO(255, 255, 255, 1),
    onSurface: Color.fromRGBO(21, 26, 38, 1),
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation Application',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor:
              const Color(0xFFF54741).withValues(alpha: 0.12),
        ),
      ),
      // initialRoute: '/org',
      routes: {
        // set the routes of the pages
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/org': (context) => const OrgMainPage(),
        '/admin': (context) => const AdminView(),
        // '/donor': (context) => const DonorView(),
        '/donor': (context) => const DonorMainPage(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // print('>>> Snapshot: $snapshot');
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          } else {
            return FutureBuilder<String>(
              future: MyAuthProvider().getUserRole(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // return CircularProgressIndicator();  # ugly in ui
                  return const Scaffold();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  String role = snapshot.data!;
                  switch (role) {
                    case 'admin':
                      return const AdminView();
                    case 'org':
                      return const OrgMainPage();
                    case 'donor':
                      // return DonorView();
                      return const DonorMainPage();
                    default:
                      return const LoginPage();
                  }
                }
              },
            );
          }
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
