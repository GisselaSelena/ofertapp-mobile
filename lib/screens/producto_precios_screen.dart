import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_state.dart';
import '../services/api_client.dart';

class ProductoPreciosScreen extends ConsumerStatefulWidget {
  final String productoId;

  const ProductoPreciosScreen({super.key, required this.productoId});

  @override
  ConsumerState<ProductoPreciosScreen> createState() =>
      _ProductoPreciosScreenState();
}

class _ProductoPreciosScreenState
    extends ConsumerState<ProductoPreciosScreen> {
  bool _cargando = true;
  String? _error;
  List<dynamic> _precios = [];

  String? _resumenIa;
  bool _cargandoResumenIa = false;

  @override
  void initState() {
    super.initState();
    _cargarPrecios();
  }

  Future<void> _cargarPrecios() async {
    setState(() => _cargando = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data =
          await apiClient.get('/api/productos/${widget.productoId}/precios');
      setState(() {
        _precios = data['precios'] as List;
        _cargando = false;
      });
      if (_precios.isNotEmpty) {
        _cargarResumenIa();
      }
    } catch (e) {
      if (e is AuthException) {
        ref.read(authProvider.notifier).sessionExpired();
      }
      setState(() {
        _error = mensajeDeError(e);
        _cargando = false;
      });
    }
  }

  /// El resumen de IA es un complemento opcional a la comparación: si
  /// falla o no está disponible, simplemente no se muestra la card —
  /// nunca se interrumpe ni se le muestra un error al usuario por esto.
  Future<void> _cargarResumenIa() async {
    setState(() => _cargandoResumenIa = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient
          .get('/api/productos/${widget.productoId}/resumen-ia');
      if (!mounted) return;
      setState(() {
        _resumenIa =
            data['disponible'] == true ? data['resumen'] as String? : null;
        _cargandoResumenIa = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargandoResumenIa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final auth = ref.watch(authProvider);
    final esAdmin = auth?.usuario.esAdministrador ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar precios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/productos'),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    if (_cargandoResumenIa || _resumenIa != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Card(
                          color: primary.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: primary.withValues(alpha: 0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    color: primary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _cargandoResumenIa
                                      ? const Text(
                                          'Analizando precios con IA...',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6B7280)),
                                        )
                                      : Text(
                                          _resumenIa!,
                                          style: const TextStyle(
                                              fontSize: 13, height: 1.4),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _cargarPrecios,
                        child: _precios.isEmpty
                            ? ListView(children: const [
                                SizedBox(height: 120),
                                Center(child: Text('Sin precios registrados aún')),
                              ])
                            : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: _precios.length,
                          itemBuilder: (context, index) {
                            final precio = _precios[index];
                            final esElMasBarato = index == 0;

                            return Card(
                              color: esElMasBarato
                                  ? primary.withValues(alpha: 0.06)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: esElMasBarato
                                      ? primary.withValues(alpha: 0.35)
                                      : const Color(0xFFECECE9),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (esElMasBarato)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: primary,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'MEJOR PRECIO',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            precio['establecimiento']
                                                ['nombre'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          Row(
                                            children: [
                                              if (precio['tiene_ubicacion'] ==
                                                  true)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                      right: 6, top: 2),
                                                  child: Icon(
                                                      Icons
                                                          .location_on_rounded,
                                                      size: 14,
                                                      color: Color(0xFF9CA3AF)),
                                                ),
                                              if (precio['tiene_foto_evidencia'] ==
                                                  true)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 2),
                                                  child: Icon(
                                                      Icons
                                                          .photo_camera_rounded,
                                                      size: 14,
                                                      color: Color(0xFF9CA3AF)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${precio['valor']}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: esElMasBarato
                                            ? primary
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: esAdmin
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.go('/productos/${widget.productoId}/precios/reportar'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Reportar precio'),
            )
          : null,
    );
  }
}