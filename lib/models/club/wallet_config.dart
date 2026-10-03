class WalletConfig {
  /// Importes sugeridos; también se permite introducir el importe manualmente.
  final List<int> recargasCentimos;
  /// Solo para pruebas; nunca acredita un pago real.
  final bool simulacionRecargas;

  const WalletConfig({
    this.recargasCentimos = const [2000, 4000, 5000, 10000],
    this.simulacionRecargas = false,
  });
}
