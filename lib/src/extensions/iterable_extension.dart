extension MapExtension<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() {
    return {for (var entry in this) entry.key: entry.value};
  }
}
