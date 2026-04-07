import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../../design/theme.dart';
import 'avatar_types.dart';

/// Displays a DiceBear avataaars SVG when a customised [AvatarConfig] is
/// provided, otherwise falls back to a coloured initial-letter circle.
class AvatarWidget extends StatefulWidget {
  final AvatarConfig? config;
  final double size;
  final String? fallbackInitial;
  final Color? fallbackBg;
  final Color? fallbackFg;

  const AvatarWidget({
    super.key,
    this.config,
    required this.size,
    this.fallbackInitial,
    this.fallbackBg,
    this.fallbackFg,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();

  /// Fetches the SVG and strips unsupported metadata elements.
  static final Map<String, String> _svgCache = {};

  static Future<String> fetchSvg(String url) async {
    if (_svgCache.containsKey(url)) return _svgCache[url]!;
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) return '';
      final cleaned = response.body
          .replaceAll(RegExp(r'<metadata[^>]*>[\s\S]*?</metadata>'), '')
          .replaceAll(RegExp(r'<metadata\s*/>'), '');
      _svgCache[url] = cleaned;
      return cleaned;
    } catch (_) {
      return '';
    }
  }

  /// Pre-warm the SVG cache for a given avatar config.
  static Future<void> prefetch(AvatarConfig? config) async {
    if (config == null || !config.hasCustomConfig) return;
    final url = buildDiceBearUrl(config);
    final svg = await fetchSvg(url);
    if (svg.isNotEmpty && config.clothingGraphic == 'bunny') {
      _svgCache['$url#bunny'] = _injectBunnyGraphic(svg);
    }
  }

  /// Returns the cache key for a given config (accounts for bunny post-processing).
  static String _cacheKey(AvatarConfig config) {
    final url = buildDiceBearUrl(config);
    return config.clothingGraphic == 'bunny' ? '$url#bunny' : url;
  }

  static const _validClothingGraphics = {
    'bat', 'bear', 'cumbia', 'deer', 'diamond', 'hola',
    'pizza', 'resist', 'skull', 'skullOutline',
  };

  /// Optimised Friendly-logo bunny paths (white fill, viewBox -4 -53 40 76).
  static const _bunnyPaths =
      '<path d="m29-38-1 2v2l-2 1-2 1-3-1-1-1v-6l-2-1-1 2-1 3-1 6h3l4 1 1 1 1 2-1 2-3 1-5 2v17l-1 3-3 2-3-2-1-1-1-2-1-16H2l-2-1-2-1v-2l1-2 2-1 3-1 2-1v-1l1-6 2-7 4-5q2-2 6-2l5 1 3 3 1 3zm0 0"/>'
      '<path d="M24-24h-1l-3-1h-1l-2 1-2 1-2 2v3l-1 2v7l-1 7-2 2-2 1H5L4-1 3-4 2-9v-23l2-3 3-1 2 1 1 2 1 2v2l4-4 5-2 3 1 3 1 2 2 1 3-2 3zm0 0"/>'
      '<path d="M12-45v2l-1 1-4 1H5l-1-2 1-2 1-1 1-1h4zm1 22v7L11-4l-1 3-3 1-2-1-1-3-1-3-1-8v-5l1-8 1-4q0-3 2-3l2-2q2 0 3 2l1 4 1 5zm0 0"/>'
      '<path d="m29-11-2 4-3 4-5 2-4 1-6-1-4-5-4-12 4-13 4-5q3-2 7-2h4l6 6 1 4-2 5q-1 3-3 5l-10 4 1 3 3 1 2-1 3-1 2-2h5zM18-27v-2l-1-1-3 1-1 2-2 5 5-2 2-1zm0 0"/>'
      '<path d="m20 2-2-1-1-2v-5l1-8v-11l-1-1-1-1-1 1-2 2-1 3v11l-1 5v2l-1 2-2 1-2 1-2-1-1-2-1-3v-28l2-3q0-2 3-2l1 1 1 1 1 2 1 2 3-3 6-2 5 2 3 4 1 5v8L25-3l-2 3zm0 0"/>'
      '<path d="M29-42v39l-1 2-3 1-3-1-1-4-4 4-5 2-5-2-3-5a26 26 0 0 1-3-15l2-8 2-4 3-2 4-1 4 1 3 3 1-10v-6l2-2 2-1 3 1 2 2v6M19-14v-5l-2-4-2-2h-2l-2 1-1 1v2l1 8 1 2 1 2 2-1 1-1zm0 0"/>'
      '<path d="M14-39v23L13-1l-1 2-3 1-3-2-1-4-2-5-1-14 2-14 1-5 2-4 3-1 2 1 1 2 1 3zm0 0"/>'
      '<path d="m16 19-4-1-3-1-3-2-1-3v-2l1-1 1-1h3l1 1 2 1h2l2-1 2-3 2-4 1-8v-3l-4 5-6 2-4-1-3-3-2-4-1-4-1-12 1-5 2-4 3-1 2 1 1 3 1 3v11l1 2 1 1 2 1 3-1 1-2 1-3v-10l1-3 1-2h2l3 1 2 3 1 5 2 12-1 13-2 7-3 7-4 4zm0 0"/>';

  /// Regex to find the clothing-graphic group inside the clothing group.
  static final _graphicGroupRe = RegExp(
    r'(<g\s+transform="translate\(77 58\)">)([\s\S]*?)(</g>)',
  );

  /// Replaces the DiceBear clothing graphic with the Friendly bunny.
  static String _injectBunnyGraphic(String svg) {
    return svg.replaceFirstMapped(_graphicGroupRe, (m) {
      // Scale bunny (viewBox -4 -53 40 76) into the ~80×37 graphic area.
      return '${m[1]}<g transform="matrix(.487 0 0 .487 32.2 25.8)" fill="#fff">'
          '$_bunnyPaths</g>${m[3]}';
    });
  }

  static String buildDiceBearUrl(AvatarConfig config) {
    final params = <String, String>{
      'top': config.top,
      'hairColor': config.hairColor,
      'clothing': config.clothing,
      'clothesColor': config.clothesColor,
      'eyebrows': config.eyebrows,
      'eyes': config.eyes,
      'mouth': config.mouth,
      'skinColor': config.skinColor,
    };

    // Use a placeholder graphic for 'bunny' (injected after fetch)
    final graphic = config.clothingGraphic;
    if (graphic == 'bunny') {
      params['clothingGraphic'] = 'bear';
    } else if (_validClothingGraphics.contains(graphic)) {
      params['clothingGraphic'] = graphic;
    }

    if (config.accessories != 'none') {
      params['accessories'] = config.accessories;
      params['accessoriesProbability'] = '100';
      params['accessoriesColor'] = config.accessoriesColor;
    } else {
      params['accessoriesProbability'] = '0';
    }

    if (config.facialHair != 'none') {
      params['facialHair'] = config.facialHair;
      params['facialHairProbability'] = '100';
      params['facialHairColor'] = config.facialHairColor;
    } else {
      params['facialHairProbability'] = '0';
    }

    final query =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'https://api.dicebear.com/7.x/avataaars/svg?$query';
  }
}

class _AvatarWidgetState extends State<AvatarWidget> {
  Future<String>? _svgFuture;
  String? _lastUrl;

  bool _isCustomised(AvatarConfig config) {
    return config.hasCustomConfig;
  }

  void _updateFuture() {
    if (widget.config != null && _isCustomised(widget.config!)) {
      final key = AvatarWidget._cacheKey(widget.config!);
      if (key != _lastUrl) {
        _lastUrl = key;
        _svgFuture = _fetchForConfig(widget.config!);
      }
    } else {
      _lastUrl = null;
      _svgFuture = null;
    }
  }

  Future<String> _fetchForConfig(AvatarConfig config) async {
    final url = AvatarWidget.buildDiceBearUrl(config);
    final svg = await AvatarWidget.fetchSvg(url);
    if (svg.isEmpty) return svg;
    if (config.clothingGraphic == 'bunny') {
      final injected = AvatarWidget._injectBunnyGraphic(svg);
      AvatarWidget._svgCache['$url#bunny'] = injected;
      return injected;
    }
    return svg;
  }

  @override
  void initState() {
    super.initState();
    _updateFuture();
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFuture();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showSvg = widget.config != null && _isCustomised(widget.config!);

    if (!showSvg) {
      final bg = widget.fallbackBg ??
          (isDark ? AppColorsDark.warmSurface : AppColors.warmSurface);
      final fg =
          widget.fallbackFg ?? (isDark ? AppColorsDark.warm : AppColors.warm);
      final initial = widget.fallbackInitial?.isNotEmpty == true
          ? widget.fallbackInitial![0].toUpperCase()
          : '?';

      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: fg,
            fontSize: widget.size * 0.42,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ClipOval(
      child: Container(
        width: widget.size,
        height: widget.size,
        color: widget.config!.style == 'circle'
            ? const Color(0xFFE8E3E1)
            : Colors.transparent,
        child: FutureBuilder<String>(
          future: _svgFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return SvgPicture.string(
                snapshot.data!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
              );
            }
            // Show initial as placeholder while loading
            final initial = widget.fallbackInitial?.isNotEmpty == true
                ? widget.fallbackInitial![0].toUpperCase()
                : '?';
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColorsDark.surfaceSubtle
                    : AppColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? Text(
                      initial,
                      style: TextStyle(
                        color: isDark ? AppColorsDark.textMuted : AppColors.textMuted,
                        fontSize: widget.size * 0.42,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : SizedBox(
                      width: widget.size * 0.3,
                      height: widget.size * 0.3,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppColorsDark.accent : AppColors.accent,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
