import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardVentasScreen extends StatefulWidget {
  const DashboardVentasScreen({Key? key}) : super(key: key);

  @override
  _DashboardVentasScreenState createState() => _DashboardVentasScreenState();
}

class _DashboardVentasScreenState extends State<DashboardVentasScreen> {
  late Future<Map<String, dynamic>> _dashboardData;
  String _periodoSeleccionadoId = "";
  List<dynamic> _listaPeriodos = [];

  @override
  void initState() {
    super.initState();
    _dashboardData = fetchDashboardData();
  }

  Future<Map<String, dynamic>> fetchDashboardData([String? periodoId]) async {
    String urlBase = 'https://app.distribuidoramaxima.cl/api/api_dashboard_ventas.php';
    if (periodoId != null && periodoId.isNotEmpty) {
      urlBase += '?periodo_id=$periodoId';
    }

    try {
      final response = await http.get(Uri.parse(urlBase));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success') {
          if (decoded['periodos'] != null) _listaPeriodos = decoded['periodos'];
          return decoded;
        } else {
          throw Exception(decoded['msg'] ?? 'Error desconocido en la API');
        }
      } else {
        throw Exception('Error de conexión (Código: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Fallo de conexión: $e');
    }
  }

  Map<String, dynamic> _parsearMapaSeguro(dynamic dato) {
    if (dato == null) return {};
    if (dato is Map<String, dynamic>) return dato;
    if (dato is Map) return Map<String, dynamic>.from(dato);
    return {};
  }

  int _mesTextoANumero(String mesTexto) {
    switch (mesTexto.toLowerCase().trim()) {
      case 'enero': return 1;
      case 'febrero': return 2;
      case 'marzo': return 3;
      case 'abril': return 4;
      case 'mayo': return 5;
      case 'junio': return 6;
      case 'julio': return 7;
      case 'agosto': return 8;
      case 'septiembre': return 9;
      case 'octubre': return 10;
      case 'noviembre': return 11;
      case 'diciembre': return 12;
      default: return DateTime.now().month;
    }
  }

  String _formatoPesos(num valor) {
    String valorString = valor.toStringAsFixed(0);
    return '\$ ' + valorString.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatoPct(num pct) {
    return '${pct.toStringAsFixed(1)}%';
  }

  Color _colorSemaforo(num pct, num meta) {
    return pct >= meta ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
  }

  Widget _buildEmptyState(String titulo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Sin datos en $titulo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            const Text('Este mes no tiene registros o ventas ingresadas todavía.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _mostrarModalCambiarPeriodo() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String tempPeriodoId = _periodoSeleccionadoId;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.all(0),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: const [
                Icon(Icons.calendar_today_rounded, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Text("Seleccionar Periodo", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 16)),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Elige el periodo a consultar:", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const SizedBox(height: 10),
              if (_listaPeriodos.isEmpty)
                const Text("No hay periodos disponibles.", style: TextStyle(color: Colors.red))
              else
                StatefulBuilder(
                  builder: (context, setStateModal) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempPeriodoId.isEmpty ? null : tempPeriodoId,
                          isExpanded: true,
                          hint: const Text("-- Seleccionar --"),
                          items: _listaPeriodos.map<DropdownMenuItem<String>>((p) {
                            return DropdownMenuItem<String>(
                              value: p['periodo_id'].toString(),
                              child: Text('${p['periodo_mes'].toString().toUpperCase()} ${p['periodo_año']}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setStateModal(() => tempPeriodoId = val);
                          },
                        ),
                      ),
                    );
                  }
                ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(0),
          actions: [
            Container(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Color(0xFFE2E8F0))), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (tempPeriodoId.isNotEmpty) {
                        setState(() {
                          _periodoSeleccionadoId = tempPeriodoId;
                          _dashboardData = fetchDashboardData(tempPeriodoId);
                        });
                      }
                    },
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text("Consultar"),
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          title: const Text('Dashboard de Ventas', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Móvil en desarrollo'))),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true, indicatorColor: Colors.white, indicatorWeight: 4,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(icon: Icon(Icons.calendar_month, color: Colors.orange), text: 'Calendario'),
              Tab(icon: Icon(Icons.attach_money, color: Colors.green), text: 'Venta Efectiva'),
              Tab(icon: Icon(Icons.track_changes_rounded, color: Colors.redAccent), text: 'Avance ABL/Confites'),
              Tab(icon: Icon(Icons.store, color: Colors.cyan), text: 'Avance por Canal'),
              Tab(icon: Icon(Icons.local_offer, color: Colors.white), text: 'Avance por Categoría'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Color(0xFF0284C7)),
                    SizedBox(height: 20),
                    Text('Cargando Dashboard...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    SizedBox(height: 8),
                    Text('Procesando datos y calculando avances...', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                      const SizedBox(height: 16),
                      const Text('¡Ups! Hubo un problema', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _dashboardData = fetchDashboardData()),
                        icon: const Icon(Icons.refresh), label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      )
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            
            final periodo = _parsearMapaSeguro(data['periodo']);
            final tiempo = _parsearMapaSeguro(data['tiempo']);
            final ventaEfectiva = _parsearMapaSeguro(data['venta_efectiva']);
            final lineas = _parsearMapaSeguro(data['lineas']);
            final canales = _parsearMapaSeguro(data['canales']);
            final categorias = _parsearMapaSeguro(data['categorias']);
            final diasBd = data['dias_calendario'] != null && data['dias_calendario'] is List ? data['dias_calendario'] as List<dynamic> : [];
            
            final metaMes = double.tryParse(tiempo['porcentaje']?.toString() ?? '0') ?? 0.0;
            final kAcumulados = double.tryParse(data['kilos_acumulados']?.toString() ?? '0') ?? 0.0;

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: const [Icon(Icons.show_chart, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('Dashboard y Avances', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))]),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text('Periodo actual: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                child: Text('${periodo['mes'] ?? ''} ${periodo['anio'] ?? ''}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                              )
                            ],
                          )
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0284C7), side: const BorderSide(color: Color(0xFF0284C7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 10)),
                        onPressed: _mostrarModalCambiarPeriodo,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Cambiar'),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTabCalendario(tiempo, periodo, diasBd),
                      _buildTabVentaEfectiva(ventaEfectiva, kAcumulados),
                      _buildTabLineas(lineas, metaMes),
                      _buildTabCanales(canales, metaMes),
                      _buildTabCategorias(categorias, metaMes),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ====================================================================
  // 1. PESTAÑA CALENDARIO
  // ====================================================================
  Widget _buildTabCalendario(Map<String, dynamic> tiempo, Map<String, dynamic> periodo, List<dynamic> diasBd) {
    if (tiempo.isEmpty) return _buildEmptyState('Tiempo y Calendario');

    DateTime fechaAyer = DateTime.now().subtract(const Duration(days: 1));
    if (tiempo['fecha_ayer'] != null) {
      try { fechaAyer = DateTime.parse(tiempo['fecha_ayer'].toString()); } catch (e) { /* fallback */ }
    }

    const diasSemana = ['LU', 'MA', 'MI', 'JU', 'VI', 'SA', 'DO'];
    List<Widget> filasGrilla = [];

    filasGrilla.add(
      Container(
        decoration: const BoxDecoration(color: Color(0xFF1E293B)),
        child: Row(children: diasSemana.map((d) => Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(d, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))))).toList()),
      )
    );

    List<Widget> celdasFilaActual = [];
    int colContador = 1;

    if (diasBd.isEmpty && tiempo['total'] != null) {
      int totalDias = int.tryParse(tiempo['total'].toString()) ?? 30;
      int year = periodo['anio'] != null ? int.tryParse(periodo['anio'].toString()) ?? DateTime.now().year : DateTime.now().year;
      int month = periodo['mes'] != null ? _mesTextoANumero(periodo['mes'].toString()) : DateTime.now().month;
      
      for (int i = 1; i <= totalDias; i++) {
        diasBd.add({
          'fecha': '$year-${month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}',
          'es_habil': (DateTime(year, month, i).weekday == 7) ? 0 : 1 
        });
      }
    }

    if (diasBd.isNotEmpty) {
      DateTime primerDia = DateTime.parse(diasBd[0]['fecha'].toString());
      int numDiaSem = primerDia.weekday; 

      for (int i = 1; i < numDiaSem; i++) {
        celdasFilaActual.add(Expanded(child: Container(decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade300, width: 0.5)), height: 40)));
        colContador++;
      }

      for (var d in diasBd) {
        if (colContador > 7) {
          filasGrilla.add(Row(children: celdasFilaActual));
          celdasFilaActual = []; colContador = 1;
        }

        DateTime fechaCelda = DateTime.parse(d['fecha'].toString());
        String diaStr = fechaCelda.day.toString();
        
        Color bgColor = Colors.white; Color textColor = const Color(0xFF1E293B); FontWeight fontWeight = FontWeight.normal;
        int esHabil = int.tryParse(d['es_habil']?.toString() ?? '1') ?? 1;

        if (esHabil == 0) {
          textColor = const Color(0xFFEF4444); fontWeight = FontWeight.bold;
        } else if (fechaCelda.isBefore(fechaAyer) || fechaCelda.isAtSameMomentAs(fechaAyer)) {
          bgColor = const Color(0xFF22C55E); textColor = Colors.white; fontWeight: FontWeight.bold;
        }

        celdasFilaActual.add(Expanded(child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: bgColor, border: Border.all(color: Colors.grey.shade300, width: 0.5)), child: Text(diaStr, style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 13)))));
        colContador++;
      }

      while (colContador <= 7) {
        celdasFilaActual.add(Expanded(child: Container(decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade300, width: 0.5)), height: 40)));
        colContador++;
      }
      if (celdasFilaActual.isNotEmpty) filasGrilla.add(Row(children: celdasFilaActual));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF0284C7)),
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), 
                    child: Text('${periodo['mes']?.toString().toUpperCase() ?? ''} ${periodo['anio'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))
                  ),
                  ...filasGrilla,
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                TableRow(children: [
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.all(12), child: const Text('Fecha Actual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ),
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.all(12), child: Text(tiempo['fecha_ayer'] ?? '-', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ),
                ]),
                TableRow(children: [
                  const Padding(padding: EdgeInsets.all(12), child: Text('Días Totales', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(12), child: Text('${tiempo['total'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                ]),
                TableRow(children: [
                  const Padding(padding: EdgeInsets.all(12), child: Text('Días Actuales', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold))),
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF22C55E)),
                    padding: const EdgeInsets.all(12), child: Text('${tiempo['actuales'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ),
                ]),
                TableRow(children: [
                  const Padding(padding: EdgeInsets.all(12), child: Text('Restantes', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(12), child: Text('${tiempo['restantes'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                ]),
                TableRow(children: [
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.all(12), child: const Text('Avance del Mes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                  ),
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.all(12), child: Text('${tiempo['porcentaje'] ?? 0}%', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                  ),
                ]),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ====================================================================
  // 2. PESTAÑA VENTA EFECTIVA
  // ====================================================================
  Widget _buildTabVentaEfectiva(Map<String, dynamic> datosVenta, double kAcumulados) {
    if (datosVenta.isEmpty) return _buildEmptyState('Venta Efectiva');
    
    List<TableRow> rowsResumen = [];
    String fechaHoy = "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";

    rowsResumen.add(
      TableRow(
        children: [
          Container(decoration: const BoxDecoration(color: Color(0xFF5B9BD5)), padding: const EdgeInsets.all(10), child: const Text('ZONAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFDDEBF7)), padding: const EdgeInsets.all(10), child: const Text('VENTA TRANSMITIDA\n(MOVIL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFDDEBF7)), padding: const EdgeInsets.all(10), child: const Text('VENTA EFECTIVA\nFACTURADA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFFFFFCC)), padding: const EdgeInsets.all(10), child: const Text('DIFERENCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
        ]
      )
    );

    double gMovil = 0, gFact = 0;
    List<Widget> tablasDetalleZonas = [];

    datosVenta.forEach((zona, territorios) {
      double sMovil = 0, sFact = 0;
      List<DataRow> filasDetalle = [];

      for (var t in (territorios as List)) {
        double movil = double.tryParse(t['venta_movil']?.toString() ?? '0') ?? 0;
        double ant = double.tryParse(t['sabana_dia_anterior']?.toString() ?? '0') ?? 0;
        double act = double.tryParse(t['sabana_actual']?.toString() ?? '0') ?? 0;
        double facturada = act - ant; double diferencia = facturada - movil;
        sMovil += movil; sFact += facturada;

        filasDetalle.add(DataRow(cells: [
          DataCell(Text(t['territorio_nombre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(t['vendedor_nombre_completo']?.toString() ?? 'Sin asignar', style: const TextStyle(fontSize: 11, color: Colors.black54))),
          DataCell(Text(_formatoPesos(ant))), DataCell(Text(_formatoPesos(act))),
          DataCell(Text(_formatoPesos(movil), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
          DataCell(Text(_formatoPesos(facturada), style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatoPesos(diferencia), style: TextStyle(color: diferencia < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
        ]));
      }

      gMovil += sMovil; gFact += sFact;
      double diff = sFact - sMovil;

      rowsResumen.add(TableRow(
        children: [
          Padding(padding: const EdgeInsets.all(10), child: Text(zona.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(sMovil), textAlign: TextAlign.right)),
          Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(sFact), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(diff), style: TextStyle(color: diff < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ]
      ));

      filasDetalle.add(DataRow(
        color: MaterialStateProperty.all(Colors.amber.shade100),
        cells: [
          const DataCell(Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold))), const DataCell(Text('')),
          const DataCell(Text('')), const DataCell(Text('')),
          DataCell(Text(_formatoPesos(sMovil), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
          DataCell(Text(_formatoPesos(sFact), style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatoPesos(diff), style: TextStyle(color: diff < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
        ]
      ));

      tablasDetalleZonas.add(
        Card(
          margin: const EdgeInsets.only(bottom: 24), elevation: 3, clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(color: Color(0xFF1E293B)),
                padding: const EdgeInsets.all(12), child: Text('ZONA: ${zona.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade50), columnSpacing: 20,
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  columns: const [
                    DataColumn(label: Text('Terr.')), DataColumn(label: Text('Vendedor')), DataColumn(label: Text('Sáb. Anterior')), 
                    DataColumn(label: Text('Sáb. Actual')), DataColumn(label: Text('Ped. Móvil', style: TextStyle(color: Colors.blue))),
                    DataColumn(label: Text('Facturada')), DataColumn(label: Text('Diferencia')),
                  ],
                  rows: filasDetalle,
                ),
              ),
            ],
          ),
        )
      );
    });

    rowsResumen.add(TableRow(
      decoration: BoxDecoration(color: Colors.yellow.shade200),
      children: [
        const Padding(padding: EdgeInsets.all(10), child: Text('TOTAL MÁXIMA', style: TextStyle(fontWeight: FontWeight.w900))),
        Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(gMovil), style: const TextStyle(fontWeight: FontWeight.w900), textAlign: TextAlign.right)),
        Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(gFact), style: const TextStyle(fontWeight: FontWeight.w900), textAlign: TextAlign.right)),
        Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(gFact - gMovil), style: const TextStyle(fontWeight: FontWeight.w900), textAlign: TextAlign.right)),
      ]
    ));

    rowsResumen.add(TableRow(
      children: [
        const SizedBox.shrink(), const SizedBox.shrink(),
        Container(
          decoration: const BoxDecoration(color: Color(0xFFffbbf1)),
          padding: const EdgeInsets.all(10), alignment: Alignment.center, child: const Text('KILOS ACUMULADOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))
        ),
        Container(padding: const EdgeInsets.all(10), alignment: Alignment.centerRight, child: Text('${kAcumulados.toStringAsFixed(2).replaceAll('.', ',')} kg', style: const TextStyle(fontWeight: FontWeight.w900))),
      ]
    ));

    return ListView(
      padding: const EdgeInsets.all(16), physics: const BouncingScrollPhysics(),
      children: [
        Card(
          elevation: 4, margin: const EdgeInsets.only(bottom: 30), clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(color: Color(0xFF002060)),
                padding: const EdgeInsets.all(12), child: Text(fechaHoy, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
              ),
              Table(border: TableBorder.all(color: Colors.grey.shade300), columnWidths: const { 0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.3), 3: FlexColumnWidth(1) }, children: rowsResumen),
            ],
          )
        ),
        Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: const [Icon(Icons.list, color: Color(0xFF1E293B)), SizedBox(width: 8), Text('Desglose Detallado por Territorio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))])),
        ...tablasDetalleZonas,
      ],
    );
  }

  // ====================================================================
  // 3. PESTAÑA LÍNEAS (ABL/CONFITES)
  // ====================================================================
  Widget _buildTabLineas(Map<String, dynamic> datosLineas, double metaMes) {
    if (datosLineas.isEmpty) return _buildEmptyState('Avance ABL/Confites');
    
    List<TableRow> rowsResumen = [];
    List<Widget> tablasDetalleZonas = [];

    rowsResumen.add(
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFF5B9BD5)),
        children: [
          _celdaHeaderGrupo('ZONA'),
          _celdaHeaderGrupo('OBJETIVO\nABL'), _celdaHeaderGrupo('OBJETIVO\nCONFITES'), _celdaHeaderGrupo('TOTAL\nOBJETIVO'),
          _celdaHeaderGrupo('AVANCE\nABL'), _celdaHeaderGrupo('AVANCE\nCONFITES'), _celdaHeaderGrupo('TOTAL\nAVANCE'),
          _celdaHeaderGrupo('% AVANCE\nABL'), _celdaHeaderGrupo('% AVANCE\nCONFITES'), _celdaHeaderGrupo('TOTAL %\nAVANCE'),
          Container(
            decoration: const BoxDecoration(color: Color(0xFFF87171)),
            padding: const EdgeInsets.all(8), child: const Text('VENTA POR CUMPLIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)
          ),
        ]
      )
    );

    double gObjAbl = 0, gObjConf = 0, gAvAbl = 0, gAvConf = 0;

    datosLineas.forEach((zona, territorios) {
      List<DataRow> filasDetalle = [];
      double tObjAbl = 0, tObjConf = 0, tAvAbl = 0, tAvConf = 0;

      for (var t in (territorios as List)) {
        double oAbl = double.tryParse(t['obj_abl']?.toString() ?? '0') ?? 0;
        double oConf = double.tryParse(t['obj_confites']?.toString() ?? '0') ?? 0;
        double aAbl = double.tryParse(t['avance_abl']?.toString() ?? '0') ?? 0;
        double aConf = double.tryParse(t['avance_confites']?.toString() ?? '0') ?? 0;

        tObjAbl += oAbl; tObjConf += oConf;
        tAvAbl += aAbl; tAvConf += aConf;

        double totObj = oAbl + oConf; double totAv = aAbl + aConf;
        double pAbl = oAbl > 0 ? (aAbl / oAbl) * 100 : 0;
        double pConf = oConf > 0 ? (aConf / oConf) * 100 : 0;
        double pTot = totObj > 0 ? (totAv / totObj) * 100 : 0;
        double faltante = totAv - totObj;

        filasDetalle.add(DataRow(cells: [
          DataCell(Text(t['territorio_nombre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Row(children: [const Icon(Icons.person, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(t['vendedor_nombre_completo']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.black54))])),
          DataCell(Text(_formatoPesos(oAbl))), DataCell(Text(_formatoPesos(oConf))), DataCell(Text(_formatoPesos(totObj), style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(_formatoPesos(aAbl))), DataCell(Text(_formatoPesos(aConf))), DataCell(Text(_formatoPesos(totAv), style: const TextStyle(fontWeight: FontWeight.bold))),
          _celdaPorcentaje(pAbl, metaMes), _celdaPorcentaje(pConf, metaMes), _celdaPorcentaje(pTot, metaMes),
          DataCell(Text(_formatoPesos(faltante), style: TextStyle(color: faltante < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
        ]));
      }

      gObjAbl += tObjAbl; gObjConf += tObjConf;
      gAvAbl += tAvAbl; gAvConf += tAvConf;

      double zTotObj = tObjAbl + tObjConf; double zTotAv = tAvAbl + tAvConf;
      double zP_Abl = tObjAbl > 0 ? (tAvAbl / tObjAbl) * 100 : 0;
      double zP_Conf = tObjConf > 0 ? (tAvConf / tObjConf) * 100 : 0;
      double zP_Tot = zTotObj > 0 ? (zTotAv / zTotObj) * 100 : 0;
      double zFaltante = zTotAv - zTotObj;

      rowsResumen.add(TableRow(
        decoration: const BoxDecoration(color: Colors.white),
        children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(zona.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tObjAbl), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tObjConf), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(zTotObj), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvAbl), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvConf), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(zTotAv), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Container(decoration: BoxDecoration(color: _colorSemaforo(zP_Abl, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(zP_Abl), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
          Container(decoration: BoxDecoration(color: _colorSemaforo(zP_Conf, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(zP_Conf), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
          Container(decoration: BoxDecoration(color: _colorSemaforo(zP_Tot, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(zP_Tot), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(zFaltante), style: TextStyle(color: zFaltante < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11))),
        ]
      ));

      tablasDetalleZonas.add(
        Card(
          margin: const EdgeInsets.only(bottom: 24), elevation: 3, clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(color: Color(0xFF5B9BD5)),
                padding: const EdgeInsets.all(12), child: Text('ZONA: ${zona.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFDDEBF7)), columnSpacing: 15, dataRowHeight: 45,
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  columns: [
                    const DataColumn(label: Text('Terr.')), const DataColumn(label: Text('Vendedor')), 
                    const DataColumn(label: Text('Obj. ABL')), const DataColumn(label: Text('Obj. Conf')), const DataColumn(label: Text('Total Obj.')),
                    const DataColumn(label: Text('Av. ABL')), const DataColumn(label: Text('Av. Conf')), const DataColumn(label: Text('Total Av.')), 
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFA9D08E)), padding: const EdgeInsets.all(8), child: const Text('% ABL'))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFA9D08E)), padding: const EdgeInsets.all(8), child: const Text('% Conf'))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFA9D08E)), padding: const EdgeInsets.all(8), child: const Text('% Total'))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFF87171)), padding: const EdgeInsets.all(8), child: const Text('Faltante', style: TextStyle(color: Colors.white)))),
                  ],
                  rows: filasDetalle,
                ),
              ),
            ],
          ),
        )
      );
    });

    double gTotObj = gObjAbl + gObjConf;
    double gTotAv = gAvAbl + gAvConf;
    double gPT_Abl = gObjAbl > 0 ? (gAvAbl / gObjAbl) * 100 : 0;
    double gPT_Conf = gObjConf > 0 ? (gAvConf / gObjConf) * 100 : 0;
    double gPT_Tot = gTotObj > 0 ? (gTotAv / gTotObj) * 100 : 0;

    rowsResumen.add(TableRow(
      decoration: BoxDecoration(color: Colors.yellow.shade200),
      children: [
        const Padding(padding: EdgeInsets.all(8), child: Text('TOTAL MÁXIMA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gObjAbl), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gObjConf), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gTotObj), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvAbl), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvConf), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gTotAv), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Container(decoration: BoxDecoration(color: _colorSemaforo(gPT_Abl, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(gPT_Abl), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
        Container(decoration: BoxDecoration(color: _colorSemaforo(gPT_Conf, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(gPT_Conf), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
        Container(decoration: BoxDecoration(color: _colorSemaforo(gPT_Tot, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(gPT_Tot), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gTotAv - gTotObj), style: TextStyle(color: (gTotAv - gTotObj) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w900, fontSize: 11))),
      ]
    ));

    return ListView(
      padding: const EdgeInsets.all(16), physics: const BouncingScrollPhysics(),
      children: [
        Card(
          elevation: 4, margin: const EdgeInsets.only(bottom: 30), clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(border: TableBorder.all(color: Colors.grey.shade300), defaultColumnWidth: const IntrinsicColumnWidth(), children: rowsResumen),
          )
        ),
        Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: const [Icon(Icons.list, color: Color(0xFF1E293B)), SizedBox(width: 8), Text('Desglose Detallado por Territorio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))])),
        ...tablasDetalleZonas,
      ],
    );
  }

  // ====================================================================
  // 4. PESTAÑA CANALES
  // ====================================================================
  Widget _buildTabCanales(Map<String, dynamic> datosCanales, double metaMes) {
    if (datosCanales.isEmpty) return _buildEmptyState('Avance por Canal');
    
    List<TableRow> rowsResumen = [];
    List<Widget> tablasDetalleZonas = [];

    rowsResumen.add(
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFDDEBF7)),
        children: [
          Container(decoration: const BoxDecoration(color: Color(0xFF5B9BD5)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: const Text('ZONAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
          _celdaHeaderGrupo('OBJETIVO CANAL\nTRADICIONAL'), _celdaHeaderGrupo('OBJETIVO CANAL\nSUPERMERCADO'), _celdaHeaderGrupo('OBJETIVO CANAL\nMAYORISTA'),
          _celdaHeaderGrupo('AVANCE CANAL\nTRADICIONAL'), _celdaHeaderGrupo('AVANCE CANAL\nSUPERMERCADO'), _celdaHeaderGrupo('AVANCE CANAL\nMAYORISTA'),
          Container(decoration: const BoxDecoration(color: Color(0xFFE2F0D9)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: const Text('% AVANCE CANAL\nTRADICIONAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFE2F0D9)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: const Text('% AVANCE CANAL\nSUPERMERCADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFE2F0D9)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: const Text('% AVANCE CANAL\nMAYORISTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFF8CBAD)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: const Text('VENTA POR CUMPLIR\nTRADICIONAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFF8CBAD)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: const Text('VENTA POR CUMPLIR\nSUPERMERCADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
          Container(decoration: const BoxDecoration(color: Color(0xFFF8CBAD)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: const Text('VENTA POR CUMPLIR\nMAYORISTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center)),
        ]
      )
    );

    double gObjTrad = 0, gObjSup = 0, gObjMay = 0;
    double gAvTrad = 0, gAvSup = 0, gAvMay = 0;

    datosCanales.forEach((zona, territorios) {
      List<DataRow> filasDetalle = [];
      double tObjTrad = 0, tObjSup = 0, tObjMay = 0;
      double tAvTrad = 0, tAvSup = 0, tAvMay = 0;

      for (var t in (territorios as List)) {
        double oTrad = double.tryParse(t['obj_tradicional']?.toString() ?? '0') ?? 0;
        double aTrad = double.tryParse(t['avance_tradicional']?.toString() ?? '0') ?? 0;
        double oSup = double.tryParse(t['obj_supermercado']?.toString() ?? '0') ?? 0;
        double aSup = double.tryParse(t['avance_supermercado']?.toString() ?? '0') ?? 0;
        double oMay = double.tryParse(t['obj_mayorista']?.toString() ?? '0') ?? 0;
        double aMay = double.tryParse(t['avance_mayorista']?.toString() ?? '0') ?? 0;

        tObjTrad += oTrad; tAvTrad += aTrad;
        tObjSup += oSup; tAvSup += aSup;
        tObjMay += oMay; tAvMay += aMay;

        double pTrad = oTrad > 0 ? (aTrad / oTrad) * 100 : 0;
        double pSup = oSup > 0 ? (aSup / oSup) * 100 : 0;
        double pMay = oMay > 0 ? (aMay / oMay) * 100 : 0;

        filasDetalle.add(DataRow(cells: [
          DataCell(Text(t['territorio_nombre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Row(children: [const Icon(Icons.person, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(t['vendedor_nombre_completo']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.black54))])),
          DataCell(Text(_formatoPesos(oTrad))), DataCell(Text(_formatoPesos(oSup))), DataCell(Text(_formatoPesos(oMay))),
          DataCell(Text(_formatoPesos(aTrad))), DataCell(Text(_formatoPesos(aSup))), DataCell(Text(_formatoPesos(aMay))),
          _celdaPorcentaje(pTrad, metaMes), _celdaPorcentaje(pSup, metaMes), _celdaPorcentaje(pMay, metaMes),
          DataCell(Text(_formatoPesos(aTrad - oTrad), style: TextStyle(color: (aTrad - oTrad) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
          DataCell(Text(_formatoPesos(aSup - oSup), style: TextStyle(color: (aSup - oSup) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
          DataCell(Text(_formatoPesos(aMay - oMay), style: TextStyle(color: (aMay - oMay) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
        ]));
      }

      gObjTrad += tObjTrad; gAvTrad += tAvTrad;
      gObjSup += tObjSup; gAvSup += tAvSup;
      gObjMay += tObjMay; gAvMay += tAvMay;

      double zP_Trad = tObjTrad > 0 ? (tAvTrad / tObjTrad) * 100 : 0;
      double zP_Sup = tObjSup > 0 ? (tAvSup / tObjSup) * 100 : 0;
      double zP_May = tObjMay > 0 ? (tAvMay / tObjMay) * 100 : 0;

      rowsResumen.add(TableRow(
        decoration: const BoxDecoration(color: Colors.white),
        children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(zona.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tObjTrad), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tObjSup), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tObjMay), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvTrad), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvSup), style: const TextStyle(fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvMay), style: const TextStyle(fontSize: 11))),
          Container(decoration: BoxDecoration(color: _colorSemaforo(zP_Trad, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(zP_Trad), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
          Container(decoration: BoxDecoration(color: _colorSemaforo(zP_Sup, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(zP_Sup), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
          Container(decoration: BoxDecoration(color: _colorSemaforo(zP_May, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(zP_May), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvTrad - tObjTrad), style: TextStyle(color: (tAvTrad - tObjTrad) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvSup - tObjSup), style: TextStyle(color: (tAvSup - tObjSup) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11))),
          Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(tAvMay - tObjMay), style: TextStyle(color: (tAvMay - tObjMay) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11))),
        ]
      ));

      tablasDetalleZonas.add(
        Card(
          margin: const EdgeInsets.only(bottom: 24), elevation: 3, clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(color: Color(0xFF5B9BD5)),
                padding: const EdgeInsets.all(12), child: Text('ZONA: ${zona.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFDDEBF7)), columnSpacing: 15, dataRowHeight: 45,
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  columns: [
                    const DataColumn(label: Text('Terr.')), const DataColumn(label: Text('Vendedor')), 
                    const DataColumn(label: Text('Obj Trad')), const DataColumn(label: Text('Obj Sup')), const DataColumn(label: Text('Obj May')),
                    const DataColumn(label: Text('Av Trad')), const DataColumn(label: Text('Av Sup')), const DataColumn(label: Text('Av May')),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFA9D08E)), padding: const EdgeInsets.all(8), child: const Text('% Trad'))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFA9D08E)), padding: const EdgeInsets.all(8), child: const Text('% Sup'))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFA9D08E)), padding: const EdgeInsets.all(8), child: const Text('% May'))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFF87171)), padding: const EdgeInsets.all(8), child: const Text('Falt. Trad', style: TextStyle(color: Colors.white)))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFF87171)), padding: const EdgeInsets.all(8), child: const Text('Falt. Sup', style: TextStyle(color: Colors.white)))),
                    DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFFF87171)), padding: const EdgeInsets.all(8), child: const Text('Falt. May', style: TextStyle(color: Colors.white)))),
                  ],
                  rows: filasDetalle,
                ),
              ),
            ],
          ),
        )
      );
    });

    double gPT_Trad = gObjTrad > 0 ? (gAvTrad / gObjTrad) * 100 : 0;
    double gPT_Sup = gObjSup > 0 ? (gAvSup / gObjSup) * 100 : 0;
    double gPT_May = gObjMay > 0 ? (gAvMay / gObjMay) * 100 : 0;

    rowsResumen.add(TableRow(
      decoration: BoxDecoration(color: Colors.yellow.shade200),
      children: [
        const Padding(padding: EdgeInsets.all(8), child: Text('TOTAL MÁXIMA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gObjTrad), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gObjSup), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gObjMay), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvTrad), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvSup), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvMay), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
        Container(decoration: BoxDecoration(color: _colorSemaforo(gPT_Trad, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(gPT_Trad), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
        Container(decoration: BoxDecoration(color: _colorSemaforo(gPT_Sup, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(gPT_Sup), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
        Container(decoration: BoxDecoration(color: _colorSemaforo(gPT_May, metaMes)), padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_formatoPct(gPT_May), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvTrad - gObjTrad), style: TextStyle(color: (gAvTrad - gObjTrad) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvSup - gObjSup), style: TextStyle(color: (gAvSup - gObjSup) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w900, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text(_formatoPesos(gAvMay - gObjMay), style: TextStyle(color: (gAvMay - gObjMay) < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w900, fontSize: 11))),
      ]
    ));

    return ListView(
      padding: const EdgeInsets.all(16), physics: const BouncingScrollPhysics(),
      children: [
        Card(
          elevation: 4, margin: const EdgeInsets.only(bottom: 30), clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(border: TableBorder.all(color: Colors.grey.shade300), defaultColumnWidth: const IntrinsicColumnWidth(), children: rowsResumen),
          )
        ),
        Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: const [Icon(Icons.list, color: Color(0xFF1E293B)), SizedBox(width: 8), Text('Desglose Detallado por Territorio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)))])),
        ...tablasDetalleZonas,
      ],
    );
  }

  // ====================================================================
  // 5. PESTAÑA CATEGORÍAS (MATRIZ)
  // ====================================================================
  Widget _buildTabCategorias(Map<String, dynamic> datosCat, double metaMes) {
    if (datosCat.isEmpty || !datosCat.containsKey('data') || datosCat['data'] is! Map || (datosCat['data'] as Map).isEmpty) return _buildEmptyState('Avance por Categoría');
    
    List<dynamic> zonas = datosCat['zonas'];
    Map<String, dynamic> matrizData = Map<String, dynamic>.from(datosCat['data']);

    List<DataColumn> columnasMatriz = [
      DataColumn(label: Container(decoration: const BoxDecoration(color: Color(0xFF0284C7)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15), child: const Text('CATEGORIAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
    ];

    for (var z in zonas) {
      columnasMatriz.addAll([
        DataColumn(label: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(decoration: const BoxDecoration(color: Color(0xFF5B9BD5)), padding: const EdgeInsets.all(6), alignment: Alignment.center, child: Text(z.toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
            Container(decoration: const BoxDecoration(color: Color(0xFFDDEBF7)), padding: const EdgeInsets.all(6), alignment: Alignment.center, child: const Text('OBJETIVO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
          ],
        )),
        DataColumn(label: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(decoration: const BoxDecoration(color: Color(0xFF5B9BD5)), padding: const EdgeInsets.all(6), child: const Text('', style: TextStyle(fontSize: 11))), 
            Container(decoration: const BoxDecoration(color: Color(0xFFDDEBF7)), padding: const EdgeInsets.all(6), alignment: Alignment.center, child: const Text('AVANCE \$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
          ],
        )),
        DataColumn(label: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(decoration: const BoxDecoration(color: Color(0xFF5B9BD5)), padding: const EdgeInsets.all(6), child: const Text('', style: TextStyle(fontSize: 11))),
            Container(decoration: const BoxDecoration(color: Color(0xFFE2F0D9)), padding: const EdgeInsets.all(6), alignment: Alignment.center, child: const Text('AVANCE %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
          ],
        )),
        DataColumn(label: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(decoration: const BoxDecoration(color: Color(0xFF5B9BD5)), padding: const EdgeInsets.all(6), child: const Text('', style: TextStyle(fontSize: 11))),
            Container(decoration: const BoxDecoration(color: Color(0xFFF8CBAD)), padding: const EdgeInsets.all(6), alignment: Alignment.center, child: const Text('VENTA POR CUMPLIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
          ],
        )),
      ]);
    }

    List<DataRow> filasMatriz = [];
    Map<String, double> gTotObjZona = {};
    Map<String, double> gTotAvZona = {};
    for (var z in zonas) { gTotObjZona[z] = 0; gTotAvZona[z] = 0; }

    matrizData.forEach((catNombre, infoZonas) {
      List<DataCell> celdas = [
        DataCell(Container(decoration: const BoxDecoration(color: Color(0xFF0284C7)), alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(catNombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11))))
      ];
      
      for (var z in zonas) {
        var dz = infoZonas[z] ?? {'obj': 0, 'av': 0};
        double obj = double.tryParse(dz['obj']?.toString() ?? '0') ?? 0;
        double av = double.tryParse(dz['av']?.toString() ?? '0') ?? 0;
        double pct = obj > 0 ? (av / obj) * 100 : 0;
        double faltante = av - obj;

        gTotObjZona[z] = gTotObjZona[z]! + obj;
        gTotAvZona[z] = gTotAvZona[z]! + av;

        celdas.add(DataCell(Text(_formatoPesos(obj), style: const TextStyle(fontSize: 12))));
        celdas.add(DataCell(Text(_formatoPesos(av), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
        celdas.add(_celdaPorcentaje(pct, metaMes));
        celdas.add(DataCell(Text(_formatoPesos(faltante), style: TextStyle(color: faltante < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12))));
      }
      filasMatriz.add(DataRow(cells: celdas, color: MaterialStateProperty.resolveWith((states) => Colors.white)));
    });

    List<DataCell> celdasTotalMatriz = [
      DataCell(Container(decoration: const BoxDecoration(color: Color(0xFF002060)), alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8), child: const Text('TOTALES', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white))))
    ];

    for (var z in zonas) {
      double tObj = gTotObjZona[z]!; double tAv = gTotAvZona[z]!;
      double tPct = tObj > 0 ? (tAv / tObj) * 100 : 0;
      celdasTotalMatriz.add(DataCell(Container(decoration: const BoxDecoration(color: Color(0xFF002060)), alignment: Alignment.centerLeft, child: Text(_formatoPesos(tObj), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))));
      celdasTotalMatriz.add(DataCell(Container(decoration: const BoxDecoration(color: Color(0xFF002060)), alignment: Alignment.centerLeft, child: Text(_formatoPesos(tAv), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))));
      celdasTotalMatriz.add(_celdaPorcentaje(tPct, metaMes));
      celdasTotalMatriz.add(DataCell(Container(decoration: const BoxDecoration(color: Color(0xFF002060)), alignment: Alignment.centerLeft, child: Text(_formatoPesos(tAv - tObj), style: const TextStyle(color: Color(0xFFffcccc), fontWeight: FontWeight.bold)))));
    }
    filasMatriz.add(DataRow(cells: celdasTotalMatriz));

    List<TableRow> rowsResumenMaxima = [];
    rowsResumenMaxima.add(
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFDDEBF7)),
        children: [
          Container(decoration: const BoxDecoration(color: Color(0xFF0284C7)), padding: const EdgeInsets.all(10), child: const Text('CATEGORIAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
          Container(padding: const EdgeInsets.all(10), child: const Text('OBJETIVO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Container(padding: const EdgeInsets.all(10), child: const Text('AVANCE \$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Container(decoration: const BoxDecoration(color: Color(0xFFE2F0D9)), padding: const EdgeInsets.all(10), child: const Text('AVANCE %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Container(decoration: const BoxDecoration(color: Color(0xFFF8CBAD)), padding: const EdgeInsets.all(10), child: const Text('VENTA POR CUMPLIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ]
      )
    );

    double grandTotalObj = 0, grandTotalAv = 0;

    matrizData.forEach((catNombre, infoZonas) {
      double cObj = 0, cAv = 0;
      for (var z in zonas) {
        cObj += double.tryParse(infoZonas[z]?['obj']?.toString() ?? '0') ?? 0;
        cAv += double.tryParse(infoZonas[z]?['av']?.toString() ?? '0') ?? 0;
      }
      grandTotalObj += cObj; grandTotalAv += cAv;
      double cPct = cObj > 0 ? (cAv / cObj) * 100 : 0;
      double cFalt = cAv - cObj;

      rowsResumenMaxima.add(TableRow(
        decoration: const BoxDecoration(color: Colors.white),
        children: [
          Padding(padding: const EdgeInsets.all(10), child: Text(catNombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 11))),
          Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(cObj))),
          Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(cAv), style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(decoration: BoxDecoration(color: _colorSemaforo(cPct, metaMes)), padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_formatoPct(cPct), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(cFalt), style: TextStyle(color: cFalt < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
        ]
      ));
    });

    double grandPct = grandTotalObj > 0 ? (grandTotalAv / grandTotalObj) * 100 : 0;
    
    rowsResumenMaxima.add(TableRow(
      decoration: const BoxDecoration(color: Color(0xFF002060)),
      children: [
        const Padding(padding: EdgeInsets.all(10), child: Text('TOTALES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
        Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(grandTotalObj), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
        Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(grandTotalAv), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
        Container(decoration: BoxDecoration(color: _colorSemaforo(grandPct, metaMes)), padding: const EdgeInsets.symmetric(vertical: 10), child: Text(_formatoPct(grandPct), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900), textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(10), child: Text(_formatoPesos(grandTotalAv - grandTotalObj), style: const TextStyle(color: Color(0xFFffcccc), fontWeight: FontWeight.w900))),
      ]
    ));

    return ListView(
      padding: const EdgeInsets.all(16), physics: const BouncingScrollPhysics(),
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: const [Icon(Icons.grid_on, color: Color(0xFF5E35B1)), SizedBox(width: 8), Text('Desglose por Zonas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF5E35B1)))])),
        Card(
          elevation: 4, clipBehavior: Clip.antiAlias, margin: const EdgeInsets.only(bottom: 30),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 60, dataRowHeight: 40, columnSpacing: 0, horizontalMargin: 0, dividerThickness: 1,
              columns: columnasMatriz, rows: filasMatriz,
            ),
          ),
        ),
        Card(
          elevation: 4, clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(color: Color(0xFF5B9BD5)),
                padding: const EdgeInsets.all(12), child: const Text('RESUMEN DE VENTAS CATEGORIAS MÁXIMA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
              ),
              Table(border: TableBorder.all(color: Colors.grey.shade300), defaultColumnWidth: const IntrinsicColumnWidth(), children: rowsResumenMaxima),
            ],
          ),
        )
      ],
    );
  }

  // --- Helpers Adicionales ---
  Widget _celdaHeaderGrupo(String texto) => Container(decoration: const BoxDecoration(color: Color(0xFFDDEBF7)), padding: const EdgeInsets.all(8), alignment: Alignment.center, child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center));
  
  DataCell _celdaPorcentaje(double pct, double metaMes) => DataCell(
    Container(
      width: double.infinity, 
      height: double.infinity, 
      alignment: Alignment.center, 
      decoration: BoxDecoration(color: _colorSemaforo(pct, metaMes)), 
      child: Text(_formatoPct(pct), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
    )
  );
}