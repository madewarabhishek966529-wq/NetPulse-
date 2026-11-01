class TorrentConstants {
  /// Verified, high-availability public BitTorrent trackers
  /// ensuring rapid peer discovery, seeder connection, and high throughput.
  static const List<String> fastTrackers = [
    'udp://tracker.opentrackr.org:1337/announce',
    'udp://open.stealth.si:80/announce',
    'udp://open.demonii.com:1337/announce',
    'udp://open.tracker.cl:1337/announce',
    'udp://tracker.qu.ax:6969/announce',
    'udp://tracker.ducks.party:1984/announce',
    'udp://explodie.org:6969/announce',
    'udp://tracker.nyaa.vc:6969/announce',
    'http://tracker2.dler.org:80/announce',
    'http://tracker.dler.com:6969/announce',
    'udp://tracker.dler.org:6969/announce',
    'http://tracker.renfei.net:8080/announce',
    'udp://tracker.peerfect.org:6969/announce',
    'udp://tracker.opentrackr.com:6969/announce',
    'udp://tracker.ilibr.org:6969/announce',
  ];

  /// Fast public DHT bootstrap routers to join the DHT network immediately
  static const List<String> dhtBootstrapNodes = [
    'dht.transmissionbt.com:6881',
    'router.bittorrent.com:6881',
    'router.utorrent.com:6881',
  ];

  static String get trackerArgString => fastTrackers.join(',');
  static String get primaryDhtNode => dhtBootstrapNodes.first;
}

