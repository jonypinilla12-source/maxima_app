import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TerritoriosScreen extends StatefulWidget {
  const TerritoriosScreen({super.key});

  @override
  State<TerritoriosScreen> createState() => _TerritoriosScreenState();
}

class _TerritoriosScreenState extends State<TerritoriosScreen> {
  // --- VARIABLE CENTRALIZADA PARA LA URL ---
  //final String baseUrl = 'http://localhost/inventariomaxima'; // Para pruebas en local
  final String baseUrl = 'https://app.distribuidoramaxima.cl'; // Para producción

  List territorios = [];
  List zonas = [];
  bool isLoading = true;
  String searchQuery = "";

  // Paleta de colores segura
  final List<List<Color>> colorPalettes = [
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
    [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
    [const Color(0xFF10B981), const Color(0xFF059669)],
    [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
  ];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() { isLoading = true; });
    await Future.wait([cargarTerritorios(), cargarZonas()]);
    setState(() { isLoading = false; });
  }

  Future<void> cargarTerritorios() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/api/territorios_listar.php'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { territorios = data['data']; });
        }
      }
    } catch (e) {
      print("Error al cargar territorios: $e");
    }
  }

  Future<void> cargarZonas() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/api/zonas_listar.php'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { zonas = data['data']; });
        }
      }
    } catch (e) {
      print("Error al cargar zonas: $e");
    }
  }

  void abrirFormulario({Map? territorio}) {
    TextEditingController nombreController = TextEditingController(
      text: territorio != null ? (territorio['territorio_nombre'] ?? '') : ''
    );

    String? selectedZonaId;
    if (territorio != null && territorio['zona_id'] != null) {
      String idStr = territorio['zona_id'].toString();
      bool existe = zonas.any((z) => z['zona_id'].toString() == idStr);
      selectedZonaId = existe ? idStr : null;
    }

    if (selectedZonaId == null && zonas.isNotEmpty) {
      selectedZonaId = zonas[0]['zona_id'].toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 25,
            top: 25,
            left: 25,
            right: 25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior decorativa
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.edit_location_alt, color: Color(0xFF6366F1), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        territorio == null ? 'Nuevo Territorio' : 'Editar Territorio',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Campo Nombre
              const Text('NOMBRE DEL TERRITORIO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
              const SizedBox(height: 8),
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej. Ruta Centro 1',
                  prefixIcon: const Icon(Icons.location_city, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                ),
              ),
              const SizedBox(height: 18),

              // Selector Zona
              const Text('ZONA ASIGNADA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: zonas.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('Cargando zonas...', style: TextStyle(color: Colors.redAccent)),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedZonaId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
                          items: zonas.map<DropdownMenuItem<String>>((z) {
                            return DropdownMenuItem<String>(
                              value: z['zona_id'].toString(),
                              child: Row(
                                children: [
                                  const Icon(Icons.map_outlined, size: 18, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  Text(z['zona_nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() { selectedZonaId = value; });
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 28),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (nombreController.text.trim().isEmpty || selectedZonaId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }

                          String id = territorio != null ? territorio['territorio_id'].toString() : '';

                          var url = Uri.parse('$baseUrl/api/territorios_guardar.php');
                          var res = await http.post(url, body: {
                            'territorio_id': id,
                            'territorio_nombre': nombreController.text.trim(),
                            'zona_id': selectedZonaId!,
                          });

                          var data = json.decode(res.body);
                          if (data['ok'] == true) {
                            Navigator.pop(context);
                            cargarTerritorios();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(data['msg']),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var listaFiltrada = territorios.where((t) {
      var nombre = (t['territorio_nombre'] ?? '').toLowerCase();
      var zona = (t['zona_nombre'] ?? '').toLowerCase();
      return nombre.contains(searchQuery.toLowerCase()) || zona.contains(searchQuery.toLowerCase());
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
          // APP BAR CON HEADER MODERNO Y GRADIENTE
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 75),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Territorios y Cobertura',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniBadge(Icons.route, '${territorios.length} Rutas'),
                          const SizedBox(width: 10),
                          _buildMiniBadge(Icons.layers, '${zonas.length} Zonas'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BARRA DE BÚSQUEDA FLOTANTE
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() { searchQuery = value; }),
                  decoration: const InputDecoration(
                    hintText: 'Buscar territorio o zona...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6366F1)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
          ),

          // LISTADO DE TARJETAS
          isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                )
              : listaFiltrada.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 70, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('No hay territorios que mostrar', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            var t = listaFiltrada[index];
                            String nombreZona = t['zona_nombre'] ?? 'Sin zona';
                            var coloresCard = colorPalettes[index % colorPalettes.length];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: coloresCard[0], width: 6),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: coloresCard),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                                    ),
                                    title: Text(
                                      t['territorio_nombre'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: coloresCard[0].withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.layers_outlined, size: 12, color: coloresCard[0]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  nombreZona,
                                                  style: TextStyle(color: coloresCard[0], fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569), size: 20),
                                        onPressed: () => abrirFormulario(territorio: t),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          onPressed: () => abrirFormulario(),
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Nuevo Territorio', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}