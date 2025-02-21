import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> posts = [
      {
        'username': 'Juan Pérez',
        'profilePic': 'https://randomuser.me/api/portraits/men/1.jpg',
        'postImage': 'assets/auto2.png',
      },
      {
        'username': 'María López',
        'profilePic': 'https://randomuser.me/api/portraits/women/2.jpg',
        'postImage': 'assets/auto2.png',
      },
      {
        'username': 'Carlos García',
        'profilePic': 'https://randomuser.me/api/portraits/men/3.jpg',
        'postImage': 'assets/auto2.png',
      },
      {
        'username': 'Ana Torres',
        'profilePic': 'https://randomuser.me/api/portraits/women/4.jpg',
        'postImage': 'assets/auto2.png',
      },
      {
        'username': 'Pedro Díaz',
        'profilePic': 'https://randomuser.me/api/portraits/men/5.jpg',
        'postImage': 'assets/auto2.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Social'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(posts[index]['profilePic']!),
                    ),
                    title: Text(
                      posts[index]['username']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Hace 2 horas'),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
                    ),
                  ),
                  Image.asset(
                    posts[index]['postImage']!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.comment),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Publicación de ${posts[index]['username']} #RedSocial',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Buscar"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Publicar"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notificaciones"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
