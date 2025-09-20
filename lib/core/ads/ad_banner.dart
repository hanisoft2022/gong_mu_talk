import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GongMuBannerAd extends StatefulWidget {
  const GongMuBannerAd({super.key});

  @override
  State<GongMuBannerAd> createState() => _GongMuBannerAdState();
}

class _GongMuBannerAdState extends State<GongMuBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final BannerAd ad = BannerAd(
      size: AdSize.banner,
      adUnitId: _testAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() => _isLoaded = false);
        },
      ),
      request: const AdRequest(),
    );

    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
