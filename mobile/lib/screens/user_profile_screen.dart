import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import '../theme/app_theme.dart';

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
  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];

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
      
      if (mounted) {
        setState(() {
          userData = response;
          isLoading = false;
        });
      }
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
      // Cargar seguidores con sus datos
      final followersData = await supabase
          .from('followers')
          .select('users!followers_follower_id_fkey(id, username, avatar_url)')
          .eq('following_id', widget.userId);

      // Cargar seguidos con sus datos
      final followingData = await supabase
          .from('followers')
          .select('users!followers_following_id_fkey(id, username, avatar_url)')
          .eq('follower_id', widget.userId);

      if (mounted) {
        setState(() {
          followers = List<Map<String, dynamic>>.from(
            followersData.map((f) => f['users'] as Map<String, dynamic>),
          );
          following = List<Map<String, dynamic>>.from(
            followingData.map((f) => f['users'] as Map<String, dynamic>),
          );
          followersCount = followers.length;
          followingCount = following.length;
        });
      }
    } catch (e) {
      debugPrint('Error cargando seguidores: $e');
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

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: AppTheme.avatarBackground,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      );
    }

    try {
      if (avatarUrl.startsWith('data:image')) {
        final base64Str = avatarUrl.split(',')[1];
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(base64.decode(base64Str)),
          backgroundColor: AppTheme.avatarBackground,
        );
      }
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppTheme.avatarBackground,
      );
    } catch (e) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: AppTheme.avatarBackground,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      );
    }
  }

  void _showFollowersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seguidores',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: followers.length,
                itemBuilder: (context, index) {
                  final follower = followers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.avatarBackground,
                      backgroundImage: follower['avatar_url'] != null
                          ? NetworkImage(follower['avatar_url'])
                          : null,
                      child: follower['avatar_url'] == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      follower['username'] ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/user-profile',
                        arguments: follower['id'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowingDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Siguiendo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: following.length,
                itemBuilder: (context, index) {
                  final followedUser = following[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.avatarBackground,
                      backgroundImage: followedUser['avatar_url'] != null
                          ? NetworkImage(followedUser['avatar_url'])
                          : null,
                      child: followedUser['avatar_url'] == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      followedUser['username'] ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/user-profile',
                        arguments: followedUser['id'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage(String mediaUrl) {
    try {
      if (mediaUrl.startsWith('data:image')) {
        final base64Str = mediaUrl.split(',')[1];
        return Image.memory(
          base64.decode(base64Str),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error),
        );
      } else if (mediaUrl.startsWith('/9j/')) {
        return Image.memory(
          base64.decode(mediaUrl),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error),
        );
      } else {
        return Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error),
        );
      }
    } catch (e) {
      debugPrint('Error al cargar imagen: $e');
      return const Icon(Icons.error);
    }
  }

  Widget _buildPostList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('post')
          .stream(primaryKey: ['id'])
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar las publicaciones',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.post_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay publicaciones aún',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: _buildAvatar(userData?['avatar_url']),
                    title: Text(
                      userData?['username'] ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      timeago.format(
                        DateTime.parse(post['created_at']),
                        locale: 'es_ES',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      post['content'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (post['media_url'] != null && post['media_url'].isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.mainGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            userData?['username'] ?? 'Perfil',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildAvatar(userData?['avatar_url']),
                    const SizedBox(height: 16),
                    Text(
                      userData?['username'] ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (userData?['bio'] != null && userData?['bio'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          userData?['bio'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: _showFollowersDialog,
                            child: Column(
                              children: [
                                Text(
                                  followersCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Seguidores',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          GestureDetector(
                            onTap: _showFollowingDialog,
                            child: Column(
                              children: [
                                Text(
                                  followingCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Siguiendo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.userId != supabase.auth.currentUser?.id)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.white.withOpacity(0.2) : AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isFollowing ? 'Siguiendo' : 'Seguir',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.grid_on),
                                SizedBox(width: 8),
                                Text(
                                  'Publicaciones',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildPostList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
} 