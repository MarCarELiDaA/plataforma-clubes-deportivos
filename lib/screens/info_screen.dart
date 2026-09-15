import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class InfoScreen extends StatelessWidget {
  InfoScreen({super.key});

  final String direccion = AppConfig.club.direccion;
  final String horario = AppConfig.club.horario;
  final String telefono = AppConfig.club.telefono;
  final String email = AppConfig.club.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Información del Club'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 20,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, isWide),
                    const SizedBox(height: 24),
                    _buildInformationCard(
                      context,
                      isWide: isWide,
                      icon: Icons.location_on_outlined,
                      title: 'Dirección',
                      content: direccion,
                    ),
                    const SizedBox(height: 14),
                    _buildInformationCard(
                      context,
                      isWide: isWide,
                      icon: Icons.access_time_outlined,
                      title: 'Horario',
                      content: horario,
                    ),
                    const SizedBox(height: 14),
                    _buildInformationCard(
                      context,
                      isWide: isWide,
                      icon: Icons.phone_outlined,
                      title: 'Teléfono',
                      content: telefono,
                    ),
                    const SizedBox(height: 14),
                    _buildInformationCard(
                      context,
                      isWide: isWide,
                      icon: Icons.email_outlined,
                      title: 'Correo electrónico',
                      content: email,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: isWide ? 180 : 150,
            height: isWide ? 180 : 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.borderSoft,
              ),
            ),
            child: Image.asset(
              AppConfig.club.logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.sports_tennis,
                  size: isWide ? 72 : 60,
                  color: AppTheme.success,
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Text(
            AppConfig.club.nombre,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Información y datos de contacto',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(
    BuildContext context, {
    required bool isWide,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 22 : 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: AppTheme.success,
              size: 23,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}