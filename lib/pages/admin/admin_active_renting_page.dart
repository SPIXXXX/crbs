part of 'admin_page.dart';

class _ActiveRentingPage extends StatelessWidget {
  const _ActiveRentingPage({required this.cars, required this.bookings});

  final List<_AdminCar> cars;
  final List<_RentalBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final active = bookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'confirmed' || s == 'active';
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(58, 48, 58, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Renting',
            style: TextStyle(
              color: _text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          if (active.isEmpty)
            const Text('No active rentals', style: TextStyle(color: _muted))
          else
            ...active.map((b) {
              final matches = cars.where((c) => c.id == b.vehicleId).toList();
              final car = matches.isNotEmpty ? matches.first : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        height: 64,
                        child: car == null
                            ? const Icon(Icons.directions_car)
                            : Image.network(
                                car.imageUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.directions_car),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.vehicleName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${b.customerName} • ${b.dateLabel}',
                              style: const TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pickup: ${b.pickupDateLabel} • ${b.pickupTime}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
