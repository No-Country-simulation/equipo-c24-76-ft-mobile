import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostScreen extends StatefulWidget {
  const PostScreen({Key? key}) : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // colorcitos
  static const Color darkBlue = Color.fromRGBO(4, 41, 64, 1); // R4 G41 B64
  static const Color teal = Color.fromRGBO(0, 92, 83, 1); // R0 G92 B83
  static const Color olive = Color.fromRGBO(159, 193, 49, 1); // R159 G193 B49
  static const Color limeYellow = Color.fromRGBO(219, 242, 39, 1); // R219 G242 B39
  static const Color beige = Color.fromRGBO(214, 213, 142, 1); // R214 G213 B142

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

  void _publishPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El contenido no puede estar vacío'),
          backgroundColor: darkBlue,
        ),
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    // Simulamos una carga
    await Future.delayed(const Duration(seconds: 2));
    
    // TODO: Implementar la lógica de publicación
    
    setState(() {
      _isUploading = false;
    });
    
    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Publicación realizada con éxito!'),
        backgroundColor: olive,
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        backgroundColor: darkBlue,
        elevation: 0,
      ),
      body: Container(
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
        child: SingleChildScrollView(
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
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
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