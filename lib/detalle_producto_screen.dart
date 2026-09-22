import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'modificar_producto_screen.dart';

class DetalleProductoScreen extends StatefulWidget {
  final String productoId;
  final int usuarioId;
  final String rolUsuario;

  const DetalleProductoScreen({
    Key? key, 
    required this.productoId,
    required this.usuarioId,
    required this.rolUsuario,
  }) : super(key: key);

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  final Color colorPrimario = const Color(0xFF6F42C1);
  final Color bgColor = const Color(0xFFF8FAFC);

  bool isLoading = true;
  Map<String, dynamic>? p;
  
  // IP o Dominio base
  //final String baseUrl = 'http://localhost/inventariomaxima'; 
  final String baseUrl = 'http://app.distribuidoramaxima.cl';

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  // --- API: OBTENER DATOS DEL PRODUCTO ---
  Future<void> _cargarDetalle() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/?c=Productos&a=AjaxObtenerProducto&id=${widget.productoId}'));
      
      if (res.statusCode == 200) {
        try {
          final data = json.decode(res.body);
          if (data['ok']) {
            setState(() => p = data['data']);
          } else {
            _mostrarError("No encontrado", data['msg']);
          }
        } catch (formatException) {
          _mostrarError("Error en PHP (XAMPP)", "El servidor no envió un JSON, envió esto:\n\n${res.body}");
        }
      } else {
        _mostrarError("Error del servidor", "Código de estado: ${res.statusCode}");
      }
    } catch (e) {
      _mostrarError("Error Técnico", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _mostrarError(String titulo, String mensaje) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () { 
              Navigator.pop(context); 
              Navigator.pop(context); 
            }, 
            child: const Text('Volver')
          )
        ],
      )
    );
  }

  // --- API: CAMBIAR ESTADO (ACTIVAR / ELIMINAR) ---
  Future<void> _cambiarEstado(bool activar) async {
    String accion = activar ? 'AjaxActivarProducto' : 'AjaxDesactivarProducto';
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => Center(child: CircularProgressIndicator(color: colorPrimario))
    );

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/?c=Productos&a=$accion'),
        body: {
          'id': p!['producto_id'].toString(),
          'posicion_id': p!['posicion_id']?.toString() ?? '',
          'usuario_id': widget.usuarioId.toString(), 
        }
      );
      
      Navigator.pop(context); // Quita Loading
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['msg']), backgroundColor: data['ok'] ? Colors.green : Colors.red)
        );
        if (data['ok']) _cargarDetalle();
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _confirmarEliminacion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text("¿Estás seguro?")]),
        content: Text("¡Estás a punto de inhabilitar este producto: ${p!['maestra_nombre']}! La posición en bodega quedará libre."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
            onPressed: () { 
              Navigator.pop(context); 
              _cambiarEstado(false); 
            },
            child: const Text("Sí, eliminarlo", style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(backgroundColor: bgColor, appBar: AppBar(backgroundColor: colorPrimario, elevation: 0), body: Center(child: CircularProgressIndicator(color: colorPrimario)));
    if (p == null) return const Scaffold();

    bool isActivo = p!['producto_estado'].toString() == "1" || p!['producto_estado'] == true;
    
    // --- LÓGICA DE PERMISOS SEPARADA ---
    bool puedeEliminar = widget.rolUsuario == 'admin' || widget.rolUsuario == 'Jefe' || widget.rolUsuario == 'Inventario' || widget.rolUsuario == 'bodega';
    bool puedeActivar  = widget.rolUsuario == 'admin' || widget.rolUsuario == 'Inventario';

    return Scaffold(
      backgroundColor: bgColor,
      // ==========================================
      // FOOTER FIJO Y COMPACTO
      // ==========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: colorPrimario.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded, color: colorPrimario, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Distribuidora Máxima © 2026',
                      style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Versión 1.0.0 • Desarrollado por Jonathan Pinilla Orellana',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Detalle del Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
        backgroundColor: Colors.white, 
        foregroundColor: const Color(0xFF1E293B), 
        elevation: 1
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF5F2FF), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight), 
                borderRadius: BorderRadius.circular(22), 
                border: Border.all(color: const Color(0xFFE7DDFF))
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_rounded, size: 40, color: colorPrimario),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Información del Producto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2F2F2F))),
                        const SizedBox(height: 4),
                        Text("Visualiza y administra el estado de este producto.", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(22), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: [
                      _buildInfoItem("CÓDIGO", p!['maestra_codigo'] ?? '-'),
                      _buildInfoItem("CÓDIGO DE BARRA", p!['maestra_codigobarra'] ?? '-'),
                      _buildInfoItem("DESCRIPCIÓN", p!['maestra_nombre'] ?? '-', fullWidth: true),
                      _buildInfoItem("CANTIDAD CAJAS", p!['producto_cantidadCajas']?.toString() ?? '0'),
                      _buildInfoItem("N° LOTE", p!['producto_lote'] ?? '-'),
                      _buildInfoItem("MEDIDAS", p!['maestra_medida'] ?? '-'),
                      _buildInfoItem("VENCIMIENTO", p!['producto_vencimiento'] ?? '-'),
                      _buildInfoItem("CÓDIGO INTERNO", p!['producto_codigo'] ?? '-'),
                      _buildInfoItem("FILA", p!['posicion_fila'] ?? '-'),
                      _buildInfoItem("SECTOR", p!['posicion_sector'] ?? '-'),
                      _buildInfoItem("POSICIÓN", p!['posicion_nombre'] ?? '-'),
                      
                      Container(
                        width: (MediaQuery.of(context).size.width - 92) / 2,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFAF8FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFECE7FB))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ESTADO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: isActivo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(50)),
                              child: Text(isActivo ? "Activo" : "Inactivo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isActivo ? const Color(0xFF166534) : const Color(0xFFB91C1C))),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      // El botón de editar siempre está visible
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario, 
                            padding: const EdgeInsets.symmetric(vertical: 14), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => ModificarProductoScreen(
                                productoId: p!['producto_id'].toString(),
                                usuarioId: widget.usuarioId,
                              ))
                            ).then((value) { 
                              if (value == true) _cargarDetalle(); 
                            });
                          },
                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                          label: const Text("Editar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      // Validación: Si ESTÁ ACTIVO y PUEDE ELIMINAR -> Muestra Eliminar
                      if (isActivo && puedeEliminar) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316), 
                              padding: const EdgeInsets.symmetric(vertical: 14), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: _confirmarEliminacion,
                            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                            label: const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],

                      // Validación: Si ESTÁ INACTIVO y PUEDE ACTIVAR -> Muestra Activar
                      if (!isActivo && puedeActivar) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981), 
                              padding: const EdgeInsets.symmetric(vertical: 14), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: () => _cambiarEstado(true),
                            icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                            label: const Text("Activar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]
                      // Si está inactivo y NO puede activar, simplemente no dibuja nada adicional (solo queda Editar).
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : (MediaQuery.of(context).size.width - 92) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFAF8FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFECE7FB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        ],
      ),
    );
  }
}