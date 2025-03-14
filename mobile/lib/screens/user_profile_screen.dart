import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  bool isFollowing = false;
  Map<String, dynamic>? userData;
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkIfFollowing();
    _loadFollowCounts();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', widget.userId)
          .single();
      
      setState(() {
        userData = response;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar el perfil')),
        );
      }
    }
  }

  Future<void> _checkIfFollowing() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final response = await supabase
        .from('followers')
        .select()
        .eq('follower_id', currentUserId)
        .eq('following_id', widget.userId)
        .maybeSingle();

    if (mounted) {
      setState(() {
        isFollowing = response != null;
      });
    }
  }

  Future<void> _loadFollowCounts() async {
    try {
      // Contar seguidores
      final followersResponse = await supabase
          .from('followers')
          .select()
          .eq('following_id', widget.userId);

      // Contar seguidos
      final followingResponse = await supabase
          .from('followers')
          .select()
          .eq('follower_id', widget.userId);

      if (mounted) {
        setState(() {
          followersCount = followersResponse.length;
          followingCount = followingResponse.length;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar conteos: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    setState(() => isFollowing = !isFollowing);

    try {
      if (isFollowing) {
        // Seguir usuario
        await supabase.from('followers').insert({
          'follower_id': currentUserId,
          'following_id': widget.userId,
        });

        // Crear notificación
        await supabase.from('notifications').insert({
          'user_id': widget.userId,
          'sender_id': currentUserId,
          'type': 'follow',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'read': false,
        });
      } else {
        // Dejar de seguir
        await supabase
            .from('followers')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.userId);
      }

      _loadFollowCounts();
    } catch (e) {
      setState(() => isFollowing = !isFollowing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar seguimiento')),
        );
      }
    }
  }

  // Agregar este método para cargar los posts
  Stream<List<Map<String, dynamic>>> _getPostsStream() {
    return supabase
        .from('post')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);
  }

  // Método para borrar un post
  Future<void> _deletePost(String postId) async {
    try {
      await supabase
          .from('post')
          .delete()
          .eq('id', postId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para mostrar el diálogo de confirmación
  Future<void> _showDeleteConfirmation(String postId) async {
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
                _deletePost(postId);
              },
            ),
          ],
        );
      },
    );
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
          return const Center(child: Text('No hay posts para mostrar'));
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
                    leading: _buildAvatar(userData?['avatar_url']),
                    title: Text(userData?['username'] ?? 'Usuario'),
                    subtitle: Text(
                      timeago.format(
                        DateTime.parse(post['created_at']),
                        locale: 'es_ES',
                      ),
                    ),
                    trailing: post['user_id'] == supabase.auth.currentUser?.id
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteConfirmation(post['id']),
                          )
                        : null,
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

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      );
    }

    try {
      if (avatarUrl.startsWith('data:image')) {
        final base64Str = avatarUrl.split(',')[1];
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(base64.decode(base64Str)),
          onBackgroundImageError: (_, __) {},
        );
      } else {
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError: (_, __) {},
        );
      }
    } catch (e) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey,
        child: Icon(Icons.error, size: 50, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(userData?['username'] ?? 'Perfil de Usuario'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAvatar(userData?['avatar_url']),
            const SizedBox(height: 16),
            Text(
              userData?['username'] ?? 'Sin nombre',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                userData?['bio'] ?? 'Sin biografía',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      followersCount.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Seguidores'),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  children: [
                    Text(
                      followingCount.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Siguiendo'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.userId != supabase.auth.currentUser?.id)
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  isFollowing ? 'Siguiendo' : 'Seguir',
                  style: TextStyle(
                    color: isFollowing ? Colors.black : Colors.white,
                  ),
                ),
              ),
            const Divider(height: 32),
            _buildPostList(),
          ],
        ),
      ),
    );
  }
} 