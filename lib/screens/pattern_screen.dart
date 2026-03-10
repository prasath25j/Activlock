import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../theme/arctic_theme.dart';

enum PatternMode { setup, verify }

class PatternScreen extends StatefulWidget {
  final PatternMode mode;
  final String? initialPattern;
  final String? packageName;
  final Function(String) onComplete;

  const PatternScreen({
    super.key,
    required this.mode,
    this.initialPattern,
    this.packageName,
    required this.onComplete,
  });

  @override
  State<PatternScreen> createState() => _PatternScreenState();
}

class _PatternScreenState extends State<PatternScreen> {
  String? _firstPattern;
  String _message = "";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _message = widget.mode == PatternMode.setup 
        ? "Draw your security pattern" 
        : "Draw pattern to unlock";
  }

  void _onPatternComplete(List<int> pattern) {
    if (pattern.length < 3) {
      setState(() {
        _message = "Pattern too short (min 3 points)";
        _isError = true;
      });
      return;
    }

    final patternString = pattern.join(",");

    if (widget.mode == PatternMode.setup) {
      if (_firstPattern == null) {
        setState(() {
          _firstPattern = patternString;
          _message = "Draw again to confirm";
          _isError = false;
        });
      } else {
        if (_firstPattern == patternString) {
          widget.onComplete(patternString);
        } else {
          setState(() {
            _firstPattern = null;
            _message = "Patterns did not match. Try again.";
            _isError = true;
          });
        }
      }
    } else {
      if (widget.initialPattern == patternString) {
        widget.onComplete(patternString);
      } else {
        setState(() {
          _message = "Incorrect pattern. Try again.";
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArcticTheme.iceWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ArcticTheme.pureWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: ArcticTheme.deepNavy.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                      ]
                    ),
                    child: Icon(
                      widget.mode == PatternMode.setup ? Icons.lock_reset_rounded : Icons.lock_outline_rounded,
                      size: 40,
                      color: ArcticTheme.frostBlue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.mode == PatternMode.setup ? "PATTERN SETUP" : "AUTHENTICATE",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: ArcticTheme.deepNavy),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _message,
                    style: TextStyle(
                      color: _isError ? ArcticTheme.alertRed : ArcticTheme.softSlate,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: 320,
                    height: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: ArcticTheme.frostDecoration,
                    child: RepaintBoundary(
                      child: PatternLock(
                        notSelectedColor: Colors.black12,
                        selectedColor: ArcticTheme.frostBlue,
                        pointRadius: 10,
                        showInput: true,
                        dimension: 3,
                        onInputComplete: _onPatternComplete,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL", style: TextStyle(color: ArcticTheme.softSlate, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
