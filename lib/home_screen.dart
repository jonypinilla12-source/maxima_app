import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:maxima_app/planificacion_ruta_screen.dart';
import 'territorios_screen.dart';
import 'maestra_screen.dart';
import 'ingresar_productos_screen.dart';
import 'productos_listar_screen.dart';
import 'posiciones_screen.dart';
import 'lector_qr_screen.dart';
import 'dashboard_infaltables_screen.dart';
import 'dashboard_pdv_screen.dart';
import 'resumen_territorio_screen.dart';
import 'crear_clientes_screen.dart';
import 'listado_censo_screen.dart';
import 'cliente_mueble_screen.dart';
import 'main.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_ventas_screen.dart'; 

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioDatos;

  const HomeScreen({super.key, required this.usuarioDatos});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color colorPrimario = const Color(0xFF6366F1);
  final Color colorSecundario = const Color(0xFF8B5CF6);

  // --- REVISAR ENCUESTAS AL INICIAR LA APP ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revisarEncuestasPendientes();
    });
  }

  Future<void> _revisarEncuestasPendientes() async {
    int userId = int.tryParse(widget.usuarioDatos['usuario_id']?.toString() ?? '0') ?? 0;
    String rol = widget.usuarioDatos['rol_nombre'] ?? ''; 

    if (userId == 0) return;

    const String baseUrl = 'https://app.distribuidoramaxima.cl';
    final url = Uri.parse('$baseUrl/api/api_encuestas.php?action=get_activa&rol=${Uri.encodeComponent(rol)}');
    
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['ok'] == true && data['data'] != null) {
          
          final prefs = await SharedPreferences.getInstance();
          List<String> encuestasRespondidas = prefs.getStringList('encuestas_listas') ?? [];
          String idActual = data['data']['encuesta_id'].toString();

          if (!encuestasRespondidas.contains(idActual)) {
            _mostrarModalEncuesta(data['data'], userId, baseUrl);
          }
          
        }
      }
    } catch (e) {
      debugPrint('Error al verificar encuestas: $e');
    }
  }

  // --- MODAL OBLIGATORIO DE ENCUESTA ---
  void _mostrarModalEncuesta(Map<String, dynamic> encuestaData, int userId, String baseUrl) {
    final TextEditingController txtRespuesta = TextEditingController();
    final TextEditingController txtTerritorio = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFFFFF7ED), shape: BoxShape.circle),
                          child: const Icon(Icons.assignment_late_rounded, color: Color(0xFFF97316), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                encuestaData['encuesta_titulo'].toString().toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFEA580C)),
                              ),
                              const Text("Acción Obligatoria", style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Text(
                        encuestaData['encuesta_pregunta'],
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text("TU RESPUESTA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: txtRespuesta,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Escribe detalladamente tu reporte aquí...",
                        filled: true, fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorPrimario, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text("VALIDACIÓN DE RUTA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: txtTerritorio,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Escribe tu territorio (Ej: 72016)",
                        prefixIcon: const Icon(Icons.map_rounded, color: Color(0xFF94A3B8)),
                        filled: true, fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorPrimario, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrimario,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isSubmitting ? null : () async {
                          if (txtRespuesta.text.trim().isEmpty || txtTerritorio.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena ambos campos.'), backgroundColor: Colors.redAccent));
                            return;
                          }

                          setStateModal(() => isSubmitting = true);

                          try {
                            final postUrl = Uri.parse('$baseUrl/api/api_encuestas.php?action=responder');
                            final response = await http.post(postUrl, body: {
                              'usuario_id': userId.toString(),
                              'encuesta_id': encuestaData['encuesta_id'].toString(),
                              'territorio': txtTerritorio.text.trim(),
                              'respuesta': txtRespuesta.text.trim(),
                            });

                            final result = json.decode(response.body);

                            if (result['ok']) {
                              final prefs = await SharedPreferences.getInstance();
                              List<String> respondidas = prefs.getStringList('encuestas_listas') ?? [];
                              respondidas.add(encuestaData['encuesta_id'].toString());
                              await prefs.setStringList('encuestas_listas', respondidas);

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['msg']), backgroundColor: Colors.green));
                              Navigator.pop(dialogContext); 
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['msg']), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión.'), backgroundColor: Colors.redAccent));
                          } finally {
                            setStateModal(() => isSubmitting = false);
                          }
                        },
                        child: isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Enviar y Continuar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        );
      },
    );
  }

  void _cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
              const SizedBox(width: 8),
              const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text("¿Estás seguro de que deseas salir del sistema?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("Sí, Salir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String nombre = widget.usuarioDatos['usuario_nombre'] ?? 'Usuario';
    String rol = widget.usuarioDatos['rol_nombre'] ?? '';
    int userId = int.tryParse(widget.usuarioDatos['usuario_id']?.toString() ?? '1') ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: _buildDrawer(context, nombre, rol, userId),
      
      // ==========================================
      // FOOTER FIJO Y ELEGANTE LIMITADO PARA WEB
      // ==========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: colorPrimario.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // <-- CORRECCIÓN CLAVE PARA EVITAR QUE SE COMA LA PANTALLA
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded, color: colorPrimario, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Distribuidora Máxima © 2026',
                            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Versión 1.0.0', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 10)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Desarrollado por Jonathan Pinilla Orellana',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // ==========================================
      // CUERPO PRINCIPAL LIMITADO PARA WEB
      // ==========================================
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: colorPrimario,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colorPrimario, colorSecundario],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                      ),
                      Positioned(top: -20, right: -20, child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.08))),
                      Positioned(bottom: -30, left: -10, child: CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.08))),
                      
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 45, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '¡Hola, $nombre!',
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.admin_panel_settings_rounded, size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text('Rol: $rol', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    children: [
                      Container(width: 4, height: 18, decoration: BoxDecoration(color: colorPrimario, borderRadius: BorderRadius.circular(10))),
                      const SizedBox(width: 8),
                      const Text('Accesos Rápidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95, 
                  children: _obtenerTarjetasRapidas(context, rol, userId),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _obtenerTarjetasRapidas(BuildContext context, String rol, int userId) {
    if (rol == 'Supervisor') {
      return [
        _buildQuickCard(context, 'Infaltables', 'Dashboard avances', Icons.auto_graph_rounded, const Color(0xFFEC4899), const DashboardInfaltablesScreen()),
        _buildQuickCard(context, 'Avance PDV', 'Dashboard PDV', Icons.storefront_rounded, const Color(0xFF3B82F6), const DashboardPdvScreen()),
        _buildQuickCard(context, 'Bodega', 'Productos', Icons.list_alt_rounded, const Color(0xFF8B5CF6), const ProductosListaScreen()),
        _buildQuickCard(context, 'Crear Cliente', 'Registro', Icons.person_add_rounded, const Color(0xFFF59E0B), const CrearClienteScreen()),
        _buildQuickCard(context, 'Ruta', 'Planificación', Icons.alt_route_rounded, const Color(0xFF10B981), const PlanificacionRutaScreen()),
        _buildQuickCard(context, 'Muebles', 'Gestión', Icons.chair_alt_rounded, const Color(0xFF6366F1), const ListadoCensoScreen()),
      ];
    } else if (rol == 'Vendedor') {
      return [
        _buildQuickCard(context, 'Crear Cliente', 'Registro', Icons.person_add_rounded, const Color(0xFFF59E0B), const CrearClienteScreen()),
        _buildQuickCard(context, 'Resumen', 'Territorios', Icons.insights_rounded, const Color(0xFF3B82F6), const ResumenTerritorioScreen()),
        _buildQuickCard(context, 'Ruta', 'Planificación', Icons.alt_route_rounded, const Color(0xFF10B981), const PlanificacionRutaScreen()),
        _buildQuickCard(context, 'Muebles', 'Gestión', Icons.chair_alt_rounded, const Color(0xFF6366F1), const ListadoCensoScreen()),
      ];
    } else if (rol == 'Inventario' || rol == 'bodega') {
      return [
        _buildQuickCard(context, 'Maestra', 'Productos', Icons.inventory_2_rounded, const Color(0xFF3B82F6), const MaestraScreen()),
        _buildQuickCard(context, 'Ingresar', 'Registrar', Icons.add_box_rounded, const Color(0xFF10B981), IngresarProductoScreen(usuarioId: userId)),
        _buildQuickCard(context, 'Bodega', 'Stock', Icons.list_alt_rounded, const Color(0xFF8B5CF6), const ProductosListaScreen()),
        _buildQuickCard(context, 'Posiciones', 'Disponibles', Icons.place_rounded, const Color(0xFFEC4899), const PosicionesScreen()),
        _buildQuickCard(context, 'Escanear QR', 'Pallet', Icons.qr_code_2_rounded, const Color(0xFFF59E0B), LectorQrScreen(usuarioId: userId, rolUsuario: rol)),
      ];
    } else if (rol == 'admin' || rol == 'Jefe') {
      return [
        _buildQuickCard(context, 'Territorios', 'Gestión de rutas', Icons.map_rounded, const Color(0xFF6366F1), const TerritoriosScreen()),
        _buildQuickCard(context, 'Crear Cliente', 'Registro PDVs', Icons.person_add_rounded, const Color(0xFFF59E0B), const CrearClienteScreen()),
        _buildQuickCard(context, 'Infaltables', 'Dashboard general', Icons.auto_graph_rounded, const Color(0xFFEC4899), const DashboardInfaltablesScreen()),
        _buildQuickCard(context, 'Inventario', 'Maestra y stock', Icons.inventory_2_rounded, const Color(0xFF10B981), const MaestraScreen()),
        _buildQuickCard(context, 'Ruta', 'Planificación', Icons.alt_route_rounded, const Color(0xFF3B82F6), const PlanificacionRutaScreen()),
        _buildQuickCard(context, 'Muebles', 'Gestión', Icons.chair_alt_rounded, const Color(0xFF8B5CF6), const ListadoCensoScreen()),
      ];
    }
    return [
      _buildQuickCard(context, 'Inicio', 'Sin accesos', Icons.home_rounded, Colors.grey, null)
    ];
  }

  Widget _buildQuickCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget? pantalla) {
    return InkWell(
      onTap: () {
        if (pantalla != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Módulo $title en desarrollo', style: const TextStyle(fontWeight: FontWeight.bold))));
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 28),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
                )
              ],
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B), letterSpacing: 0.2)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String nombre, String rol, int userId) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colorPrimario, colorSecundario], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorPrimario),
                  ),
                ),
                const SizedBox(height: 16),
                Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text(rol.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                if (rol == 'Supervisor') ...[
                  _buildDrawerSection('INDICADORES Y BODEGA'),
                  _buildDrawerItem(context, icon: Icons.auto_graph_rounded, color: Colors.deepPurple, title: 'Dashboard Infaltables', pantalla: const DashboardInfaltablesScreen()),
                  _buildDrawerItem(context, icon: Icons.storefront_rounded, color: Colors.deepPurpleAccent, title: 'Avance PDV', pantalla: const DashboardPdvScreen()),
                  _buildDrawerItem(context, icon: Icons.list_alt_rounded, color: Colors.blueAccent, title: 'Productos en Bodega', pantalla: const ProductosListaScreen()),
                  _buildDrawerItem(context, icon: Icons.insights_rounded, color: Colors.deepOrange, title: 'Dashboard de Ventas', pantalla: const DashboardVentasScreen()),
                  _buildDrawerSection('CLIENTES Y RUTAS'),
                  _buildDrawerItem(context, icon: Icons.person_add_rounded, color: Colors.pink, title: 'Crear Cliente', pantalla: const CrearClienteScreen()),
                  _buildDrawerItem(context, icon: Icons.alt_route_rounded, color: Colors.amber, title: 'Planificación de Ruta', pantalla: const PlanificacionRutaScreen()),
                  _buildDrawerSection('MUEBLES'),
                  _buildDrawerItem(context, icon: Icons.chair_alt_rounded, color: Colors.indigo, title: 'Listado de Muebles', pantalla: const ListadoCensoScreen()),
                  _buildDrawerItem(context, icon: Icons.add_box_rounded, color: Colors.teal, title: 'Crear Mueble', pantalla: const ClienteMuebleScreen()),
                ],

                if (rol == 'Vendedor') ...[
                  _buildDrawerSection('GESTIÓN Y RUTAS'),
                  _buildDrawerItem(context, icon: Icons.person_add_rounded, color: Colors.pink, title: 'Crear Cliente', pantalla: const CrearClienteScreen()),
                  _buildDrawerItem(context, icon: Icons.insights_rounded, color: Colors.deepOrange, title: 'Resumen por Territorio', pantalla: const ResumenTerritorioScreen()),
                  _buildDrawerItem(context, icon: Icons.alt_route_rounded, color: Colors.amber, title: 'Planificación de Ruta', pantalla: const PlanificacionRutaScreen()),
                  _buildDrawerItem(context, icon: Icons.insights_rounded, color: Colors.deepOrange, title: 'Dashboard de Ventas', pantalla: const DashboardVentasScreen()),
                  _buildDrawerSection('MUEBLES'),
                  _buildDrawerItem(context, icon: Icons.chair_alt_rounded, color: Colors.indigo, title: 'Listado de Muebles', pantalla: const ListadoCensoScreen()),
                  _buildDrawerItem(context, icon: Icons.add_box_rounded, color: Colors.teal, title: 'Crear Mueble', pantalla: const ClienteMuebleScreen()),
                ],

                if (rol == 'bodega' || rol == 'Inventario') ...[
                  _buildDrawerSection('BODEGA E INVENTARIO'),
                  _buildDrawerItem(context, icon: Icons.inventory_2_rounded, color: Colors.blue, title: 'Maestra Productos', pantalla: const MaestraScreen()),
                  _buildDrawerItem(context, icon: Icons.add_box_rounded, color: Colors.green, title: 'Ingresar Productos', pantalla: IngresarProductoScreen(usuarioId: userId)),
                  _buildDrawerItem(context, icon: Icons.list_alt_rounded, color: Colors.blueAccent, title: 'Productos en Bodega', pantalla: const ProductosListaScreen()),
                  _buildDrawerItem(context, icon: Icons.place_rounded, color: Colors.teal, title: 'Posiciones Disponibles', pantalla: const PosicionesScreen()),
                  _buildDrawerItem(context, icon: Icons.qr_code_2_rounded, color: Colors.purple, title: 'Escanear QR Pallet', pantalla: LectorQrScreen(usuarioId: userId, rolUsuario: rol)),
                ],

                if (rol == 'admin' || rol == 'Jefe') ...[
                  _buildDrawerSection('ADMINISTRACIÓN'),
                  _buildDrawerItem(context, icon: Icons.map_rounded, color: Colors.indigo, title: 'Territorios', pantalla: const TerritoriosScreen()),
                  _buildDrawerSection('BODEGA E INVENTARIO'),
                  _buildDrawerItem(context, icon: Icons.inventory_2_rounded, color: Colors.blue, title: 'Maestra Productos', pantalla: const MaestraScreen()),
                  _buildDrawerItem(context, icon: Icons.add_box_rounded, color: Colors.green, title: 'Ingresar Productos', pantalla: IngresarProductoScreen(usuarioId: userId)),
                  _buildDrawerItem(context, icon: Icons.list_alt_rounded, color: Colors.blueAccent, title: 'Productos en Bodega', pantalla: const ProductosListaScreen()),
                  _buildDrawerItem(context, icon: Icons.place_rounded, color: Colors.teal, title: 'Posiciones Disponibles', pantalla: const PosicionesScreen()),
                  _buildDrawerItem(context, icon: Icons.qr_code_2_rounded, color: Colors.purple, title: 'Escanear QR Pallet', pantalla: LectorQrScreen(usuarioId: userId, rolUsuario: rol)),
                  _buildDrawerSection('CLIENTES E INDICADORES'),
                  _buildDrawerItem(context, icon: Icons.person_add_rounded, color: Colors.pink, title: 'Crear Cliente', pantalla: const CrearClienteScreen()),
                  _buildDrawerItem(context, icon: Icons.auto_graph_rounded, color: Colors.deepPurple, title: 'Dashboard Infaltables', pantalla: const DashboardInfaltablesScreen()),
                  _buildDrawerItem(context, icon: Icons.storefront_rounded, color: Colors.deepPurpleAccent, title: 'Dashboard PDV', pantalla: const DashboardPdvScreen()),
                  _buildDrawerItem(context, icon: Icons.insights_rounded, color: Colors.deepOrange, title: 'Resumen por Territorio', pantalla: const ResumenTerritorioScreen()),
                  _buildDrawerItem(context, icon: Icons.insights_rounded, color: Colors.deepOrange, title: 'Dashboard de Ventas', pantalla: const DashboardVentasScreen()),
                  _buildDrawerSection('RUTAS Y MUEBLES'),
                  _buildDrawerItem(context, icon: Icons.alt_route_rounded, color: Colors.amber, title: 'Planificación de Ruta', pantalla: const PlanificacionRutaScreen()),
                  _buildDrawerItem(context, icon: Icons.chair_alt_rounded, color: Colors.indigo, title: 'Listado de Muebles', pantalla: const ListadoCensoScreen()),
                  _buildDrawerItem(context, icon: Icons.add_box_rounded, color: Colors.teal, title: 'Crear Mueble', pantalla: const ClienteMuebleScreen()),
                ],
              ],
            ),
          ),

          // BOTÓN CERRAR SESIÓN
          SafeArea(
            top: false, 
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
              child: InkWell(
                onTap: () => _cerrarSesion(context), 
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFECACA))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 20),
                      SizedBox(width: 8),
                      Text("Cerrar Sesión", style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required Color color, required String title, required Widget? pantalla}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155), fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
        onTap: () {
          Navigator.pop(context); 
          if (pantalla != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Módulo $title en desarrollo', style: const TextStyle(fontWeight: FontWeight.bold))));
          }
        },
        hoverColor: const Color(0xFFF1F5F9),
      ),
    );
  }
}