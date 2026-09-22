import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PosicionesScreen extends StatefulWidget {
  const PosicionesScreen({super.key});

  @override
  State<PosicionesScreen> createState() => _PosicionesScreenState();
}

class _PosicionesScreenState extends State<PosicionesScreen> {
  // --- VARIABLE CENTRALIZADA PARA LA URL ---
  //final String baseUrl = 'https://localhost/inventariomaxima'; // Para pruebas en local
  final String baseUrl = 'https://app.distribuidoramaxima.cl';

  List posiciones = [];
  bool isLoading = true;
  String searchQuery = "";

  final List<List<Color>> colorPalettes = [
    [const Color(0xFF10B981), const Color(0xFF059669)], // Esmeralda (Ideal para disponible)
    [const Color(0xFF3B82F6), const Color(0xFF06B6D4)], // Azul - Cyan
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo - Púrpura
    [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Ámbar
  ];

  @override
  void initState() {
    super.initState();
    cargarPosiciones();
  }

  Future<void> cargarPosiciones() async {
    setState(() { isLoading = true; });
    try {
      var response = await http.get(Uri.parse('$baseUrl/api/posiciones_listar.php'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { posiciones = data['data']; });
        }
      }
    } catch (e) {
      print("Error al cargar posiciones: $e");
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    var listaFiltrada = posiciones.where((pos) {
      var nombre = (pos['posicion_nombre'] ?? '').toLowerCase();
      var fila = (pos['posicion_fila'] ?? '').toLowerCase();
      var sector = (pos['posicion_sector'] ?? '').toLowerCase();
      return nombre.contains(searchQuery.toLowerCase()) || 
             fila.contains(searchQuery.toLowerCase()) || 
             sector.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // ==========================================
      // AQUÍ VA EL FOOTER INFORMATIVO CON CRÉDITOS
      // ==========================================
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
                  color: Color(0xFFCBD5E1), // Un gris un poco más suave
                  fontSize: 10, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // AppBar con Degradado Moderno
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF10B981),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 65),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Posiciones Disponibles',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${posiciones.length} espacios libres en bodega',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Buscador Flotante
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, fila o sector...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF10B981)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
          ),

          // Listado de Posiciones
          isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                )
              : listaFiltrada.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_outlined, size: 70, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('No hay posiciones disponibles', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            var pos = listaFiltrada[index];
                            var coloresCard = colorPalettes[index % colorPalettes.length];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: coloresCard[0], width: 6)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: coloresCard),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                                    ),
                                    title: Text(
                                      'Posición: ${pos['posicion_nombre']}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Fila: ${pos['posicion_fila']}  |  Sector: ${pos['posicion_sector']}',
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Disponible',
                                        style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: listaFiltrada.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}