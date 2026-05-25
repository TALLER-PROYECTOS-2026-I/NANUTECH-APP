import 'dart:async';

import 'package:flutter/material.dart';

class SosPanicButton extends StatefulWidget {
  final bool enabled;
  final Future<void> Function() onCompleted;

  const SosPanicButton({
    super.key,
    required this.enabled,
    required this.onCompleted,
  });

  @override
  State<SosPanicButton> createState() => _SosPanicButtonState();
}

class _SosPanicButtonState extends State<SosPanicButton> {
  Timer? timer;
  int seconds = 3;
  bool pressing = false;
  bool sending = false;

  void startHold() {
    if (!widget.enabled || sending) return;

    setState(() {
      pressing = true;
      seconds = 3;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (!mounted) return;

        setState(() {
          seconds--;
        });

        if (seconds <= 0) {
          timer.cancel();

          setState(() {
            sending = true;
            pressing = false;
          });

          await widget.onCompleted();

          if (mounted) {
            setState(() {
              sending = false;
              seconds = 3;
            });
          }
        }
      },
    );
  }

  void cancelHold() {
    if (!pressing) return;

    timer?.cancel();

    setState(() {
      pressing = false;
      seconds = 3;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => startHold(),
      onLongPressEnd: (_) => cancelHold(),
      onLongPressCancel: cancelHold,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: widget.enabled ? const Color(0xffdc2626) : Colors.grey,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            if (pressing)
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 6,
                    ),
                    Text(
                      '$seconds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 54,
              ),
            const SizedBox(height: 10),
            Text(
              pressing
                  ? 'Mantén presionado...'
                  : sending
                      ? 'Enviando alerta...'
                      : 'SOS PÁNICO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mantén presionado 3 segundos',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}