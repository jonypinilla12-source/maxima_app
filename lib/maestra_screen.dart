import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MaestraScreen extends StatefulWidget {
  const MaestraScreen({super.key});

  @override
  State<MaestraScreen> createState() => _MaestraScreenState();
}

class _MaestraScreenState extends State<MaestraScreen> {
  // --- VARIABLE CENTRALIZADA PARA LA URL ---
  //final String baseUrl = 'http://localhost/inventariomaxima'; // Para pruebas en local
  final String baseUrl = 'https://app.distribuidoramaxima.cl'; // Para producción

  List productos = [];
  List categorias = [];
  bool isLoading = true;
  String searchQuery = "";

  // Paleta de colores dinámica para las tarjetas
  final List<List<Color>> colorPalettes = [
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo - Púrpura
    [const Color(0xFF3B82F6), const Color(0xFF06B6D4)], // Azul - Cyan
    [const Color(0xFF10B981), const Color(0xFF059669)], // Esmeralda
    [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Ámbar
    [const Color(0xFFEC4899), const Color(0xFFF43F5E)], // Rosa - Coral
  ];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() { isLoading = true; });
    await Future.wait([cargarProductos(), cargarCategorias()]);
    setState(() { isLoading = false; });
  }

  Future<void> cargarProductos() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/api/maestra_listar.php'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { productos = data['data']; });
        }
      }
    } catch (e) {
      print("Error al cargar productos: $e");
    }
  }

  Future<void> cargarCategorias() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/api/categorias_listar.php'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { categorias = data['data']; });
        }
      }
    } catch (e) {
      print("Error al cargar categorías: $e");
    }
  }

  // ELIMINAR PRODUCTO CON ALERTA DE CONFIRMACIÓN
  void confirmarEliminacion(String id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas eliminar el producto "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              var res = await http.post(Uri.parse('$baseUrl/api/maestra_eliminar.php'), body: {'maestra_id': id});
              var data = json.decode(res.body);
              if (data['ok'] == true) {
                cargarProductos();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.green));
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // VENTANA FLOTANTE MODERNA PARA CREAR O MODIFICAR
  void abrirFormulario({Map? producto}) {
    TextEditingController codBarraController = TextEditingController(text: producto != null ? producto['maestra_codigobarra'] ?? '' : '');
    TextEditingController codigoController = TextEditingController(text: producto != null ? producto['maestra_codigo'] ?? '' : '');
    TextEditingController nombreController = TextEditingController(text: producto != null ? producto['maestra_nombre'] ?? '' : '');
    TextEditingController tipoController = TextEditingController(text: producto != null ? producto['maestra_tipo'] ?? '' : '');
    TextEditingController medidaController = TextEditingController(text: producto != null ? producto['maestra_medida'] ?? '' : '');

    String? selectedCategoriaId;
    if (producto != null && producto['categoria_id'] != null) {
      String idStr = producto['categoria_id'].toString();
      bool existe = categorias.any((c) => c['categoria_id'].toString() == idStr);
      selectedCategoriaId = existe ? idStr : null;
    }
    if (selectedCategoriaId == null && categorias.isNotEmpty) {
      selectedCategoriaId = categorias[0]['categoria_id'].toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 25,
            top: 25, left: 25, right: 25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
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
                          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF6366F1), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(producto == null ? 'Nuevo Producto' : 'Modificar Producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 25),

                _buildTextField('Código de Barra', codBarraController, Icons.qr_code_rounded),
                const SizedBox(height: 14),
                _buildTextField('Código Interno', codigoController, Icons.code_rounded),
                const SizedBox(height: 14),
                _buildTextField('Nombre del Producto', nombreController, Icons.shopping_bag_outlined),
                const SizedBox(height: 14),
                _buildTextField('Tipo', tipoController, Icons.category_outlined),
                const SizedBox(height: 14),
                _buildTextField('Medida', medidaController, Icons.straighten_rounded),
                const SizedBox(height: 16),

                // Selector de Categoría
                const Text('CATEGORÍA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: categorias.isEmpty
                      ? const Padding(padding: EdgeInsets.all(12), child: Text('Cargando categorías...', style: TextStyle(color: Colors.grey)))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategoriaId,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
                            items: categorias.map<DropdownMenuItem<String>>((c) {
                              return DropdownMenuItem<String>(
                                value: c['categoria_id'].toString(),
                                child: Text(c['categoria_nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedCategoriaId = val),
                          ),
                        ),
                ),
                const SizedBox(height: 25),

                // Botón Guardar con Degradado
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (nombreController.text.trim().isEmpty || codigoController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código y Nombre son obligatorios'), backgroundColor: Colors.redAccent));
                        return;
                      }

                      String id = producto != null ? producto['maestra_id'].toString() : '';

                      var res = await http.post(Uri.parse('$baseUrl/api/maestra_guardar.php'), body: {
                        'maestra_id': id,
                        'codigobarra': codBarraController.text.trim(),
                        'codigo': codigoController.text.trim(),
                        'nombre': nombreController.text.trim(),
                        'tipo': tipoController.text.trim(),
                        'medida': medidaController.text.trim(),
                        'categoria': selectedCategoriaId!,
                      });

                      var data = json.decode(res.body);
                      if (data['ok'] == true) {
                        Navigator.pop(context);
                        cargarProductos();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: const Color(0xFF10B981)));
                      }
                    },
                    child: const Text('Guardar Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var listaFiltrada = productos.where((p) {
      var nombre = (p['maestra_nombre'] ?? '').toLowerCase();
      var codigo = (p['maestra_codigo'] ?? '').toLowerCase();
      var categoria = (p['categoria_nombre'] ?? '').toLowerCase();
      return nombre.contains(searchQuery.toLowerCase()) || codigo.contains(searchQuery.toLowerCase()) || categoria.contains(searchQuery.toLowerCase());
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
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 75),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Maestra de Productos',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniBadge(Icons.inventory_2_rounded, '${productos.length} Productos'),
                          const SizedBox(width: 10),
                          _buildMiniBadge(Icons.category_rounded, '${categorias.length} Categorías'),
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, código o categoría...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6366F1)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
          ),

          // LISTADO DE PRODUCTOS
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
                            Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('No hay productos registrados', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
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
                            String nombreCat = p['categoria_nombre'] ?? 'Sin categoría';
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: coloresCard),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.inventory_2, color: Colors.white, size: 22),
                                    ),
                                    title: Text(
                                      p['maestra_nombre'] ?? '',
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
                                            child: Text(
                                              'Cód: ${p['maestra_codigo']} | $nombreCat',
                                              style: TextStyle(color: coloresCard[0], fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                          child: IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF475569), size: 20),
                                            onPressed: () => abrirFormulario(producto: p),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                            onPressed: () => confirmarEliminacion(p['maestra_id'].toString(), p['maestra_nombre']),
                                          ),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          onPressed: () => abrirFormulario(),
          icon: const Icon(Icons.add_box_rounded),
          label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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