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
  final supabase = Supabase.instance.client;
  
static const Color darkBlue = Color.fromRGBO(18, 38, 17, 1); // negrito
static const Color teal = Color.fromRGBO(70, 94, 166, 1); // celestito
static const Color olive = Color.fromRGBO(54, 36, 166, 1); // azul
static const Color limeYellow = Color.fromRGBO(191, 10, 43, 1); // rojo
static const Color beige = Color.fromRGBO(217, 30, 133, 1); // rosa

  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId.toString())
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final List<Map<String, dynamic>> enrichedData = [];
          for (var row in data) {
            final sender = await supabase
                .from('users')
                .select()
                .eq('id', row['sender_id'])
                .single();

            enrichedData.add({
              ...row,
              'sender_name': sender['username'] ?? 'Usuario',
              'sender_avatar': sender['avatar_url'] ?? '',
            });
          }
          return enrichedData;
        });
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    // Si el avatar es una imagen en base64
    if (avatarUrl.startsWith('data:image')) {
      try {
        final base64Str = avatarUrl.split(',')[1];
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(base64.decode(base64Str)),
          backgroundColor: Colors.grey,
          child: const Icon(Icons.person, color: Colors.white),
        );
      } catch (e) {
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        );
      }
    }

    // Si el avatar es una URL
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(avatarUrl),
      backgroundColor: Colors.grey,
      child: const Icon(Icons.person, color: Colors.white),
      onBackgroundImageError: (_, __) {},
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.pushNamed(
      context,
      '/user-profile',
      arguments: userId,
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToUserProfile(notification['sender_id']),
        child: _buildAvatar(notification['sender_avatar']),
      ),
      title: Text(_getNotificationText(notification)),
      subtitle: Text(
        timeago.format(
          DateTime.parse(notification['created_at']),
          locale: 'es_ES',
        ),
      ),
      onTap: () => _navigateToUserProfile(notification['sender_id']),
    );
  }

  String _getNotificationText(Map<String, dynamic> notification) {
    final senderName = notification['sender_name'] ?? 'Usuario';
    final type = notification['type'];

    switch (type) {
      case 'follow':
        return '$senderName te empezó a seguir';
      case 'like':
        return 'A $senderName le gustó tu post';
      case 'comment':
        return '$senderName comentó tu post';
      default:
        return 'Nueva notificación de $senderName';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Aplicamos el gradiente a toda la pantalla como contenedor principal
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            darkBlue,
            teal,
          ],
        ),
      ),
      child: Scaffold(
        // Hacemos transparente el Scaffold para que se vea el gradiente
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Notificaciones',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 20, 
              color: limeYellow
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: limeYellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final notifications = snapshot.data ?? [];
            
            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'No hay notificaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationTile(notifications[index]);
              },
            );
          },
        ),
      ),
    );
  }
}