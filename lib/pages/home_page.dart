import 'package:flutter/material.dart';
import '../widgets/drivo_auth_scaffold.dart';
import 'login_page.dart';
import 'signup_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DrivoAuthScaffold(
      child: DrivoAuthCard(
        subtitle: 'Welcome to CRBS',
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Color(0xFF2D7BF5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Car Rental Booking System',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Book your ride with ease',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF8B9DC3)),
          ),
          const SizedBox(height: 48),
          DrivoPrimaryButton(
            label: 'Sign In',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
          ),
          const SizedBox(height: 20),
          DrivoPrimaryButton(
            label: 'Create Account',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupPage()),
            ),
          ),
        ],
      ),
    );
  }
}
