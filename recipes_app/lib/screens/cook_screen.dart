import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n.dart';
import '../markdown_view.dart' show minutesIn;
import '../theme.dart';

/// Режим «Готую»: один крок на весь екран, таймер, екран не гасне.
/// «Готувати голосом»: апка читає кроки вголос і слухає команди «далі / назад / повтори / таймер».
class CookScreen extends StatefulWidget {
  const CookScreen({super.key, required this.title, required this.steps});
  final String title;
  final List<String> steps;

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  static const _bg = AppColors.ink;
  static const _fg = Color(0xFFF4F1FF);

  final _pages = PageController();
  int _i = 0;

  // таймер одного кроку (можна піти на інший крок — він рахує далі)
  Timer? _timer;
  int? _timerStep;
  int _left = 0;

  // голос
  final _tts = FlutterTts();
  final _stt = SpeechToText();
  bool _voice = false;
  bool _sttReady = false;
  bool _speaking = false;
  bool _listening = false;
  bool _handled = false; // команда в поточній сесії слухання вже виконана
  String? _sttLocale;
  late Strings _t;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // руки в борошні — екран не повинен гаснути
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _t = L10n.of(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    _voice = false;
    _stt.cancel();
    _tts.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  // ---------------- голос ----------------

  Future<void> _toggleVoice() async {
    if (_voice) {
      setState(() => _voice = false);
      await _stt.cancel();
      await _tts.stop();
      return;
    }
    await _tts.setLanguage(_t.ttsLocale);
    await _tts.setSpeechRate(0.48);
    await _tts.awaitSpeakCompletion(true);

    _sttReady = await _stt.initialize(onStatus: _onStatus, onError: (_) => _scheduleListen());
    if (_sttReady) {
      // Якщо українська/польська недоступна в розпізнавачі телефона — мова системи
      final locales = await _stt.locales();
      final want = _t.sttLocale.toLowerCase();
      _sttLocale = locales.any((l) => l.localeId.toLowerCase() == want) ? _t.sttLocale : null;
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.voiceUnavailable)));
    }
    if (!mounted) return;
    setState(() => _voice = true);
    await _say(widget.steps[_i]); // читання працює навіть без мікрофона
  }

  Future<void> _say(String text) async {
    if (!_voice) return;
    _speaking = true;
    await _stt.stop(); // щоб апка не почула саму себе
    await _tts.speak(text);
    _speaking = false;
    _listen();
  }

  void _listen() {
    if (!_voice || !_sttReady || _speaking || _stt.isListening || !mounted) return;
    _handled = false;
    _stt.listen(
      onResult: _onResult,
      localeId: _sttLocale,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 8),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  void _scheduleListen() {
    if (!_voice || _speaking) return;
    Future.delayed(const Duration(milliseconds: 400), _listen);
  }

  void _onStatus(String status) {
    final listening = status == 'listening';
    if (mounted && listening != _listening) setState(() => _listening = listening);
    if (status == 'done' || status == 'notListening') _scheduleListen(); // Android зупиняє слухання сам — перезапускаємо
  }

  bool _has(String words, List<String> cmds) => cmds.any((c) => words.contains(c));

  void _onResult(SpeechRecognitionResult r) {
    if (_handled) return;
    final w = r.recognizedWords.toLowerCase();
    void run(VoidCallback action) {
      _handled = true;
      _stt.stop();
      action();
    }

    if (_has(w, _t.cmdNext)) {
      run(_nextOrFinish);
    } else if (_has(w, _t.cmdBack)) {
      run(() {
        if (_i > 0) {
          _go(_i - 1);
        } else {
          _say(widget.steps[_i]);
        }
      });
    } else if (_has(w, _t.cmdRepeat)) {
      run(() => _say(widget.steps[_i]));
    } else if (_has(w, _t.cmdTimer)) {
      run(() {
        if (minutesIn(widget.steps[_i]) > 0 && _timerStep != _i) _toggleTimer(_i);
        _say(_timerStep == _i ? '${_t.startTimer}: ${_fmt(_left)}' : widget.steps[_i]);
      });
    }
  }

  // ---------------- кроки й таймер ----------------

  void _go(int i) => _pages.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);

  void _nextOrFinish() {
    if (_i == widget.steps.length - 1) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(_t.enjoy)));
    } else {
      _go(_i + 1);
    }
  }

  void _toggleTimer(int step) {
    if (_timerStep == step) {
      _timer?.cancel();
      setState(() => _timerStep = null);
      return;
    }
    _timer?.cancel();
    setState(() {
      _timerStep = step;
      _left = minutesIn(widget.steps[step]) * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        final finished = _timerStep!;
        setState(() => _timerStep = null);
        _alarm(finished);
      }
    });
  }

  Future<void> _alarm(int step) async {
    for (var k = 0; k < 3; k++) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t.timeUp(step + 1)), duration: const Duration(seconds: 6)),
    );
    if (_voice) _say(_t.timeUp(step + 1));
  }

  static String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final n = widget.steps.length;
    final last = _i == n - 1;
    final t = _t;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              IconButton(
                tooltip: t.close,
                color: _fg,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: List.generate(
                    n,
                    (k) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: k <= _i ? AppColors.lime : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Перемикач «Готувати голосом»
              Material(
                color: _voice ? AppColors.lime : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: _toggleVoice,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_voice ? Icons.mic : Icons.mic_none, size: 18, color: _voice ? AppColors.ink : _fg),
                      const SizedBox(width: 6),
                      Text(_voice ? t.voiceOn : t.voiceOff,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _voice ? AppColors.ink : _fg)),
                    ]),
                  ),
                ),
              ),
            ]),
            if (_voice)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _listening ? AppColors.lime : Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t.voiceHint, style: TextStyle(color: _fg.withValues(alpha: 0.75), fontSize: 13)),
                  ),
                ]),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: n,
                onPageChanged: (i) {
                  setState(() => _i = i);
                  if (_voice) _say(widget.steps[i]);
                },
                itemBuilder: (context, i) {
                  final minutes = minutesIn(widget.steps[i]);
                  final running = _timerStep == i;
                  final onTimer = running ? Colors.white : _fg;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: 24),
                      Text(t.stepOf(i + 1, n), style: display(15, color: _fg.withValues(alpha: 0.7))),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(widget.steps[i], style: display(26, color: _fg).copyWith(height: 1.3)),
                        ),
                      ),
                      if (minutes > 0)
                        Material(
                          color: running ? AppColors.berry : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _toggleTimer(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(children: [
                                Icon(running ? Icons.stop_circle_outlined : Icons.timer_outlined, color: onTimer),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(running ? t.stopTimer : t.startTimer,
                                      style: TextStyle(fontWeight: FontWeight.w700, color: onTimer)),
                                ),
                                Text(
                                  _fmt(running ? _left : minutes * 60),
                                  style: display(26, color: onTimer)
                                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                    ]),
                  );
                },
              ),
            ),
            if (_timerStep != null && _timerStep != _i)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.berry),
                  onPressed: () => _go(_timerStep!),
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(t.timerOfStep(_timerStep! + 1, _fmt(_left))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: _fg,
                        disabledForegroundColor: _fg.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      onPressed: _i == 0 ? null : () => _go(_i - 1),
                      child: Text(t.back),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 60,
                    child: FilledButton(onPressed: _nextOrFinish, child: Text(last ? t.finish : t.next)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
