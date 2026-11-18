import 'package:material_ui/material_ui.dart';

/// Classic two-colour deck: hearts and diamonds red, spades and clubs black.
const _suitGlyph = {'s': '\u2660', 'h': '\u2665', 'd': '\u2666', 'c': '\u2663'};

String rankLabel(String card) => card.isEmpty ? '' : (card[0] == 'T' ? '10' : card[0]);
String suitGlyph(String card) => card.length < 2 ? '' : _suitGlyph[card[1]] ?? '';
bool isRed(String card) => card.length > 1 && (card[1] == 'h' || card[1] == 'd');

/// One playing card, face up ([card] like "As") or face down (null).
class PlayingCard extends StatelessWidget {
  const PlayingCard(this.card, {super.key, this.width = 40, this.dim = false, this.highlight = false});

  final String? card;
  final double width;
  final bool dim;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.4;
    final c = card;
    final Widget face;
    if (c == null) {
      face = Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8E1B2B),
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            '\u2666',
            style: TextStyle(fontFamily: 'NotoSansSuits', color: Colors.white54, fontSize: width * 0.5),
          ),
        ),
      );
    } else {
      final color = isRed(c) ? const Color(0xFFC62828) : const Color(0xFF1B1B1B);
      face = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(color: highlight ? const Color(0xFFFFC400) : Colors.black26, width: highlight ? 3 : 1),
        ),
        padding: EdgeInsets.all(width * 0.06),
        child: FittedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rankLabel(c),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: width * 0.42, height: 1),
              ),
              Text(
                suitGlyph(c),
                style: TextStyle(fontFamily: 'NotoSansSuits', color: color, fontSize: width * 0.42, height: 1.1),
              ),
            ],
          ),
        ),
      );
    }
    return Semantics(
      label: c ?? 'card',
      child: Opacity(
        opacity: dim ? 0.45 : 1,
        child: SizedBox(width: width, height: h, child: face),
      ),
    );
  }
}

/// A row of cards; [count] face-down cards when [cards] is empty.
class CardRow extends StatelessWidget {
  const CardRow({super.key, this.cards = const [], this.count = 0, this.width = 40, this.dim = false, this.slots = 0});

  final List<String> cards;
  final int count;
  final double width;
  final bool dim;
  final int slots; // empty placeholders up to this many (the board)

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final c in cards) PlayingCard(c, width: width, dim: dim),
      if (cards.isEmpty)
        for (var i = 0; i < count; i++) PlayingCard(null, width: width, dim: dim),
      for (var i = cards.length; i < slots; i++)
        Container(
          width: width,
          height: width * 1.4,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(width * 0.12),
          ),
        ),
    ];
    return Wrap(spacing: width * 0.1, children: items);
  }
}

String chips(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('\u202f');
    b.write(s[i]);
  }
  return b.toString();
}
