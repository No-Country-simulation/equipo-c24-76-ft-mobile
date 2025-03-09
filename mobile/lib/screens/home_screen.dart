import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? currentUserId;
  Map<String, bool> _likedPosts = {};
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadPosts();
  }

  Future<void> _getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.id;
      });
      _loadLikedPosts();
    }
  }

  Future<void> _loadLikedPosts() async {
    final userId = currentUserId;
    if (userId == null) return;

    final likes = await supabase
        .from('likes')
        .select('post_id')
        .eq('user_id', userId);

    setState(() {
     for (var like in likes) {
    _likedPosts[like['post_id'].toString()] = true;
      }
    });
  }

  Future<void> _loadPosts() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final following = await _getFollowingQuery();
      
      // Primero, obtener posts de usuarios que seguimos
      final followingPosts = following.isNotEmpty
          ? await supabase
              .from('post')
              .select('''
                *,
                users:user_id (username, avatar_url),
                likes:likes (count),
                comments:comments (count)
              ''')
              .or('user_id.in.(${following}),user_id.eq.${userId}')
              .order('created_at', ascending: false)
          : [];

      // Obtener posts sugeridos (de usuarios que no seguimos)
      final suggestedPosts = await supabase
          .from('post')
          .select('''
            *,
            users:user_id (username, avatar_url),
            likes:likes (count),
            comments:comments (count)
          ''')
          .not('user_id', 'in', '($following,$userId)')
          .order('created_at', ascending: false)
          .limit(10); // Limitamos a 10 posts sugeridos

      // Combinar los posts y marcarlos como sugeridos o no
      final allPosts = [
        ...List<Map<String, dynamic>>.from(followingPosts).map((post) => {
              ...post,
              'is_suggested': false,
            }),
        ...List<Map<String, dynamic>>.from(suggestedPosts).map((post) => {
              ...post,
              'is_suggested': true,
            }),
      ];

      // Ordenar todos los posts por fecha
      allPosts.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));

      setState(() {
        _posts = allPosts;
        _isLoading = false;
      });
    } catch (error) {
      print('Error cargando posts: $error');
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getFollowingQuery() async {
    final userId = currentUserId;
    if (userId == null) return '';
    
    final following = await supabase
        .from('followers')
        .select('following_id')
        .eq('follower_id', userId);
    
    if (following.isEmpty) return '';
    return following.map((f) => f['following_id']).join(',');
  }
Future<void> _toggleLike(String postId) async {
  final userId = currentUserId;
  if (userId == null) return;

  setState(() {
    _likedPosts[postId] = !(_likedPosts[postId] ?? false);
  });

  try {
    if (_likedPosts[postId] ?? false) {
      await supabase.from('likes').insert({
        'user_id': userId,
        'post_id': postId, // Aseguramos que sea String
      });

      final post = _posts.firstWhere((p) => p['id'] == postId);
      await supabase.from('notifications').insert({
        'user_id': post['user_id'],
        'sender_id': userId,
        'type': 'like',
        'post_id': postId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'read': false,
      });
    } else {
      await supabase.from('likes').delete().eq('user_id', userId).eq('post_id', postId);
    }
    _loadPosts();
  } catch (error) {
    print('Error al actualizar like: $error');
    setState(() {
      _likedPosts[postId] = !(_likedPosts[postId] ?? false);
    });
  }
}

  Future<void> _addComment(String postId) async {
    if (currentUserId == null || _commentController.text.trim().isEmpty) return;

    try {
      await supabase.from('comments').insert({
        'user_id': currentUserId,
        'post_id': postId,
        'content': _commentController.text.trim(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Crear notificación
      final post = _posts.firstWhere((p) => p['id'] == postId);
      await supabase.from('notifications').insert({
        'user_id': post['user_id'],
        'sender_id': currentUserId,
        'type': 'comment',
        'post_id': postId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'read': false,
      });

      _commentController.clear();
      _loadPosts(); // Recargar para actualizar contadores
    } catch (error) {
      print('Error al agregar comentario: $error');
    }
  }

  void _showComments(BuildContext context, String postId) async {
    final comments = await supabase
        .from('comments')
        .select('*, users:user_id (username, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Comentarios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        comment['users']['avatar_url'] ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                    title: Text(comment['users']['username'] ?? 'Usuario'),
                    subtitle: Text(comment['content']),
                    trailing: Text(
                      timeago.format(DateTime.parse(comment['created_at']), locale: 'es'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 8,
                right: 8,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Añade un comentario...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      _addComment(postId);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _followUser(String userId) async {
    final currentId = currentUserId;
    if (currentId == null) return;

    try {
      // Insertar nuevo seguidor
      await supabase.from('followers').insert({
        'follower_id': currentId,
        'following_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Crear notificación
      await supabase.from('notifications').insert({
        'user_id': userId,
        'sender_id': currentId,
        'type': 'follow',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'read': false,
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Ahora sigues a este usuario!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }

      // Recargar los posts para actualizar la UI
      await _loadPosts();
    } catch (error) {
      print('Error al seguir usuario: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al seguir al usuario'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay publicaciones para mostrar',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final isLiked = _likedPosts[post['id'].toString()] ?? false;
                      final isSuggested = post['is_suggested'] ?? false;

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSuggested)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: Colors.blue.withOpacity(0.1),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_add,
                                        size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Publicación sugerida',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/profile',
                                    arguments: post['user_id'],
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    post['users']['avatar_url'] ??
                                        'https://via.placeholder.com/150',
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      post['users']['username'] ?? 'Usuario',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isSuggested)
                                    TextButton.icon(
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Seguir'),
                                      onPressed: () async {
                                        await _followUser(post['user_id']);
                                        _loadPosts(); // Recargar posts después de seguir
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                timeago.format(
                                  DateTime.parse(post['created_at']),
                                  locale: 'es',
                                ),
                              ),
                            ),
                            if (post['image_url'] != null)
                              Image.network(
                                post['image_url'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(post['content']),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : null,
                                  ),
                                 onPressed: () => _toggleLike(post['id'].toString()),

                                ),
                                Text('${post['likes'][0]['count'] ?? 0}'),
                                IconButton(
                                  icon: const Icon(Icons.comment_outlined),
                                  onPressed: () => _showComments(context, post['id'].toString()),
                                ),
                                Text('${post['comments'][0]['count'] ?? 0}'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
