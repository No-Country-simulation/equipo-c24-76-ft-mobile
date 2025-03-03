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

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchUsers();
  }

  Future<void> _getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.id; // Guardamos el ID del usuario autenticado
      });
    }
  }

  Future<void> _fetchUsers([String query = '']) async {
    final response = await supabase
        .from('users')
        .select('*');
        

    setState(() {
      _users = response;
    });
  }

  Future<void> _followUser(String userId) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      return;
    }

    await supabase.from('followers').insert({
      'follower_id': currentUserId,
      'following_id': userId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ahora sigues a este usuario')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
          onChanged: _fetchUsers,
        ),
      ),
      body: _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['avatar_url'] ??
                        'https://via.placeholder.com/150'),
                  ),
                  title: Text(user['email'] ?? 'Usuario desconocido'),
                  subtitle: Text(user['bio'] ?? 'Sin descripción'),
                  trailing: ElevatedButton(
                    onPressed: () => _followUser(user['id']),
                    child: const Text('Seguir'),
                  ),
                  onTap: () {
                    // Implementar navegación al perfil
                  },
                );
              },
            ),
    );
  }
}
