import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'price_provider.dart';

class BinanceWsProvider implements LivePriceStream {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, double>>.broadcast();
  StreamSubscription? _subscription;
  bool _connected = false;
  List<String> _symbols = [];
  Timer? _reconnectTimer;

  @override
  Stream<Map<String, double>> get priceUpdates => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(List<String> symbols) async {
    if (symbols.isEmpty) return;
    _symbols = symbols;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    await disconnect();

    final streams =
        _symbols.map((s) => '${s.toLowerCase()}@miniTicker').join('/');
    final uri =
        Uri.parse('wss://stream.binance.com:9443/stream?streams=$streams');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;

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
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) return;

      final symbol = (payload['s'] as String?)?.toLowerCase();
      final price = double.tryParse(payload['c']?.toString() ?? '');
      if (symbol != null && price != null) {
        _controller.add({symbol: price});
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
