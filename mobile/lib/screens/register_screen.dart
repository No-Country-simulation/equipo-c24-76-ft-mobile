import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _avatarController = TextEditingController(); // Para ingresar URL del avatar

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _authListener();
  }

  void _authListener() {
    final supabase = Supabase.instance.client;
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Registro con email y contraseña
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user != null) {
        // Luego de registrarse, inserta datos adicionales en la tabla "users" (ajusta el nombre de la tabla si es necesario)
        final insertResponse = await supabase.from('users').insert({
          'uid': user.id, // Asegúrate de que el campo coincida con el ID del usuario de Auth
          'username': _usernameController.text.trim(),
          'avatar': _avatarController.text.trim(),
        });

        if (insertResponse.error != null) {
          _showMessage("Error al guardar datos adicionales: ${insertResponse.error!.message}", Colors.red);
        } else {
          _showMessage("Registro exitoso.", Colors.green);
        }
      }
    } on AuthException catch (e) {
      _showMessage("Error de autenticación: ${e.message}", Colors.red);
    } catch (e) {
      _showMessage("Error inesperado: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Campo para el nombre de usuario (nick)
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Nombre de usuario"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Ingrese su nombre de usuario";
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Campo para la URL del avatar
                TextFormField(
                  controller: _avatarController,
                  decoration: const InputDecoration(labelText: "URL del avatar (opcional)"),
                  // No es obligatorio; si se deja vacío se puede usar un valor por defecto en la base
                  validator: (value) {
                    // Si se ingresa algo, se valida que sea una URL básica
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^https?:\/\/').hasMatch(value)) {
                        return "Ingrese una URL válida";
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Campo de correo electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Correo electrónico"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Ingrese su email";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Ingrese un email válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Campo de contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Ingrese su contraseña";
                    if (value.length < 6) return "Mínimo 6 caracteres";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text("Registrarse"),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
