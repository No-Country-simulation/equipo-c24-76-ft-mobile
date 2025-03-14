import 'dart:convert';  // Asegúrate de importar este paquete
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(  // StreamBuilder para escuchar cambios
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());  // Cargando
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las notificaciones'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No tienes notificaciones aún'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final senderAvatar = notification['sender_avatar'];  // Avatar del usuario
              final senderId = notification['sender_id'];  // ID del usuario que envió la notificación

              return ListTile(
                leading: GestureDetector(
                  onTap: () {
                    // Al hacer click en el avatar, navegar al perfil del usuario
                    _navigateToProfile(senderId);
                  },
                  child: _buildAvatar(notification['sender_avatar']),
                ),
                title: Text(_getNotificationText(notification)),
                subtitle: Text(
                  timeago.format(
                    DateTime.parse(notification['created_at']),
                    locale: 'es_ES',
                  ),
                ),
                onTap: () {
                  _handleNotificationTap(notification);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Función para obtener las notificaciones con datos enriquecidos (nombre y avatar del usuario)
  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return const Stream.empty();
    }

    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) async {
          final List<Map<String, dynamic>> enrichedData = [];
          for (var row in data) {
            // Obtener el sender_name, avatar_url y username desde la tabla users usando sender_id
            final sender = await supabase
                .from('users')
                .select('username, avatar_url')
                .eq('id', row['sender_id'])
                .maybeSingle();

            row['sender_name'] = sender?['username'] ?? 'Usuario desconocido';
            row['sender_avatar'] = sender?['avatar_url'] ?? '';
            enrichedData.add(row);
          }
          return enrichedData;
        }).asyncMap((event) async {
          return await event;
        });
  }

  // Función que devuelve el texto de la notificación según el tipo
  String _getNotificationText(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'follow':
        return '📌 ${notification['sender_name']} te ha seguido';
      case 'like':
        return '❤️ ${notification['sender_name']} le dio me gusta a tu post';
      case 'comment':
        return '💬 ${notification['sender_name']} comentó tu post';
      default:
        return '🔔 Nueva notificación';
    }
  }

  // Función para manejar la navegación según el tipo de notificación
  void _handleNotificationTap(Map<String, dynamic> notification) {
    if (notification['type'] == 'follow') {
      // Navegar al perfil del usuario que sigue
      _navigateToProfile(notification['sender_id']);
    } else if (notification['type'] == 'like' || notification['type'] == 'comment') {
      // Navegar al post específico
      Navigator.pushNamed(context, '/post', arguments: notification['post_id']);
    }
  }

  // Modifica el Widget que muestra el avatar
  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    try {
      if (avatarUrl.startsWith('data:image')) {
        final base64Str = avatarUrl.split(',')[1];
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(base64Decode(base64Str)),
          onBackgroundImageError: (_, __) {},
        );
      } else {
        return CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError: (_, __) {},
        );
      }
    } catch (e) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey,
        child: Icon(Icons.error, color: Colors.white),
      );
    }
  }

  void _navigateToProfile(String userId) {
    // Si el userId es el del usuario actual, ir a su perfil
    if (userId == supabase.auth.currentUser?.id) {
      Navigator.pushNamed(context, '/profile');
    } else {
      // Si es otro usuario, ir al perfil de usuario
      Navigator.pushNamed(
        context,
        '/user-profile',
        arguments: userId,
      );
    }
  }
}
