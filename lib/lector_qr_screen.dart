import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'detalle_producto_screen.dart';

class LectorQrScreen extends StatefulWidget {
  final int usuarioId; 
  final String rolUsuario;

  const LectorQrScreen({
    super.key, 
    required this.usuarioId,
    required this.rolUsuario,
  });

  @override
  State<LectorQrScreen> createState() => _LectorQrScreenState();
}

class _LectorQrScreenState extends State<LectorQrScreen> {
  bool _isScanned = false;
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _isTorchOn = false; // <-- Control manual de la linterna

  // Controlador de la cámara para manejar el Zoom y el Flash
  final MobileScannerController cameraController = MobileScannerController(
    formats: const [BarcodeFormat.all],
  );

  double _zoomFactor = 0.0;

  final Color colorPrimario = const Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _verificarPermiso();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _verificarPermiso() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });
  }

  // --- LÓGICA PARA EXTRAER EL ID Y NAVEGAR ---
  void _procesarQR(String rawValue) {
    String idExtraido = rawValue;

    if (rawValue.toLowerCase().startsWith('http')) {
      try {
        final uri = Uri.parse(rawValue);
        
        if (uri.queryParameters.containsKey('id')) {
          idExtraido = uri.queryParameters['id']!;
        } else if (uri.queryParameters.containsKey('qr')) {
          idExtraido = uri.queryParameters['qr']!;
        } else {
          idExtraido = uri.pathSegments.last;
        }
      } catch (e) {
        debugPrint("Error al limpiar la URL: $e");
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleProductoScreen(
          productoId: idExtraido, 
          usuarioId: widget.usuarioId, 
          rolUsuario: widget.rolUsuario,
        ), 
      ),
    ).then((_) {
      if (mounted) setState(() => _isScanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Escanear QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: colorPrimario,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(child: CircularProgressIndicator(color: colorPrimario)),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Escanear QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: colorPrimario,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Se necesita permiso de cámara para poder escanear los códigos QR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _verificarPermiso,
                  child: const Text('Conceder Permiso', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro para que resalte la cámara
      appBar: AppBar(
        title: const Text('Escanear QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: colorPrimario,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // BOTÓN DE FLASH (Linterna) CORREGIDO
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.white70,
            ),
            iconSize: 30.0,
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. ESCÁNER CON CONTROLADOR
          MobileScanner(
            controller: cameraController,
            errorBuilder: (context, error, child) {
              return Center(
                child: Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${error.errorCode.name}\nDetalles: ${error.errorDetails?.message}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null) {
                  setState(() { _isScanned = true; });

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded, color: colorPrimario, size: 28),
                          const SizedBox(width: 8),
                          const Text('¡QR Encontrado!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Código procesado:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                            child: Text(rawValue, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() { _isScanned = false; });
                          },
                          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(context); 
                            _procesarQR(rawValue);  
                          },
                          child: const Text('Ver Detalles', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  break;
                }
              }
            },
          ),
          
          // 2. CUADRO GUÍA DEL ESCÁNER
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // 3. BARRA INFERIOR DE ZOOM
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white),
                  Expanded(
                    child: Slider(
                      value: _zoomFactor,
                      min: 0.0,
                      max: 1.0,
                      activeColor: colorPrimario,
                      inactiveColor: Colors.white30,
                      onChanged: (value) {
                        setState(() {
                          _zoomFactor = value;
                          cameraController.setZoomScale(value);
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}