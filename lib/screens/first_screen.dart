import 'package:flutter/material.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:just_work/screens/second_screen.dart';

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('First Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Prikaz dijaloga sa jednim dugmetom
            final result = await showOkAlertDialog(
              context: context,
              title: 'Obaveštenje',
              message: 'Ovo je neka poruka iz baze podataka. Kliknite Next Question da nastavite.',
              okLabel: 'Next Question',
            );

            // Ako korisnik klikne "OK", preusmeri na drugi ekran
            if (result == OkCancelResult.ok) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondScreen()),
              );
            }
          },
          child: Text('Prikaži dijalog'),
        ),
      ),
    );
  }
}