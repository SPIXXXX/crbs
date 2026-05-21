import 'package:flutter/material.dart';

import 'homepage.dart';

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key, this.successMessage});

  final String? successMessage;

  @override
  Widget build(BuildContext context) {
    return CustomerHomePage(successMessage: successMessage);
  }
}
