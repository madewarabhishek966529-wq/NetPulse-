class TorrentConstants {
  /// Curated list of high-speed, reliable public BitTorrent trackers
  /// to ensure maximum peer discovery and accelerated download throughput.
  static const List<String> fastTrackers = [
    'udp://tracker.opentrackr.org:1337/announce',
    'udp://open.stealth.si:80/announce',
    'udp://tracker.openbittorrent.com:6969/announce',
    'udp://tracker.torrent.eu.org:451/announce',
    'udp://explodie.org:6969/announce',
    'udp://tracker.moeking.me:6969/announce',
    'http://tracker.openbittorrent.com:80/announce',
    'udp://opentracker.i2p.rocks:6969/announce',
    'udp://tracker.internetwarriors.net:1337/announce',
    'udp://p4p.arenabg.com:1337/announce',
  ];

  static String get trackerArgString => fastTrackers.join(',');
}
