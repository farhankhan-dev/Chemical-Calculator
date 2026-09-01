import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Security: Real Ad Unit ID is passed at build time via --dart-define
  // Default fallback is Google's official test Ad Unit ID
  static const String _prodAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // Test ID
  );

  final String _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // Always use test ID in debug
      : _prodAdUnitId;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) debugPrint('BannerAd loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          if (kDebugMode) debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    
    // Placeholder while loading or if it fails (only in debug mode)
    if (kDebugMode) {
      return Container(
        alignment: Alignment.center,
        width: 320,
        height: 50,
        color: Colors.grey[300],
        child: const Text('Banner Ad Space', style: TextStyle(color: Colors.black54)),
      );
    }

    return const SizedBox.shrink();
  }
}
