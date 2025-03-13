import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Obtener la instancia de Supabase
  final supabase = Supabase.instance.client;

  // colorcitos
  static const Color darkBlue = Color.fromRGBO(18, 38, 17, 1); // negrito
  static const Color teal = Color.fromRGBO(70, 94, 166, 1); // celestito
  static const Color olive = Color.fromRGBO(54, 36, 166, 1); // azul
  static const Color limeYellow = Color.fromRGBO(191, 10, 43, 1); // rojo
  static const Color beige = Color.fromRGBO(217, 30, 133, 1); // rosa

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
          backgroundColor: darkBlue,
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
          backgroundColor: olive,
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
            'Nueva Publicación',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: limeYellow),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _isUploading
                  ? const SizedBox(
                      width: 90,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: limeYellow,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _publishPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: limeYellow,
                        foregroundColor: darkBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.send, size: 16),
                        ],
                      ),
                    ),
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar y nombre de usuario (simulado)
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: limeYellow,
                    child: Icon(Icons.person, color: darkBlue, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tu Nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: limeYellow,
                        ),
                      ),
                      Text(
                        '@usuario',
                        style: TextStyle(
                          fontSize: 14,
                          color: beige,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Campo de texto
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLength: 280,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: '¿Qué estás pensando?',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: darkBlue.withOpacity(0.4)),
                      ),
                      style: const TextStyle(fontSize: 16, color: darkBlue),
                    ),
                    
                    // Contador de caracteres personalizado
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_contentController.text.length}/280',
                        style: TextStyle(
                          color: _contentController.text.length > 260
                              ? olive
                              : teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Imagen seleccionada
              if (_imageFile != null)
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                  child: ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Image.file(
    _imageFile!,
    height: 200, // Ajusta según el tamaño que prefieras
    width: double.infinity,
    fit: BoxFit.cover, // Asegura que la imagen se ajuste al tamaño especificado
  ),
),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: limeYellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: darkBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 20),
              
              // Botones de medios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _mediaButton(
                    icon: Icons.image,
                    label: 'Galería',
                    onTap: _pickImage,
                    color: olive,
                    bgColor: Colors.white,
                  ),
                  _mediaButton(
                    icon: Icons.camera_alt,
                    label: 'Cámara',
                    onTap: _takePhoto,
                    color: limeYellow,
                    bgColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _mediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}