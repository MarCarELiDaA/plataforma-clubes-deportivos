import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import '../models/club/instalacion.dart';
import '../services/admin_service.dart';
import '../services/reserva_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'admin_reservas_screen.dart';

class AdminInformesScreen extends StatefulWidget {
  const AdminInformesScreen({super.key});

  @override
  State<AdminInformesScreen> createState() => _AdminInformesScreenState();
}

class _AdminInformesScreenState extends State<AdminInformesScreen> {
  final _service = AdminService();
  final _horarios = ReservaService();
  Stream<List<Map<String, dynamic>>>? _reservas;
  Stream<List<Map<String, dynamic>>>? _publicas;
  Stream<({List<Map<String, dynamic>> saldos, List<Map<String, dynamic>> movimientos})>? _wallet;
  late DateTime _diaAgenda;
  String? _desde;
  String? _hasta;
  String? _deporte;
  String? _instalacion;
  String? _usuarioWallet;
  int _apartado = 0;
  bool get _esAdmin => AppConfig.esAdministrador(FirebaseAuth.instance.currentUser?.email);
  String _fecha(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);
  String _euros(int centimos) => NumberFormat.currency(locale: 'es_ES', symbol: '€').format(centimos / 100);
  Map<String, Instalacion> get _instalaciones => {
    for (final instalacion in [
      ...AppConfig.club.instalaciones,
      ...AppConfig.club.actividades.expand((actividad) => actividad.instalaciones),
    ]) instalacion.id: instalacion,
  };

  @override
  void initState() {
    super.initState();
    _horarios.getInicioHorarioPublico(DateTime.now(), '00:00');
    final hoy = tz.TZDateTime.now(tz.getLocation(AppConfig.club.zonaHoraria));
    _diaAgenda = DateTime(hoy.year, hoy.month, hoy.day);
    _desde = _fecha(DateTime(hoy.year, hoy.month, 1));
    _hasta = _fecha(_diaAgenda);
    if (_esAdmin) _reservas = _service.getReservasClubStream();
  }

  void _abrirApartado(int apartado) {
    if (!_esAdmin) return;
    setState(() {
      _apartado = apartado;
      if (apartado == 2 && AppConfig.club.moduloActivo('wallet')) {
        _wallet ??= _service.getInformeWalletStream();
      }
      if (apartado == 3) _publicas ??= _service.getDisponibilidadClubStream();
    });
  }

  Future<void> _periodo() async {
    final rango = await showDateRangePicker(context: context,
      initialDateRange: _desde == null ? null : DateTimeRange(
          start: DateTime.parse(_desde!), end: DateTime.parse(_hasta!)),
      firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (!mounted || rango == null) return;
    setState(() { _desde = _fecha(rango.start); _hasta = _fecha(rango.end); });
  }

  Future<void> _elegirDia() async {
    final dia = await showDatePicker(context: context, initialDate: _diaAgenda,
        firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (mounted && dia != null) setState(() => _diaAgenda = dia);
  }

  String _nombreInstalacion(String id) => _instalaciones[id]?.nombre ?? id;
  String _nombreDeporte(Map<String, dynamic> reserva) {
    for (final actividad in AppConfig.club.actividades) {
      if (actividad.id == reserva['actividadId'] ||
          actividad.instalaciones.any((i) => i.id == reserva['instalacionId'])) return actividad.nombre;
    }
    return 'Otras instalaciones';
  }

  bool _cancelada(Map<String, dynamic> reserva) =>
      reserva['estadoReserva'] is String && (reserva['estadoReserva'] as String).startsWith('CANCELADA');
  String _cobrado(List<Map<String, dynamic>> reservas) {
    final cobradas = reservas.where((r) => r['estadoWallet'] == 'COBRADO').toList();
    final sinImporte = cobradas.where((r) => r['importeWalletCentimos'] is! int).length;
    if (cobradas.isNotEmpty && sinImporte == cobradas.length) return 'Importe no registrado';
    final total = cobradas.where((r) => r['importeWalletCentimos'] is int)
        .fold<int>(0, (suma, r) => suma + (r['importeWalletCentimos'] as int));
    return '${_euros(total)}${sinImporte == 0 ? '' : ' ($sinImporte sin importe)'}';
  }
  bool _enPeriodo(String? fecha) => fecha != null && (_desde == null ||
      (fecha.compareTo(_desde!) >= 0 && fecha.compareTo(_hasta!) <= 0));
  bool _enInstalaciones(Map<String, dynamic> reserva) =>
      (_instalacion == null || reserva['instalacionId'] == _instalacion) &&
      (_deporte == null || _nombreDeporte(reserva) == _deporte);

  ({DateTime inicio, DateTime fin})? _intervalo(Map<String, dynamic> reserva) {
    try {
      final duracion = reserva['duracionMinutos'];
      if (duracion is! int || duracion <= 0) return null;
      final inicio = reserva['inicioReserva'] is Timestamp
          ? (reserva['inicioReserva'] as Timestamp).toDate().toUtc()
          : _horarios.getInicioHorarioPublico(DateTime.parse(reserva['fecha'] as String),
              reserva['horaInicio'] as String);
      return (inicio: inicio, fin: inicio.add(Duration(minutes: duracion)));
    } catch (_) { return null; }
  }

  List<Map<String, dynamic>> _ocupantes(List<Map<String, dynamic>> reservas,
      Instalacion instalacion, DateTime dia, String hora) {
    final inicio = _horarios.getInicioHorarioPublico(dia, hora);
    final fin = inicio.add(Duration(minutes: instalacion.duracionReservaMinutos));
    return reservas.where((r) {
      if (r['estadoReserva'] != 'CONFIRMADA' || r['instalacionId'] != instalacion.id) return false;
      final intervalo = _intervalo(r);
      return intervalo != null && intervalo.inicio.isBefore(fin) && intervalo.fin.isAfter(inicio);
    }).toList();
  }

  Widget _panel(String titulo, List<Widget> children) => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.clubSurface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.clubBorderSoft), boxShadow: AppTheme.softShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), ...children,
    ]));

  Widget _tabla(List<String> columnas, List<List<String>> filas) => filas.isEmpty
      ? const Text('No hay datos para esta consulta.')
      : SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          columns: columnas.map((c) => DataColumn(label: Text(c))).toList(),
          rows: filas.map((fila) => DataRow(cells: fila.map((dato) => DataCell(
              SelectableText(dato))).toList())).toList()));

  Widget _agrupacion(String titulo, List<Map<String, dynamic>> reservas,
      String Function(Map<String, dynamic>) clave) {
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final reserva in reservas) { (grupos[clave(reserva)] ??= []).add(reserva); }
    final claves = grupos.keys.toList()..sort();
    return _panel(titulo, [_tabla(['Grupo', 'Confirmadas', 'Canceladas', 'Cobrado'], [
      for (final key in claves) [key,
        '${grupos[key]!.where((r) => r['estadoReserva'] == 'CONFIRMADA').length}',
        '${grupos[key]!.where(_cancelada).length}',
        _cobrado(grupos[key]!),
      ],
    ])]);
  }

  List<Widget> _resumen(List<Map<String, dynamic>> todas) {
    final reservas = todas.where((r) => _enInstalaciones(r) &&
        _enPeriodo(r['fecha'] is String ? r['fecha'] as String : null)).toList();
    final sinFecha = todas.where((r) => _enInstalaciones(r) && r['fecha'] is! String).length;
    final confirmadas = reservas.where((r) => r['estadoReserva'] == 'CONFIRMADA').length;
    final canceladas = reservas.where(_cancelada).length;
    final porUsuario = <String, List<Map<String, dynamic>>>{};
    for (final r in reservas) { (porUsuario[r['usuarioId'] as String? ?? 'Sin usuario'] ??= []).add(r); }
    final usuarios = porUsuario.keys.toList()..sort((a, b) => porUsuario[b]!.length.compareTo(porUsuario[a]!.length));
    return [
      _panel('Resumen del periodo', [
        Text('${reservas.length} reservas registradas · $confirmadas confirmadas · $canceladas canceladas'),
        Text(reservas.isEmpty ? 'Tasa de cancelación: sin datos' :
            'Tasa de cancelación: ${NumberFormat('0.0', 'es_ES').format(canceladas * 100 / reservas.length)} %'),
        Text('${porUsuario.length} usuarios con reservas en este periodo'),
        if (sinFecha > 0) Text('$sinFecha reservas sin fecha válida no se pueden incluir en el periodo. Consulta Incidencias.'),
        if (reservas.any((r) => r['importeWalletCentimos'] is! int))
          const Text('Hay reservas sin importe registrado. No se calcula su precio con las tarifas actuales.'),
        const Text('El periodo se refiere al día reservado. Los cobros son los estados guardados, no pagos bancarios.'),
      ]),
      _agrupacion('Reservas por deporte', reservas, _nombreDeporte),
      _agrupacion('Reservas por instalación', reservas, (r) => _nombreInstalacion(r['instalacionId'] as String? ?? 'Sin instalación')),
      _agrupacion('Evolución por día', reservas, (r) => r['fecha'] as String? ?? 'Fecha no registrada'),
      _agrupacion('Evolución por mes', reservas, (r) {
        final fecha = r['fecha'];
        return fecha is String && fecha.length >= 7 ? fecha.substring(0, 7) : 'Fecha no registrada';
      }),
      _agrupacion('Demanda por horario', reservas, (r) => r['horaInicio'] as String? ?? 'Hora no registrada'),
      _panel('Actividad por usuario', [_tabla(['Usuario', 'ID de cuenta', 'Reservas', 'Confirmadas', 'Canceladas'], [
        for (final uid in usuarios) [
          porUsuario[uid]!.last['nombreUsuario']?.toString() ?? 'Usuario sin nombre', uid,
          '${porUsuario[uid]!.length}', '${porUsuario[uid]!.where((r) => r['estadoReserva'] == 'CONFIRMADA').length}',
          '${porUsuario[uid]!.where(_cancelada).length}',
        ],
      ])]),
      _agrupacion('Autor de las cancelaciones', reservas.where(_cancelada).toList(),
          (r) => r['estadoReserva'] == 'CANCELADA_POR_ADMIN' ? 'Administrador'
              : r['estadoReserva'] == 'CANCELADA_POR_USUARIO' ? 'Usuario' : 'Origen no registrado'),
      _agrupacion('Creación de reservas', reservas, (r) => r['creadaPorUid'] == null
          ? 'Autor no registrado' : r['creadaPorUid'] != r['usuarioId'] ? 'Asignadas por el administrador' : 'Para la propia cuenta'),
      _ocupacion(todas),
    ];
  }

  Widget _ocupacion(List<Map<String, dynamic>> todas) {
    if (_desde == null) return _panel('Uso de horarios y plazas', [
      const Text('Selecciona un periodo para calcular el uso respecto a los horarios configurados.')]);
    final primero = DateTime.parse(_desde!);
    final ultimo = DateTime.parse(_hasta!);
    final filas = <List<String>>[];
    for (final instalacion in _instalaciones.values.where((i) => i.activa && i.reservasActivas &&
        _enInstalaciones({'instalacionId': i.id}))) {
      final candidatas = todas.where((r) => r['instalacionId'] == instalacion.id && r['estadoReserva'] == 'CONFIRMADA').toList();
      if (candidatas.any((r) => _intervalo(r) == null)) {
        filas.add([instalacion.nombre, 'Sin verificar', 'Datos incompletos', 'Sin verificar', 'Sin verificar']);
        continue;
      }
      int ofrecidas = 0, ocupadas = 0, completas = 0, excedidas = 0;
      for (var dia = primero; !dia.isAfter(ultimo); dia = DateTime(dia.year, dia.month, dia.day + 1)) {
        for (final hora in instalacion.horarios) {
          ofrecidas += instalacion.aforoPorHorario;
          final cantidad = _ocupantes(candidatas, instalacion, dia, hora).length;
          ocupadas += cantidad > instalacion.aforoPorHorario ? instalacion.aforoPorHorario : cantidad;
          if (cantidad >= instalacion.aforoPorHorario) completas++;
          if (cantidad > instalacion.aforoPorHorario) excedidas++;
        }
      }
      filas.add([instalacion.nombre, '$ocupadas / $ofrecidas',
        ofrecidas == 0 ? 'Sin horarios' : '${NumberFormat('0.0', 'es_ES').format(ocupadas * 100 / ofrecidas)} %',
        '$completas', '$excedidas']);
    }
    return _panel('Uso respecto a la configuración actual', [
      const Text('Referencia calculada con los horarios y aforos actuales. No contempla cierres ni cambios históricos de configuración. '
          'Las reservas canceladas no ocupan; las que cruzan medianoche se cuentan en ambos días afectados.'),
      _tabla(['Instalación', 'Plazas ocupadas/ofrecidas', 'Uso', 'Franjas completas', 'Sobreaforo'], filas),
    ]);
  }

  List<Widget> _agenda(List<Map<String, dynamic>> todas) => [
    _panel('Agenda del día ${DateFormat('dd/MM/yyyy').format(_diaAgenda)}', [
      OutlinedButton.icon(onPressed: _elegirDia, icon: const Icon(Icons.calendar_today_outlined),
          label: const Text('Elegir día')),
      const Text('La agenda usa su propio día, independientemente del periodo de los informes.'),
    ]),
    for (final instalacion in _instalaciones.values.where((i) => i.activa && i.reservasActivas &&
        _enInstalaciones({'instalacionId': i.id})))
      _panel(instalacion.nombre, [
        for (final hora in instalacion.horarios) Builder(builder: (context) {
          final ocupantes = _ocupantes(todas, instalacion, _diaAgenda, hora);
          final invalida = todas.any((r) => r['instalacionId'] == instalacion.id &&
              r['estadoReserva'] == 'CONFIRMADA' && _intervalo(r) == null);
          final completa = ocupantes.length >= instalacion.aforoPorHorario;
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: invalida || completa
                  ? AppTheme.error : ocupantes.isEmpty ? AppTheme.clubBorderSoft : AppTheme.warning),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$hora · ${invalida ? 'Ocupación sin verificar: hay reservas con datos inválidos'
                    : completa ? 'COMPLETO / RESERVADO' : ocupantes.isEmpty ? 'LIBRE'
                    : '${ocupantes.length}/${instalacion.aforoPorHorario} plazas ocupadas'}'),
                for (final reserva in ocupantes) SelectableText(
                    '${reserva['nombreUsuario'] ?? 'Usuario'} · Reserva ${reserva['id']}'),
                if (ocupantes.length > instalacion.aforoPorHorario)
                  const Text('Incidencia: se supera el aforo configurado.'),
                if (ocupantes.isNotEmpty) TextButton(onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdminReservasScreen(
                        fechaInicial: _fecha(_diaAgenda), instalacionInicial: instalacion.id))),
                    child: const Text('Gestionar reservas de esta instalación y día')),
              ]));
        }),
      ]),
    _panel('Gestionar las reservas', [OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminReservasScreen())),
      icon: const Icon(Icons.event_note_outlined), label: const Text('Abrir listado y cancelaciones'))]),
  ];

  Widget _informeWallet() {
    if (!AppConfig.club.moduloActivo('wallet')) return _panel('Wallet', [const Text('Módulo desactivado en este club.')]);
    return StreamBuilder<({List<Map<String, dynamic>> saldos, List<Map<String, dynamic>> movimientos})>(
      stream: _wallet, builder: (context, snapshot) {
        if (snapshot.hasError) return _panel('Error al consultar Wallet', [Text('${snapshot.error}')]);
        if (!snapshot.hasData) return _panel('Wallet', [const LinearProgressIndicator(),
          const Text('Consultando los historiales completos. No se mostrarán totales parciales.')]);
        final cuentas = snapshot.data!.saldos;
        final saldos = cuentas.where((s) => _usuarioWallet == null || s['usuarioId'] == _usuarioWallet).toList();
        final movimientos = snapshot.data!.movimientos.where((m) =>
            (_usuarioWallet == null || m['usuarioId'] == _usuarioWallet) && _enPeriodo(_fecha(
            tz.TZDateTime.from((m['fecha'] as Timestamp).toDate(), tz.getLocation(AppConfig.club.zonaHoraria)))))
            .toList()..sort((a, b) => (b['fecha'] as Timestamp).compareTo(a['fecha'] as Timestamp));
        int sumar(String campo) => saldos.fold<int>(0, (suma, s) => suma + (s[campo] as int));
        const tipos = ['INGRESO', 'INGRESO_PRUEBA', 'RECARGA_SIMULADA', 'RETIRADA', 'BLOQUEO', 'LIBERACION', 'COBRO', 'DEVOLUCION'];
        final sinReserva = movimientos.where((m) => const ['BLOQUEO', 'LIBERACION', 'COBRO'].contains(m['tipo'])
            && m['reservaId'] == null).length;
        final porDia = <String, List<Map<String, dynamic>>>{};
        for (final movimiento in movimientos) {
          final fecha = _fecha(tz.TZDateTime.from((movimiento['fecha'] as Timestamp).toDate(),
              tz.getLocation(AppConfig.club.zonaHoraria)));
          (porDia[fecha] ??= []).add(movimiento);
        }
        final dias = porDia.keys.toList()..sort();
        int sumaTipo(List<Map<String, dynamic>> lista, String tipo) => lista.where((m) => m['tipo'] == tipo)
            .fold<int>(0, (suma, m) => suma + (m['importeCentimos'] as int));
        return Column(children: [
          _panel('Seleccionar cuentas', [DropdownButton<String>(
            value: cuentas.any((s) => s['usuarioId'] == _usuarioWallet) ? _usuarioWallet : null,
            hint: const Text('Todas las cuentas'), isExpanded: true,
            items: [const DropdownMenuItem<String>(value: null, child: Text('Todas las cuentas')),
              ...cuentas.map((s) => DropdownMenuItem(value: s['usuarioId'] as String,
                  child: Text('${s['nombre']} (${s['email']})')))],
            onChanged: (value) => setState(() => _usuarioWallet = value))]),
          _panel('Saldos actuales de las cuentas seleccionadas', [
            Text('${saldos.length} Wallets · Total: ${_euros(sumar('saldoTotalCentimos'))} · '
                'Bloqueado: ${_euros(sumar('saldoBloqueadoCentimos'))} · '
                'Disponible: ${_euros(sumar('saldoTotalCentimos') - sumar('saldoBloqueadoCentimos'))}'),
            const Text('Los saldos son actuales; el periodo solo filtra los movimientos. '
                'Los filtros de deporte e instalación no se aplican a los saldos ni a los movimientos.'),
            _tabla(['Usuario', 'Correo', 'Total', 'Bloqueado', 'Disponible', 'Modo'], [
              for (final saldo in saldos) [saldo['nombre'].toString(), saldo['email'].toString(),
                _euros(saldo['saldoTotalCentimos'] as int), _euros(saldo['saldoBloqueadoCentimos'] as int),
                _euros((saldo['saldoTotalCentimos'] as int) - (saldo['saldoBloqueadoCentimos'] as int)),
                saldo['esPrueba'] == true ? 'Prueba' : 'Normal'],
            ]),
          ]),
          _panel('Movimientos del periodo', [
            const Text('Ingresos manuales y recargas simuladas se muestran por separado. '
                'Bloquear o liberar dinero no es cobrar ni devolver un pago bancario.'),
            _tabla(['Tipo', 'Operaciones', 'Importe'], [for (final tipo in tipos) [tipo,
              '${movimientos.where((m) => m['tipo'] == tipo).length}',
              _euros(movimientos.where((m) => m['tipo'] == tipo)
                  .fold<int>(0, (suma, m) => suma + (m['importeCentimos'] as int)))]]),
            if (sinReserva > 0) Text('$sinReserva movimientos de reserva sin identificador: trazabilidad incompleta.'),
          ]),
          _panel('Evolución diaria de Wallet', [_tabla(
              ['Día', 'Ingreso manual', 'Ingreso de prueba', 'Recarga simulada', 'Retiradas', 'Cobros', 'Bloqueos', 'Liberaciones', 'Devoluciones'], [
            for (final dia in dias) [dia, for (final tipo in [
              'INGRESO', 'INGRESO_PRUEBA', 'RECARGA_SIMULADA', 'RETIRADA',
              'COBRO', 'BLOQUEO', 'LIBERACION', 'DEVOLUCION',
            ]) _euros(sumaTipo(porDia[dia]!, tipo))],
          ])]),
          _panel('Historial y trazabilidad', [_tabla(['Fecha del club', 'Usuario', 'Tipo', 'Importe', 'Reserva', 'Autor (ID cuenta)', 'Motivo'], [
            for (final movimiento in movimientos) [
              DateFormat('dd/MM/yyyy HH:mm').format(tz.TZDateTime.from(
                  (movimiento['fecha'] as Timestamp).toDate(), tz.getLocation(AppConfig.club.zonaHoraria))),
              movimiento['email'].toString(), movimiento['tipo'].toString(),
              _euros(movimiento['importeCentimos'] as int), movimiento['reservaId']?.toString() ?? 'No asociada',
              movimiento['autorUid']?.toString() ?? 'No registrado',
              movimiento['motivo'].toString(),
            ],
          ])]),
        ]);
      });
  }

  Widget _incidencias(List<Map<String, dynamic>> todas) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: _publicas, builder: (context, snapshot) {
      if (snapshot.hasError) return _panel('Error de comprobación', [Text('${snapshot.error}')]);
      if (!snapshot.hasData) return _panel('Comprobando disponibilidad', [const LinearProgressIndicator()]);
      final publicas = {for (final publica in snapshot.data!) publica['id']: publica};
      final privadas = {for (final reserva in todas) reserva['id']: reserva};
      final filas = <List<String>>[];
      const campos = ['instalacionId', 'fecha', 'horaInicio', 'duracionMinutos'];
      for (final reserva in todas) {
        if (reserva['importeWalletCentimos'] is! int) filas.add([reserva['id'].toString(), 'Importe no registrado']);
        if (_intervalo(reserva) == null) filas.add([reserva['id'].toString(), 'Intervalo inválido o incompleto']);
        if (reserva['clubId'] == null) filas.add([reserva['id'].toString(), 'Reserva antigua sin clubId']);
        if (reserva['estadoReserva'] == 'CONFIRMADA') {
          final publica = publicas[reserva['id']];
          if (publica == null) filas.add([reserva['id'].toString(), 'Falta disponibilidad pública']);
          else if (campos.any((campo) => publica[campo] != reserva[campo]) || publica.length != 5) {
            filas.add([reserva['id'].toString(), 'Disponibilidad pública distinta o con campos adicionales']);
          }
        }
      }
      for (final publica in publicas.values) {
        if (privadas[publica['id']]?['estadoReserva'] != 'CONFIRMADA') {
          filas.add([publica['id'].toString(), 'Documento público sin reserva confirmada del club']);
        }
      }
      for (final instalacion in _instalaciones.values) {
        final confirmadas = todas.where((r) => r['instalacionId'] == instalacion.id &&
            r['estadoReserva'] == 'CONFIRMADA' && _intervalo(r) != null).toList()
          ..sort((a, b) => _intervalo(a)!.inicio.compareTo(_intervalo(b)!.inicio));
        for (var index = 0; index < confirmadas.length; index++) {
          final reserva = confirmadas[index];
          final intervalo = _intervalo(reserva)!;
          final simultaneas = confirmadas.take(index + 1).where((r) => _intervalo(r)!.fin.isAfter(intervalo.inicio)).toList();
          if (simultaneas.length > instalacion.aforoPorHorario) {
            filas.add([reserva['id'].toString(), 'Solapamiento o sobreaforo en ${instalacion.nombre}']);
          }
          if (instalacion.aforoPorHorario > 1 && confirmadas.take(index).any((r) =>
              r['usuarioId'] == reserva['usuarioId'] && r['fecha'] == reserva['fecha'] &&
              r['horaInicio'] == reserva['horaInicio'])) {
            filas.add([reserva['id'].toString(), 'Usuario repetido en la misma clase']);
          }
        }
      }
      return _panel('Incidencias de todo el historial', [
        const Text('Comprobación de lectura, independiente del periodo y los filtros. '
            'No elimina ni repara documentos. Durante una actualización puede aparecer una diferencia transitoria entre las escuchas.'),
        Text('${filas.length} observaciones'),
        filas.isEmpty ? const Text('No se han detectado incidencias en los datos consultados.')
            : _tabla(['Reserva / documento', 'Observación'], filas),
      ]);
    });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.clubBackground, drawer: const AppDrawer(),
    appBar: AppBar(title: const Text('Informes del club'), backgroundColor: AppTheme.clubSurface,
      foregroundColor: AppTheme.clubTextPrimary, leadingWidth: 96,
      leading: AppDrawer.menuConAtras(context), actions: [AppDrawer.botonCerrarSesion(context)]),
    body: !_esAdmin ? const Center(child: Text('Acceso reservado al administrador'))
        : StreamBuilder<List<Map<String, dynamic>>>(stream: _reservas, builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24),
              child: Text('No se pudieron cargar las reservas: ${snapshot.error}')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final todas = snapshot.data!;
          final deportes = <String>{...AppConfig.club.actividades.where((a) => a.activa).map((a) => a.nombre),
            ...todas.map(_nombreDeporte)}.toList()..sort();
          final instalaciones = <String>{..._instalaciones.keys,
            ...todas.map((r) => r['instalacionId']).whereType<String>()}.toList()..sort();
          return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _panel('Consultar', [
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    OutlinedButton.icon(onPressed: _periodo, icon: const Icon(Icons.date_range_outlined),
                        label: Text(_desde == null ? 'Todo el historial' : '$_desde — $_hasta')),
                    TextButton(onPressed: () => setState(() { _desde = null; _hasta = null; }),
                        child: const Text('Todo el historial')),
                    DropdownButton<String>(value: _deporte, hint: const Text('Todos los deportes'),
                        items: [const DropdownMenuItem<String>(value: null, child: Text('Todos los deportes')),
                          ...deportes.map((d) => DropdownMenuItem(value: d, child: Text(d)))],
                        onChanged: (value) => setState(() => _deporte = value)),
                    DropdownButton<String>(value: _instalacion, hint: const Text('Todas las instalaciones'),
                        items: [const DropdownMenuItem<String>(value: null, child: Text('Todas las instalaciones')),
                          ...instalaciones.map((i) => DropdownMenuItem(value: i, child: Text(_nombreInstalacion(i))))],
                        onChanged: (value) => setState(() => _instalacion = value)),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final apartado in [(0, 'Reservas'), (1, 'Agenda diaria'), (2, 'Wallet'), (3, 'Incidencias')])
                      ChoiceChip(label: Text(apartado.$2), selected: _apartado == apartado.$1,
                          onSelected: (_) => _abrirApartado(apartado.$1)),
                  ]),
                ]),
                if (_apartado == 0) ..._resumen(todas),
                if (_apartado == 1) ..._agenda(todas),
                if (_apartado == 2) _informeWallet(),
                if (_apartado == 3) _incidencias(todas),
              ]))));
        }),
  );
}
