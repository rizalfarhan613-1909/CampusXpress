import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Word Rotator (PRD §8 komponen 2): mengganti kata tiap 2,4 detik tanpa
/// layout shift karena lebar dikunci oleh kata terpanjang.
class WordRotator extends StatefulWidget {
  const WordRotator({
    super.key,
    required this.words,
    this.interval = const Duration(milliseconds: 2400),
    this.style,
  });

  final List<String> words;
  final Duration interval;
  final TextStyle? style;

  @override
  State<WordRotator> createState() => _WordRotatorState();
}

class _WordRotatorState extends State<WordRotator> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.words.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widest = widget.words.fold<String>(
      '',
      (current, word) => word.length > current.length ? word : current,
    );
    final textStyle =
        widget.style ??
        const TextStyle(
          color: Ce.emerald500,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          height: 1.1,
        );

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Opacity(opacity: 0, child: Text(widest, style: textStyle, maxLines: 1)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.9),
              end: Offset.zero,
            ).animate(animation);
            return ClipRect(
              child: SlideTransition(
                position: offset,
                child: FadeTransition(opacity: animation, child: child),
              ),
            );
          },
          child: Text(
            widget.words[_index],
            key: ValueKey(widget.words[_index]),
            style: textStyle,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
