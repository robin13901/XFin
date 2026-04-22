import 'dart:async';

abstract class LivePriceStream {
  Stream<Map<String, double>> get priceUpdates;
  Future<void> connect(List<String> symbols);
  Future<void> disconnect();
  bool get isConnected;
}

abstract class RestPriceProvider {
  Future<Map<String, double>> getCurrentPrices(
      List<String> identifiers, String baseCurrency);

  Future<Map<int, double>> getHistoricalDailyPrices(
      String identifier, DateTime from, DateTime to, String baseCurrency);
}

abstract class SymbolSearchProvider {
  Future<List<SymbolSearchResult>> search(String query);
}

class SymbolSearchResult {
  final String symbol;
  final String name;
  final String? exchange;
  final String? type;

  const SymbolSearchResult({
    required this.symbol,
    required this.name,
    this.exchange,
    this.type,
  });
}
