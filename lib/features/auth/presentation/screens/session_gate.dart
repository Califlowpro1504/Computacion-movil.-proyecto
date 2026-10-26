import 'package:flutter/material.dart';

/// Selects the root screen without leaving login in the navigation history.
class SessionGate extends StatelessWidget {
  const SessionGate({
    super.key,
    required this.sessionChanges,
    required this.initiallySignedIn,
    required this.signedInBuilder,
    required this.signedOutBuilder,
  });

  final Stream<bool> sessionChanges;
  final bool initiallySignedIn;
  final WidgetBuilder signedInBuilder;
  final WidgetBuilder signedOutBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: sessionChanges,
      initialData: initiallySignedIn,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('No pudimos comprobar tu sesión. Reinicia la aplicación.')),
          );
        }
        return snapshot.data == true
            ? signedInBuilder(context)
            : signedOutBuilder(context);
      },
    );
  }
}
