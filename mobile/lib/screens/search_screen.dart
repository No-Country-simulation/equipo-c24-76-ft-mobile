import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // Esto es necesario para usar base64Decode

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> _users = [];
  String? currentUserId; // Aquí guardamos el ID del usuario autenticado
  bool _isLoading = false;
  Map<String, bool> _followingStatus = {};

  // Definimos los colores igual que en PostScreen
  static const Color darkBlue = Color.fromRGBO(18, 38, 17, 1); // negrito
  static const Color teal = Color.fromRGBO(70, 94, 166, 1); // celestito
  static const Color olive = Color.fromRGBO(54, 36, 166, 1); // azul
  static const Color limeYellow = Color.fromRGBO(191, 10, 43, 1); // rojo
  static const Color beige = Color.fromRGBO(217, 30, 133, 1); // rosa

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchUsers();
    _loadFollowingStatus();
  }

  Future<void> _getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.id;
      });
      _loadFollowingStatus(); // Ejecutar solo después de obtener el usuario
    }
  }

  Future<void> _loadFollowingStatus() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final following = await supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      if (following != null && following is List) {
        setState(() {
          for (var follow in following) {
            _followingStatus[follow['following_id']] = true;
          }
        });
      }
    } catch (error) {
      print('Error cargando seguidores: $error');
    }
  }

  Future<void> _fetchUsers([String query = '']) async {
    setState(() => _isLoading = true);

    try {
      final userId = currentUserId;
      final response = await supabase
          .from('users')
          .select('*')
          .neq('id', userId as String) // Casting explícito
          .ilike('email', '%$query%')
          .or('username.ilike.%$query%,bio.ilike.%$query%')
          .order('username', ascending: true);

      setState(() {
        _users = response;
        _isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar usuarios: $error')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _followUser(String userId) async {
    final currentId = currentUserId;
    if (currentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    setState(() => _followingStatus[userId] = !(_followingStatus[userId] ?? false));

    try {
      if (_followingStatus[userId] ?? false) {
        // Seguir usuario
        await supabase.from('followers').insert({
          'follower_id': currentId,
          'following_id': userId,
        });

        // Agregar la notificación
        await supabase.from('notifications').insert({
          'user_id': userId,  // Cambié receiver_id por user_id
          'sender_id': currentId,
          'type': 'follow',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'read': false,  // Agregué un valor para la columna read
        });

        _showSnackBar('Ahora sigues a este usuario');
      } else {
        // Dejar de seguir
        await supabase
            .from('followers')
            .delete()
            .eq('follower_id', currentId)
            .eq('following_id', userId);

        _showSnackBar('Dejaste de seguir a este usuario');
      }
    } catch (error) {
      setState(() => _followingStatus[userId] = !(_followingStatus[userId] ?? false));
      _showSnackBar('Error al actualizar seguimiento');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Aplicamos el gradiente a toda la pantalla como contenedor principal
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            darkBlue,
            teal,
          ],
        ),
      ),
      child: Scaffold(
        // Hacemos transparente el Scaffold para que se vea el gradiente
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                hintStyle: TextStyle(color: darkBlue.withOpacity(0.7)),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: beige),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: darkBlue),
                      onPressed: () {
                        _searchController.clear();
                        _fetchUsers();
                      },
                    )
                  : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              style: const TextStyle(color: darkBlue),
              onChanged: (value) {
                setState(() {});
                _fetchUsers(value);
              },
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: limeYellow))
            : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 64, color: Colors.white70),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron usuarios',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isFollowing = _followingStatus[user['id']] ?? false;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: teal.withOpacity(0.2),
                            backgroundImage: user['avatar_url'] != null && user['avatar_url'].isNotEmpty
                                ? user['avatar_url'].startsWith('data:image')
                                    ? MemoryImage(base64Decode(user['avatar_url'].split(',').last)) // Decodificamos si es base64
                                    : NetworkImage(user['avatar_url']) as ImageProvider // Si es una URL normal, usamos NetworkImage
                                : null,
                            child: user['avatar_url'] == null || user['avatar_url'].isEmpty
                                ? const Icon(Icons.person, size: 30, color: teal)
                                : null,
                          ),
                          title: Text(
                            user['username'] ?? user['email'] ?? 'Usuario desconocido',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: darkBlue,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                user['bio'] ?? 'Sin descripción',
                                style: TextStyle(color: darkBlue.withOpacity(0.7)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _followUser(user['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? limeYellow : beige,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: Text(
                              isFollowing ? 'Siguiendo' : 'Seguir',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context, 
                              '/user-profile',
                              arguments: user['id'],
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}