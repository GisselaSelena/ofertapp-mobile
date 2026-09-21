import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/permissions_service.dart';
import '../services/location_service.dart';
import '../services/local_storage_service.dart';
import '../state/auth_state.dart';

class ReportarPrecioScreen extends ConsumerStatefulWidget {
  final String productoId;

  const ReportarPrecioScreen({super.key, required this.productoId});

  @override
  ConsumerState<ReportarPrecioScreen> createState() =>
      _ReportarPrecioScreenState();
}

class _ReportarPrecioScreenState extends ConsumerState<ReportarPrecioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();

  List<dynamic> _establecimientos = [];
  String? _establecimientoSeleccionado;
  bool _cargandoEstablecimientos = true;

  double? _lat;
  double? _lng;
  String? _mensajeUbicacion;
  bool _cargandoUbicacion = false;

  XFile? _foto;
  String? _mensajeFoto;

  bool _enviando = false;
  String? _errorGeneral;

  @override
  void initState() {
    super.initState();
    _cargarEstablecimientos();
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstablecimientos() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/api/establecimientos');
      setState(() {
        _establecimientos = data as List;
        _cargandoEstablecimientos = false;
      });
    } catch (e) {
      setState(() => _cargandoEstablecimientos = false);
    }
  }

  Future<void> _usarUbicacion() async {
    setState(() {
      _cargandoUbicacion = true;
      _mensajeUbicacion = null;
    });

    final estadoActual = await PermissionsService.estadoActualUbicacion();
    EstadoPermiso estado = estadoActual;

    if (estado == EstadoPermiso.noSolicitado) {
      estado = await PermissionsService.solicitarUbicacion();
    }

    switch (estado) {
      case EstadoPermiso.concedido:
        final resultado = await LocationService.obtenerPosicionActual();
        if (resultado.exito) {
          await LocalStorageService.guardarUltimaUbicacion(
              resultado.lat!, resultado.lng!);
          setState(() {
            _lat = resultado.lat;
            _lng = resultado.lng;
            _mensajeUbicacion = 'Ubicación capturada correctamente';
          });
        } else {
          setState(() => _mensajeUbicacion = resultado.error);
        }
        break;

      case EstadoPermiso.denegado:
        setState(() =>
            _mensajeUbicacion = 'Permiso denegado. El precio se registrará sin ubicación.');
        break;

      case EstadoPermiso.denegadoPermanente:
        _mostrarDialogoAjustes(
          'Ubicación bloqueada',
          'Denegaste el permiso de ubicación de forma permanente. '
              'Puedes activarlo manualmente en Ajustes, o continuar sin '
              'ubicación.',
        );
        break;

      case EstadoPermiso.noSolicitado:
        break;
    }

    setState(() => _cargandoUbicacion = false);
  }

  Future<void> _tomarFoto() async {
    setState(() => _mensajeFoto = null);

    final estadoActual = await PermissionsService.estadoActualCamara();
    EstadoPermiso estado = estadoActual;

    if (estado == EstadoPermiso.noSolicitado) {
      estado = await PermissionsService.solicitarCamara();
    }

    switch (estado) {
      case EstadoPermiso.concedido:
        final picker = ImagePicker();
        final foto = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        if (foto != null) {
          await LocalStorageService.guardarUltimaFotoPath(foto.path);
          setState(() {
            _foto = foto;
            _mensajeFoto = 'Foto capturada';
          });
        }
        break;

      case EstadoPermiso.denegado:
        setState(() =>
            _mensajeFoto = 'Permiso denegado. El precio se registrará sin foto.');
        break;

      case EstadoPermiso.denegadoPermanente:
        _mostrarDialogoAjustes(
          'Cámara bloqueada',
          'Denegaste el permiso de cámara de forma permanente. '
              'Puedes activarlo manualmente en Ajustes, o continuar sin '
              'adjuntar foto.',
        );
        break;

      case EstadoPermiso.noSolicitado:
        break;
    }
  }

  void _mostrarDialogoAjustes(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar sin esto'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionsService.abrirAjustesDelSistema();
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_establecimientoSeleccionado == null) {
      setState(() => _errorGeneral = 'Selecciona un establecimiento');
      return;
    }

    setState(() {
      _enviando = true;
      _errorGeneral = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/api/precios', {
        'producto_id': widget.productoId,
        'establecimiento_id': _establecimientoSeleccionado,
        'valor': double.parse(_valorController.text),
        if (_lat != null) 'reportado_lat': _lat,
        if (_lng != null) 'reportado_lng': _lng,
        'tiene_foto_evidencia': _foto != null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Precio reportado')));
        context.go('/productos/${widget.productoId}/precios');
      }
    } catch (e) {
      setState(() => _errorGeneral = 'No se pudo reportar el precio');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar precio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.go('/productos/${widget.productoId}/precios'),
        ),
      ),
      body: _cargandoEstablecimientos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _establecimientoSeleccionado,
                      decoration:
                          const InputDecoration(labelText: 'Establecimiento'),
                      items: _establecimientos
                          .map<DropdownMenuItem<String>>((e) =>
                              DropdownMenuItem(
                                  value: e['id'] as String,
                                  child: Text(e['nombre'])))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _establecimientoSeleccionado = v),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _valorController,
                      decoration: const InputDecoration(labelText: 'Precio (USD)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa un valor';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Ingresa un número válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('Ubicación del reporte (opcional)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    const Text(
                      'Se usará para respaldar que el precio fue verificado en sitio.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _cargandoUbicacion ? null : _usarUbicacion,
                      icon: _cargandoUbicacion
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.location_on_outlined),
                      label: Text(_lat != null
                          ? 'Ubicación: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                          : 'Usar mi ubicación actual'),
                    ),
                    if (_mensajeUbicacion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_mensajeUbicacion!,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(height: 20),
                    Text('Foto de evidencia (opcional)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_foto != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_foto!.path),
                            height: 160, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _tomarFoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_foto != null ? 'Tomar otra foto' : 'Tomar foto'),
                    ),
                    if (_mensajeFoto != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_mensajeFoto!,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(height: 28),
                    if (_errorGeneral != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_errorGeneral!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _enviando ? null : _enviar,
                        child: _enviando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Reportar precio'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}