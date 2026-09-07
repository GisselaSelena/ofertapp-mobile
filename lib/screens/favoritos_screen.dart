import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_state.dart';

class FavoritosScreen extends ConsumerStatefulWidget {
  const FavoritosScreen({super.key});

  @override
  ConsumerState<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends ConsumerState<FavoritosScreen> {
  bool _cargando = true;
  String? _error;
  List<dynamic> _favoritos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/api/favoritos');
      setState(() {
        _favoritos = data['favoritos'] as List;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los favoritos';
        _cargando = false;
      });
    }
  }

  Future<void> _eliminar(String favoritoId) async {
    final apiClient = ref.read(apiClientProvider);
    setState(() {
      _favoritos = _favoritos.where((f) => f['id'] != favoritoId).toList();
    });
    try {
      await apiClient.delete('/api/favoritos/$favoritoId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar, intenta de nuevo')),
        );
      }
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis favoritos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/productos'),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _favoritos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border_rounded,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('Aún no tienes favoritos'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _favoritos.length,
                        itemBuilder: (context, index) {
                          final favorito = _favoritos[index];
                          final producto = favorito['producto'];

                          return Dismissible(
                            key: ValueKey(favorito['id']),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _eliminar(favorito['id']),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.white),
                            ),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                onTap: () => context
                                    .go('/productos/${producto['id']}/precios'),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.favorite_rounded,
                                      color: primary, size: 20),
                                ),
                                title: Text(producto['nombre']),
                                subtitle: producto['categoria'] != null
                                    ? Text(producto['categoria'],
                                        style: const TextStyle(fontSize: 12))
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFF9CA3AF)),
                                  onPressed: () => _eliminar(favorito['id']),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}