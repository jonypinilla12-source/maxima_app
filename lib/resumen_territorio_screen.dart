import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResumenTerritorioScreen extends StatefulWidget {
  const ResumenTerritorioScreen({super.key});

  @override
  State<ResumenTerritorioScreen> createState() => _ResumenTerritorioScreenState();
}

class _ResumenTerritorioScreenState extends State<ResumenTerritorioScreen> {
  final Color colorPrimario = const Color(0xFF6366F1); // Color del menú lateral
  final Color colorAzulBuscador = const Color(0xFF3B82F6); // Azul vibrante web

  List<dynamic> periodos = [];
  String? periodoSeleccionado;
  TextEditingController territorioController = TextEditingController();

  bool isLoading = false;
  String? errorTerritorio;
  
  String? territorioIdEncontrado;
  String? territorioNombreEncontrado;
  List<dynamic> resumenPdv = [];
  List<dynamic> resumenInfaltables = [];

  @override
  void initState() {
    super.initState();
    _cargarPeriodos();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Future<void> _cargarPeriodos() async {
    final url = Uri.parse('http://app.distribuidoramaxima.cl/api/periodo_listar.php');
    //final url = Uri.parse('http://localhost/inventariomaxima/api/periodo_listar.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { periodos = List.from(data['data'] ?? []); });
        }
      }
    } catch (e) {
      print("Error al cargar períodos: $e");
    }
  }

  Future<void> _buscarTerritorio() async {
    if (periodoSeleccionado == null || territorioController.text.trim().isEmpty) {
      setState(() { errorTerritorio = "Seleccione un período e ingrese un código."; });
      return;
    }

    setState(() {
      isLoading = true;
      errorTerritorio = null;
      territorioIdEncontrado = null;
      territorioNombreEncontrado = null;
      resumenPdv = [];
      resumenInfaltables = [];
    });

    final url = Uri.parse('http://app.distribuidoramaxima.cl/api/api_resumen_territorio.php?periodo_id=$periodoSeleccionado&territorio_nombre=${territorioController.text.trim()}');
    //final url = Uri.parse('http://localhost/inventariomaxima/api/api_resumen_territorio.php?periodo_id=$periodoSeleccionado&territorio_nombre=${territorioController.text.trim()}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() {
            territorioIdEncontrado = data['data']['territorio_id'].toString();
            territorioNombreEncontrado = data['data']['territorio_nombre'];
            resumenPdv = List.from(data['data']['resumen_pdv'] ?? []);
            resumenInfaltables = List.from(data['data']['resumen_infaltables'] ?? []);
          });
        } else {
          setState(() { errorTerritorio = data['msg'] ?? "Error desconocido"; });
        }
      }
    } catch (e) {
      setState(() { errorTerritorio = "Error de conexión al servidor."; });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _abrirModalClientes(String tipo, String itemId, String nombreRuta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ModalClientesContenido(
          periodoId: periodoSeleccionado!,
          territorioId: territorioIdEncontrado!,
          tipo: tipo,
          itemId: itemId,
          nombreRuta: nombreRuta,
        );
      },
    );
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
          // APP BAR IDÉNTICO AL HOME
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
                                child: const Icon(Icons.route_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('Resumen por Territorio', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900), maxLines: 1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Analiza el rendimiento comercial, cobertura de clientes y objetivos de tu ruta.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TARJETA DE BÚSQUEDA (ESTILO FOTO)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(14),
                      border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 6)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FILTROS RESPONSIVOS
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 400;
                            List<Widget> formFields = [
                              // PERIODO
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("PERÍODO OPERATIVO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                      ),
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                                      hint: const Text("Seleccione un período", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
                                      value: periodoSeleccionado,
                                      items: periodos.map((p) => DropdownMenuItem<String>(value: p['periodo_id'].toString(), child: Text(p['periodo_etiqueta'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 13)))).toList(),
                                      onChanged: (val) { setState(() { periodoSeleccionado = val; }); },
                                    ),
                                  ],
                                ),
                              ),
                              if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                              // CÓDIGO
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("CÓDIGO DE TERRITORIO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: territorioController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "Ej. 72016",
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                              // BOTON
                              SizedBox(
                                width: isWide ? null : double.infinity,
                                height: 48,
                                child: Padding(
                                  padding: EdgeInsets.only(top: isWide ? 22.0 : 0),
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _buscarTerritorio,
                                    icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                                    label: Text(isLoading ? "Buscando..." : "Consultar", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorAzulBuscador,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 0),
                                    ),
                                  ),
                                ),
                              )
                            ];

                            return isWide 
                              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: formFields)
                              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: formFields);
                          },
                        ),
                        
                        // ALERTA O ÉXITO
                        if (errorTerritorio != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18), const SizedBox(width: 8), Expanded(child: Text(errorTerritorio!, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13)))]),
                          )
                        ],
                        if (territorioNombreEncontrado != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(50), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFF6366F1), size: 16),
                                const SizedBox(width: 8),
                                Text("Territorio: $territorioNombreEncontrado", style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 13)),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),

                  // ===============================================
                  // RESULTADOS PDV
                  // ===============================================
                  if (resumenPdv.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text("Resumen PDV", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16, runSpacing: 16,
                      children: resumenPdv.map<Widget>((item) => SizedBox(
                        width: MediaQuery.of(context).size.width > 600 ? 320 : double.infinity, 
                        child: _construirTarjeta(item, 'pdv', 'CUBIERTOS')
                      )).toList(),
                    ),
                  ],

                  // ===============================================
                  // RESULTADOS INFALTABLES
                  // ===============================================
                  if (resumenInfaltables.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text("Resumen Infaltables", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16, runSpacing: 16,
                      children: resumenInfaltables.map<Widget>((item) => SizedBox(
                        width: MediaQuery.of(context).size.width > 600 ? 320 : double.infinity, 
                        child: _construirTarjeta(item, 'infaltable', 'COMPRARON')
                      )).toList(),
                    ),
                    const SizedBox(height: 40),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- TARJETA DE ESTILO WEB (Cajas de color sólidas y Progress Bar ancha) ---
  Widget _construirTarjeta(dynamic data, String tipo, String labelOk) {
    String nombre = data['nombre'] ?? '';
    int objetivo = int.tryParse(data['objetivo']?.toString() ?? '0') ?? 0;
    int cumplidos = int.tryParse(data['cumplidos']?.toString() ?? '0') ?? 0;
    double porcentaje = double.tryParse(data['porcentaje']?.toString() ?? '0') ?? 0.0;

    int faltantes = (objetivo - cumplidos) > 0 ? (objetivo - cumplidos) : 0;
    int superado = (cumplidos - objetivo) > 0 ? (cumplidos - objetivo) : 0;

    Color colorBarra; String estado;
    if (porcentaje >= 100) { colorBarra = const Color(0xFF10B981); estado = "Meta Lograda"; }
    else if (porcentaje >= 80) { colorBarra = const Color(0xFF10B981); estado = "Óptimo"; }
    else if (porcentaje >= 50) { colorBarra = const Color(0xFFF59E0B); estado = "En Progreso"; }
    else { colorBarra = const Color(0xFFEF4444); estado = "Bajo Cumplimiento"; }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombre.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          
          // CAJAS SOLIDAS (OK / FALTANTES)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: const Color(0xFFD1FAE5), border: Border.all(color: const Color(0xFFA7F3D0)), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      Text(labelOk, style: const TextStyle(fontSize: 10, color: Color(0xFF065F46), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(_formatNumber(cumplidos), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10), 
                  decoration: BoxDecoration(
                    color: porcentaje >= 100 ? const Color(0xFFEFF6FF) : const Color(0xFFFEE2E2), 
                    border: Border.all(color: porcentaje >= 100 ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA)), 
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Column(
                    children: [
                      Text(porcentaje >= 100 ? "SOBRE META" : "FALTANTES", style: TextStyle(fontSize: 10, color: porcentaje >= 100 ? const Color(0xFF1E40AF) : const Color(0xFF991B1B), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(porcentaje >= 100 ? "+${_formatNumber(superado)}" : _formatNumber(faltantes), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: porcentaje >= 100 ? const Color(0xFF1E40AF) : const Color(0xFF991B1B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BARRA DE PROGRESO CON TEXTO CENTRADO
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 22, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20))),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 22, width: constraints.maxWidth * ((porcentaje > 100 ? 100 : porcentaje) / 100),
                    decoration: BoxDecoration(color: colorBarra, borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
              Center(child: Text("${porcentaje.toInt()}%", style: TextStyle(fontSize: 11, color: porcentaje > 15 ? Colors.white : Colors.black54, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 16),

          // FOOTER: TEXTO + BOTÓN LISTA
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0), style: BorderStyle.solid))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                      children: [
                        TextSpan(text: "${_formatNumber(cumplidos)} / ${_formatNumber(objetivo)} "),
                        TextSpan(text: "($estado)", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _abrirModalClientes(tipo, data['id'].toString(), nombre),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(50), color: const Color(0xFFF8FAFC)),
                    child: const Row(
                      children: [
                        Icon(Icons.list_rounded, size: 14, color: Color(0xFF3B82F6)),
                        SizedBox(width: 4),
                        Text("Clientes", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6))),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// =======================================================================================
// WIDGET CON ESTADO SEPARADO PARA EL MODAL (Para manejar su propio loading)
// =======================================================================================
class _ModalClientesContenido extends StatefulWidget {
  final String periodoId;
  final String territorioId;
  final String tipo;
  final String itemId;
  final String nombreRuta;

  const _ModalClientesContenido({required this.periodoId, required this.territorioId, required this.tipo, required this.itemId, required this.nombreRuta});

  @override
  State<_ModalClientesContenido> createState() => _ModalClientesContenidoState();
}

class _ModalClientesContenidoState extends State<_ModalClientesContenido> {
  bool isLoading = true;
  List<dynamic> clientesTotales = [];
  String filtroDia = 'Todos';
  String filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final url = Uri.parse('http://app.distribuidoramaxima.cl/api/api_clientes_territorio.php?periodo_id=${widget.periodoId}&territorio_id=${widget.territorioId}&tipo=${widget.tipo}&item_id=${widget.itemId}');
    //final url = Uri.parse('http://localhost/inventariomaxima/api/api_clientes_territorio.php?periodo_id=${widget.periodoId}&territorio_id=${widget.territorioId}&tipo=${widget.tipo}&item_id=${widget.itemId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { clientesTotales = List.from(data['data'] ?? []); });
        }
      }
    } catch (e) {
      print("Error cargando clientes modal: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List clientesFiltrados = clientesTotales.where((c) {
      bool pasaDia = true;
      bool pasaEstado = true;
      
      if (filtroDia != 'Todos') {
        // Agregamos .trim() para limpiar espacios fantasma antes de comparar
        String diaCliente = c['visita_nombre']?.toString().trim().toLowerCase() ?? '';
        String diaFiltro = filtroDia.trim().toLowerCase();
        
        if (diaCliente != diaFiltro) pasaDia = false;
      }
      
      if (filtroEstado != 'Todos') {
        String estado = c['avance_estado'].toString();
        if (filtroEstado == 'Cumple' && estado != '1') pasaEstado = false;
        if (filtroEstado == 'No cumple' && estado == '1') pasaEstado = false;
      }
      
      return pasaDia && pasaEstado;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(widget.tipo == 'infaltable' ? Icons.local_fire_department_rounded : Icons.store_rounded, color: widget.tipo == 'infaltable' ? Colors.redAccent : Colors.blueAccent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.nombreRuta.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildFiltro("Día de Visita", filtroDia, ['Todos', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'No Informada'], (val) => setState(() => filtroDia = val!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFiltro("Estado", filtroEstado, ['Todos', 'Cumple', 'No cumple'], (val) => setState(() => filtroEstado = val!))),
                  ],
                )
              ],
            ),
          ),

          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : clientesFiltrados.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_rounded, size: 60, color: Colors.grey[300]), const SizedBox(height: 12), const Text('No hay clientes en esta ruta.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 16))]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        var c = clientesFiltrados[index];
                        bool cumple = c['avance_estado'].toString() == '1';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2))]),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['cliente_razonsocial'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
                                    const SizedBox(height: 4),
                                    Text("RUT: ${c['cliente_rut']}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                          child: Row(children: [const Icon(Icons.calendar_month_rounded, size: 12, color: Color(0xFF475569)), const SizedBox(width: 4), Text(c['visita_nombre'] ?? 'N/A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))]),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                          child: Text("Local: ${c['cliente_local'] ?? '-'}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(cumple ? Icons.check_rounded : Icons.close_rounded, color: cumple ? const Color(0xFF10B981) : const Color(0xFFF43F5E), size: 20),
                                  const SizedBox(height: 4),
                                  Text(cumplidosText(cumple, widget.tipo), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cumple ? const Color(0xFF10B981) : const Color(0xFFF43F5E))),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  String cumplidosText(bool cumple, String tipo) {
    if (cumple) { return tipo == 'pdv' ? 'CUBIERTO' : 'COMPRÓ'; }
    return 'FALTANTE';
  }

  Widget _buildFiltro(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFCBD5E1))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true, value: value,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}