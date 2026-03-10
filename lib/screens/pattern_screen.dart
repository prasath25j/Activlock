import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../theme/modern_theme.dart';

enum PatternMode { setup, verify }

class PatternScreen extends StatefulWidget {
  final PatternMode mode;
  final String? initialPattern;
  final Function(String) onComplete;

  const PatternScreen({
    super.key,
    required this.mode,
    this.initialPattern,
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
      // Verify Mode
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
    // PERFORMANCE: Use solid background and NO GlassContainer/Blur
    // during pattern interaction to prevent lag.
    return Scaffold(
      backgroundColor: ModernTheme.slate900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.mode == PatternMode.setup ? Icons.lock_reset_rounded : Icons.lock_outline_rounded,
                      size: 40,
                      color: ModernTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.mode == PatternMode.setup ? "PATTERN SETUP" : "SECURITY CHECK",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _message,
                    style: TextStyle(
                      color: _isError ? ModernTheme.accentPink : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // RepaintBoundary helps isolate the PatternLock's frequent repaints
                  RepaintBoundary(
                    child: SizedBox(
                      height: 300,
                      width: 300,
                      child: PatternLock(
                        notSelectedColor: Colors.white12,
                        selectedColor: ModernTheme.primaryBlue,
                        pointRadius: 10,
                        showInput: true,
                        dimension: 3,
                        onInputComplete: _onPatternComplete,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CANCEL", style: TextStyle(color: Colors.white.withOpacity(0.3))),
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
