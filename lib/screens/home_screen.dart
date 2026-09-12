import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/reserva_service.dart';
import '../models/pista_info.dart';
import '../utils/network_utils.dart';
import '../theme/app_theme.dart';
import 'my_reservations_screen.dart';
import 'login_screen.dart';
import 'confirmation_screen.dart';
import 'info_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  final _reservaService = ReservaService();

  DateTime? _selectedDate;
  PistaInfo? _pistaInfo;
  List<String> _availableTimes = [];
  List<String> _reservedTimes = [];
  bool _isLoading = false;
  bool _isLoadingPista = false;
  String _userRole = 'user';

  StreamSubscription<List<String>>? _reservedTimesSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPistaInfo();
    _checkUserRole();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reservedTimesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUserExists();
    }
  }

  Future<void> _checkUserExists() async {
    final user = _authService.currentUser;

    if (user != null && mounted) {
      try {
        final userStatus = await _authService.getUserStatus();

        if (userStatus == null && mounted) {
          await _authService.signOut();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        }
      } catch (e) {
        // Error silenciado para producción.
      }
    }
  }

  Future<void> _checkUserRole() async {
    final user = _authService.currentUser;

    if (user != null && mounted) {
      setState(() {
        _userRole =
            user.email == 'martin.bautista.sanchez@gmail.com'
                ? 'admin'
                : 'user';
      });
    }
  }

  Future<void> _loadPistaInfo() async {
    if (!await NetworkUtils.isNetworkAvailable()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay conexión a internet'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _availableTimes = [
          '06:30',
          '08:00',
          '09:30',
          '11:00',
          '12:30',
          '14:00',
          '15:30',
          '17:00',
          '18:30',
          '20:00',
          '21:30',
          '23:00',
        ];
        _isLoadingPista = false;
      });

      return;
    }

    setState(() {
      _isLoadingPista = true;
    });

    final pistaInfo = await _reservaService.getPistaInfo();

    if (mounted) {
      setState(() {
        _pistaInfo = pistaInfo;

        _availableTimes =
            pistaInfo?.franjasDisponiblesPorDefecto ??
            [
              '06:30',
              '08:00',
              '09:30',
              '11:00',
              '12:30',
              '14:00',
              '15:30',
              '17:00',
              '18:30',
              '20:00',
              '21:30',
              '23:00',
            ];

        _isLoadingPista = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 10),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _reservedTimes = [];
      });

      _loadReservedTimes(picked);
    }
  }

  void _loadReservedTimes(DateTime date) {
    _reservedTimesSubscription?.cancel();

    final dateFormat =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    setState(() {
      _isLoading = true;
    });

    _reservedTimesSubscription =
        _reservaService
            .getHorariosReservadosStream(dateFormat)
            .listen(
      (reservedTimes) {
        if (mounted) {
          setState(() {
            _reservedTimes = reservedTimes;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  bool _isTimePast(String time) {
    if (_selectedDate == null) return false;

    final now = DateTime.now();

    final selectedDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    final timeParts = time.split(':');

    final selectedTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    return now.isAfter(selectedTime);
  }

  Future<void> _selectTime(String time) async {
    if (_selectedDate != null) {
      final user = _authService.currentUser;

      if (user != null) {
        final dateFormat =
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

        try {
          final puedeReservar =
              await _reservaService.cumpleLimiteReservasPorDia(
            user.uid,
            dateFormat,
          );

          if (!puedeReservar) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ya tienes dos reservas para este día',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }

            return;
          }

          final noEsConsecutiva =
              await _reservaService.noEsConsecutivaConReservasExistentes(
            user.uid,
            dateFormat,
            time,
          );

          if (!noEsConsecutiva) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No puedes reservar horarios consecutivos. Debe existir un bloque de 1 hora y 30 minutos entre tus reservas.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }

            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error al verificar disponibilidad. Inténtalo de nuevo.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }

          return;
        }
      }
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(
          selectedDate: _selectedDate!,
          selectedTime: time,
          pistaName:
              _pistaInfo?.nombrePista ?? 'Pista Padel Navales',
          duration:
              _pistaInfo?.duracionPartidoMinutos ?? 90,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.destructiveRed,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  Widget _buildActionButtons(bool isWeb) {
    final buttonHeight = isWeb ? 44.0 : 52.0;
    final fontSize = isWeb ? 14.0 : 16.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoadingPista ? null : _selectDate,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                  ),
                  label: Text(
                    'Reservar Pista',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const MyReservationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.list_alt_outlined,
                  ),
                  label: Text(
                    'Mis Reservas',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: buttonHeight,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
            label: Text(
              'Información del Club',
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ),
        if (_userRole == 'admin') ...[
          const SizedBox(height: 10),
          SizedBox(
            height: buttonHeight,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.admin_panel_settings,
              ),
              label: Text(
                'Panel Admin',
                style: TextStyle(fontSize: fontSize),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentYellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeGrid(bool isWeb) {
    final columns = isWeb ? 4 : 3;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: isWeb ? 2.8 : 2.2,
        crossAxisSpacing: isWeb ? 10 : 8,
        mainAxisSpacing: isWeb ? 8 : 8,
      ),
      itemCount: _availableTimes.length,
      itemBuilder: (context, index) {
        final time = _availableTimes[index];

        final isReserved =
            _reservedTimes.contains(time);

        final isPast = _isTimePast(time);

        final isAvailable =
            !isReserved && !isPast;

        return Card(
          margin: EdgeInsets.zero,
          elevation: isAvailable ? 3 : 1,
          color: isAvailable
              ? AppTheme.accentGreen
              : isReserved
                  ? AppTheme.accentYellow
                  : Colors.red,
          child: InkWell(
            onTap:
                isAvailable
                    ? () => _selectTime(time)
                    : null,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    isReserved
                        ? Icons.block
                        : isPast
                            ? Icons.history
                            : Icons.access_time,
                    color: isAvailable
                        ? Colors.white
                        : Colors.white70,
                    size: isWeb ? 20 : 22,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isReserved
                        ? 'RESERVADO'
                        : isPast
                            ? 'PASADA'
                            : time,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 13 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isWeb) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_tennis,
            size: isWeb ? 70 : 100,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(height: 12),
          Text(
            'Selecciona una fecha para ver los horarios disponibles',
            style: TextStyle(
              fontSize: isWeb ? 16 : 18,
              color: AppTheme.accentWhite,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        final maxContentWidth =
            isWeb ? 1050.0 : double.infinity;

        final horizontalPadding =
            isWeb ? 24.0 : 16.0;

        final verticalPadding =
            isWeb ? 12.0 : 16.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'PADEL NAVALES',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.person,
                  color: Colors.grey,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProfileScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_outlined,
                  color: Colors.grey,
                ),
                onPressed: _logout,
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.backgroundDark,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: isWeb ? 80 : 110,
                          child: Image.asset(
                            'assets/images/fondo.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(
                          height: isWeb ? 10 : 16,
                        ),

                        _buildActionButtons(isWeb),

                        SizedBox(
                          height: isWeb ? 12 : 16,
                        ),

                        if (_selectedDate != null) ...[
                          Text(
                            'Fecha seleccionada: '
                            '${_selectedDate!.day}/'
                            '${_selectedDate!.month}/'
                            '${_selectedDate!.year}',
                            style: TextStyle(
                              fontSize:
                                  isWeb ? 16 : 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  AppTheme.accentWhite,
                            ),
                            textAlign:
                                TextAlign.center,
                          ),

                          SizedBox(
                            height: isWeb ? 10 : 14,
                          ),

                          if (_isLoading)
                            const Expanded(
                              child: Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                            )
                          else
                            Expanded(
                              child: Center(
                                child: _buildTimeGrid(
                                  isWeb,
                                ),
                              ),
                            ),
                        ] else
                          Expanded(
                            child:
                                _buildEmptyState(
                              isWeb,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

