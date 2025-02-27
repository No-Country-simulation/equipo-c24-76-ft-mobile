import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Implementar navegación a configuración
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nombre de Usuario',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Biografía del usuario',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('Publicaciones'),
                          Text('120'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Seguidores'),
                          Text('1.2K'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Siguiendo'),
                          Text('350'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            // Grid de publicaciones
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 9, // Ejemplo con 9 publicaciones
              itemBuilder: (context, index) {
                return Image.network(
                  'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 