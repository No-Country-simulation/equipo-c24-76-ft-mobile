import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
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
    // Aquí iría la lógica para publicar el post
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El contenido no puede estar vacío')),
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
        title: Text('Nueva Publicación'),
        actions: [
          TextButton(
            onPressed: _publishPost,
            child: Text('Publicar'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLength: 280,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '¿Qué estás pensando?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text('Agregar imagen'),
            ),
          ],
        ),
      ),
    );
  }
} 