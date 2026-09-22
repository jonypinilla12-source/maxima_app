import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart'; // <-- Importamos el escáner

class IngresarProductoScreen extends StatefulWidget {
  final int usuarioId;

  const IngresarProductoScreen({super.key, required this.usuarioId});

  @override
  State<IngresarProductoScreen> createState() => _IngresarProductoScreenState();
}

class _IngresarProductoScreenState extends State<IngresarProductoScreen> {
  // --- VARIABLE CENTRALIZADA PARA LA URL ---
  //final String baseUrl = 'http://localhost/inventariomaxima'; // Para pruebas en local
  final String baseUrl = 'https://app.distribuidoramaxima.cl'; // Para producción

  final TextEditingController codigoBarraController = TextEditingController();
  final TextEditingController cantidadCajasController = TextEditingController();
  final TextEditingController loteController = TextEditingController(text: '1');
  
  String nombreProducto = 'Esperando código de barra...';
  bool isLoadingNombre = false;
  bool isSaving = false;
  DateTime fechaVencimiento = DateTime.now().add(const Duration(days: 90));

  Future<void> buscarProductoPorCodigo(String codigo) async {
    if (codigo.trim().isEmpty) {
      setState(() { nombreProducto = 'Esperando código de barra...'; });
      return;
    }

    setState(() { isLoadingNombre = true; });

    try {
      var url = Uri.parse('$baseUrl/api/buscar_maestra.php?codigo_barra=$codigo');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['ok'] == true) {
          setState(() {
            nombreProducto = data['data']['maestra_nombre'];
          });
        } else {
          setState(() {
            nombreProducto = '❌ Producto no encontrado en la maestra';
          });
        }
      }
    } catch (e) {
      setState(() {
        nombreProducto = 'Error de conexión';
      });
    }

    setState(() { isLoadingNombre = false; });
  }

  Future<void> guardarProducto() async {
    if (codigoBarraController.text.trim().isEmpty || cantidadCajasController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el código de barra y la cantidad de cajas'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() { isSaving = true; });

    try {
      var url = Uri.parse('$baseUrl/api/productos_guardar.php');
      var response = await http.post(url, body: {
        'codigo_barra': codigoBarraController.text.trim(),
        'cantidadcajas': cantidadCajasController.text.trim(),
        'vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
        'lote': loteController.text.trim().isEmpty ? '1' : loteController.text.trim(),
        'usuario_id': widget.usuarioId.toString(),
      });

      var data = json.decode(response.body);

      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['msg']), 
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        codigoBarraController.clear();
        cantidadCajasController.clear();
        loteController.text = '1';
        setState(() { nombreProducto = 'Esperando código de barra...'; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['msg']), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar al servidor'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() { isSaving = false; });
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaVencimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != fechaVencimiento) {
      setState(() {
        fechaVencimiento = picked;
      });
    }
  }

  // --- FUNCIÓN PARA ABRIR LA CÁMARA ---
  Future<void> _abrirEscaner() async {
    final String? codigoEscaneado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _EscaneoRapidoPantalla()),
    );

    // Si la cámara devuelve un código, rellenamos el input y buscamos automáticamente
    if (codigoEscaneado != null && codigoEscaneado.isNotEmpty) {
      codigoBarraController.text = codigoEscaneado;
      buscarProductoPorCodigo(codigoEscaneado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // ==========================================
      // FOOTER INFORMATIVO CON CRÉDITOS
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
      body: CustomScrollView(
        slivers: [
          // APP BAR CON GRADIENTE MODERNO
          SliverAppBar(
            expandedHeight: 140,
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
                child: const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ingreso de Productos',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CONTENIDO PRINCIPAL EN TARJETA FLOTANTE CON ANCHO CONTROLADO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de descripción superior
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recepción en Bodega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            SizedBox(height: 6),
                            Text('Registra un nuevo producto recepcionado en bodega de forma rápida y ordenada.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Formulario principal estilizado
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CÓDIGO DE BARRA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            TextField(
                              controller: codigoBarraController,
                              onChanged: buscarProductoPorCodigo,
                              decoration: InputDecoration(
                                hintText: 'Ingrese o escanee el código...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF94A3B8)), // Icono modificado
                                // --- BOTÓN DE CÁMARA AGREGADO AQUÍ ---
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6366F1), size: 26),
                                  tooltip: 'Escanear con cámara',
                                  onPressed: _abrirEscaner,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Nombre del producto autocompletado
                            const Text('NOMBRE DEL PRODUCTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: Row(
                                children: [
                                  if (isLoadingNombre)
                                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                                  else
                                    const Icon(Icons.shopping_bag_rounded, color: Color(0xFF6366F1), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      nombreProducto,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800, 
                                        fontSize: 15, 
                                        color: nombreProducto.contains('❌') ? Colors.redAccent : const Color(0xFF312E81)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Fila: Vencimiento y Cantidad de Cajas
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('VENCIMIENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _seleccionarFecha(context),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6366F1)),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${fechaVencimiento.day.toString().padLeft(2, '0')}-${fechaVencimiento.month.toString().padLeft(2, '0')}-${fechaVencimiento.year}',
                                                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('CANTIDAD CAJAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: cantidadCajasController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Ej. 10',
                                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                          prefixIcon: const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF6366F1)),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Lote
                            const Text('LOTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            TextField(
                              controller: loteController,
                              decoration: InputDecoration(
                                hintText: 'Número de lote (por defecto 1)',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                prefixIcon: const Icon(Icons.label_outline_rounded, color: Color(0xFF6366F1)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Botón Guardar con Degradado
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: isSaving ? null : guardarProducto,
                                child: isSaving 
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Registrar en Bodega', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// PANTALLA SECUNDARIA: ESCÁNER RÁPIDO DE CÓDIGO DE BARRAS
// =======================================================
class _EscaneoRapidoPantalla extends StatefulWidget {
  const _EscaneoRapidoPantalla();

  @override
  State<_EscaneoRapidoPantalla> createState() => _EscaneoRapidoPantallaState();
}

class _EscaneoRapidoPantallaState extends State<_EscaneoRapidoPantalla> {
  bool _yaEscaneado = false;
  final Color colorPrimario = const Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: colorPrimario,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_yaEscaneado) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  setState(() => _yaEscaneado = true);
                  // Retornamos el código a la pantalla anterior
                  Navigator.pop(context, rawValue);
                  break;
                }
              }
            },
          ),
          
          // Cuadro visual de enfoque
          Center(
            child: Container(
              width: 280,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Texto inferior
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código de barras del producto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}