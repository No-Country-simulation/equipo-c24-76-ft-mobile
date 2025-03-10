import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  String username = "Cargando...";
  String bio = "Cargando...";
  String avatarUrl = "";
  bool isLoading = true;
  bool showSettings = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/login");
        }
        return;
      }

      final response = await supabase
          .from('users')
          .select('username, bio, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Si no hay datos, crear un perfil predeterminado
        await supabase.from('users').insert({
          'id': user.id,
          'username': 'Usuario Nuevo',
          'bio': 'Sin biografía',
          'avatar_url': '',
        });
        
        if (mounted) {
          setState(() {
            username = 'Usuario Nuevo';
            bio = 'Sin biografía';
            avatarUrl = '';
            isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          username = response['username'] ?? "Sin nombre";
          bio = response['bio'] ?? "Sin biografía";
          avatarUrl = response['avatar_url'] ?? "";
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error cargando el perfil: $error");
      if (mounted) {
        setState(() {
          username = "Error";
          bio = "No se pudo cargar la biografía";
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar perfil: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final usernameController = TextEditingController(text: username);
    final bioController = TextEditingController(text: bio);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Perfil"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Nombre de usuario"),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: "Biografía"),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = supabase.auth.currentUser;
                if (user == null) return;

                final newUsername = usernameController.text.trim();
                final newBio = bioController.text.trim();

                if (newUsername.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("El nombre de usuario es obligatorio"),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }

                try {
                  await supabase.from('users').update({
                    'username': newUsername,
                    'bio': newBio,
                  }).eq('id', user.id);

                  if (mounted) {
                    setState(() {
                      username = newUsername;
                      bio = newBio;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Perfil actualizado con éxito"),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Error al actualizar: $e"),
                    backgroundColor: Colors.red,
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al cerrar sesión: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reducir calidad para optimizar
      );
      
      if (image == null) return;
      
      setState(() {
        isLoading = true;
      });
      
      final bytes = await image.readAsBytes();
      final base64String = "data:image/png;base64,${base64Encode(bytes)}";
      
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      await supabase.from('users').update({
        'avatar_url': base64String
      }).eq('id', user.id);
      
      if (mounted) {
        setState(() {
          avatarUrl = base64String;
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Imagen actualizada correctamente"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print("Error subiendo la imagen: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al subir la imagen: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                showSettings = !showSettings;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : showSettings
              ? _buildSettingsScreen()
              : _buildProfileScreen(),
    );
  }

  Widget _buildProfileScreen() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    children: [
                      _buildAvatarImage(),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _editProfile,
                  child: const Text("Editar perfil"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
    
    try {
      if (avatarUrl.startsWith('data:image')) {
        final base64Str = avatarUrl.split(',')[1];
        return CircleAvatar(
          radius: 50,
          child: ClipOval(
            child: Image.memory(
              base64Decode(base64Str),
              fit: BoxFit.cover,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                print("Error rendering image: $error");
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ),
        );
      } else {
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError: (exception, stackTrace) {
            print("Error loading network image: $exception");
          },
          child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
        );
      }
    } catch (e) {
      print("Error cargando la imagen del avatar: $e");
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.error, size: 40, color: Colors.red),
      );
    }
  }

  Widget _buildSettingsScreen() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text("Editar Perfil"),
          onTap: _editProfile,
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: const Text("Cambiar foto de perfil"),
          onTap: _pickAndUploadImage,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Cerrar sesión", 
            style: TextStyle(color: Colors.red),
          ),
          onTap: _logout,
        ),
      ],
    );
  }
}