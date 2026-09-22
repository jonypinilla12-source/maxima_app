import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; 

class PlanificacionRutaScreen extends StatefulWidget {
  const PlanificacionRutaScreen({Key? key}) : super(key: key);

  @override
  State<PlanificacionRutaScreen> createState() => _PlanificacionRutaScreenState();
}

class _PlanificacionRutaScreenState extends State<PlanificacionRutaScreen> {
  final Color colorPrimario = const Color(0xFF6366F1);
  final Color colorAzulBuscador = const Color(0xFF3B82F6);
  final Color bgColor = const Color(0xFFF8FAFC);

  final TextEditingController territorioController = TextEditingController();
  final MapController mapController = MapController();
  
  bool isLoading = false;
  List<dynamic> clientesRuta = [];
  String mensajeEstado = "Ingresa un territorio y presiona Consultar.";
  String? errorTerritorio;

  String diaSeleccionado = 'Lunes';
  final List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  LatLng? miUbicacion;

  //final String baseUrl = 'http://localhost/inventariomaxima'; 
  final String baseUrl = 'http://app.distribuidoramaxima.cl';

  @override
  void initState() {
    super.initState();
    _obtenerMiUbicacion();
  }

  Future<void> _obtenerMiUbicacion() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        miUbicacion = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Error GPS: $e");
    }
  }

  Future<void> _buscarRuta() async {
    if (territorioController.text.trim().isEmpty) {
      setState(() => errorTerritorio = "Por favor ingresa un código de territorio.");
      return;
    }

    setState(() {
      isLoading = true;
      errorTerritorio = null;
      mensajeEstado = "Buscando clientes activos y calculando distancias...";
      clientesRuta = [];
    });

    try {
      double lat = miUbicacion?.latitude ?? 0;
      double lng = miUbicacion?.longitude ?? 0;
      String territorio = territorioController.text.trim();

      final url = Uri.parse('$baseUrl/api/api_planificacion_ruta.php?lat=$lat&lng=$lng&territorio_id=$territorio&dia=$diaSeleccionado');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['ok']) {
          setState(() {
            clientesRuta = data['data'];
          });
          if (clientesRuta.isNotEmpty && miUbicacion != null) {
            mapController.move(miUbicacion!, 13.0);
          }
        } else {
          setState(() => errorTerritorio = data['msg']);
        }
      }
    } catch (e) {
      setState(() => errorTerritorio = "Error de conexión al servidor.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _centrarMapaEnCliente(double lat, double lng) {
    mapController.move(LatLng(lat, lng), 17.0); 
  }

  Future<void> _abrirNavegacion(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa.'), backgroundColor: Colors.red));
    }
  }

  // --- WIDGET DINÁMICO PARA PINTAR CHIPS ---
  Widget _buildInfaltablesChips(String dataStr, Color borderColor, Color textColor) {
    if (dataStr.trim().isEmpty) return const SizedBox.shrink();
    
    List<String> items = dataStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor)
        ),
        child: Text(
          item, 
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textColor)
        ),
      )).toList(),
    );
  }

  // --- MODAL AMPLIADO CON MÁS INFO Y BOTÓN DE RUTA ---
  void _mostrarInfoClienteModal(dynamic cliente, double distancia) {
    bool alertaCapri = cliente['alerta_capri'] == true;
    String nombreCliente = cliente['cliente_razonsocial'] ?? cliente['cliente_razonlocal'] ?? 'Cliente sin nombre';
    double clLat = double.tryParse(cliente['cliente_latitud']?.toString() ?? '0') ?? 0;
    double clLng = double.tryParse(cliente['cliente_longitud']?.toString() ?? '0') ?? 0;

    // Capturamos los dos bloques de texto que manda PHP
    String faltantes = cliente['faltantes_str'] ?? '';
    String comprados = cliente['comprados_str'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: SafeArea(
            // SOLUCIÓN AL ERROR DE DESBORDAMIENTO (OVERFLOW)
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF3B82F6), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombreCliente, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text("${distancia.toStringAsFixed(1)} km de distancia", style: TextStyle(color: colorPrimario, fontWeight: FontWeight.w800, fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(child: _buildInfoDato("RUT", cliente['cliente_rut'] ?? '-')),
                      Expanded(child: _buildInfoDato("LOCAL", "Local ${cliente['cliente_local'] ?? '1'}")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoDato("DIRECCIÓN", cliente['cliente_direccion'] ?? 'Sin dirección', icon: Icons.location_on_rounded),
                  const SizedBox(height: 16),
                  _buildInfoDato("COMUNA", cliente['cliente_comuna'] ?? 'Sin comuna', icon: Icons.map_rounded),
                  
                  // ==========================================
                  // BLOQUE 1: INFALTABLES PENDIENTES (Naranjo)
                  // ==========================================
                  if (faltantes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFED7AA))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
                              SizedBox(width: 8),
                              Text("INFALTABLES PENDIENTES", style: TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w900, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfaltablesChips(faltantes, const Color(0xFFFED7AA), const Color(0xFFC2410C)),
                        ],
                      ),
                    ),
                  ],

                  // ==========================================
                  // BLOQUE 2: INFALTABLES OK (Verde)
                  // ==========================================
                  if (comprados.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFA7F3D0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                              SizedBox(width: 8),
                              Text("INFALTABLES OK", style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfaltablesChips(comprados, const Color(0xFFA7F3D0), const Color(0xFF047857)),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // --- BOTONES DE ACCIÓN ---
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFFCBD5E1))),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cerrar", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size(0, 50), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                          label: const Text("Cómo Llegar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            if (clLat != 0 && clLng != 0) {
                              _abrirNavegacion(clLat, clLng);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente sin coordenadas válidas'), backgroundColor: Colors.orange));
                            }
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildInfoDato(String label, String valor, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: const Color(0xFF94A3B8)), const SizedBox(width: 4)],
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> marcadoresMapa = [];
    
    if (miUbicacion != null) {
      marcadoresMapa.add(
        Marker(
          point: miUbicacion!,
          width: 120, height: 70,
          alignment: Alignment.topCenter, 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
                child: const Text("Usted está aquí", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF3B82F6), size: 38),
            ],
          ),
        )
      );
    }

    for (var c in clientesRuta) {
      double? lat = double.tryParse(c['cliente_latitud']?.toString() ?? '');
      double? lng = double.tryParse(c['cliente_longitud']?.toString() ?? '');
      double distancia = double.tryParse(c['distancia_km']?.toString() ?? '0') ?? 0.0;
      
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        marcadoresMapa.add(
          Marker(
            point: LatLng(lat, lng),
            width: 50, height: 50,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () => _mostrarInfoClienteModal(c, distancia),
              child: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 45),
            ),
          )
        );
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Distribuidora Máxima © 2026 | Versión 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8), 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Desarrollado por Jonathan Pinilla Orellana',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFCBD5E1), 
                  fontSize: 10, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(title: const Text('Ruta Inteligente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E293B), elevation: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TERRITORIO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 45,
                            child: TextField(
                              controller: territorioController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                hintText: "Ej. 72016", contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorAzulBuscador, width: 2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("DÍA DE RUTA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Container(
                            height: 45, padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFCBD5E1))),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: diaSeleccionado, isExpanded: true,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 14),
                                items: diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => diaSeleccionado = val);
                                    if (territorioController.text.isNotEmpty) _buscarRuta();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 45,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _buscarRuta,
                    icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                    label: Text(isLoading ? "Calculando..." : "Ver Ruta en Mapa", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(backgroundColor: colorAzulBuscador, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                if (errorTerritorio != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(errorTerritorio!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12))),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: miUbicacion ?? const LatLng(-34.98, -71.23), 
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.maxima.app'),
                    MarkerLayer(markers: marcadoresMapa),
                  ],
                ),
                
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoomInBtn',
                        backgroundColor: Colors.white,
                        onPressed: () => mapController.move(mapController.camera.center, mapController.camera.zoom + 1),
                        child: const Icon(Icons.add, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoomOutBtn',
                        backgroundColor: Colors.white,
                        onPressed: () => mapController.move(mapController.camera.center, mapController.camera.zoom - 1),
                        child: const Icon(Icons.remove, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),

                if (clientesRuta.isNotEmpty)
                  DraggableScrollableSheet(
                    initialChildSize: 0.35, 
                    minChildSize: 0.22,     
                    maxChildSize: 0.85,     
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -4))]
                        ),
                        child: Column(
                          children: [
                            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 8),
                                  Text("${clientesRuta.length} Clientes Activos", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController, 
                                padding: const EdgeInsets.only(top: 8, bottom: 20),
                                itemCount: clientesRuta.length,
                                itemBuilder: (context, index) {
                                  final cliente = clientesRuta[index];
                                  bool alertaCapri = cliente['alerta_capri'] == true;
                                  double distancia = double.tryParse(cliente['distancia_km']?.toString() ?? '0') ?? 0.0;
                                  String nombre = cliente['cliente_razonsocial'] ?? cliente['cliente_razonlocal'] ?? 'Sin nombre';
                                  double clLat = double.tryParse(cliente['cliente_latitud']?.toString() ?? '0') ?? 0;
                                  double clLng = double.tryParse(cliente['cliente_longitud']?.toString() ?? '0') ?? 0;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: alertaCapri ? Colors.orange.withOpacity(0.5) : const Color(0xFFE2E8F0)),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(backgroundColor: alertaCapri ? const Color(0xFFFFF7ED) : const Color(0xFFEEF2FF), child: Icon(alertaCapri ? Icons.warning_rounded : Icons.store, color: alertaCapri ? Colors.orange : colorPrimario)),
                                      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text("${distancia.toStringAsFixed(1)} km • ${cliente['cliente_direccion'] ?? ''}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.my_location_rounded, color: Color(0xFF3B82F6)),
                                        tooltip: "Ver en el mapa",
                                        onPressed: () {
                                          if (clLat != 0 && clLng != 0) _centrarMapaEnCliente(clLat, clLng);
                                        },
                                      ),
                                      onTap: () => _mostrarInfoClienteModal(cliente, distancia),
                                    ),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}