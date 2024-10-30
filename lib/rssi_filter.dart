class MovingAverageFilter {
  final int windowSize;
  final Map<String, List<double>> _buffers = {};

  MovingAverageFilter(this.windowSize);

  double filter(String macAddress, double value) {
    if (!_buffers.containsKey(macAddress)) {
      _buffers[macAddress] = [];
    }
    var buffer = _buffers[macAddress]!;
    
    buffer.add(value);
    if (buffer.length > windowSize) {
      buffer.removeAt(0);
    }
    return buffer.reduce((a, b) => a + b) / buffer.length;
  }
}