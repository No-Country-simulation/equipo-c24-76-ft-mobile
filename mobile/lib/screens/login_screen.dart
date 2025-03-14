import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  double _opacity = 0.4;

  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  void initState() {
    super.initState();
    _startAnimation();
  }
  void _startAnimation() {
  Timer.periodic(const Duration(seconds: 2), (timer) {
    if (!mounted) return; // Evita errores si el widget se desmonta
    setState(() {
      _opacity = _opacity == 0.4 ? 0.2 : 0.4; // Alterna entre 0.4 y 0.2
    });
  });
}
  /// 🔹 Iniciar sesión con email y contraseña
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

 

  /// 🔹 Iniciar sesión con Google
  Future<void> _signInWithGoogle() async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      _showError(e.message);
    }
  }

  /// 🔹 Iniciar sesión con Facebook
Future<void> _signInWithFacebook() async {
  try {
    await supabase.auth.signInWithOAuth(
    
      OAuthProvider.facebook,
      redirectTo: 'https://gpo1ketouwpxmjopmu.supabase.co/auth/v1/callback',
    );
    Navigator.pushReplacementNamed(context, '/home');
  } on AuthException catch (e) {
    _showError(e.message);
  }
}


  /// 🔹 Mostrar errores
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 🔹 Mostrar éxito
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD91EAA),Colors.white, Color(0xFF3624A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
           // Círculo inferior derecho
          Positioned(
            bottom: -50.0,
            left: -50.0,
            child: AnimatedOpacity(
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              opacity: _opacity,
              child: Container(
                width: 150.0,
                height: 150.0,
                decoration: BoxDecoration(
                  color: Color(0xFFD91EAA),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Círculo superior izquierdo
          Positioned(
            top: -50.0, // Ajustado para que sea visible
            right: -50.0, // Ajustado para que no quede fuera de pantalla
            child: AnimatedOpacity(
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              opacity: _opacity,
              child: Container(
                width: 150.0,
                height: 150.0,
                decoration: BoxDecoration(
                  color: Color(0xFF3624A6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "¡Hola!",
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF465EA6),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email, color: Color(0xFF465EA6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) return "Ingrese su email";
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF465EA6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) return "Ingrese su contraseña";
                              if (value.length < 6) return "Mínimo 6 caracteres";
                              return null;
                            },
                          ),
                        const SizedBox(height: 20.0,),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity, // Hace que el Row ocupe todo el ancho
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Alinea a la derecha
                                  children: [
                                    ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3624A6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 80,
                                    ),
                                  ),
                                  child: Text(
                                    "Ingresar",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                  ],
                                ),
                              ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              "¿No tienes cuenta? Registrate aquí",
                              style: GoogleFonts.poppins(color: Color(0xFF3624A6)),
                            ),
                          ),
                         TextButton(
                          onPressed: () {},
                          child: Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(color: Color(0xFF3624A6)),
                          ),
                        ), /*Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _signInWithFacebook,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1877F2), // Color oficial de Facebook
                                  shape: const CircleBorder(), // Hace el botón circular
                                  padding: const EdgeInsets.all(11.0),
                                ),
                                child: const Icon(Icons.facebook, color: Colors.white, size: 30.0),
                              ),
                              ElevatedButton(
                                onPressed:_signInWithGoogle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(11.0),
                                ), 
                                child: Image.asset(
                                  'assets/google_logo.png',
                                  height: 30.0,
                                )
                              ),
                            ],
                          )*/
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 