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

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }
Future<void> fetchPosts() async {
  try {
    final List<Map<String, dynamic>> response = await supabase
        .from('post')
        .select('id, created_at, content, media_url, user_id');

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
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
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
