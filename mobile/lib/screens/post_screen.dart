import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _username = '';
  String _avatarUrl = '';

  // Obtener la instancia de Supabase
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userData = await supabase
          .from('users')
          .select('username, avatar_url')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _username = userData['username'] ?? 'Usuario';
          _avatarUrl = userData['avatar_url'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario: $e');
    }
  }

  Widget _buildAvatar() {
    if (_avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.avatarBackground,
        child: Icon(Icons.person, color: Colors.white, size: 30),
      );
    }

    try {
      if (_avatarUrl.startsWith('data:image')) {
        final base64Str = _avatarUrl.split(',')[1];
        return CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(base64.decode(base64Str)),
          backgroundColor: AppTheme.avatarBackground,
          onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.white, size: 30),
        );
      } else if (_avatarUrl.startsWith('/9j/')) {
        return CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(base64.decode(_avatarUrl)),
          backgroundColor: AppTheme.avatarBackground,
          onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.white, size: 30),
        );
      } else {
        return CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(_avatarUrl),
          backgroundColor: AppTheme.avatarBackground,
          onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.white, size: 30),
        );
      }
    } catch (e) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.avatarBackground,
        child: Icon(Icons.person, color: Colors.white, size: 30),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  // Convertir imagen a base64
  Future<String?> _imageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print('Error convirtiendo imagen a base64: $e');
      return null;
    }
  }

  Future<void> _publishPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El contenido no puede estar vacío'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
      return;
    }
    
    // Verificar si hay un usuario autenticado
    final User? currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para publicar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Preparar los datos para Supabase
      Map<String, dynamic> postData = {
        'content': _contentController.text,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': currentUser.id, // Añadir el ID del usuario actual
      };
      
      // Si hay una imagen, la convertimos a base64
      if (_imageFile != null) {
        String? base64Image = await _imageToBase64(_imageFile!);
        if (base64Image != null) {
          postData['media_url'] = base64Image;
        }
      }
      
      // Insertar en la tabla posts de Supabase
      final response = await supabase
          .from('post')
          .insert(postData)
          .select();
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Publicación realizada con éxito!'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      
      // Limpiar el formulario
      _contentController.clear();
      setState(() {
        _imageFile = null;
      });
      
      // Volver a la pantalla anterior
      Navigator.pop(context);
      
    } catch (e) {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.mainGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Nueva Publicación',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAvatar(),
                          const SizedBox(width: 12),
                          Text(
                            '@$_username',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '¿Qué estás pensando?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_imageFile != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _removeImage,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Eliminar imagen',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galería'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Cámara'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _publishPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Publicar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}