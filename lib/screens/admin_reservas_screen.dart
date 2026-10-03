import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../services/admin_service.dart';
import '../services/reserva_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class AdminReservasScreen extends StatefulWidget {
  final String? fechaInicial;
  final String? instalacionInicial;
  const AdminReservasScreen({super.key, this.fechaInicial, this.instalacionInicial});

  @override
  State<AdminReservasScreen> createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen> {
  Stream<List<Map<String, dynamic>>>? _reservas;
  String? _cancelando;
  String? _desde;
  String? _hasta;
  String? _instalacion;
  String? _estado;
  bool get _esAdmin => AppConfig.esAdministrador(FirebaseAuth.instance.currentUser?.email);
  String _euros(int centimos) => NumberFormat.currency(locale: 'es_ES', symbol: '€')
      .format(centimos / 100);

  @override
  void initState() {
    super.initState();
    _desde = widget.fechaInicial;
    _hasta = widget.fechaInicial;
    _instalacion = widget.instalacionInicial;
    if (_esAdmin) _reservas = AdminService().getReservasClubStream();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fechas = await showDateRangePicker(context: context,
        initialDateRange: _desde == null ? null : DateTimeRange(
            start: DateTime.parse(_desde!), end: DateTime.parse(_hasta!)),
        currentDate: hoy,
        firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (mounted && fechas != null) {
      setState(() {
        _desde = DateFormat('yyyy-MM-dd').format(fechas.start);
        _hasta = DateFormat('yyyy-MM-dd').format(fechas.end);
      });
    }
  }

  Future<void> _cancelar(Map<String, dynamic> reserva) async {
    if (!_esAdmin || _cancelando != null || reserva['estadoReserva'] != 'CONFIRMADA') return;
    final id = reserva['id'] as String;
    final cobrada = reserva['estadoWallet'] == 'COBRADO';
    final bloqueada = reserva['estadoWallet'] == 'BLOQUEADO';
    final confirmar = await showDialog<bool>(context: context, builder: (dialogContext) =>
        AlertDialog(title: const Text('Cancelar reserva como administrador'),
          content: Text('¿Cancelar la reserva $id de ${reserva['nombreUsuario'] ?? 'este usuario'}? '
              '${cobrada ? 'El importe ya cobrado no se devuelve automáticamente. Puedes gestionar un ingreso desde Wallet.' : bloqueada ? 'El importe bloqueado volverá a estar disponible para el usuario.' : 'Esta reserva no tiene un importe bloqueado.'}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Conservar reserva')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Sí, cancelar')),
          ]));
    if (!mounted || confirmar != true || !_esAdmin) return;
    setState(() => _cancelando = id);
    try {
      await ReservaService().cancelarReserva(id, comoAdministrador: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada correctamente')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cancelar la reserva: $error'),
              backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _cancelando = null);
    }
  }

  String _nombreInstalacion(String id) {
    for (final instalacion in [
      ...AppConfig.club.instalaciones,
      ...AppConfig.club.actividades.expand((actividad) => actividad.instalaciones),
    ]) {
      if (instalacion.id == id) return instalacion.nombre;
    }
    return id;
  }

  Widget _tarjeta(Widget child) => Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppTheme.clubSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.clubBorderSoft),
          boxShadow: AppTheme.softShadow), child: child);

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.clubBackground,
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Reservas e informes'),
          backgroundColor: AppTheme.clubSurface, foregroundColor: AppTheme.clubTextPrimary,
          leadingWidth: 96, leading: AppDrawer.menuConAtras(context),
          actions: [AppDrawer.botonCerrarSesion(context)]),
      body: !_esAdmin ? const Center(child: Text('Acceso reservado al administrador'))
          : StreamBuilder<List<Map<String, dynamic>>>(stream: _reservas,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No se pudieron consultar las reservas: ${snapshot.error}')));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final todas = snapshot.data!;
                final instalaciones = todas.map((r) => r['instalacionId']).whereType<String>()
                    .toSet().toList()..sort();
                final filtradas = todas.where((r) =>
                    (_desde == null || (r['fecha'] is String &&
                        (r['fecha'] as String).compareTo(_desde!) >= 0 &&
                        (r['fecha'] as String).compareTo(_hasta!) <= 0)) &&
                    (_instalacion == null || r['instalacionId'] == _instalacion) &&
                    (_estado == null || (_estado == 'CANCELADA'
                        ? (r['estadoReserva'] as String? ?? '').startsWith('CANCELADA')
                        : r['estadoReserva'] == _estado))).toList()
                  ..sort((a, b) => '${b['fecha']} ${b['horaInicio']}'
                      .compareTo('${a['fecha']} ${a['horaInicio']}'));
                final confirmadas = filtradas.where((r) => r['estadoReserva'] == 'CONFIRMADA').length;
                final canceladas = filtradas.where((r) =>
                    (r['estadoReserva'] as String? ?? '').startsWith('CANCELADA')).length;
                int importe(String estadoWallet) => filtradas
                    .where((r) => r['estadoWallet'] == estadoWallet)
                    .fold<int>(0, (total, r) => total + (r['importeWalletCentimos'] as int? ?? 0));
                final sinImporte = filtradas.where((r) => r['importeWalletCentimos'] is! int).length;
                return SingleChildScrollView(padding: const EdgeInsets.all(20),
                  child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _tarjeta(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Consultar reservas del club', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(onPressed: _elegirFecha,
                                icon: const Icon(Icons.calendar_today_outlined),
                                label: Text(_desde == null ? 'Todas las fechas' : '$_desde — $_hasta')),
                            if (_desde != null) TextButton(onPressed: () => setState(() {
                              _desde = null;
                              _hasta = null;
                            }),
                                child: const Text('Todas las fechas')),
                            DropdownButton<String>(value: instalaciones.contains(_instalacion) ? _instalacion : null,
                                hint: const Text('Todas las instalaciones'),
                                items: [const DropdownMenuItem<String>(value: null,
                                    child: Text('Todas las instalaciones')),
                                  ...instalaciones.map((id) => DropdownMenuItem(value: id,
                                      child: Text(_nombreInstalacion(id))))],
                                onChanged: (value) => setState(() => _instalacion = value)),
                            DropdownButton<String>(value: _estado, hint: const Text('Todos los estados'),
                                items: const [
                                  DropdownMenuItem<String>(value: null, child: Text('Todos los estados')),
                                  DropdownMenuItem(value: 'CONFIRMADA', child: Text('Confirmadas')),
                                  DropdownMenuItem(value: 'CANCELADA', child: Text('Canceladas')),
                                ], onChanged: (value) => setState(() => _estado = value)),
                          ]),
                      ])),
                      _tarjeta(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Reservas por instalación', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        if (filtradas.isEmpty) const Text('No hay datos para el periodo y filtros elegidos.'),
                        for (final id in instalaciones.where((id) => filtradas.any((r) => r['instalacionId'] == id)))
                          Padding(padding: const EdgeInsets.only(bottom: 8),
                            child: Text('${_nombreInstalacion(id)}: '
                                '${filtradas.where((r) => r['instalacionId'] == id && r['estadoReserva'] == 'CONFIRMADA').length} confirmadas · '
                                '${filtradas.where((r) => r['instalacionId'] == id && (r['estadoReserva'] as String? ?? '').startsWith('CANCELADA')).length} canceladas')),
                      ])),
                      _tarjeta(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Resumen de la consulta', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Text('${filtradas.length} reservas · $confirmadas confirmadas · $canceladas canceladas'),
                        const SizedBox(height: 8),
                        Text('Importe bloqueado: ${_euros(importe('BLOQUEADO'))}'),
                        Text('Importe registrado como cobrado: ${_euros(importe('COBRADO'))}'),
                        if (sinImporte > 0) Text('$sinImporte reservas antiguas sin importe registrado.'),
                        const SizedBox(height: 8),
                        const Text('Los importes proceden de las reservas guardadas. '
                            'Este resumen no es un informe de ingresos y retiradas de Wallet.'),
                      ])),
                      if (filtradas.isEmpty) _tarjeta(const Text('No hay reservas para esta consulta.')),
                      ...filtradas.map((r) => _tarjeta(Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r['nombreUsuario'] ?? 'Usuario'} · ${_nombreInstalacion(r['instalacionId'] as String? ?? '')}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('${r['fecha']} · ${r['horaInicio']} · ${r['duracionMinutos']} minutos'),
                        SelectableText('Reserva: ${r['id']}'),
                        Text('Estado: ${r['estadoReserva']}'),
                        Text(r['importeWalletCentimos'] is int
                            ? 'Importe: ${_euros(r['importeWalletCentimos'] as int)} · ${r['estadoWallet'] ?? 'Sin estado Wallet'}'
                            : 'Importe: no registrado'),
                        if (r['estadoReserva'] == 'CONFIRMADA') ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(onPressed: _cancelando != null ? null : () => _cancelar(r),
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(_cancelando == r['id'] ? 'Cancelando…' : 'Cancelar como administrador')),
                        ],
                      ]))),
                    ]))));
              }),
    );
  }
}
