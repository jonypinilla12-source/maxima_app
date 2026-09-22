import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class ClienteMuebleScreen extends StatefulWidget {
  const ClienteMuebleScreen({Key? key}) : super(key: key);

  @override
  _ClienteMuebleScreenState createState() => _ClienteMuebleScreenState();
}

class _ClienteMuebleScreenState extends State<ClienteMuebleScreen> {
  final Color colorPrimario = const Color(0xFF6366F1);
  final Color colorAzul = const Color(0xFF3B82F6);
  final Color bgColor = const Color(0xFFF8FAFC); 

  TextEditingController rutController = TextEditingController();
  
  bool isLoading = false;
  List<dynamic> clientesEncontrados = [];
  dynamic clienteSeleccionado;
  List<dynamic> mueblesCliente = [];
  List<dynamic> tiposMueble = [];

  // --- VARIABLES DEL MAPA ---
  double? miLatitud;
  double? miLongitud;
  double distanciaKm = 0.0;

  // Ajusta tu URL base aquí
  //final String baseUrl = 'http://localhost/inventariomaxima'; 
  final String baseUrl = 'https://app.distribuidoramaxima.cl';

  @override
  void initState() {
    super.initState();
    _cargarTiposMueble();
  }

  Future<void> _cargarTiposMueble() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/api_tipos_muebles_listar.php'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['ok']) setState(() => tiposMueble = data['data']);
      }
    } catch (e) {
      debugPrint("Error tipos mueble: $e");
    }
  }

  // --- BUSCAR CLIENTE Y VALIDAR DISTANCIA ---
  Future<void> _buscarCliente({String? rutEspecifico, String? clienteIdSelect}) async {
    String rutBuscar = rutEspecifico ?? rutController.text.trim();
    if (rutBuscar.isEmpty) return;

    setState(() {
      isLoading = true;
      clienteSeleccionado = null;
      mueblesCliente = [];
      clientesEncontrados = [];
      miLatitud = null;
      miLongitud = null;
    });

    try {
      final apiRes = await http.get(Uri.parse('$baseUrl/api/api_buscar_clientes_rut.php?rut=$rutBuscar'));
      
      if (apiRes.statusCode == 200) {
        List<dynamic> lista = json.decode(apiRes.body);
        
        if (lista.isNotEmpty) {
          if (clienteIdSelect != null) {
            clienteSeleccionado = lista.firstWhere((c) => c['cliente_id'].toString() == clienteIdSelect, orElse: () => lista.first);
          } else {
            clienteSeleccionado = lista.first;
          }
          
          _cargarMueblesCliente(clienteSeleccionado['cliente_id'].toString());
          await _calcularDistanciaMapa(clienteSeleccionado);
        }
        
        setState(() => clientesEncontrados = lista);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al buscar cliente")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarMueblesCliente(String clienteId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/api_muebles_clientes.php?cliente_id=$clienteId'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => mueblesCliente = data['data'] ?? []);
      }
    } catch (e) {
      debugPrint("Error muebles: $e");
    }
  }

  // --- LÓGICA GEOLOCALIZACIÓN Y DISTANCIA ---
  Future<void> _calcularDistanciaMapa(dynamic cliente) async {
    double latCli = double.tryParse(cliente['cliente_latitud']?.toString() ?? '0') ?? 0.0;
    double lngCli = double.tryParse(cliente['cliente_longitud']?.toString() ?? '0') ?? 0.0;

    if (latCli == 0.0 || lngCli == 0.0) return; 

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    double distMetros = Geolocator.distanceBetween(latCli, lngCli, pos.latitude, pos.longitude);
    double km = distMetros / 1000;

    setState(() {
      miLatitud = pos.latitude;
      miLongitud = pos.longitude;
      distanciaKm = km;
    });

    if (km > 1.0) {
      _mostrarAlertaDesactualizada(km.toStringAsFixed(2));
    }
  }

  void _mostrarAlertaDesactualizada(String km) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 50),
            ),
            const SizedBox(height: 20),
            const Text("Ubicación desactualizada", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                children: [
                  const TextSpan(text: "Este cliente tiene una diferencia de "),
                  TextSpan(text: "$km km\n", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const TextSpan(text: "Se recomienda regularizar la ubicación 📍"),
                ]
              )
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      )
    );
  }

  // --- MODAL ASIGNAR MUEBLE ---
  void _mostrarModalAsignar() {
    String? tipoMuebleId;
    TextEditingController qrController = TextEditingController();
    TextEditingController fechaController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    
    String? errorQrMsg;
    Color errorQrColor = Colors.red;
    bool qrValido = false; 
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            void validarQR(String qr) async {
              if (qr.trim().length < 2) {
                setModalState(() { errorQrMsg = null; qrValido = false; });
                return;
              }
              try {
                final res = await http.get(Uri.parse('$baseUrl/api/api_validar_qr.php?qr=$qr'));
                if (res.statusCode == 200) {
                  final data = json.decode(res.body);
                  setModalState(() {
                    if (data['existe'] == true) {
                      qrValido = false;
                      if (tipoMuebleId != null && tipoMuebleId != data['tipo_id'].toString()) {
                        errorQrColor = Colors.red;
                        errorQrMsg = "Este QR pertenece a: ${data['tipo_nombre']}";
                      } else {
                        errorQrColor = Colors.orange;
                        errorQrMsg = "Este QR ya está registrado como: ${data['tipo_nombre']}";
                      }
                    } else {
                      qrValido = true; 
                      errorQrMsg = null;
                    }
                  });
                }
              } catch (e) {
                debugPrint("Error validando QR: $e");
              }
            }

            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    const Text("Asignar Nuevo Mueble", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    const SizedBox(height: 20),

                    const Text("TIPO DE MUEBLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      decoration: _inputDeco(),
                      hint: const Text("Seleccionar tipo", style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                      items: tiposMueble.map((tm) => DropdownMenuItem(value: tm['tipomueble_id'].toString(), child: Text(tm['tipomueble_nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))).toList(),
                      onChanged: (val) {
                        setModalState(() => tipoMuebleId = val);
                        if (qrController.text.isNotEmpty) validarQR(qrController.text);
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text("QR / IDENTIFICADOR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: qrController,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      decoration: _inputDeco().copyWith(
                        hintText: "Ej: QR-0001",
                        errorText: errorQrMsg,
                        errorStyle: TextStyle(color: errorQrColor, fontWeight: FontWeight.bold),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: errorQrColor, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: errorQrColor)),
                      ),
                      onChanged: (qr) {
                        if (debounce?.isActive ?? false) debounce!.cancel();
                        debounce = Timer(const Duration(milliseconds: 400), () {
                          validarQR(qr);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text("FECHA INSTALACIÓN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: fechaController, 
                      decoration: _inputDeco(), 
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrimario, 
                          elevation: 0, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey[300]
                        ),
                        onPressed: (!qrValido || tipoMuebleId == null || qrController.text.isEmpty) ? null : () async {
                          showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: colorPrimario)));

                          try {
                            final res = await http.post(Uri.parse('$baseUrl/?c=ClienteMueble&a=AjaxGuardar'), body: {
                              'rut': clienteSeleccionado['cliente_rut'],
                              'cliente_id': clienteSeleccionado['cliente_id'].toString(),
                              'tipomueble_id': tipoMuebleId!,
                              'clientemueble_qr': qrController.text.trim(),
                              'clientemueble_fecha': fechaController.text,
                            });
                            
                            Navigator.pop(context); 
                            
                            if (res.statusCode == 200) {
                              final data = json.decode(res.body);
                              if (data['ok']) {
                                Navigator.pop(context);
                                _buscarCliente(rutEspecifico: clienteSeleccionado['cliente_rut'], clienteIdSelect: clienteSeleccionado['cliente_id'].toString());
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.green));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.red));
                              }
                            }
                          } catch (e) {
                            Navigator.pop(context); 
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al asignar mueble"), backgroundColor: Colors.red));
                          }
                        },
                        child: const Text("Guardar Mueble", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL ACTUALIZAR UBICACIÓN GPS ---
  void _mostrarModalUbicacion() {
    TextEditingController latController = TextEditingController(text: clienteSeleccionado['cliente_latitud']?.toString() ?? '');
    TextEditingController lngController = TextEditingController(text: clienteSeleccionado['cliente_longitud']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Text("Actualizar Ubicación GPS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const SizedBox(height: 20),

                  const Text("LATITUD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextField(controller: latController, decoration: _inputDeco(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),

                  const Text("LONGITUD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextField(controller: lngController, decoration: _inputDeco(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: Color(0xFFCBD5E1))),
                    icon: const Icon(Icons.my_location, color: Color(0xFF3B82F6), size: 18),
                    label: const Text("Usar mi ubicación actual", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3B82F6), fontSize: 13)),
                    onPressed: () async {
                      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) return;
                      LocationPermission permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                        if (permission == LocationPermission.denied) return;
                      }
                      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                      setModalState(() {
                        latController.text = position.latitude.toString();
                        lngController.text = position.longitude.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: colorPrimario)));

                        try {
                          final res = await http.post(Uri.parse('$baseUrl/?c=ClienteMueble&a=ActualizarUbicacion'), body: {
                            'cliente_id': clienteSeleccionado['cliente_id'].toString(),
                            'lat': latController.text,
                            'lng': lngController.text,
                          });

                          Navigator.pop(context); 

                          if (res.statusCode == 200) {
                            final data = json.decode(res.body);
                            if (data['ok']) {
                              Navigator.pop(context); 
                              _buscarCliente(rutEspecifico: clienteSeleccionado['cliente_rut'], clienteIdSelect: clienteSeleccionado['cliente_id'].toString());
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.green));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.red));
                            }
                          }
                        } catch (e) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al conectar con el servidor"), backgroundColor: Colors.red));
                        }
                      },
                      child: const Text("Guardar Ubicación", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true, fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorAzul, width: 2)),
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // APP BAR ESTILO RESUMEN
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
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('Muebles por Cliente', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900), maxLines: 1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Busca por RUT, selecciona el local y gestiona los activos.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TARJETA DE BÚSQUEDA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 6)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("RUT CLIENTE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rutController,
                            decoration: _inputDeco().copyWith(hintText: "Ej: 12345678-9"),
                            onSubmitted: (_) => _buscarCliente(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: colorAzul, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => _buscarCliente(),
                            child: const Icon(Icons.search, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    if (clientesEncontrados.length > 1) ...[
                      const SizedBox(height: 16),
                      const Text("SELECCIONAR LOCAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        decoration: _inputDeco(),
                        value: clienteSeleccionado?['cliente_id']?.toString(),
                        items: clientesEncontrados.map((c) => DropdownMenuItem<String>(
                          value: c['cliente_id'].toString(),
                          child: Text("Local ${c['cliente_local']} - ${c['cliente_razonsocial']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        )).toList(),
                        onChanged: (id) {
                          setState(() {
                            clienteSeleccionado = clientesEncontrados.firstWhere((c) => c['cliente_id'].toString() == id);
                            _cargarMueblesCliente(id!);
                            _calcularDistanciaMapa(clienteSeleccionado);
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),

          if (isLoading)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (clienteSeleccionado != null) ...[
            
            // --- 1. FICHA DEL CLIENTE (MODERNO EN 2 COLUMNAS) ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: const Color(0xFFE2E8F0)), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))]
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 18, decoration: BoxDecoration(color: colorPrimario, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          const Text("Ficha del Cliente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Razón social a todo el ancho
                      _buildGridItem("RAZÓN SOCIAL", clienteSeleccionado['cliente_razonsocial'] ?? '', Icons.business_rounded),
                      const SizedBox(height: 12),
                      
                      // Fila 1: RUT y LOCAL (2 Columnas)
                      Row(
                        children: [
                          Expanded(child: _buildGridItem("RUT", clienteSeleccionado['cliente_rut'] ?? '', Icons.badge_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGridItem("LOCAL", "Local ${clienteSeleccionado['cliente_local'] ?? '1'}", Icons.storefront_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Dirección a todo el ancho
                      _buildGridItem("DIRECCIÓN", clienteSeleccionado['cliente_direccion'] ?? '', Icons.location_on_rounded),
                      const SizedBox(height: 12),
                      
                      // Fila 2: COMUNA y VENDEDOR (2 Columnas)
                      Row(
                        children: [
                          Expanded(child: _buildGridItem("COMUNA", clienteSeleccionado['cliente_comuna'] ?? '', Icons.map_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGridItem("VENDEDOR", clienteSeleccionado['vendedor_nombre'] ?? 'Sin vendedor', Icons.person_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Fila 3: ESTADO y COORDENADAS (2 Columnas)
                      Row(
                        children: [
                          // Tarjeta especial para el Estado
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                                      SizedBox(width: 6),
                                      Text("ESTADO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: clienteSeleccionado['cliente_estado'] == 1 ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), 
                                      borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Text(
                                      clienteSeleccionado['cliente_estado'] == 1 ? "Activo" : "Inactivo", 
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: clienteSeleccionado['cliente_estado'] == 1 ? const Color(0xFF065F46) : const Color(0xFF991B1B))
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Agrupamos Latitud y Longitud en un solo cuadro para ahorrar espacio
                          Expanded(
                            child: _buildGridItem(
                              "COORDENADAS GPS", 
                              "${clienteSeleccionado['cliente_latitud'] ?? '-'}\n${clienteSeleccionado['cliente_longitud'] ?? '-'}", 
                              Icons.gps_fixed_rounded
                            )
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

            // --- 2. MAPA DE UBICACIÓN ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 4, height: 18, decoration: BoxDecoration(color: colorPrimario, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        const Text("Ubicación del cliente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMapa(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
                        label: const Text("Actualizar ubicación", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: _mostrarModalUbicacion,
                      ),
                    )
                  ],
                ),
              ),
            ),

            // --- 3. MUEBLES INSTALADOS ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Muebles Instalados", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: colorPrimario, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text("Asignar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _mostrarModalAsignar,
                    )
                  ],
                ),
              ),
            ),

            if (mueblesCliente.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("Este cliente no tiene muebles asignados.", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var m = mueblesCliente[index];
                      bool activo = m['clientemueble_estado'].toString() == '1';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2))]),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(20)),
                                        child: Text(m['tipomueble_nombre'], style: const TextStyle(color: Color(0xFF5B21B6), fontSize: 11, fontWeight: FontWeight.w900)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(m['clientemueble_qr'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Instalación: ${m['clientemueble_fecha']}", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: activo ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                                    child: Text(activo ? "ACTIVO" : "INACTIVO", style: TextStyle(color: activo ? const Color(0xFF065F46) : const Color(0xFF991B1B), fontSize: 10, fontWeight: FontWeight.w900)),
                                  )
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("¿Desactivar mueble?"),
                                    content: Text("El mueble ${m['clientemueble_qr']} pasará a estado inactivo."),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await http.get(Uri.parse('$baseUrl/?c=ClienteMueble&a=Delete&id=${m['clientemueble_id']}&rut=${clienteSeleccionado['cliente_rut']}&cliente_id=${clienteSeleccionado['cliente_id']}'));
                                          _buscarCliente(rutEspecifico: clienteSeleccionado['cliente_rut'], clienteIdSelect: clienteSeleccionado['cliente_id'].toString());
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mueble desactivado con éxito")));
                                        },
                                        child: const Text("Desactivar", style: TextStyle(color: Colors.white)),
                                      )
                                    ],
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      );
                    },
                    childCount: mueblesCliente.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30))
          ]
        ],
      ),
    );
  }

  // --- WIDGET PARA LA GRILLA DE FICHA MEJORADO ---
  Widget _buildGridItem(String title, String value, [IconData? icon]) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '-' : value, 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    double latCli = double.tryParse(clienteSeleccionado['cliente_latitud']?.toString() ?? '0') ?? 0.0;
    double lngCli = double.tryParse(clienteSeleccionado['cliente_longitud']?.toString() ?? '0') ?? 0.0;

    if (latCli == 0.0 || lngCli == 0.0) {
      return Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("Ubicación no disponible", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
      );
    }

    List<Marker> markers = [
      Marker(
        point: LatLng(latCli, lngCli),
        width: 40, height: 40,
        child: const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 40),
      )
    ];

    List<Polyline> polylines = [];

    if (miLatitud != null && miLongitud != null) {
      markers.add(
        Marker(
          point: LatLng(miLatitud!, miLongitud!),
          width: 40, height: 40,
          child: const Icon(Icons.person_pin_circle_rounded, color: Colors.black, size: 40),
        )
      );

      polylines.add(
        Polyline(
          points: [LatLng(latCli, lngCli), LatLng(miLatitud!, miLongitud!)],
          color: colorPrimario,
          strokeWidth: 3.0,
          // Se eliminó isDotted porque la nueva versión de flutter_map ya no lo usa
        )
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(latCli, lngCli),
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.distribuidoramaxima.app',
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}