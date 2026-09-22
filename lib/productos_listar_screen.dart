import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductosListaScreen extends StatefulWidget {
  const ProductosListaScreen({super.key});

  @override
  State<ProductosListaScreen> createState() => _ProductosListaScreenState();
}

class _ProductosListaScreenState extends State<ProductosListaScreen> {
  // --- VARIABLE CENTRALIZADA PARA LA URL ---
  //final String baseUrl = 'http://localhost/inventariomaxima'; // Para pruebas en local
  final String baseUrl = 'https://app.distribuidoramaxima.cl'; // Para producción

  List productos = [];
  bool isLoading = true;
  String searchQuery = "";

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
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    setState(() { isLoading = true; });
    try {
      var response = await http.get(Uri.parse('$baseUrl/api/productos_listar.php'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { productos = data['data']; });
        }
      }
    } catch (e) {
      print("Error al cargar productos: $e");
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    var listaFiltrada = productos.where((p) {
      var nombre = (p['maestra_nombre'] ?? '').toLowerCase();
      var codigo = (p['maestra_codigo'] ?? '').toLowerCase();
      var categoria = (p['categoria_nombre'] ?? '').toLowerCase();
      return nombre.contains(searchQuery.toLowerCase()) || 
             codigo.contains(searchQuery.toLowerCase()) || 
             categoria.contains(searchQuery.toLowerCase());
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
          // AppBar con Degradado
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
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
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 65),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Inventario en Bodega',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${productos.length} productos registrados y ordenados por vencimiento',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Buscador
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
                    hintText: 'Buscar por código, nombre o categoría...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6366F1)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
          ),

          // Lista de Inventario
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
                            Icon(Icons.inventory_outlined, size: 70, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('No hay productos en bodega', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            var p = listaFiltrada[index];
                            var coloresCard = colorPalettes[index % colorPalettes.length];

                            // Lógica de cálculo de vencimiento igual que en PHP
                            DateTime fechaVenc = DateTime.parse(p['producto_vencimiento']);
                            DateTime hoy = DateTime.now();
                            int diasRestantes = fechaVenc.difference(hoy).inDays;

                            Color badgeColor;
                            Color badgeBg;
                            String textoVenc;

                            if (diasRestantes < 0) {
                              badgeColor = const Color(0xFFB91C1C);
                              badgeBg = const Color(0xFFFEE2E2);
                              textoVenc = 'Vencido';
                            } else if (diasRestantes <= 30) {
                              badgeColor = const Color(0xFF92400E);
                              badgeBg = const Color(0xFFFEF3C7);
                              textoVenc = '$diasRestantes días';
                            } else {
                              badgeColor = const Color(0xFF166534);
                              badgeBg = const Color(0xFFDCFCE7);
                              textoVenc = '$diasRestantes días';
                            }

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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                p['maestra_nombre'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                textoVenc,
                                                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.code, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text('Cód: ${p['maestra_codigo']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                                            const SizedBox(width: 15),
                                            Icon(Icons.category, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text('${p['categoria_nombre']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.indigo),
                                                const SizedBox(width: 4),
                                                Text('Cajas: ${p['producto_cantidadCajas']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13)),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.place_outlined, size: 14, color: Colors.teal),
                                                const SizedBox(width: 4),
                                                Text('Pos: ${p['posicion_nombre']} (${p['posicion_sector']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 13)),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text('${p['producto_vencimiento']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
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