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
                    Navigator.pushNamed(context, '/profile', arguments: senderId);
                  },
                  child: CircleAvatar(
                    backgroundImage: senderAvatar != null && senderAvatar.isNotEmpty
                        ? NetworkImage(senderAvatar)  // Si existe el avatar, se muestra
                        : const NetworkImage('https://via.placeholder.com/150'),  // Imagen por defecto si no hay avatar
                  ),
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
            // Obtener el sender_name y avatar_url desde la tabla users usando sender_id
            final sender = await supabase
                .from('users')
                .select('username, avatar_url') // Obtener el nombre de usuario y avatar
                .eq('id', row['sender_id'])
                .maybeSingle();

            // Asignar el nombre y el avatar a los datos de la notificación
            row['sender_name'] = sender?['username'] ?? 'Usuario desconocido';
            row['sender_avatar'] = sender?['avatar_url'] ?? '';  // Aquí asignamos el avatar_url
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
      Navigator.pushNamed(context, '/profile', arguments: notification['sender_id']);
    } else if (notification['type'] == 'like' || notification['type'] == 'comment') {
      // Navegar al post específico
      Navigator.pushNamed(context, '/post', arguments: notification['post_id']);
    }
  }
}
