import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/productos_state.dart';
import '../state/auth_state.dart';
import '../services/api_client.dart';
import '../models/models.dart';

class ProductosListScreen extends ConsumerStatefulWidget {
  const ProductosListScreen({super.key});

  @override
  ConsumerState<ProductosListScreen> createState() =>
      _ProductosListScreenState();
}

class _ProductosListScreenState extends ConsumerState<ProductosListScreen> {
  final Set<String> _agregandoFavorito = {};
  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productosProvider.notifier).cargar());
    _busquedaController.addListener(() {
      setState(() => _busqueda = _busquedaController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _agregarAFavoritos(String productoId) async {
    setState(() => _agregandoFavorito.add(productoId));
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/api/favoritos', {'producto_id': productoId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agregado a favoritos')),
        );
      }
    } catch (e) {
      if (e is AuthException) {
        ref.read(authProvider.notifier).sessionExpired();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is AuthException
                ? mensajeDeError(e)
                : 'Ya estaba en tus favoritos, o hubo un error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _agregandoFavorito.remove(productoId));
    }
  }

  List<Producto> _filtrar(List<Producto> productos) {
    if (_busqueda.isEmpty) return productos;
    return productos
        .where((p) =>
            p.nombre.toLowerCase().contains(_busqueda) ||
            (p.categoria?.toLowerCase().contains(_busqueda) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(productosProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final auth = ref.watch(authProvider);
    final esAdmin = auth?.usuario.esAdministrador ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OfertApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => context.go('/favoritos'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.go('/perfil'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Busca un producto, ej. arroz, pollo...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _busquedaController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: switch (estado) {
              RemoteIdle() || RemoteLoading() =>
                const Center(child: CircularProgressIndicator()),
              RemoteError(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $message',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              RemoteSuccess(:final data) => _buildLista(
                  context, _filtrar(data), primary, esAdmin),
            },
          ),
        ],
      ),
      floatingActionButton: esAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/productos/nuevo'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          : null,
    );
  }

  Widget _buildLista(BuildContext context, List<Producto> productos,
      Color primary, bool esAdmin) {
    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _busqueda.isEmpty
                  ? 'Aún no hay productos registrados'
                  : 'No se encontró "$_busqueda"',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        final cargandoFavorito = _agregandoFavorito.contains(producto.id);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go('/productos/${producto.id}/precios'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 64,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shopping_basket_outlined,
                        color: primary, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (producto.categoria != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              producto.categoria!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF6B7280)),
                            ),
                          ),
                        )
                      else
                        const SizedBox(),
                      cargandoFavorito
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : GestureDetector(
                              onTap: () => _agregarAFavoritos(producto.id),
                              child: Icon(Icons.favorite_border_rounded,
                                  color: primary, size: 20),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}