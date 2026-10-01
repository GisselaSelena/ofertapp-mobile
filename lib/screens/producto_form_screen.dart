import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/productos_state.dart';
import '../state/form_draft_state.dart';
import '../utils/validadores.dart';
import '../models/models.dart';

class ProductoFormScreen extends ConsumerStatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  ConsumerState<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends ConsumerState<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _categoriaController;
  final _nombreFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(productoFormDraftProvider);
    _nombreController = TextEditingController(
      text: widget.producto == null ? draft.nombre : widget.producto!.nombre,
    );
    _categoriaController = TextEditingController(
      text: widget.producto == null
          ? draft.categoria
          : widget.producto!.categoria ?? '',
    );

    _nombreFocus.addListener(() {
      if (!_nombreFocus.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _nombreFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(crearProductoProvider.notifier);
    if (widget.producto == null) {
      await notifier.crear(
        nombre: _nombreController.text.trim(),
        categoria: _categoriaController.text.trim(),
      );
    } else {
      await notifier.actualizar(
        id: widget.producto!.id,
        nombre: _nombreController.text.trim(),
        categoria: _categoriaController.text.trim(),
      );
    }

    final estado = ref.read(crearProductoProvider);
    if (estado is RemoteSuccess) {
      if (widget.producto == null) {
        ref.read(productoFormDraftProvider.notifier).limpiar();
      } else {
        await ref.read(productosProvider.notifier).cargar();
      }
      ref.read(crearProductoProvider.notifier).reset();
      if (mounted) context.go('/productos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(crearProductoProvider);
    final cargando = estado is RemoteLoading;

    final erroresDeCampo = switch (estado) {
      RemoteError(fieldErrors: final fe) => fe,
      _ => null,
    };

    final mensajeError = switch (estado) {
      RemoteError(message: final m) => m,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.producto == null ? 'Nuevo producto' : 'Editar producto',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/productos'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                focusNode: _nombreFocus,
                decoration: InputDecoration(
                  labelText: 'Nombre del producto',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  errorText: erroresDeCampo?['nombre'],
                ),
                validator: validarNombreProducto,
                onChanged: (value) {
                  if (widget.producto == null) {
                    ref
                        .read(productoFormDraftProvider.notifier)
                        .actualizarNombre(value);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categoriaController,
                decoration: InputDecoration(
                  labelText: 'Categoría (opcional)',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  errorText: erroresDeCampo?['categoria'],
                ),
                onChanged: (value) {
                  if (widget.producto == null) {
                    ref
                        .read(productoFormDraftProvider.notifier)
                        .actualizarCategoria(value);
                  }
                },
              ),
              const SizedBox(height: 24),
              if (mensajeError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    mensajeError,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: cargando ? null : _submit,
                  child: cargando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          widget.producto == null
                              ? 'Guardar producto'
                              : 'Guardar cambios',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
