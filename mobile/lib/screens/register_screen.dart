import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final supabase = Supabase.instance.client;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Método para seleccionar imagen
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400, 
      maxHeight: 400,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Método para convertir la imagen a base64
  Future<String?> _imageToBase64() async {
    if (_selectedImage == null) return null;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      print("Error al convertir imagen: $e");
      return null;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Supabase Auth
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user != null) {
        // 2. Convertir imagen a base64 si fue seleccionada
        String? avatarBase64;
        if (_selectedImage != null) {
          avatarBase64 = await _imageToBase64();
        }

        // 3. Inserta datos adicionales en la tabla 'users'
        try {
          final userData = {
            'id': user.id,
            'username': _usernameController.text.trim(),
            'bio': _bioController.text.trim(),
            'email': user.email,
          };
          
          // Solo agregamos avatar_url si tenemos una imagen
          if (avatarBase64 != null) {
            userData['avatar_url'] = avatarBase64;
          }
          
          await supabase.from('users').upsert([userData]);
          
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Registro exitoso"),
            backgroundColor: Colors.green,
          ));

          Navigator.pushReplacementNamed(context, '/login');
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error al guardar datos: $error"),
            backgroundColor: Colors.red,
          ));
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error de autenticación: ${e.message}"),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error inesperado: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro", 
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF3624A6),
        elevation: 0,),
       body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFE77FF), Colors.white, // Color superior (rosa)
            Color(0xFF465EA6), // Color inferior (azul)
          ],
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [              // Widget para seleccionar imagen
              Center(
                child: Column(
                  children: [
                    _selectedImage != null
                        ? Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(_selectedImage!),
                              ),
                            ),
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF465EA6),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Seleccionar avatar"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildTextField(_usernameController, "Nombre de usuario", Icons.person),
              _buildTextField(_bioController, "Biografía (opcional)", Icons.info, isOptional: true),
              _buildTextField(_emailController, "Correo electrónico", Icons.email, isEmail: true),
              _buildTextField(_passwordController, "Contraseña", Icons.lock, isPassword: true),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3624A6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Registrarse", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("¿Ya tienes cuenta? Inicia sesión", style: TextStyle(color: Color(0xFF3624A6))),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        validator: isOptional ? null : (value) => value!.isEmpty ? "Campo requerido" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF3624A6)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
