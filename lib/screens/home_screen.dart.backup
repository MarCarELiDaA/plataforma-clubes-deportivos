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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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
      // Verificar si el usuario aún existe cuando la app se reanuda
      _checkUserExists();
    }
  }

  Future<void> _checkUserExists() async {
    final user = _authService.currentUser;
    if (user != null && mounted) {
      try {
        final userStatus = await _authService.getUserStatus();
        if (userStatus == null && mounted) {
          // El usuario fue borrado de Firestore, cerrar sesión
          await _authService.signOut();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } catch (e) {
        // Error silenciado para producción
      }
    }
  }

  Future<void> _checkUserRole() async {
    final user = _authService.currentUser;
    if (user != null && mounted) {
      // Verificar si es el administrador por correo electrónico
      if (user.email == 'martin.bautista.sanchez@gmail.com') {
        setState(() {
          _userRole = 'admin';
        });
      } else {
        setState(() {
          _userRole = 'user';
        });
      }
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
        _availableTimes = ['06:30', '08:00', '09:30', '11:00', '12:30', '14:00', '15:30', '17:00', '18:30', '20:00', '21:30', '23:00'];
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
        _availableTimes = pistaInfo?.franjasDisponiblesPorDefecto ?? 
            ['06:30', '08:00', '09:30', '11:00', '12:30', '14:00', '15:30', '17:00', '18:30', '20:00', '21:30', '23:00'];
        _isLoadingPista = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 10)),
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
    // Cancelar subscription anterior si existe
    _reservedTimesSubscription?.cancel();
    
    final dateFormat = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    setState(() {
      _isLoading = true;
    });

    _reservedTimesSubscription = _reservaService.getHorariosReservadosStream(dateFormat).listen(
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
    final selectedDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
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
    // Verificar límites del usuario antes de navegar
    if (_selectedDate != null) {
      final user = _authService.currentUser;
      if (user != null) {
        final dateFormat = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
        
        try {
          // Verificar máximo de reservas por día
          final puedeReservar = await _reservaService.cumpleLimiteReservasPorDia(user.uid, dateFormat);
          if (!puedeReservar) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ya tienes dos reservas para este día'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Verificar consecutividad
          final noEsConsecutiva = await _reservaService.noEsConsecutivaConReservasExistentes(user.uid, dateFormat, time);
          if (!noEsConsecutiva) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No puedes reservar horarios consecutivos. Debe existir un bloque de 1 hora y 30 minutos entre tus reservas.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } catch (e) {
          // Error silenciado para producción
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al verificar disponibilidad. Inténtalo de nuevo.'),
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
          pistaName: _pistaInfo?.nombrePista ?? 'Pista Padel Navales',
          duration: _pistaInfo?.duracionPartidoMinutos ?? 90,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(color: Colors.white)),
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
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PADEL NAVALES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.grey),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.grey),
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
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset(
                'assets/images/logofinal1.png',
                height: screenHeight * 0.15,
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingPista ? null : _selectDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Reservar Pista'),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MyReservationsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('Mis Reservas'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InfoScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Información del Club'),
              ),
              if (_userRole == 'admin') ...[
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Panel Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
              SizedBox(height: screenHeight * 0.02),
              if (_selectedDate != null) ...[
                Text(
                  'Fecha seleccionada: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth > 600 ? 3 : 2,
                        childAspectRatio: 2,
                        crossAxisSpacing: screenWidth * 0.02,
                        mainAxisSpacing: screenHeight * 0.02,
                      ),
                      itemCount: _availableTimes.length,
                      itemBuilder: (context, index) {
                        final time = _availableTimes[index];
                        final isReserved = _reservedTimes.contains(time);
                        final isPast = _isTimePast(time);
                        final isAvailable = !isReserved && !isPast;

                        return Card(
                          elevation: isAvailable ? 4 : 2,
                          color: isAvailable
                              ? AppTheme.accentGreen
                              : isReserved
                                  ? AppTheme.accentYellow
                                  : Colors.red,
                          child: InkWell(
                            onTap: isAvailable ? () => _selectTime(time) : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isReserved
                                        ? Icons.block
                                        : isPast
                                            ? Icons.history
                                            : Icons.access_time,
                                    color: isAvailable ? Colors.white : Colors.white70,
                                    size: screenWidth * 0.08,
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    isReserved
                                        ? 'RESERVADO'
                                        : isPast
                                            ? 'PASADA'
                                            : time,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
              if (_selectedDate == null) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_tennis,
                          size: screenWidth * 0.25,
                          color: AppTheme.accentGreen,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Selecciona una fecha para ver los horarios disponibles',
                          style: TextStyle(fontSize: screenWidth * 0.045, color: AppTheme.accentWhite),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
