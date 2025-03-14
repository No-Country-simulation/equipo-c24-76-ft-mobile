import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

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
          ],
        ),
      ),
    );
  }
} 