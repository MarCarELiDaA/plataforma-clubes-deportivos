import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';

class WalletScreen extends StatefulWidget {
  final String? usuarioId;
  final String? correoUsuario;
  final bool gestionAdmin;
  const WalletScreen({super.key, this.usuarioId, this.correoUsuario, this.gestionAdmin = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _auth = AuthService();
  late final _authStream = _auth.authStateChanges;
  final _service = WalletService();
  String? _usuarioId;
  Stream<WalletSaldo?>? _saldoStream;
  Stream<List<WalletMovimiento>>? _movimientosStream;
  bool _adjusting = false;
  bool _searching = false;
  bool _recharging = false;
  ({String usuarioId, int importe, String referencia})? _recargaPendiente;

  Future<void> _introducirRecarga() async {
    if (_recharging || _adjusting) return;
    final pendiente = _recargaPendiente;
    if (pendiente != null) {
      await _simularRecarga(pendiente.importe);
      return;
    }
    final importe = TextEditingController();
    final form = GlobalKey<FormState>();
    final amount = await showDialog<int>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Importe de la recarga simulada'),
        content: Form(key: form, child: TextFormField(controller: importe,
          autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Importe en euros'),
          validator: (value) => _centimos(value ?? '') == null
              ? 'Introduce un importe positivo con hasta dos decimales.' : null)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (form.currentState!.validate()) Navigator.of(dialogContext).pop(_centimos(importe.text));
          }, child: const Text('Continuar')),
        ],
      ));
    if (mounted && amount != null) await _simularRecarga(amount);
  }

  Future<void> _simularRecarga(int amount) async {
    final user = _auth.currentUser;
    if (_recharging || user == null || _usuarioId != user.uid ||
        !AppConfig.club.wallet.simulacionRecargas) return;
    final pending = _recargaPendiente;
    if (pending != null && (pending.usuarioId != user.uid || pending.importe != amount)) return;
    setState(() => _recharging = true);
    try {
      final confirmed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Simular recarga'),
          content: Text('Añadir ${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(amount / 100)} '
              'de prueba a ${user.email}. No se realizará ningún pago real.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Simular ingreso')),
          ],
        ));
      if (!mounted || confirmed != true) return;
      final recarga = pending ?? (usuarioId: user.uid, importe: amount,
          referencia: _service.crearReferenciaSimulacion(user.uid));
      _recargaPendiente = recarga;
      await _service.simularRecarga(recarga.usuarioId, importeCentimos: recarga.importe,
          referencia: recarga.referencia);
      if (!mounted) return;
      setState(() => _recargaPendiente = null);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recarga simulada registrada. No se ha realizado ningún pago real.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_errorMessage(error)} Reintenta el mismo importe.')));
    } finally {
      if (mounted) setState(() => _recharging = false);
    }
  }

  Future<void> _buscarWallet() async {
    if (_searching || !widget.gestionAdmin || !AppConfig.esAdministrador(_auth.currentUser?.email)) return;
    final controller = TextEditingController();
    final identificador = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buscar Wallet de usuario'),
        content: TextField(controller: controller, autofocus: true,
            decoration: const InputDecoration(labelText: 'Correo o teléfono')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Buscar')),
        ],
      ),
    );
    if (!mounted || identificador == null) return;
    setState(() => _searching = true);
    try {
      final usuarios = await _service.buscarUsuarios(identificador);
      if (!mounted) return;
      final usuario = usuarios.length == 1 ? usuarios.single
          : await showDialog<({String id, String email, String nombre})>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Seleccionar usuario'),
                content: SizedBox(
                  width: 420,
                  height: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${usuarios.length} cuentas coinciden con $identificador. '
                          'Elige el usuario cuyo Wallet quieres gestionar.'),
                      const SizedBox(height: 12),
                      Expanded(child: ListView.builder(
                        itemCount: usuarios.length,
                        itemBuilder: (context, index) {
                          final cuenta = usuarios[index];
                          return ListTile(
                            title: Text(cuenta.nombre),
                            subtitle: Text(cuenta.email),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(dialogContext).pop(cuenta),
                          );
                        },
                      )),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar')),
                ],
              ),
            );
      if (!mounted || usuario == null) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
          WalletScreen(usuarioId: usuario.id, correoUsuario: usuario.email, gestionAdmin: true)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _ajustarSaldo(bool ingreso) async {
    if (_adjusting || !widget.gestionAdmin || _usuarioId == null ||
        !AppConfig.esAdministrador(_auth.currentUser?.email)) return;
    final usuarioId = _usuarioId!;
    final importe = TextEditingController();
    final motivo = TextEditingController();
    final form = GlobalKey<FormState>();
    final datos = await showDialog<({int centimos, String motivo})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ingreso ? 'Ingresar saldo' : 'Retirar saldo'),
        content: SingleChildScrollView(child: Form(key: form, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.correoUsuario ?? _auth.currentUser?.email ?? ''),
            TextFormField(controller: importe,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Importe en euros'),
              validator: (value) => _centimos(value ?? '') == null
                  ? 'Introduce un importe positivo con hasta dos decimales.' : null),
            TextFormField(controller: motivo,
              decoration: const InputDecoration(labelText: 'Motivo obligatorio'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Indica el motivo.' : null),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (form.currentState!.validate()) Navigator.of(dialogContext).pop(
                (centimos: _centimos(importe.text)!, motivo: motivo.text.trim()));
          }, child: const Text('Continuar')),
        ],
      ),
    );
    if (!mounted || datos == null) return;
    setState(() => _adjusting = true);
    try {
      final confirmed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmar ajuste'),
          content: Text('${ingreso ? 'Ingresar' : 'Retirar'} ${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(datos.centimos / 100)} '
              'en ${widget.correoUsuario ?? _auth.currentUser?.email}.\nMotivo: ${datos.motivo}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirmar')),
          ],
        ));
      if (!mounted || confirmed != true) return;
      await _service.ajustarSaldo(usuarioId, importeCentimos: datos.centimos,
          ingreso: ingreso, motivo: datos.motivo);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saldo y movimiento registrados correctamente.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _adjusting = false);
    }
  }

  int? _centimos(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final euros = int.tryParse(parts[0]);
    if (euros == null) return null;
    final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
    final total = euros * 100 + cents;
    // Enteros representables exactamente en todas las plataformas, incluida web.
    return total > 0 && total <= 9007199254740991 ? total : null;
  }

  void _listen(String? usuarioId) {
    if (usuarioId != _usuarioId) _recargaPendiente = null;
    _usuarioId = usuarioId;
    _saldoStream = usuarioId == null ? null : _service.getSaldoStream(usuarioId);
    _movimientosStream = usuarioId == null
        ? null : _service.getMovimientosStream(usuarioId);
  }

  String _errorMessage(Object error) {
    if (error is FirebaseException) {
      return 'No se pudo completar la operación de Wallet (${error.code}).';
    }
    if (error is StateError) return error.message.toString();
    return 'No se pudieron consultar los datos de Wallet.';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authStream,
      initialData: _auth.currentUser,
      builder: (context, snapshot) {
        final enabled = AppConfig.club.moduloActivo('wallet');
        final admin = AppConfig.esAdministrador(snapshot.data?.email);
        final authenticated = snapshot.data != null &&
            (!widget.gestionAdmin || admin) && (widget.usuarioId == null || admin);
        final usuarioId = enabled && authenticated ? widget.usuarioId ?? snapshot.data?.uid : null;
        if (usuarioId != _usuarioId) _listen(usuarioId);
        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Text(widget.gestionAdmin ? 'Administración de saldos' : 'Wallet'),
            automaticallyImplyLeading: false,
            leadingWidth: 96,
            leading: AppDrawer.menuConAtras(context),
            actions: [AppDrawer.botonCerrarSesion(context)],
          ),
          body: !enabled || !authenticated
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          enabled
                              ? widget.gestionAdmin ? 'Acceso reservado al administrador.' : 'Inicia sesión para acceder a tu Wallet.'
                              : 'Wallet no está disponible en este club.',
                          textAlign: TextAlign.center,
                        ),
                        if (enabled) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Iniciar sesión'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : StreamBuilder<WalletSaldo?>(
                  key: ValueKey(usuarioId),
                  stream: _saldoStream,
                  builder: (context, saldoSnapshot) {
                    final loading = saldoSnapshot.connectionState == ConnectionState.waiting;
                    final error = saldoSnapshot.error;
                    final saldo = loading || error != null ? null : saldoSnapshot.data;
                    return _content(
                      context,
                      saldo,
                      loading ? 'Cargando saldo…'
                          : error != null ? _errorMessage(error)
                          : saldo == null ? 'Tu Wallet todavía no está inicializado.'
                          : null,
                      error != null,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _content(BuildContext context, WalletSaldo? saldo, String? message, bool retry) {
    final currency = NumberFormat.currency(
      locale: 'es_ES', symbol: '€', decimalDigits: 2,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _panel(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.identityLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.account_balance_wallet_outlined,
                          color: AppTheme.identity, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.usuarioId == null
                              ? widget.gestionAdmin ? 'Saldo de ${_auth.currentUser?.email ?? ''}' : 'Tu monedero'
                              : 'Monedero de ${widget.correoUsuario}',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(AppConfig.club.nombre,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (widget.gestionAdmin && AppConfig.esAdministrador(_auth.currentUser?.email)) ...[
                _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Gestión de saldo', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    OutlinedButton(onPressed: _searching || _adjusting ? null : _buscarWallet,
                        child: const Text('Buscar usuario')),
                    FilledButton(onPressed: _adjusting || (saldo == null && message != 'Tu Wallet todavía no está inicializado.')
                        ? null : () => _ajustarSaldo(true), child: const Text('Ingresar saldo')),
                    OutlinedButton(onPressed: _adjusting || saldo == null ? null : () => _ajustarSaldo(false),
                        child: const Text('Retirar saldo')),
                  ]),
                  if (_adjusting) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Procesando ajuste…')),
                ])),
                const SizedBox(height: 18),
              ],
              if (message != null) ...[
                _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      if (retry) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => setState(() => _listen(_usuarioId)),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (saldo?.esPrueba == true) ...[
                Text('Saldo de prueba', style: TextStyle(
                  color: AppTheme.warning, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 12),
              ],
              Text('El importe de una reserva queda bloqueado al confirmar y se libera al cancelar dentro del plazo. '
                  'Durante estas pruebas, las reservas ya iniciadas se cobran en el siguiente inicio de sesión.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 660 ? 3 : 1;
                  final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final item in [
                        ('Saldo total', 'Todo el saldo de tu monedero.', saldo?.totalCentimos),
                        ('Bloqueado', 'Importe retenido para tus reservas.', saldo?.bloqueadoCentimos),
                        ('Disponible', 'Saldo que puedes utilizar para reservar.', saldo?.disponibleCentimos),
                      ])
                        SizedBox(
                          width: width,
                          child: _panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.$1,
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 12),
                                Text(item.$3 == null ? 'No disponible'
                                    : currency.format(item.$3! / 100),
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    )),
                                const SizedBox(height: 8),
                                Text(item.$2,
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              if (!widget.gestionAdmin) _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recargar saldo',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(AppConfig.club.wallet.simulacionRecargas
                        ? 'Simulación de recargas: saldo de prueba, sin pago real.'
                        : 'Las recargas estarán disponibles próximamente.'),
                    if (_recargaPendiente != null)
                      const Text('Hay una recarga pendiente de comprobar. Pulsa el mismo importe para reintentar sin duplicarla.'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          onPressed: !AppConfig.club.wallet.simulacionRecargas ||
                              _usuarioId != _auth.currentUser?.uid || _recharging || _adjusting ||
                              (saldo == null && message != 'Tu Wallet todavía no está inicializado.') ||
                              (saldo != null && !saldo.esPrueba)
                              ? null : _introducirRecarga,
                          child: Text(_recargaPendiente == null ? 'Introducir importe' : 'Reintentar recarga pendiente'),
                        ),
                        for (final amount in AppConfig.club.wallet.recargasCentimos)
                          OutlinedButton(
                            onPressed: !AppConfig.club.wallet.simulacionRecargas ||
                                _usuarioId != _auth.currentUser?.uid || _recharging || _adjusting ||
                                (saldo == null && message != 'Tu Wallet todavía no está inicializado.') ||
                                (saldo != null && !saldo.esPrueba) ||
                                (_recargaPendiente != null && _recargaPendiente!.importe != amount)
                                ? null : () => _simularRecarga(amount),
                            child: Text(NumberFormat.currency(
                              locale: 'es_ES', symbol: '€', decimalDigits: 0,
                            ).format(amount / 100)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Movimientos',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    Icon(Icons.receipt_long_outlined,
                        color: AppTheme.textSecondaryColor, size: 32),
                    const SizedBox(height: 12),
                    if (saldo == null)
                      const Text('Los movimientos no están disponibles todavía.')
                    else
                      _movimientos(context, currency),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _movimientos(BuildContext context, NumberFormat currency) {
    return StreamBuilder<List<WalletMovimiento>>(
      key: ValueKey(_usuarioId),
      stream: _movimientosStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Cargando movimientos…');
        }
        if (snapshot.hasError) return Text(_errorMessage(snapshot.error!));
        final items = snapshot.data;
        if (items == null) return const Text('Movimientos no disponibles.');
        if (items.isEmpty) return const Text('Todavía no hay movimientos.');
        const labels = {
          'INGRESO': 'Ingreso', 'INGRESO_PRUEBA': 'Ingreso de prueba',
          'RECARGA_SIMULADA': 'Recarga simulada (sin pago real)',
          'RETIRADA': 'Retirada', 'BLOQUEO': 'Saldo bloqueado',
          'LIBERACION': 'Saldo liberado', 'COBRO': 'Cobro',
          'DEVOLUCION': 'Devolución',
        };
        return Column(
          children: [
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labels[item.tipo]!),
                subtitle: Text('${item.motivo}\n'
                    '${item.reservaId == null ? '' : 'Reserva: ${item.reservaId}\n'}'
                    '${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(item.fecha.toLocal())}'),
                trailing: Text('${const {'RETIRADA', 'COBRO'}.contains(item.tipo) ? '−' : const {'INGRESO', 'INGRESO_PRUEBA', 'RECARGA_SIMULADA', 'DEVOLUCION'}.contains(item.tipo) ? '+' : ''}${currency.format(item.importeCentimos / 100)}'),
              ),
          ],
        );
      },
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSoftColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}
