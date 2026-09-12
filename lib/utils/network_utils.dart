import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkUtils {
  static const String errorNoInternet = 'No hay conexión a internet. Por favor verifica tu conexión.';
  static const String errorFirebase = 'Error de conexión con el servidor. Intenta nuevamente.';

  static Future<bool> isNetworkAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.none) == false;
  }

  static Future<void> showNoInternetError(BuildContext context) async {
    if (!await isNetworkAvailable()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(errorNoInternet),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}