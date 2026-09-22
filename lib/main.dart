import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'home_screen.dart';

// --- VARIABLE CENTRALIZADA PARA LA URL ---
//const String baseUrl = 'http://localhost/inventariomaxima'; // Para pruebas en local
const String baseUrl = 'https://app.distribuidoramaxima.cl'; // Para producción

void main() async {
  // 1. Asegurar que los widgets estén inicializados antes de arrancar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Firebase en la aplicación
  try {
    await Firebase.initializeApp();

    // 3. Solicitar permiso para mostrar notificaciones (importante en Android 13+)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Capturar el Token único de este celular
    String? token = await messaging.getToken();
    if (token != null) {
      _guardarTokenEnBD(token);
    }
  } catch (e) {
    print("Error al inicializar Firebase: $e");
  }

  runApp(const MaximaApp());
}

// 5. Función que envía el Token a tu PHP para guardarlo en MySQL
Future<void> _guardarTokenEnBD(String token) async {
  final url = Uri.parse('$baseUrl/api/api_guardar_token.php');
  try {
    await http.post(url, body: {'token': token});
    print("Token de notificaciones registrado con éxito.");
  } catch (e) {
    print('Error guardando el token: $e');
  }
}

class MaximaApp extends StatelessWidget {
  const MaximaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Máxima App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isLoading = false;

  Future<void> iniciarSesion() async {
    setState(() { isLoading = true; });

    var url = Uri.parse('$baseUrl/api/api_login.php');
    
    try {
      var respuesta = await http.post(url, body: {
        'email': emailController.text.trim(),
        'password': passController.text,
      });

      if (respuesta.statusCode == 200) {
        var jsonPHP = json.decode(respuesta.body);

        if (jsonPHP['ok'] == true) {
          var datosUsuario = jsonPHP['datos'];

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(usuarioDatos: datosUsuario),
            ),
          );
        } else {
          mostrarAlerta(jsonPHP['msg'], Colors.redAccent);
        }
      } else {
        mostrarAlerta("Error del servidor: ${respuesta.statusCode}", Colors.redAccent);
      }
    } catch (e) {
      mostrarAlerta("No se pudo conectar al servidor local.", Colors.redAccent);
      print("Detalle del error: $e");
    }

    setState(() { isLoading = false; });
  }

  void mostrarAlerta(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(30.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==========================================
                        // LOGO DE LA EMPRESA
                        // ==========================================
                        Image.asset(
                          'assets/logo.png', // Ruta de tu imagen
                          height: 90, // Ajusta este valor para hacer el logo más grande o más chico
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Muestra un icono de respaldo si la imagen no se encuentra o hay un error en pubspec
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
                                ],
                              ),
                              child: const Icon(Icons.store_mall_directory_rounded, size: 50, color: Colors.white),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        const Text(
                          "Bienvenido", 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))
                        ),
                        const SizedBox(height: 6),
                        const Text("Inicia sesión para continuar en terreno", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 35),
                        
                        // Campo Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            hintText: 'ejemplo@correo.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6366F1)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Campo Contraseña
                        TextField(
                          controller: passController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6366F1)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Botón Ingresar Degradado
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: isLoading ? null : iniciarSesion,
                            child: isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Ingresar al Sistema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ==========================================
                // CRÉDITOS CORPORATIVOS AL FONDO DEL LOGIN
                // ==========================================
                const SizedBox(height: 40),
                const Text(
                  'Distribuidora Máxima © 2026 | Versión 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500, height: 1.5),
                    children: [
                      TextSpan(text: 'Desarrollado por\n'),
                      TextSpan(
                        text: 'Jonathan Pinilla Orellana',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}