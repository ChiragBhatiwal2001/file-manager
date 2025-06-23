import 'package:flutter/material.dart';

Future<void> showProgressDialog({
  required BuildContext context,
  required Future<void> Function(void Function(double progress)) operation,
}) async {
  double progress = 0.0;
  String? error;

  await showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      late void Function(void Function()) localSetState;

      operation((value) {
        progress = value;
        if (localSetState != null) localSetState(() {});
      }).then((_) {
        if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
      }).catchError((e) {
        error = e.toString();
        if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
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

  await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => AlertDialog(
      title: Text(error != null ? "Operation Failed" : "Operation Finished Successfully"),
      content: error != null ? Text(error!) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
