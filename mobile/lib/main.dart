import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/search_screen.dart';
import 'screens/post_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pxplkoteuxwgnixmppum.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4cGxrb3RldXh3Z25peG1wcHVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMjMxNjcsImV4cCI6MjA1NTU5OTE2N30.ADpeeAE7XsK1ZbmIhFZggEzZIJE7aIZPQ-_lB1ln6_U',
  );

  await requestPermissions();

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
    Permission.location,
  ].request();
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Red Social de Viajes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthCheck(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/search': (context) => const SearchScreen(),
        '/post': (context) => const PostScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/register': (context) => const RegisterScreen(),
        '/user-profile': (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as String;
          return UserProfileScreen(userId: userId);
        },
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const MainNavigationScreen(); // Usuario autenticado, va a inicio
    } else {
      return const OnboardingScreen(); // Usuario no autenticado, va a onboarding
    }
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const PostScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/post');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      extendBody: true, // Importante: permite que el cuerpo se extienda debajo de la navbar
      bottomNavigationBar: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Importante: evita que se recorte el botón
        children: [
          Container(
            margin: const EdgeInsets.only(top: 15), // Margen para el botón
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 248, 201, 200).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BottomNavigationBar(
                backgroundColor: const Color.fromRGBO(217, 30, 133, 1),
                selectedItemColor: const Color.fromRGBO(70, 94, 166, 1),
                unselectedItemColor: const Color.fromRGBO(54, 36, 166, 1).withOpacity(0.9),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                elevation: 0,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
                  BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
                  BottomNavigationBarItem(icon: Icon(Icons.add_circle, color: Colors.transparent), label: "Publicar"), // Botón invisible
                  BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notificaciones"),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5, // Ajusta este valor para que sobresalga más
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/post'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(18, 38, 17, 1).withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(217, 30, 133, 1),
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: Color.fromRGBO(54, 36, 166, 1),
                    size: 35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}