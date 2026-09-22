import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auditar_mueble_screen.dart';

class ListadoCensoScreen extends StatefulWidget {
  const ListadoCensoScreen({Key? key}) : super(key: key);

  @override
  _ListadoCensoScreenState createState() => _ListadoCensoScreenState();
}

class _ListadoCensoScreenState extends State<ListadoCensoScreen> {
  // --- COLORES IDÉNTICOS AL RESUMEN TERRITORIO ---
  final Color colorPrimario = const Color(0xFF6366F1); 
  final Color colorAzulBuscador = const Color(0xFF3B82F6); 

  List<dynamic> muebles = [];
  Map<String, dynamic> kpis = {
    'total': 0, 'censados': 0, 'faltantes': 0, 'porcentaje': 0.0
  };
  
  bool isLoading = false; // Comienza en false para no mostrar el spinner al entrar
  bool isInitialState = true; // Nueva variable para saber si el usuario aún no busca nada
  TextEditingController searchController = TextEditingController();

  // --- VARIABLES DE FILTROS ---
  String? supervisorId;
  String? vendedorId;
  String? visitaId;
  String estadoCenso = '';
  String estadoCliente = '';

  List<dynamic> supervisores = [];
  List<dynamic> territorios = [];
  List<dynamic> diasVisita = [];

  // IP o Dominio base
  //final String baseUrl = 'http://localhost/inventariomaxima'; 
  final String baseUrl = 'http://app.distribuidoramaxima.cl';

  @override
  void initState() {
    super.initState();
    _cargarSupervisores();
    // Eliminamos _cargarDatos() de aquí para que no cargue todo al entrar
  }

  // --- LLAMADAS A LA API ---
  Future<void> _cargarSupervisores() async {
    try {
      final url = Uri.parse('$baseUrl/api/api_get_supervisores.php');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() => supervisores = json.decode(res.body));
      }
    } catch (e) {
      debugPrint("Error cargando supervisores: $e");
    }
  }

  Future<void> _cargarTerritorios(String supId) async {
    try {
      final url = Uri.parse('$baseUrl/api/api_get_territorios_censo.php');
      final res = await http.post(url, body: {'supervisor_id': supId});
      if (res.statusCode == 200) {
        setState(() {
          territorios = json.decode(res.body);
          vendedorId = null; 
          visitaId = null;
          diasVisita = [];
        });
      }
    } catch (e) {
      debugPrint("Error cargando territorios: $e");
    }
  }

  Future<void> _cargarDias(String venId) async {
    try {
      final url = Uri.parse('$baseUrl/api/api_get_dias_censo.php');
      final res = await http.post(url, body: {'vendedor_id': venId});
      if (res.statusCode == 200) {
        setState(() {
          diasVisita = json.decode(res.body);
          visitaId = null;
        });
      }
    } catch (e) {
      debugPrint("Error cargando días: $e");
    }
  }

  Future<void> _cargarDatos({String rut = ''}) async {
    setState(() {
      isLoading = true;
      isInitialState = false; // Ocultamos el mensaje inicial porque ya buscó
    });
    
    final url = Uri.parse('$baseUrl/api/api_listado_censo.php');
    
    try {
      final response = await http.post(url, body: {
        'rut': rut,
        'supervisor_id': supervisorId ?? '',
        'vendedor_id': vendedorId ?? '',
        'visita_id': visitaId ?? '',
        'estado_censo': estadoCenso,
        'cliente_estado': estadoCliente,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          setState(() {
            muebles = data['data'];
            kpis = data['kpis'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error API: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        physics: const BouncingScrollPhysics(),
        slivers: [
          // APP BAR
          SliverAppBar(
            expandedHeight: 140, floating: false, pinned: true, backgroundColor: colorPrimario, elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorPrimario, const Color(0xFF8B5CF6)]),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 45, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('Censo de Muebles', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900), maxLines: 1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Visualiza los muebles instalados y audita el estado actual en terreno.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // DASHBOARD SUPERIOR DE KPIS (Oculto si no se ha buscado)
          if (!isInitialState)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildKpiBox("Total", kpis['total'].toString(), const Color(0xFF3B82F6), const Color(0xFFEFF6FF))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildKpiBox("Censados", kpis['censados'].toString(), const Color(0xFF10B981), const Color(0xFFD1FAE5))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildKpiBox("Faltan", kpis['faltantes'].toString(), const Color(0xFFEF4444), const Color(0xFFFEE2E2))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Progreso de Censo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                          Text('${kpis['porcentaje']}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: colorPrimario)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: (kpis['porcentaje'] as num) / 100,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(colorPrimario),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // TARJETA DE FILTROS AVANZADOS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 6)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.tune_rounded, color: Color(0xFF3B82F6)),
                    title: const Text("Filtros de Búsqueda", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 14)),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      _buildLabel("SUPERVISOR"),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration(),
                        value: supervisorId,
                        hint: const Text("Todos", style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("Todos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                          ...supervisores.map((s) => DropdownMenuItem(value: s['supervisor_id'].toString(), child: Text(s['supervisor_nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))))
                        ],
                        onChanged: (val) {
                          setState(() => supervisorId = val);
                          if (val != null) _cargarTerritorios(val);
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildLabel("TERRITORIO"),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration(),
                        value: vendedorId,
                        hint: const Text("Seleccione supervisor...", style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("Todos los territorios", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                          ...territorios.map((t) => DropdownMenuItem(value: t['vendedor_id'].toString(), child: Text(t['territorio_nombre'] ?? 'Sin territorio', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))))
                        ],
                        onChanged: territorios.isEmpty ? null : (val) {
                          setState(() => vendedorId = val);
                          if (val != null) _cargarDias(val);
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildLabel("DÍA VISITA"),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration(),
                        value: visitaId,
                        hint: const Text("Seleccione territorio...", style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("Todos los días", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                          ...diasVisita.map((d) => DropdownMenuItem(value: d['visita_id'].toString(), child: Text(d['visita_nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))))
                        ],
                        onChanged: diasVisita.isEmpty ? null : (val) => setState(() => visitaId = val),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("ESTADO CENSO"),
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration(),
                                  value: estadoCenso,
                                  items: const [
                                    DropdownMenuItem(value: "", child: Text("Todos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: "1", child: Text("Censados", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: "0", child: Text("Pendientes", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                  ],
                                  onChanged: (val) => setState(() => estadoCenso = val!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("ESTADO CLIENTE"),
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration(),
                                  value: estadoCliente,
                                  items: const [
                                    DropdownMenuItem(value: "", child: Text("Todos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: "1", child: Text("Activos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: "0", child: Text("Inactivos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                  ],
                                  onChanged: (val) => setState(() => estadoCliente = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.filter_list_rounded, size: 18, color: Colors.white),
                          label: const Text("Aplicar Filtros", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorAzulBuscador,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _cargarDatos(rut: searchController.text),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BARRA DE BÚSQUEDA RÁPIDA (POR RUT)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Búsqueda rápida por RUT...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: colorAzulBuscador, width: 2)),
                ),
                onSubmitted: (value) => _cargarDatos(rut: value),
              ),
            ),
          ),

          // LÓGICA DE ESTADOS Y LISTADO
          if (isInitialState)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildInitialState(),
            )
          else if (isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (muebles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMuebleCard(muebles[index]),
                  childCount: muebles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorAzulBuscador, width: 2)),
    );
  }

  Widget _buildKpiBox(String title, String value, Color colorText, Color colorBg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorText.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colorText, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorText)),
        ],
      ),
    );
  }

  // --- WIDGET: ESTADO INICIAL ---
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: colorAzulBuscador.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.manage_search_rounded, size: 60, color: colorAzulBuscador.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text('Realiza una búsqueda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('Aplica filtros o ingresa un RUT para cargar la lista.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // --- WIDGET: ESTADO VACÍO ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_rounded, size: 60, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text('No hay resultados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('No se encontraron muebles con los filtros seleccionados.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // --- TARJETA DE MUEBLE (ESTILO WEB MODERNO) ---
  Widget _buildMuebleCard(dynamic m) {
    bool isCensado = m['estado_censo'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(m['clientemueble_qr'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCensado ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCensado ? Icons.check_circle_rounded : Icons.pending_actions_rounded, size: 12, color: isCensado ? const Color(0xFF065F46) : const Color(0xFF991B1B)),
                    const SizedBox(width: 4),
                    Text(isCensado ? 'CENSADO' : 'PENDIENTE', style: TextStyle(color: isCensado ? const Color(0xFF065F46) : const Color(0xFF991B1B), fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(m['tipomueble_nombre'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['cliente_razonsocial'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text("RUT: ${m['cliente_rut']} • Local ${m['cliente_local'] ?? '1'}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(m['cliente_direccion'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // BOTÓN AUDITAR IDÉNTICO A LA WEB
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCensado ? const Color(0xFFF8FAFC) : colorPrimario,
                foregroundColor: isCensado ? const Color(0xFF3B82F6) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: isCensado ? const BorderSide(color: Color(0xFFCBD5E1)) : BorderSide.none,
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuditarMuebleScreen(qrCode: m['clientemueble_qr']),
                  ),
                );

                if (result == true) {
                  // Si el searchController está vacío, podemos decidir recargar datos
                  // Solo recargamos si hay búsqueda activa o filtros aplicados
                  _cargarDatos(rut: searchController.text);
                }
              },
              icon: Icon(isCensado ? Icons.gps_fixed_rounded : Icons.my_location_rounded, size: 16),
              label: Text(isCensado ? 'Auditar de nuevo / Ver' : 'Auditar Mueble', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }
}