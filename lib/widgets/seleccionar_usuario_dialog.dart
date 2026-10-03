import 'package:flutter/material.dart';

import '../services/wallet_service.dart';

/// Selección administrativa explícita: nunca elige una cuenta por coincidencia parcial.
Future<({String id, String email, String nombre})?> seleccionarUsuario(
  BuildContext context,
) async {
  final controller = TextEditingController();
  final identificador = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Seleccionar usuario'),
      content: TextField(controller: controller, autofocus: true,
          decoration: const InputDecoration(labelText: 'Correo o teléfono')),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Buscar')),
      ],
    ),
  );
  if (!context.mounted || identificador == null) return null;
  try {
    final cuentas = await WalletService().buscarUsuarios(identificador);
    if (!context.mounted) return null;
    if (cuentas.length == 1) return cuentas.single;
    return await showDialog<({String id, String email, String nombre})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Seleccionar usuario'),
        content: SizedBox(width: 420, height: 320,
          child: ListView.builder(itemCount: cuentas.length, itemBuilder: (_, index) {
            final cuenta = cuentas[index];
            return ListTile(title: Text(cuenta.nombre), subtitle: Text(cuenta.email),
                onTap: () => Navigator.of(dialogContext).pop(cuenta));
          })),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'))],
      ),
    );
  } catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo buscar el usuario: $error')));
    return null;
  }
}
