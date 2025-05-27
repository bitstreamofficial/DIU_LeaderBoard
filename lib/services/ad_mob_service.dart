import 'dart:io';

class AdMobService {
  static String get bannerAddUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1245700809694096/6131170753';
    } else if (Platform.isIOS) {
      return '';
    } else {
      throw UnsupportedError('Unsupported Platform');
    }
  }
}
