import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  String username = "Cargando...";
  String bio = "Cargando...";
  String avatarUrl = "";
  bool isLoading = true;
  bool showSettings = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/login");
        }
        return;
      }

      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId.toString())
          .single();

      if (mounted) {
        setState(() {
          username = response['username'] ?? "Sin nombre";
          bio = response['bio'] ?? "Sin biografía";
          avatarUrl = response['avatar_url'] ?? "";
          _usernameController.text = username;
          _bioController.text = bio;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
    }
  }

  Future<void> _editProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('users')
          .update({
            'username': _usernameController.text,
            'bio': _bioController.text,
          })
          .eq('id', userId.toString());

      setState(() {
        username = _usernameController.text;
        bio = _bioController.text;
        showSettings = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al cerrar sesión: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _getPostsStream() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return supabase
        .from('post')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId.toString())
        .order('created_at', ascending: false);
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final postId = post['id'].toString();
      
      await supabase
          .from('post')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> post) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar post'),
          content: const Text('¿Estás seguro de que quieres eliminar este post?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(post);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostImage(String mediaUrl) {
    try {
      if (mediaUrl.startsWith('data:image')) {
        final base64Str = mediaUrl.split(',')[1];
        return Image.memory(
          base64.decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error),
        );
      } else {
        return Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error),
        );
      }
    } catch (e) {
      return const Icon(Icons.error);
    }
  }

  Widget _buildPostList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay posts para mostrar'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatarUrl.isNotEmpty
                          ? _getAvatarImage()
                          : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(username),
                    subtitle: Text(
                      timeago.format(
                        DateTime.parse(post['created_at']),
                        locale: 'es_ES',
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(post),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(post['content']),
                  ),
                  if (post['media_url'] != null && post['media_url'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildPostImage(post['media_url']),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ImageProvider _getAvatarImage() {
    if (avatarUrl.startsWith('data:image')) {
      final base64Str = avatarUrl.split(',')[1];
      return MemoryImage(base64.decode(base64Str));
    }
    return NetworkImage(avatarUrl);
  }

  Future<void> _pickImage() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final newAvatarUrl = 'data:image/png;base64,$base64String';

      await supabase
          .from('users')
          .update({'avatar_url': newAvatarUrl})
          .eq('id', userId.toString());

      setState(() {
        avatarUrl = newAvatarUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                showSettings = !showSettings;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: showSettings ? _pickImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? _getAvatarImage()
                        : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  if (showSettings)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (showSettings) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Biografía',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _editProfile,
                      child: const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
            const Divider(height: 32),
            _buildPostList(),
          ],
        ),
      ),
    );
  }
}