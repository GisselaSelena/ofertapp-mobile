import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_state.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final esAdmin = auth?.usuario.esAdministrador ?? false;
    final iniciales = (auth?.usuario.nombre ?? '?')
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/productos'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 44,
              backgroundColor: primary,
              child: Text(
                iniciales,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            Text(auth?.usuario.nombre ?? '',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(auth?.usuario.email ?? '',
                style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: esAdmin
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFF1F5F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                esAdmin ? 'ADMINISTRADOR' : 'USUARIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: esAdmin
                      ? const Color(0xFF92400E)
                      : const Color(0xFF4B5563),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}