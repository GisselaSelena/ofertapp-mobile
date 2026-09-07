import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../state/productos_state.dart';
import '../state/form_draft_state.dart';

class ProductoFormScreen extends ConsumerStatefulWidget {
  const ProductoFormScreen({super.key});

  @override
  ConsumerState<ProductoFormScreen> createState() =>
      _ProductoFormScreenState();
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
    _nombreController = TextEditingController(text: draft.nombre);
    _categoriaController = TextEditingController(text: draft.categoria);

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

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 3) {
      return 'Debe tener al menos 3 caracteres';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(crearProductoProvider.notifier).crear(
          nombre: _nombreController.text.trim(),
          categoria: _categoriaController.text.trim(),
        );

    final estado = ref.read(crearProductoProvider);
    if (estado is RemoteSuccess) {
      ref.read(productoFormDraftProvider.notifier).limpiar();
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
        title: const Text('Nuevo producto'),
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
                validator: _validarNombre,
                onChanged: (value) => ref
                    .read(productoFormDraftProvider.notifier)
                    .actualizarNombre(value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categoriaController,
                decoration: InputDecoration(
                  labelText: 'Categoría (opcional)',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  errorText: erroresDeCampo?['categoria'],
                ),
                onChanged: (value) => ref
                    .read(productoFormDraftProvider.notifier)
                    .actualizarCategoria(value),
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
                              color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text('Guardar producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
