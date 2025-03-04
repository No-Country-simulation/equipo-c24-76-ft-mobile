import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuarios...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _fetchUsers();
                    },
                  )
                : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onChanged: (value) {
              setState(() {});
              _fetchUsers(value);
            },
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron usuarios',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                       leading: CircleAvatar(
  radius: 30,
  backgroundImage: user['avatar_url'] != null && user['avatar_url'].isNotEmpty
      ? NetworkImage(user['avatar_url'])
      : null,
  child: user['avatar_url'] == null || user['avatar_url'].isEmpty
      ? Icon(Icons.person, size: 30, color: Colors.grey)
      : null,
),

                        title: Text(
                          user['username'] ?? user['email'] ?? 'Usuario desconocido',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              user['bio'] ?? 'Sin descripción',
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _followUser(user['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
                            foregroundColor: isFollowing ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context, 
                            '/profile',
                            arguments: user['id'],
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
