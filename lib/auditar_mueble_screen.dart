import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuditarMuebleScreen extends StatefulWidget {
  final String qrCode;

  const AuditarMuebleScreen({Key? key, required this.qrCode}) : super(key: key);

  @override
  _AuditarMuebleScreenState createState() => _AuditarMuebleScreenState();
}

class _AuditarMuebleScreenState extends State<AuditarMuebleScreen> {
  // --- COLORES IDÉNTICOS A TUS OTRAS VISTAS ---
  final Color colorPrimario = const Color(0xFF6366F1); 
  final Color colorAzulBuscador = const Color(0xFF3B82F6); 

  bool isLoading = true;
  Map<String, dynamic>? muebleData;
  
  //final String baseUrl = 'http://localhost/inventariomaxima'; // Cambia por tu IP si estás en físico
  final String baseUrl = 'https://app.distribuidoramaxima.cl';

  @override
  void initState() {
    super.initState();
    _buscarInfoMueble();
  }

  Future<void> _buscarInfoMueble() async {
    try {
      final url = Uri.parse('$baseUrl/?c=ClienteMueble&a=AjaxObtenerInfoQR&qr=${widget.qrCode}');
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['ok']) {
          setState(() {
            muebleData = data['data'];
            isLoading = false;
          });
        } else {
          _mostrarError("QR no encontrado", data['msg']);
        }
      }
    } catch (e) {
      _mostrarError("Error de conexión", "No se pudo conectar con el servidor.");
    }
  }

  void _mostrarError(String titulo, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 10),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(mensaje, style: const TextStyle(color: Color(0xFF1E293B))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: Text('Volver', style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  // --- LÓGICA DE PROCESAMIENTO (AJAX) ---
  Future<void> _procesarAccion(String accion, String observacion, {String? nuevoClienteId}) async {
    Navigator.pop(context); // Cierra el modal/dialogo actual
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: colorPrimario)),
    );

    try {
      final url = Uri.parse('$baseUrl/?c=ClienteMueble&a=AjaxProcesarCenso');
      final body = {
        'accion': accion,
        'qr': widget.qrCode,
        'cliente_id_actual': muebleData!['cliente_id'].toString(),
        'clientemueble_id': muebleData!['clientemueble_id'].toString(),
        'observacion': observacion,
        'usuario_id': '1', 
      };

      if (accion == 'mover' && nuevoClienteId != null) {
        body['nuevo_cliente_id'] = nuevoClienteId;
      }

      final res = await http.post(url, body: body);
      Navigator.pop(context); // Oculta el loading

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['ok']) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("¡Éxito!", style: TextStyle(fontWeight: FontWeight.w900)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 60),
                  const SizedBox(height: 15),
                  Text(data['msg'], textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    onPressed: () {
                      Navigator.pop(context); 
                      Navigator.pop(context, true); 
                    },
                    child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            )
          );
        } else {
          _mostrarFallo(data['msg']);
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarFallo("Ocurrió un problema al procesar la solicitud.");
    }
  }

  void _mostrarFallo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ), 
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }

  // --- MODALES DE ACCIÓN ---
  void _modalConfirmar() {
    TextEditingController obsController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text("Confirmar mueble", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("El mueble está en el local. Puedes dejar una observación opcional:", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: obsController,
              decoration: InputDecoration(
                hintText: "Ej: En buen estado...", 
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
              ),
              maxLines: 2,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            onPressed: () => _procesarAccion('confirmar', obsController.text),
            child: const Text("Sí, proceder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  void _modalBaja() {
    TextEditingController obsController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text("Dar de baja", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Indica el motivo por el cual el mueble pasará a Inactivo (Obligatorio):", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: obsController,
              decoration: InputDecoration(
                hintText: "Motivo de la baja...", 
                filled: true,
                fillColor: const Color(0xFFFEF2F2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFECACA))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFECACA))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
              ),
              maxLines: 2,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            onPressed: () {
              if (obsController.text.trim().isEmpty) {
                _mostrarFallo("Debes ingresar un motivo para dar de baja.");
                return;
              }
              _procesarAccion('baja', obsController.text);
            },
            child: const Text("Dar de Baja", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  void _modalReasignar() {
    TextEditingController rutController = TextEditingController();
    TextEditingController obsController = TextEditingController();
    List<dynamic> localesEncontrados = [];
    String? localSeleccionado;
    bool buscando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.sync_alt_rounded, color: Color(0xFFF59E0B), size: 26),
                      SizedBox(width: 10),
                      Text("Reasignar Mueble", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  const Text("1. Buscar RUT del nuevo cliente", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rutController,
                          decoration: InputDecoration(
                            hintText: "Ej: 12345678-9", 
                            filled: true, fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorAzulBuscador, 
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: () async {
                            if (rutController.text.length < 3) return;
                            setModalState(() => buscando = true);
                            final url = Uri.parse('$baseUrl/?c=ClienteMueble&a=BuscarClientesRut&rut=${rutController.text}');
                            final res = await http.get(url);
                            setModalState(() {
                              localesEncontrados = json.decode(res.body);
                              localSeleccionado = localesEncontrados.isNotEmpty ? localesEncontrados.first['cliente_id'].toString() : null;
                              buscando = false;
                            });
                          },
                          child: buscando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.search, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text("2. Seleccionar Local de destino", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                    ),
                    hint: const Text("Selecciona un local...", style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                    value: localSeleccionado,
                    items: localesEncontrados.map((c) => DropdownMenuItem<String>(
                      value: c['cliente_id'].toString(),
                      child: Text("Local ${c['cliente_local']} - ${c['cliente_razonsocial']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setModalState(() => localSeleccionado = val),
                  ),
                  const SizedBox(height: 16),

                  const Text("3. Observaciones (Opcional)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: obsController,
                    decoration: InputDecoration(
                      hintText: "¿Por qué se encontró aquí?", 
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () {
                        if (localSeleccionado == null) {
                          _mostrarFallo("Debes seleccionar un cliente destino");
                          return;
                        }
                        _procesarAccion('mover', obsController.text, nuevoClienteId: localSeleccionado);
                      },
                      child: const Text("Confirmar Traslado", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      }
    );
  }

  // --- UI PRINCIPAL CON SLIVERAPPBAR ---
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

      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: colorPrimario))
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // APP BAR IDÉNTICO AL RESTO DE LA APP
              SliverAppBar(
                expandedHeight: 130, floating: false, pinned: true, backgroundColor: colorPrimario, elevation: 0,
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Auditoría de Activo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 44),
                                child: Text('QR: ${widget.qrCode}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CONTENIDO DE LA FICHA
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TARJETAS DE INFORMACIÓN (Estilo Grid 2x2 Limpio)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildInfoCard("TIPO DE MUEBLE", muebleData!['tipomueble_nombre'], Icons.chair_rounded, const Color(0xFF7E22CE), const Color(0xFFF3E8FF))),
                                const SizedBox(width: 15),
                                Expanded(child: _buildEstadoCard()),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
                            Row(
                              children: [
                                Expanded(child: _buildInfoCard("CLIENTE ASIGNADO", muebleData!['cliente_razonsocial'], Icons.storefront_rounded, const Color(0xFFB45309), const Color(0xFFFFEDD5))),
                                const SizedBox(width: 15),
                                Expanded(child: _buildInfoCard("RUT / LOCAL", "${muebleData!['cliente_rut']}\nLocal ${muebleData!['cliente_local'] ?? '1'}", Icons.location_on_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      const Text("¿Qué deseas hacer con este mueble?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),

                      // BOTONES DE ACCIÓN (Verde, Naranja, Rojo idénticos a web)
                      _buildActionButton(
                        "Confirmar Mueble", 
                        Icons.check_circle_rounded, 
                        const Color(0xFF10B981), 
                        _modalConfirmar
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        "Reasignar Cliente", 
                        Icons.sync_alt_rounded, 
                        const Color(0xFFF59E0B), 
                        _modalReasignar
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        "Dar de Baja", 
                        Icons.delete_outline_rounded, 
                        const Color(0xFFEF4444), 
                        _modalBaja
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              )
            ],
          ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color iconColor, Color bgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.2)),
      ],
    );
  }

  Widget _buildEstadoCard() {
    // Verificamos si existe el registro de censo/auditoría para este mueble
    bool isCensado = muebleData!['estado_censo'] != null || muebleData!['fecha_censo'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF0369A1), size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text("ESTADO ACTUAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isCensado ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), 
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isCensado ? Icons.check_circle_rounded : Icons.pending_actions_rounded, size: 13, color: isCensado ? const Color(0xFF065F46) : const Color(0xFF991B1B)),
              const SizedBox(width: 4),
              Text(isCensado ? "CENSADO" : "SIN CENSAR", style: TextStyle(color: isCensado ? const Color(0xFF065F46) : const Color(0xFF991B1B), fontWeight: FontWeight.w900, fontSize: 10)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}