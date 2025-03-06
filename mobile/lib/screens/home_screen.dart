/*import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  String errorMessage = '';

  int limit = 10; //Cantidad de posts a cargar por página
  int offset = 0; //Para paginación
  bool isLoadingMore = false; //Para evitar múltiples cargas


  final ScrollController _scrollController=ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPosts();

    //Agregar listener para detectar cuando llegue al final
    _scrollController.addListener((){
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100){
        fetchMorePosts();

      }
    });
  }

Future<void> fetchPosts() async{
  try {
    final List<Map<String, dynamic>> response = await supabase
        .from('post')
        .select('id, created_at, content, media_url, user_id');
        .order('created_at', ascending: false);
        .limit (limit)
        .offset(offset);


    setState(() {
      posts = response;
      isLoading = false;
    });
  } catch (error) {
     print('Error al obtener posts: $error'); // Muestra el error en la consola
    setState(() {
      errorMessage = 'Error al obtener publicaciones: $error';
      isLoading = false;
    });
  }
}

Future<void>.fetchMorePosts() async {
  if (is isLoadingMore) return;//Evitar múltiples llamadas

  setState(() => isLoadingMore = true );
  
  try{
    final List<Map<String, dynamic>> response = await supabase
      .from('post')
      .select('id, created_at' , ascending: false)
      .limit(limit)
      .offset(offset + limit); //Siguiente página

    setState((){
      if (response.isNotEmpty){
        posts.addAll(response);
        offset += limit;//Actualizar el offset
      }
      isLoadingMore = false;
    });
  } catch (error){
    print('Error al cargar más posts: $error');
    setState(() => isLoadingMore =false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Social'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : posts.isEmpty
                  ? const Center(child: Text('No hay publicaciones aún.'))
                  : ListView.builder(
                      controller: _scrollController,//Vincular el scrollController
                      itemCount: posts.length + (isLoadingMore ? 1 : 0),//agregar un loader al final
                      itemBuilder: (context, index) {
                        if (index == posts.length){
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final post = posts[index];

                        // Formatear la fecha
                        String formattedDate = 'Fecha desconocida';
                        if (post['created_at'] != null) {
                          DateTime dateTime = DateTime.parse(post['created_at']);
                          formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: post['profilePic'] != null
                                      ? NetworkImage(post['profilePic'])
                                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                ),
                                title: Text(
                                  post['username'] ?? 'Usuario desconocido',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(formattedDate),
                              ),
                              if (post['postImage'] != null)
                                Image.network(
                                  post['postImage'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 250,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Text('No se pudo cargar la imagen'));
                                  },
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  post['content'] ?? 'Sin contenido',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
*/
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
  await [
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
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Publicar"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notificaciones"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          
        ],
      ),
    );
  }
}
