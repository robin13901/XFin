import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'price_provider.dart';

class FinnhubWsProvider implements LivePriceStream {
  final String apiKey;
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, double>>.broadcast();
  StreamSubscription? _subscription;
  bool _connected = false;
  List<String> _symbols = [];
  Timer? _reconnectTimer;

  FinnhubWsProvider({required this.apiKey});

  @override
  Stream<Map<String, double>> get priceUpdates => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(List<String> symbols) async {
    if (symbols.isEmpty || apiKey.isEmpty) return;
    _symbols = symbols;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    await disconnect();

    final uri = Uri.parse('wss://ws.finnhub.io?token=$apiKey');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;

      for (final symbol in _symbols) {
        _channel!.sink.add(jsonEncode({'type': 'subscribe', 'symbol': symbol}));
      }

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      if (data['type'] != 'trade') return;

      final trades = data['data'] as List<dynamic>?;
      if (trades == null || trades.isEmpty) return;

      final prices = <String, double>{};
      for (final trade in trades) {
        final symbol = trade['s'] as String?;
        final price = (trade['p'] as num?)?.toDouble();
        if (symbol != null && price != null) {
          prices[symbol] = price;
        }
      }
      if (prices.isNotEmpty) {
        _controller.add(prices);
      }
    } catch (_) {}
  }

  void _onError(Object error) {
    _connected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    _connected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_connected && _symbols.isNotEmpty) {
        _connectInternal();
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _connected = false;
    if (_channel != null && _connected) {
      for (final symbol in _symbols) {
        _channel!.sink
            .add(jsonEncode({'type': 'unsubscribe', 'symbol': symbol}));
      }
    }
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
