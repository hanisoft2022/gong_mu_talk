import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class LoungeAdBanner extends StatefulWidget {
  const LoungeAdBanner({super.key});

  @override
  State<LoungeAdBanner> createState() => _LoungeAdBannerState();
}

class _LoungeAdBannerState extends State<LoungeAdBanner> {
  static bool _mobileAdsInitialized = false;
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeAds();
    _loadBanner();
  }

  void _initializeAds() {
    if (_mobileAdsInitialized) {
      return;
    }
    _mobileAdsInitialized = true;
    MobileAds.instance.initialize();
  }

  void _loadBanner() {
    final BannerAd ad = BannerAd(
      size: AdSize.banner,
      request: const AdRequest(),
      adUnitId: _adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _loadFailed = false;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
              _loadFailed = true;
            });
          }
        },
      ),
    );
    ad.load();
  }

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    }

    if (_loadFailed) {
      return const _AdFallback();
    }

    return const _AdLoadingPlaceholder();
  }
}

class _AdLoadingPlaceholder extends StatelessWidget {
  const _AdLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdFallback extends StatelessWidget {
  const _AdFallback();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
            const Gap(12),
            Expanded(
              child: Text(
                '광고를 불러오는 중이에요. 네트워크 상태를 확인해주세요.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
