import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:geolocator/geolocator.dart';

class CrearClienteScreen extends StatefulWidget {
  const CrearClienteScreen({super.key});

  @override
  State<CrearClienteScreen> createState() => _CrearClienteScreenState();
}

class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    if (text.length > 9) text = text.substring(0, 9);

    String result = '';
    if (text.length > 1) {
      String cuerpo = text.substring(0, text.length - 1);
      String dv = text.substring(text.length - 1);
      
      String cuerpoFormateado = '';
      int contador = 0;
      for (int i = cuerpo.length - 1; i >= 0; i--) {
        cuerpoFormateado = cuerpo[i] + cuerpoFormateado;
        contador++;
        if (contador == 3 && i > 0) {
          cuerpoFormateado = '.' + cuerpoFormateado;
          contador = 0;
        }
      }
      result = '$cuerpoFormateado-$dv';
    } else {
      result = text;
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _CrearClienteScreenState extends State<CrearClienteScreen> {
  // --- VARIABLE CENTRALIZADA PARA LA URL ---
  //final String baseUrl = 'http://localhost/inventariomaxima'; // Para pruebas en local
  final String baseUrl = 'https://app.distribuidoramaxima.cl'; // Para producción

  final Color colorPrimario = const Color(0xFF6366F1);
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  final txtRazonSocial = TextEditingController();
  final txtRut = TextEditingController();
  final txtDireccion = TextEditingController();
  final txtEntrega = TextEditingController();
  final txtComuna = TextEditingController();
  
  final txtLatitud = TextEditingController(text: "-0");
  final txtLongitud = TextEditingController(text: "-0");

  PlatformFile? archivoBoleta;
  final ImagePicker _picker = ImagePicker();

  List zonas = [];
  List tiposCliente = [];
  List vendedores = [];
  List visitas = [];

  String? zonaSel;
  String? vendedorSel;
  String? visitaSel;
  String? tipoSel;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        txtLatitud.text = position.latitude.toString();
        txtLongitud.text = position.longitude.toString();
      });
    } catch (e) {
      print("Error obteniendo GPS: $e");
    }
  }

  Future<void> _cargarDatosIniciales() async {
    final url = Uri.parse('$baseUrl/api/api_crear_clientes.php?action=get_datos_iniciales');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['ok']) {
          setState(() {
            zonas = data['zonas'];
            tiposCliente = data['tipos'];
          });
        }
      }
    } catch (e) {
      print("Error cargando datos iniciales: $e");
    }
  }

  Future<void> _cargarVendedores(String zonaId) async {
    setState(() { vendedorSel = null; visitaSel = null; vendedores = []; visitas = []; });
    final url = Uri.parse('$baseUrl/api/api_crear_clientes.php?action=get_vendedores&zona_id=$zonaId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      setState(() { vendedores = json.decode(res.body)['vendedores'] ?? []; });
    }
  }

  Future<void> _cargarVisitas(String vendedorId) async {
    setState(() { visitaSel = null; visitas = []; });
    final url = Uri.parse('$baseUrl/api/api_crear_clientes.php?action=get_visitas&vendedor_id=$vendedorId');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      setState(() { visitas = json.decode(res.body)['visitas'] ?? []; });
    }
  }

  Future<void> _seleccionarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null) {
      setState(() { archivoBoleta = result.files.first; });
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        archivoBoleta = PlatformFile(name: photo.name, size: bytes.length, bytes: bytes, path: photo.path);
      });
    }
  }

  void _mostrarOpcionesArchivo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1)),
                title: const Text('Tomar Foto con la Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(context); _tomarFoto(); },
              ),
              ListTile(
                leading: const Icon(Icons.folder_rounded, color: Color(0xFF6366F1)),
                title: const Text('Seleccionar Archivo / Galería', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(context); _seleccionarArchivo(); },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generarPdfVoucher({required String razonSocial, required String rut, required String direccion, required String comuna, required String zonaNombre, required String vendedorNombre}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: pw_pdf.PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('DISTRIBUIDORA MÁXIMA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Comprobante de Registro', style: pw.TextStyle(fontSize: 10, color: pw_pdf.PdfColors.grey700))),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              pw.Text('Razón Social:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text(razonSocial, style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Text('RUT:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text(rut, style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Text('Dirección:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('$direccion, $comuna', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Text('Zona / Vendedor:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('$zonaNombre / $vendedorNombre', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('¡Cliente registrado con éxito!', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'comprobante_cliente.pdf',
    );
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    if (zonaSel == null || vendedorSel == null || visitaSel == null || tipoSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complete todos los selectores", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSubmitting = true);

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/api_crear_clientes.php?action=guardar'));
  
    request.fields['RazonSocial'] = txtRazonSocial.text;
    request.fields['Rut'] = txtRut.text;
    request.fields['Direccion'] = txtDireccion.text;
    request.fields['Entrega'] = txtEntrega.text;
    request.fields['Comuna'] = txtComuna.text;
    request.fields['Latitud'] = txtLatitud.text;
    request.fields['Longitud'] = txtLongitud.text;
    request.fields['zona'] = zonaSel!;
    request.fields['vendedor'] = vendedorSel!;
    request.fields['visita'] = visitaSel!;
    request.fields['tipo'] = tipoSel!;

    if (archivoBoleta != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('Boleta', archivoBoleta!.bytes!, filename: archivoBoleta!.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('Boleta', archivoBoleta!.path!));
      }
    }

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);

      if (data['ok']) {
        String zonaNombre = zonas.firstWhere((z) => z['zona_id'].toString() == zonaSel)['zona_nombre'];
        String vendedorNombre = vendedores.firstWhere((v) => v['vendedor_id'].toString() == vendedorSel)['nombre'];

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.green));
        
        await _generarPdfVoucher(
          razonSocial: txtRazonSocial.text,
          rut: txtRut.text,
          direccion: txtDireccion.text,
          comuna: txtComuna.text,
          zonaNombre: zonaNombre,
          vendedorNombre: vendedorNombre,
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("Error guardando cliente: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      
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
        title: const Text("Registro de Cliente", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: colorPrimario,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 5, height: 20, decoration: BoxDecoration(color: colorPrimario, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(width: 8),
                    const Text("Datos del Cliente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildInput("Razón Social", "Nombre del cliente", txtRazonSocial, Icons.business),
                const SizedBox(height: 16),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rut", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: txtRut,
                      inputFormatters: [RutInputFormatter()],
                      decoration: InputDecoration(
                        hintText: "12.345.678-9",
                        prefixIcon: const Icon(Icons.badge, color: Color(0xFF94A3B8), size: 20),
                        filled: true, fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildInput("Dirección", "Dirección", txtDireccion, Icons.location_on),
                const SizedBox(height: 16),
                _buildInput("Dirección Entrega", "Dirección de entrega", txtEntrega, Icons.local_shipping),
                const SizedBox(height: 16),
                
                _buildInput("Comuna", "Comuna", txtComuna, Icons.map),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildInputBloqueado("Latitud (GPS)", txtLatitud, Icons.gps_fixed)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInputBloqueado("Longitud (GPS)", txtLongitud, Icons.gps_fixed)),
                  ],
                ),
                const SizedBox(height: 24),

                const Text("Documento Boleta", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _mostrarOpcionesArchivo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E1))),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt_rounded, color: colorPrimario),
                        const SizedBox(width: 12),
                        Expanded(child: Text(archivoBoleta != null ? archivoBoleta!.name : "Tomar foto o elegir archivo...", style: TextStyle(color: archivoBoleta != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildDropdown("Zona", "Seleccione una zona", zonaSel, zonas.map((z) => DropdownMenuItem<String>(value: z['zona_id'].toString(), child: Text(z['zona_nombre']))).toList(), (val) {
                  setState(() { zonaSel = val; });
                  _cargarVendedores(val!);
                }),
                const SizedBox(height: 16),
                
                // ==========================================
                // LÓGICA INTELIGENTE PARA EL SELECT DE VENDEDOR
                // ==========================================
                _buildDropdown(
                  "Vendedor", 
                  zonaSel == null ? "Seleccione una zona primero" : "Seleccione un vendedor", 
                  vendedorSel, 
                  vendedores.map((v) {
                    String numText = v['vendedor_numero']?.toString() ?? '';
                    String nameText = v['nombre']?.toString().trim() ?? '';
                    
                    // Si el "vendedor_numero" ya tiene escrito el nombre adentro, no lo volvemos a concatenar.
                    String displayText = numText;
                    if (!numText.toLowerCase().contains(nameText.toLowerCase()) && nameText.isNotEmpty) {
                      displayText = "$numText - $nameText";
                    }
                    
                    return DropdownMenuItem<String>(
                      value: v['vendedor_id'].toString(), 
                      child: Text(displayText, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(), 
                  (val) {
                    setState(() { vendedorSel = val; });
                    _cargarVisitas(val!);
                  }
                ),
                
                const SizedBox(height: 16),
                _buildDropdown("Día Visita", vendedorSel == null ? "Seleccione un vendedor primero" : "Seleccione un día", visitaSel, visitas.map((v) => DropdownMenuItem<String>(value: v['visita_id'].toString(), child: Text(v['visita_nombre']))).toList(), (val) => setState(() => visitaSel = val)),
                const SizedBox(height: 16),
                _buildDropdown("Tipo Cliente", "Seleccione un tipo", tipoSel, tiposCliente.map((t) => DropdownMenuItem<String>(value: t['tipocliente_id'].toString(), child: Text(t['tipocliente_nombre']))).toList(), (val) => setState(() => tipoSel = val)),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _guardarCliente,
                    style: ElevatedButton.styleFrom(backgroundColor: colorPrimario, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("GUARDAR CLIENTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => value!.isEmpty ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _buildInputBloqueado(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          enabled: false,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            filled: true, fillColor: const Color(0xFFE2E8F0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true, // Importante para que el texto no desborde hacia los lados
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}