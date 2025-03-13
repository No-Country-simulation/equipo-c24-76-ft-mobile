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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              return ListTile(
               leading: CircleAvatar(
  backgroundImage: NetworkImage(notification['sender_avatar'] ?? 'https://via.placeholder.com/150'),
),

                title: Text(_getNotificationText(notification)),
                subtitle: Text(timeago.format(DateTime.parse(notification['created_at']))),
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
          // Obtener el sender_name desde la tabla users usando sender_id
          final sender = await supabase
              .from('users')
              .select('username')
              .eq('id', row['sender_id'])
              .maybeSingle();
          
          row['sender_name'] = sender?['username'] ?? 'Usuario desconocido';
          enrichedData.add(row);
        }
        return enrichedData;
      }).asyncMap((event) async => await event);
}

  /// 🔥 Función que genera el texto de la notificación basado en el tipo
  String _getNotificationText(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'follow':
        return '📌 ${notification['sender_name']} te ha seguido';
      case 'like':
        return '❤️ ${notification['username']} le dio me gusta a tu post';
      case 'comment':
        return '💬 ${notification['sender_name']} comentó tu post';
      default:
        return '🔔 Nueva notificación';
    }
  }

  /// 🔥 Función para manejar la navegación según el tipo de notificación
  void _handleNotificationTap(Map<String, dynamic> notification) {
    if (notification['type'] == 'follow') {
      // Navegar al perfil del usuario que sigue
      Navigator.pushNamed(context, '/profile', arguments: notification['sender_id']);
    } else if (notification['type'] == 'like' || notification['type'] == 'comment') {
      // Navegar al post específico
      Navigator.pushNamed(context, '/post', arguments: notification['post_id']);
    }
  }
}
