import 'package:flutter/material.dart';

Future<String?> showProgressDialog({
  required BuildContext context,
  required Future<void> Function(void Function(double progress)) operation,
}) async {
  double progress = 0.0;
  String? error;

  return await showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      late void Function(void Function()) localSetState;

      operation((value) {
            progress = value;
            localSetState(() {});
          })
          .then((_) {
            if (Navigator.of(dialogContext).canPop())
              Navigator.of(dialogContext).pop(null);
          })
          .catchError((e) {
            error = e.toString();
            if (Navigator.of(dialogContext).canPop())
              Navigator.of(dialogContext).pop(error.toString());
          });

      return StatefulBuilder(
        builder: (context, setState) {
          localSetState = setState;
          return AlertDialog(
            title: const Text("Processing..."),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 16),
                Text("${(progress * 100).toStringAsFixed(0)}%"),
              ],
            ),
          );
        },
      );
    },
  );
}
