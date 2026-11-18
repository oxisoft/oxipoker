import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../api/models.dart';
import '../state/session.dart';

/// Theme ids, as stored on the server.
const themeClassic = 'classic';
const themeCyberpunk = 'cyberpunk';

/// Bundled fonts (see pubspec.yaml): text in Noto Sans, card suits from a subset of
/// Noto Sans Symbols 2. Nothing is fetched from a font CDN.
const appFont = 'NotoSans';
const appFontFallback = ['NotoSansSuits'];

/// Colours of the table and the screens behind the forms, per theme.
@immutable
class TablePalette extends ThemeExtension<TablePalette> {
  const TablePalette({
    required this.background,
    required this.felt,
    required this.feltLight,
    required this.rail,
    required this.railLight,
  });

  final Color background;
  final Color felt;
  final Color feltLight;
  final Color rail;
  final Color railLight;

  static const classic = TablePalette(
    background: Color(0xFF0B5D3B),
    felt: Color(0xFF0B5D3B),
    feltLight: Color(0xFF15834F),
    rail: Color(0xFF5B3A1E),
    railLight: Color(0xFF8A5A2B),
  );

  /// OxiSoft palette: dark base, electric blue felt, electric red rail. No cyan.
  static const cyberpunk = TablePalette(
    background: Color(0xFF06070C),
    felt: Color(0xFF0A1030),
    feltLight: Color(0xFF1A2E7A),
    rail: Color(0xFF3A0A12),
    railLight: Color(0xFFFF2A3D),
  );

  @override
  TablePalette copyWith({Color? background, Color? felt, Color? feltLight, Color? rail, Color? railLight}) => TablePalette(
        background: background ?? this.background,
        felt: felt ?? this.felt,
        feltLight: feltLight ?? this.feltLight,
        rail: rail ?? this.rail,
        railLight: railLight ?? this.railLight,
      );

  @override
  TablePalette lerp(TablePalette? other, double t) {
    if (other == null) return this;
    return TablePalette(
      background: Color.lerp(background, other.background, t)!,
      felt: Color.lerp(felt, other.felt, t)!,
      feltLight: Color.lerp(feltLight, other.feltLight, t)!,
      rail: Color.lerp(rail, other.rail, t)!,
      railLight: Color.lerp(railLight, other.railLight, t)!,
    );
  }
}

extension PaletteX on BuildContext {
  TablePalette get palette => Theme.of(this).extension<TablePalette>() ?? TablePalette.classic;
}

/// The app theme for a theme id; unknown ids fall back to classic.
ThemeData themeFor(String? id) {
  if (id == themeCyberpunk) {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF2F6BFF),
      onPrimary: Colors.white,
      secondary: Color(0xFFFF8A1F),
      onSecondary: Colors.black,
      tertiary: Color(0xFFFF2BD6),
      error: Color(0xFFFF2A3D),
      surface: Color(0xFF0D0F18),
      onSurface: Color(0xFFDDE1EC),
      surfaceContainerHighest: Color(0xFF1F2436),
      outline: Color(0xFF1F2436),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: appFont,
      fontFamilyFallback: appFontFallback,
      scaffoldBackgroundColor: const Color(0xFF06070C),
      cardTheme: const CardThemeData(color: Color(0xFF0D0F18)),
      extensions: const [TablePalette.cyberpunk],
    );
  }
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: TablePalette.classic.felt, brightness: Brightness.dark),
    useMaterial3: true,
    fontFamily: appFont,
    fontFamilyFallback: appFontFallback,
    extensions: const [TablePalette.classic],
  );
}

/// Card backs every server has (the server lists the same ids).
const builtInCardBacks = ['classic-red', 'classic-blue', 'cyber-grid', 'cyber-circuit'];
const defaultCardBack = 'classic-red';

/// The server's card backs and default; built-ins only when it cannot be read.
final cardBacksProvider = FutureProvider<CardBackList>((ref) async {
  ref.watch(sessionProvider.select((s) => s.user?.id));
  try {
    return await ref.read(sessionProvider.notifier).api().cardBacks();
  } catch (_) {
    return CardBackList(defaultCardBack, [for (final id in builtInCardBacks) CardBackInfo(id, id, builtIn: true)]);
  }
});

/// The back the signed-in user sees: their own pick, else the server default.
final cardBackProvider = Provider<String>((ref) {
  final own = ref.watch(sessionProvider.select((s) => s.user?.cardBack ?? ''));
  if (own.isNotEmpty) return own;
  return ref.watch(cardBacksProvider).value?.defaultId ?? defaultCardBack;
});

/// The back of a card in design [id]. Built-in designs are painted here;
/// uploaded ones are loaded from the server.
class CardBackFace extends ConsumerWidget {
  const CardBackFace(this.id, {super.key, required this.width});

  final String id;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(width * 0.12);
    if (!builtInCardBacks.contains(id)) {
      final s = ref.watch(sessionProvider);
      final api = ref.read(sessionProvider.notifier).api();
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          api.cardBackImageUrl(id).toString(),
          width: width,
          height: width * 1.4,
          fit: BoxFit.cover,
          headers: ref.read(nativeProvider) && s.token != null ? {'Authorization': 'Bearer ${s.token}'} : null,
          errorBuilder: (_, _, _) => CardBackFace(defaultCardBack, width: width),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CustomPaint(
        key: Key('back-$id'),
        size: Size(width, width * 1.4),
        painter: _BackPainter(id),
      ),
    );
  }
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.id);

  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final border = max(1.5, size.width * 0.05);
    final inner = r.deflate(border * 1.6);
    switch (id) {
      case 'classic-blue':
      case 'classic-red':
        final base = id == 'classic-red' ? const Color(0xFF8E1B2B) : const Color(0xFF1A3D8F);
        canvas.drawRect(r, Paint()..color = Colors.white);
        canvas.drawRect(inner, Paint()..color = base);
        // Diamond lattice.
        final line = Paint()
          ..color = Colors.white24
          ..strokeWidth = max(0.8, size.width * 0.02);
        canvas.save();
        canvas.clipRect(inner);
        final step = size.width / 5;
        for (var x = -size.height; x < size.width + size.height; x += step) {
          canvas.drawLine(Offset(x, inner.top), Offset(x + size.height, inner.bottom), line);
          canvas.drawLine(Offset(x, inner.bottom), Offset(x + size.height, inner.top), line);
        }
        canvas.restore();
      case 'cyber-grid':
        canvas.drawRect(r, Paint()..color = const Color(0xFF06070C));
        final grid = Paint()
          ..color = const Color(0xFF2F6BFF).withValues(alpha: 0.55)
          ..strokeWidth = max(0.6, size.width * 0.015);
        final step = size.width / 6;
        for (var x = inner.left; x <= inner.right; x += step) {
          canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), grid);
        }
        for (var y = inner.top; y <= inner.bottom; y += step) {
          canvas.drawLine(Offset(inner.left, y), Offset(inner.right, y), grid);
        }
        canvas.drawRect(
            inner,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0xFFFF2BD6)
              ..strokeWidth = border * 0.6);
      default: // cyber-circuit
        canvas.drawRect(r, Paint()..color = const Color(0xFF0D0F18));
        final trace = Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFFF2A3D)
          ..strokeWidth = max(0.8, size.width * 0.025);
        final dot = Paint()..color = const Color(0xFFFF8A1F);
        final w = inner.width, h = inner.height;
        final paths = [
          [Offset(0.1, 0.0), Offset(0.1, 0.3), Offset(0.4, 0.45), Offset(0.4, 1.0)],
          [Offset(0.9, 0.0), Offset(0.9, 0.55), Offset(0.6, 0.7), Offset(0.6, 1.0)],
          [Offset(0.0, 0.8), Offset(0.25, 0.8), Offset(0.4, 0.65)],
          [Offset(1.0, 0.2), Offset(0.7, 0.2), Offset(0.55, 0.35)],
        ];
        for (final p in paths) {
          final pts = [for (final o in p) inner.topLeft + Offset(o.dx * w, o.dy * h)];
          canvas.drawPath(Path()..addPolygon(pts, false), trace);
          canvas.drawCircle(pts.last, trace.strokeWidth * 1.4, dot);
        }
        canvas.drawRect(
            inner,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0xFF2F6BFF)
              ..strokeWidth = border * 0.6);
    }
  }

  @override
  bool shouldRepaint(_BackPainter old) => old.id != id;
}
