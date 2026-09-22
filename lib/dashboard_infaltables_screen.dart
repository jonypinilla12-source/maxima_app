import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DashboardInfaltablesScreen extends StatefulWidget {
  const DashboardInfaltablesScreen({super.key});

  @override
  State<DashboardInfaltablesScreen> createState() => _DashboardInfaltablesScreenState();
}

class _DashboardInfaltablesScreenState extends State<DashboardInfaltablesScreen> {
  bool isLoadingDashboard = false;
  bool isLoadingTerritorios = false;
  bool isLoadingAvance = false;
  
  List<dynamic> periodos = [];
  List<dynamic> zonas = [];
  List<dynamic> territorios = [];
  
  List<dynamic> rawResumenZonas = []; 
  List<dynamic> infaltablesAgrupados = []; 
  List<dynamic> avanceTerritorio = []; 
  
  String? periodoSeleccionado;
  String? zonaSeleccionada;
  String? territorioSeleccionado;

  final Color colorPrimario = const Color(0xFF6366F1); 

  @override
  void initState() {
    super.initState();
    _cargarPeriodos();
  }

  // --- FORMATEADOR DE NÚMEROS (Para poner los puntitos de miles) ---
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

  Future<void> _obtenerDashboard(String periodoId) async {
    setState(() {
      isLoadingDashboard = true;
      periodoSeleccionado = periodoId;
      zonaSeleccionada = null; 
      territorioSeleccionado = null;
      territorios = [];
      avanceTerritorio = [];
    });

    final url = Uri.parse('http://app.distribuidoramaxima.cl/api/api_dashboard.php?periodo_id=$periodoId');
    //final url = Uri.parse('http://localhost/inventariomaxima/api/api_dashboard.php?periodo_id=$periodoId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          List rawZonasList = data['data']['zonas'] ?? [];
          List rawDataZonas = data['data']['resumen_todas_zonas'] ?? [];

          Map<String, Map<String, dynamic>> agrupado = {};
          for (var zona in rawDataZonas) {
            String nombreZona = zona['zona_nombre']?.toString() ?? 'Zona';
            for (var inf in List.from(zona['infaltables'] ?? [])) {
              String nombreInfaltable = inf['infaltable_nombre']?.toString() ?? 'Producto';
              if (!agrupado.containsKey(nombreInfaltable)) {
                agrupado[nombreInfaltable] = {'infaltable_nombre': nombreInfaltable, 'zonas': []};
              }
              agrupado[nombreInfaltable]!['zonas'].add({
                'nombre_mostrar': nombreZona,
                'objetivo_total': inf['objetivo_total'],
                'cumplidos_total': inf['cumplidos_total'],
                'porcentaje': inf['porcentaje']
              });
            }
          }

          setState(() {
            zonas = List.from(rawZonasList);
            rawResumenZonas = List.from(rawDataZonas);
            infaltablesAgrupados = agrupado.values.toList();
          });
        }
      }
    } catch (e) {
      print("Error de conexión: $e");
    } finally {
      setState(() => isLoadingDashboard = false);
    }
  }

  Future<void> _cargarTerritorios(String zonaId) async {
    setState(() {
      zonaSeleccionada = zonaId;
      territorioSeleccionado = null;
      avanceTerritorio = [];
      isLoadingTerritorios = true;
    });

    final url = Uri.parse('http://app.distribuidoramaxima.cl/api/api_territorios.php?zona_id=$zonaId');
    //final url = Uri.parse('http://localhost/inventariomaxima/api/api_territorios.php?zona_id=$zonaId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { territorios = List.from(data['data'] ?? []); });
        }
      }
    } catch (e) {
      print("Error cargar territorios: $e");
    } finally {
      setState(() => isLoadingTerritorios = false);
    }
  }

  Future<void> _cargarAvanceTerritorio(String territorioId) async {
    setState(() {
      territorioSeleccionado = territorioId;
      isLoadingAvance = true;
    });

    final url = Uri.parse('http://app.distribuidoramaxima.cl/api/api_avance_territorio.php?periodo_id=$periodoSeleccionado&territorio_id=$territorioId');
    //final url = Uri.parse('http://localhost/inventariomaxima/api/api_avance_territorio.php?periodo_id=$periodoSeleccionado&territorio_id=$territorioId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() { avanceTerritorio = List.from(data['data'] ?? []); });
        }
      }
    } catch (e) {
      print("Error cargar avance territorio: $e");
    } finally {
      setState(() => isLoadingAvance = false);
    }
  }

  // ===========================================================================
  // MODAL PARA LISTAR CLIENTES CON FILTROS (ESTILO WEB)
  // ===========================================================================
  void _abrirModalClientes(dynamic infaltableData) {
    String nombreProducto = infaltableData['nombre_mostrar'] ?? 'Producto';
    List clientesTotales = List.from(infaltableData['clientes'] ?? []);
    
    String filtroDia = 'Todos';
    String filtroEstado = 'Todos';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // Lógica de Filtrado Local
            List clientesFiltrados = clientesTotales.where((c) {
              bool pasaDia = true;
              bool pasaEstado = true;

              if (filtroDia != 'Todos') {
                String diaCliente = c['visita_nombre']?.toString() ?? '';
                if (diaCliente.toLowerCase() != filtroDia.toLowerCase()) pasaDia = false;
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
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(nombreProducto.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            ),
                            IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildModalFilter(
                                label: "Día Visita",
                                value: filtroDia,
                                items: ['Todos', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'No Informada'],
                                onChanged: (val) => setModalState(() => filtroDia = val!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModalFilter(
                                label: "Estado",
                                value: filtroEstado,
                                items: ['Todos', 'Cumple', 'No cumple'],
                                onChanged: (val) => setModalState(() => filtroEstado = val!),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  Expanded(
                    child: clientesFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off_rounded, size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                const Text('No hay clientes con esos filtros', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 16)),
                              ],
                            ),
                          )
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
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['cliente_razonsocial'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 4),
                                          Text("RUT: ${c['cliente_rut']}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month_rounded, size: 12, color: Color(0xFF475569)),
                                                    const SizedBox(width: 4),
                                                    Text(c['visita_nombre'] ?? 'N/A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                                child: Text("Local: ${c['cliente_local'] ?? '-'}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cumple ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF43F5E).withOpacity(0.1),
                                        shape: BoxShape.circle
                                      ),
                                      child: Icon(
                                        cumple ? Icons.check_rounded : Icons.close_rounded,
                                        color: cumple ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                        size: 24,
                                      ),
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
          },
        );
      },
    );
  }

  Widget _buildModalFilter({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B))),
              items: items.map((e) => DropdownMenuItem(value: e, child: Padding(padding: const EdgeInsets.only(left: 12.0), child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)))))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List infaltablesDeLaZona = [];
    if (zonaSeleccionada != null) {
      var zonaEncontrada = rawResumenZonas.firstWhere((z) => z['zona_id'].toString() == zonaSeleccionada, orElse: () => null);
      if (zonaEncontrada != null && zonaEncontrada['infaltables'] != null) {
        infaltablesDeLaZona = (zonaEncontrada['infaltables'] as List).map((inf) {
          return {
            'nombre_mostrar': inf['infaltable_nombre'],
            'objetivo_total': inf['objetivo_total'],
            'cumplidos_total': inf['cumplidos_total'],
            'porcentaje': inf['porcentaje']
          };
        }).toList();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
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
          // CABECERA
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: colorPrimario,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorPrimario, const Color(0xFF8B5CF6)]),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
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
                          const Text('Dashboard Infaltables', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.analytics_rounded, color: Colors.white.withOpacity(0.9), size: 16),
                              const SizedBox(width: 6),
                              Text(periodoSeleccionado != null ? 'Datos actualizados' : 'Esperando selección', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
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

          // 1. SELECTOR DE PERÍODO Y DASHBOARD GENERAL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectorModerno(
                    titulo: "Seleccionar Período", icono: Icons.date_range_rounded, hint: "Elige un mes a evaluar", valor: periodoSeleccionado,
                    items: periodos.map((p) => DropdownMenuItem<String>(value: p['periodo_id'].toString(), child: Text(p['periodo_etiqueta'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))))).toList(),
                    onChanged: (val) { if (val != null) _obtenerDashboard(val); },
                  ),
                  
                  if (infaltablesAgrupados.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildTituloSeccion("Resumen por Zonas", Icons.pie_chart_rounded),
                  ]
                ],
              ),
            ),
          ),

          if (isLoadingDashboard)
            SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: colorPrimario)))
          else if (infaltablesAgrupados.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]), child: const Icon(Icons.travel_explore_rounded, size: 50, color: Color(0xFFCBD5E1))),
                    const SizedBox(height: 20),
                    const Text('No hay datos visibles', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Selecciona un período arriba para comenzar', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var grupo = infaltablesAgrupados[index];
                    List zonasDelProducto = List.from(grupo['zonas'] ?? []);
                    String nombreProducto = grupo['infaltable_nombre']?.toString() ?? 'PRODUCTO';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TÍTULO DEL PRODUCTO Y SUBTÍTULO
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombreProducto.toUpperCase(), style: TextStyle(color: colorPrimario, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                              const SizedBox(height: 2),
                              const Text("Rendimiento general del infaltable", style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                        // TARJETA DE CUMPLIMIENTO GENERAL (TOTAL DE LAS ZONAS)
                        _buildCumplimientoGeneralCard(zonasDelProducto),
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 16, runSpacing: 16,
                          children: zonasDelProducto.map<Widget>((z) => SizedBox(width: MediaQuery.of(context).size.width > 600 ? 320 : double.infinity, child: _construirTarjetaKPI(z))).toList(),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                  childCount: infaltablesAgrupados.length,
                ),
              ),
            ),

          // 2. SELECTOR DE ZONA Y RESUMEN GENERAL
          if (infaltablesAgrupados.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 40, thickness: 1, color: Color(0xFFE2E8F0)),
                    _buildSelectorModerno(
                      titulo: "Filtrar por Zona", icono: Icons.location_on_rounded, hint: "Elige una zona...", valor: zonaSeleccionada,
                      items: zonas.map((z) => DropdownMenuItem<String>(value: z['zona_id'].toString(), child: Text(z['zona_nombre'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))))).toList(),
                      onChanged: (val) { if (val != null) _cargarTerritorios(val); },
                    ),

                    if (zonaSeleccionada != null) ...[
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildTituloSeccion("General de la Zona", Icons.domain_rounded)),
                          _buildBotonExcel(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16, runSpacing: 16,
                        children: infaltablesDeLaZona.map<Widget>((inf) => SizedBox(width: MediaQuery.of(context).size.width > 600 ? 320 : double.infinity, child: _construirTarjetaKPI(inf))).toList(),
                      ),
                    ]
                  ],
                ),
              ),
            ),

          // 3. SELECTOR DE TERRITORIO Y DETALLE FINAL
          if (zonaSeleccionada != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 40, thickness: 1, color: Color(0xFFE2E8F0)),
                    _buildSelectorModerno(
                      titulo: "Filtrar por Territorio", icono: Icons.map_rounded, hint: isLoadingTerritorios ? "Cargando..." : "Elige un territorio...", valor: territorioSeleccionado,
                      items: territorios.map((t) => DropdownMenuItem<String>(value: t['territorio_id'].toString(), child: Text(t['territorio_nombre'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))))).toList(),
                      onChanged: (val) { if (val != null) _cargarAvanceTerritorio(val); },
                    ),

                    if (territorioSeleccionado != null) ...[
                      const SizedBox(height: 32),
                      _buildTituloSeccion("Avance por Producto", Icons.insights_rounded),
                      const SizedBox(height: 16),
                      if (isLoadingAvance)
                         Center(child: Padding(padding: const EdgeInsets.all(30), child: CircularProgressIndicator(color: colorPrimario)))
                      else
                        Wrap(
                          spacing: 16, runSpacing: 16,
                          children: avanceTerritorio.map<Widget>((inf) => SizedBox(width: MediaQuery.of(context).size.width > 600 ? 320 : double.infinity, child: _construirTarjetaKPI(inf, mostrarVerClientes: true))).toList(),
                        ),
                      const SizedBox(height: 60),
                    ]
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =======================================================================================
  // NUEVO: TARJETA DE CUMPLIMIENTO GENERAL (Suma todas las zonas)
  // =======================================================================================
  Widget _buildCumplimientoGeneralCard(List zonasDelProducto) {
    int totalObjetivo = 0;
    int totalCumplidos = 0;

    for (var z in zonasDelProducto) {
      totalObjetivo += int.tryParse(z['objetivo_total']?.toString() ?? '0') ?? 0;
      totalCumplidos += int.tryParse(z['cumplidos_total']?.toString() ?? '0') ?? 0;
    }

    int totalFaltantes = totalObjetivo > totalCumplidos ? (totalObjetivo - totalCumplidos) : 0;
    double porcentajeGlobal = totalObjetivo > 0 ? (totalCumplidos / totalObjetivo) * 100 : 0.0;

    Color colorPrincipal; 
    if (porcentajeGlobal >= 100) { colorPrincipal = const Color(0xFF10B981); }
    else if (porcentajeGlobal >= 80) { colorPrincipal = const Color(0xFF34D399); }
    else if (porcentajeGlobal >= 50) { colorPrincipal = const Color(0xFFF59E0B); }
    else { colorPrincipal = const Color(0xFFF43F5E); }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CUMPLIMIENTO GENERAL", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: _formatNumber(totalCumplidos), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 32, fontWeight: FontWeight.w900)),
                TextSpan(text: " / ${_formatNumber(totalObjetivo)}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Text("${porcentajeGlobal.toInt()}%", style: TextStyle(color: colorPrincipal, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (porcentajeGlobal > 100 ? 100 : porcentajeGlobal) / 100,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: colorPrincipal,
                    minHeight: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Faltan ${_formatNumber(totalFaltantes)} clientes", style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- DISEÑO DE TARJETA KPI ---
  Widget _construirTarjetaKPI(dynamic data, {bool mostrarVerClientes = false}) {
    int objetivo = int.tryParse(data['objetivo_total']?.toString() ?? '0') ?? 0;
    int cumplidos = int.tryParse(data['cumplidos_total']?.toString() ?? '0') ?? 0;
    double porcentaje = double.tryParse(data['porcentaje']?.toString() ?? '0') ?? 0.0;

    int faltantes = (objetivo - cumplidos) > 0 ? (objetivo - cumplidos) : 0;
    int superado = (cumplidos - objetivo) > 0 ? (cumplidos - objetivo) : 0;

    Color colorPrincipal; Color colorFondoSoft; String estado;

    if (porcentaje >= 100) { colorPrincipal = const Color(0xFF10B981); colorFondoSoft = const Color(0xFFECFDF5); estado = "Meta Lograda"; }
    else if (porcentaje >= 80) { colorPrincipal = const Color(0xFF34D399); colorFondoSoft = const Color(0xFFECFDF5); estado = "Excelente"; }
    else if (porcentaje >= 50) { colorPrincipal = const Color(0xFFF59E0B); colorFondoSoft = const Color(0xFFFFFBEB); estado = "En progreso"; }
    else { colorPrincipal = const Color(0xFFF43F5E); colorFondoSoft = const Color(0xFFFFF1F2); estado = "Riesgo"; }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: colorPrincipal, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(data['nombre_mostrar'] ?? 'Dato', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: colorFondoSoft, borderRadius: BorderRadius.circular(10)), child: Text("${porcentaje.toInt()}%", style: TextStyle(fontWeight: FontWeight.w900, color: colorPrincipal, fontSize: 14)))
            ],
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("LOGRADOS", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(_formatNumber(cumplidos), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(porcentaje >= 100 ? "EXTRAS" : "FALTANTES", style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(porcentaje >= 100 ? "+${_formatNumber(superado)}" : _formatNumber(faltantes), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: porcentaje >= 100 ? const Color(0xFF10B981) : const Color(0xFFF43F5E))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: (porcentaje > 100 ? 100 : porcentaje) / 100, backgroundColor: const Color(0xFFF1F5F9), color: colorPrincipal, minHeight: 8),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${_formatNumber(cumplidos)} de ${_formatNumber(objetivo)} locales", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Text(estado, style: TextStyle(fontSize: 12, color: colorPrincipal, fontWeight: FontWeight.w800)),
            ],
          ),

          if (mostrarVerClientes) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _abrirModalClientes(data),
                icon: Icon(Icons.groups_rounded, size: 16, color: colorPrimario),
                label: Text("VER CLIENTES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorPrimario, letterSpacing: 0.5)),
                style: TextButton.styleFrom(
                  backgroundColor: colorPrimario.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10)
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  // --- SELECTOR ESTILO INPUT MODERNO ---
  Widget _buildSelectorModerno({required String titulo, required IconData icono, required String hint, required String? valor, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: colorPrimario, size: 18),
            const SizedBox(width: 8),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF475569))),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
            icon: const Icon(Icons.unfold_more_rounded, color: Color(0xFF94A3B8)),
            hint: Text(hint, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
            value: valor, items: items, onChanged: onChanged, dropdownColor: Colors.white, borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  // --- TÍTULOS Y COMPONENTES EXTRAS ---
  Widget _buildTituloSeccion(String titulo, IconData icono) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: colorPrimario.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icono, color: colorPrimario, size: 18)),
        const SizedBox(width: 10),
        Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildBotonExcel() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Descarga Excel iniciada..."))); },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Row(
            children: [
              Icon(Icons.download_rounded, size: 16, color: Color(0xFF059669)),
              SizedBox(width: 6),
              Text("EXCEL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))],
      ),
    );
  }
}