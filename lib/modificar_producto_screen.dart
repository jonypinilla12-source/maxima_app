import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async'; 

class ModificarProductoScreen extends StatefulWidget {
  final String? productoId; 
  final int usuarioId;

  const ModificarProductoScreen({
    Key? key, 
    this.productoId, 
    required this.usuarioId
  }) : super(key: key);

  @override
  State<ModificarProductoScreen> createState() => _ModificarProductoScreenState();
}

class _ModificarProductoScreenState extends State<ModificarProductoScreen> {
  final Color colorPrimario = const Color(0xFF6F42C1);
  final Color colorVerde = const Color(0xFF10B981);
  final Color bgColor = const Color(0xFFF8FAFC);

  // --- CONTROLADORES ---
  final TextEditingController _codBarraCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _cantidadCtrl = TextEditingController(text: "0");
  final TextEditingController _vencimientoCtrl = TextEditingController();
  final TextEditingController _loteCtrl = TextEditingController(text: "1");
  final TextEditingController _cajasCtrl = TextEditingController(text: "0");
  final TextEditingController _posBarraCtrl = TextEditingController();
  final TextEditingController _filaCtrl = TextEditingController();
  final TextEditingController _sectorCtrl = TextEditingController();
  final TextEditingController _posicionCtrl = TextEditingController();

  String? maestraId;
  String? posicionId;
  String? idPosOriginal;
  bool posicionNoDisponible = false;
  bool isLoading = true; 

  Timer? _debounceMaestra;
  Timer? _debouncePosicion;

  //final String baseUrl = 'http://localhost/inventariomaxima'; 
  final String baseUrl = 'http://app.distribuidoramaxima.cl'; 
  
  @override
  void initState() {
    super.initState();
    if (widget.productoId != null) {
      _cargarDatosProducto(widget.productoId!);
    } else {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    _debounceMaestra?.cancel();
    _debouncePosicion?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatosProducto(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/?c=Productos&a=AjaxObtenerProducto&id=$id'));
      if (res.statusCode == 200) {
        final jsonResponse = json.decode(res.body);
        if (jsonResponse['ok']) {
          final data = jsonResponse['data'];
          setState(() {
            maestraId = data['maestra_id']?.toString();
            posicionId = data['posicion_id']?.toString();
            idPosOriginal = data['posicion_id']?.toString();

            _codBarraCtrl.text = data['maestra_codigobarra'] ?? '';
            _nombreCtrl.text = data['maestra_nombre'] ?? '';
            _cantidadCtrl.text = data['producto_cantidad']?.toString() ?? '0';
            _vencimientoCtrl.text = data['producto_vencimiento'] ?? '';
            _loteCtrl.text = data['producto_lote'] ?? '1';
            _cajasCtrl.text = data['producto_cantidadCajas']?.toString() ?? '0';
            _posBarraCtrl.text = data['posicion_codigo'] ?? '';
            _filaCtrl.text = data['posicion_fila'] ?? '';
            _sectorCtrl.text = data['posicion_sector'] ?? '';
            _posicionCtrl.text = data['posicion_nombre'] ?? '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonResponse['msg']), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Error cargando producto: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión"), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _buscarMaestraId(String codigo) async {
    if (codigo.isEmpty) {
      setState(() => _nombreCtrl.text = '');
      return;
    }
    try {
      final res = await http.get(Uri.parse('$baseUrl/?c=Productos&a=BuscarMaestraId&codigo_barra=$codigo'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          maestraId = data['maestra_id']?.toString();
          _nombreCtrl.text = data['maestra_nombre'] ?? 'Producto no encontrado';
        });
      }
    } catch (e) {
      debugPrint("Error buscando maestra: $e");
    }
  }

  Future<void> _buscarPosicionId(String codigo) async {
    if (codigo.isEmpty) {
      setState(() {
        posicionId = null;
        _filaCtrl.text = '';
        _sectorCtrl.text = '';
        _posicionCtrl.text = '';
        posicionNoDisponible = false;
      });
      return;
    }

    try {
      final res = await http.get(Uri.parse('$baseUrl/?c=Productos&a=BuscarPosicionId&posicion_barra=$codigo'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          if (data['posicion_id'] != null) {
            posicionId = data['posicion_id']?.toString();
            _filaCtrl.text = data['posicion_fila'] ?? '';
            _sectorCtrl.text = data['posicion_sector'] ?? '';
            _posicionCtrl.text = data['posicion_nombre'] ?? '';

            int estado = data['posicion_estado'] is int ? data['posicion_estado'] : int.tryParse(data['posicion_estado'].toString()) ?? 1;
            
            if (estado == 0 && posicionId != idPosOriginal) {
              posicionNoDisponible = true;
            } else {
              posicionNoDisponible = false;
            }
          } else {
            _filaCtrl.text = '';
            _sectorCtrl.text = '';
            _posicionCtrl.text = '';
            posicionNoDisponible = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error buscando posición: $e");
    }
  }

  Future<void> _seleccionarFecha() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: colorPrimario, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _vencimientoCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _abrirEscaner(bool isProducto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context); 
                      String codigoLeido = barcode.rawValue!.trim();
                      
                      if (isProducto) {
                        _codBarraCtrl.text = codigoLeido;
                        _buscarMaestraId(codigoLeido);
                      } else {
                        _posBarraCtrl.text = codigoLeido;
                        _buscarPosicionId(codigoLeido);
                      }
                      break;
                    }
                  }
                },
              ),
              Positioned(
                top: 20, right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Center(
                child: Text("Escaneando...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarErrorVisual(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(mensaje)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
        ],
      )
    );
  }

  Future<void> _guardarCambios() async {
    if (posicionNoDisponible) return;
    
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/?c=Productos&a=AjaxUpdateProductos'), // <-- Debe apuntar a AjaxUpdateProductos
        body: {
          'id': widget.productoId ?? '0',
          'maestra_id': maestraId ?? '',
          'posicion_id': posicionId ?? '',
          'idpos': idPosOriginal ?? '',
          'cantidad': _cantidadCtrl.text,
          'vencimiento': _vencimientoCtrl.text,
          'lote': _loteCtrl.text,
          'cajas': _cajasCtrl.text,
          'usuario_id': widget.usuarioId.toString(), // Enviando el usuario real de Flutter
        }
      );

      if (res.statusCode == 200) {
        try {
          final data = json.decode(res.body);
          if (data['ok']) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.green));
            Navigator.pop(context, true); 
          } else {
            _mostrarErrorVisual("No se pudo guardar", data['msg']);
          }
        } catch (formatException) {
          _mostrarErrorVisual("Error de PHP", "El servidor no envió JSON, envió esto:\n\n${res.body}");
        }
      } else {
        _mostrarErrorVisual("Error HTTP", "Código de estado: ${res.statusCode}");
      }
    } catch (e) {
      _mostrarErrorVisual("Error Técnico", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDeco({bool readOnly = false, Widget? suffixIcon}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorPrimario, width: 2)),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
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
      appBar: AppBar(
        title: const Text('Modificación de Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 1,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colorPrimario))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(width: 4, height: 20, decoration: BoxDecoration(color: colorPrimario, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          const Text("Formulario de edición", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Código de Barra"),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codBarraCtrl,
                                  decoration: _inputDeco(),
                                  onChanged: (val) {
                                    if (_debounceMaestra?.isActive ?? false) _debounceMaestra!.cancel();
                                    _debounceMaestra = Timer(const Duration(milliseconds: 500), () {
                                      _buscarMaestraId(val);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorVerde,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: () => _abrirEscaner(true),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text("Escanear", style: TextStyle(fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),

                          _buildLabel("Nombre del Producto"),
                          TextField(
                            controller: _nombreCtrl,
                            readOnly: true,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            decoration: _inputDeco(readOnly: true),
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Cantidad"),
                                    TextField(controller: _cantidadCtrl, keyboardType: TextInputType.number, decoration: _inputDeco()),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Fecha Vencimiento"),
                                    TextField(
                                      controller: _vencimientoCtrl,
                                      readOnly: true,
                                      onTap: _seleccionarFecha,
                                      decoration: _inputDeco(suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B))),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Lote"),
                                    TextField(controller: _loteCtrl, decoration: _inputDeco()),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Cantidad de Cajas"),
                                    TextField(controller: _cajasCtrl, keyboardType: TextInputType.number, decoration: _inputDeco()),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Código Barra Posición"),
                                    TextField(
                                      controller: _posBarraCtrl,
                                      decoration: _inputDeco(
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.qr_code_scanner_rounded, color: colorPrimario),
                                          onPressed: () => _abrirEscaner(false),
                                        )
                                      ),
                                      onChanged: (val) {
                                        if (_debouncePosicion?.isActive ?? false) _debouncePosicion!.cancel();
                                        _debouncePosicion = Timer(const Duration(milliseconds: 500), () {
                                          _buscarPosicionId(val);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          if (posicionNoDisponible)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFED7AA)),
                              ),
                              child: const Text(
                                "¡La posición NO ESTÁ DISPONIBLE!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Fila"),
                                    TextField(controller: _filaCtrl, readOnly: true, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)), decoration: _inputDeco(readOnly: true)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Sector"),
                                    TextField(controller: _sectorCtrl, readOnly: true, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)), decoration: _inputDeco(readOnly: true)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Posición"),
                                    TextField(controller: _posicionCtrl, readOnly: true, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)), decoration: _inputDeco(readOnly: true)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimario,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                disabledBackgroundColor: Colors.grey[300]
                              ),
                              onPressed: (posicionNoDisponible || isLoading) ? null : _guardarCambios,
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text("Guardar cambios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}