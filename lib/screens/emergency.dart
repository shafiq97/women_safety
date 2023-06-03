import 'package:flutter/material.dart';
import 'package:google_login/screens/emergencies/ambulance.dart';
import 'package:google_login/screens/emergencies/army.dart';
import 'package:google_login/screens/emergencies/fire.dart';
import 'package:google_login/screens/emergencies/police.dart';
import 'package:google_login/screens/emergencies/polosk.dart';

class Emergency extends StatelessWidget {
  const Emergency({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 180,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          Police(
            title: 'Police',
            subtitle: "Tap here or dial 999",
            image: "assets/e1.jpg",
            number: "999",
          ),
          // AmbulanceEmergency(
          //     // title: 'Ambulance',
          //     // subtitle: "Tap here or dial 999",
          //     // image: "assets/e5.jpg",
          //     // number: "102",
          //     ),
          Police(
            title: 'Mental Health',
            subtitle: "Tap here or dial +603-27806803",
            image: "assets/enjoy.jpg",
            number: "+603-27806803",
          ),
          Police(
            title: 'Hospital',
            subtitle: "Tap here or dial 03-51237333",
            image: "assets/hosp.png",
            number: "03-51237333",
          ),
          Police(
            title: 'Fire Department',
            subtitle: "Tap here or dial 603-8892 7600",
            image: "assets/e4.jpg",
            number: "603-8892 7600",
          ),
        ],
      ),
    );
  }
}
