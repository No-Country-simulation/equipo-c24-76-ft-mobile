import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _publishPost() {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El contenido no puede estar vacío')),
      );
      return;
    }
    
    // TODO: Implementar la lógica de publicación
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Publicación'),
        actions: [
          TextButton(
            onPressed: _publishPost,
            child: const Text('Publicar'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLength: 280,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '¿Qué estás pensando?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Agregar imagen'),
            ),
          ],
        ),
      ),
    );
  }
}
