import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones'),
      ),
      body: ListView.builder(
        itemCount: 15, // Ejemplo con 15 notificaciones
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            title: Text('Usuario te ha seguido'),
            subtitle: Text('Hace 2 horas'),
            onTap: () {
              // Implementar navegación a la notificación
            },
          );
        },
      ),
    );
  }
} 