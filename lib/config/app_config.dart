import '../models/club/club_config.dart';
import 'club/club_config_actual.dart';
import 'club/legal_config.dart';
import 'club/legal_config_actual.dart';

class AppConfig {
  static bool esAdministrador(String? email) {
    if (email == null) return false;
    return club.administradores.contains(email.toLowerCase());
  }
  static final ClubConfig club = ClubConfigActual.config;
  static final LegalConfig legal = LegalConfigActual.config;
}
