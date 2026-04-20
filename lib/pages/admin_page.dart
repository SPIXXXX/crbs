// ================================================================
// lib/pages/admin_page.dart
// DRIVO — Car Rental Booking System
// Admin Dashboard — Vehicle & Fleet Management
// ================================================================
//
// ── DATABASE TABLES REQUIRED (Laravel migrations) ────────────────
//
// 1. vehicles
//    - id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
//    - name               VARCHAR(100)   NOT NULL
//    - model              VARCHAR(100)   NOT NULL
//    - year               YEAR           NOT NULL
//    - category           ENUM('Sedan','SUV','Hatchback','Van','Truck')
//    - seats              TINYINT        NOT NULL
//    - fuel_type          ENUM('Gasoline','Diesel','Electric','Hybrid')
//    - transmission       ENUM('Automatic','Manual','CVT')
//    - daily_rate         DECIMAL(10,2)  NOT NULL
//    - plate_number       VARCHAR(20)    NOT NULL UNIQUE
//    - status             ENUM('available','rented','maintenance','inactive') DEFAULT 'available'
//    - description        TEXT           NULLABLE
//    - created_at, updated_at TIMESTAMPS
//
// 2. vehicle_images
//    - id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
//    - vehicle_id         BIGINT UNSIGNED NOT NULL  REFERENCES vehicles(id) ON DELETE CASCADE
//    - angle              ENUM('front','side','rear','interior')
//    - image_url          VARCHAR(500)   NOT NULL  (Laravel storage path)
//    - created_at, updated_at TIMESTAMPS
//
// 3. customers
//    - id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
//    - user_id            BIGINT UNSIGNED NOT NULL  REFERENCES users(id) ON DELETE CASCADE
//    - first_name         VARCHAR(100)   NOT NULL
//    - last_name          VARCHAR(100)   NOT NULL
//    - phone              VARCHAR(20)    NOT NULL
//    - license_number     VARCHAR(50)    NOT NULL UNIQUE
//    - license_expiry     DATE           NOT NULL
//    - status             ENUM('active','suspended') DEFAULT 'active'
//    - created_at, updated_at TIMESTAMPS
//
// 4. bookings
//    - id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
//    - reference_number   VARCHAR(50)    NOT NULL UNIQUE  (e.g. DRIVO-20260318-A1B2)
//    - customer_id        BIGINT UNSIGNED NOT NULL  REFERENCES customers(id)
//    - vehicle_id         BIGINT UNSIGNED NOT NULL  REFERENCES vehicles(id)
//    - pickup_location    VARCHAR(200)   NOT NULL
//    - pickup_date        DATE           NOT NULL
//    - return_date        DATE           NOT NULL
//    - total_days         TINYINT        NOT NULL
//    - daily_rate         DECIMAL(10,2)  NOT NULL  (snapshot of rate at time of booking)
//    - total_fee          DECIMAL(10,2)  NOT NULL
//    - status             ENUM('Pending','Confirmed','Active','Completed','Cancelled') DEFAULT 'Pending'
//    - notes              TEXT           NULLABLE
//    - created_at, updated_at TIMESTAMPS
//
// 5. admin_settings
//    - id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
//    - key                VARCHAR(100)   NOT NULL UNIQUE
//    - value              TEXT           NOT NULL
//    - created_at, updated_at TIMESTAMPS
//
// ── LARAVEL API ENDPOINTS REQUIRED ───────────────────────────────
//
// All routes are prefixed with /api and protected by:
//   - Sanctum token auth middleware (auth:sanctum)
//   - Admin role middleware for admin/* routes
//
// AUTH
//   POST   /api/auth/login              → { email, password }            → { token, user }
//   POST   /api/auth/logout             → (invalidates token)
//   POST   /api/auth/change-password    → { current_password, new_password, password_confirmation }
//
// VEHICLES (Admin only)
//   GET    /api/admin/vehicles          → paginated list with images
//   POST   /api/admin/vehicles          → create vehicle
//   GET    /api/admin/vehicles/{id}     → single vehicle with images
//   PUT    /api/admin/vehicles/{id}     → update vehicle fields
//   DELETE /api/admin/vehicles/{id}     → soft delete vehicle
//   PATCH  /api/admin/vehicles/{id}/status  → { status }  change status only
//
// VEHICLE IMAGES (Admin only)
//   POST   /api/admin/vehicles/{id}/images        → multipart upload { angle, image }
//                                                   stores in storage/vehicles/{id}/
//                                                   returns { image_url }
//   DELETE /api/admin/vehicles/{id}/images/{imgId} → remove one image
//
// VEHICLES (Customer — public read)
//   GET    /api/vehicles                → available vehicles list (status=available)
//   GET    /api/vehicles/{id}           → single vehicle detail with images
//
// BOOKINGS (Admin)
//   GET    /api/admin/bookings          → all bookings with customer+vehicle eager loaded
//   GET    /api/admin/bookings/{id}     → single booking detail
//   PATCH  /api/admin/bookings/{id}/confirm   → mark Confirmed, notifies customer
//   PATCH  /api/admin/bookings/{id}/activate  → mark Active (vehicle picked up)
//   PATCH  /api/admin/bookings/{id}/complete  → mark Completed, frees vehicle
//   PATCH  /api/admin/bookings/{id}/cancel    → mark Cancelled, frees vehicle
//
// BOOKINGS (Customer)
//   GET    /api/bookings                → own bookings only
//   POST   /api/bookings               → create booking { vehicle_id, pickup_location, pickup_date, return_date }
//   PATCH  /api/bookings/{id}/cancel   → cancel own booking (if Pending or Confirmed)
//
// CUSTOMERS (Admin)
//   GET    /api/admin/customers         → all customers with booking counts
//   GET    /api/admin/customers/{id}    → single customer with bookings
//   PATCH  /api/admin/customers/{id}/status   → { status: 'active' | 'suspended' }
//
// CUSTOMER PROFILE (Customer)
//   GET    /api/auth/user               → own profile
//   PATCH  /api/auth/user               → update profile fields
//
// DASHBOARD STATS (Admin)
//   GET    /api/admin/dashboard/stats   → { total_revenue, active_rentals, pending_bookings,
//                                           available_vehicles, fleet_total }
//
// REPORTS (Admin)
//   GET    /api/admin/reports           → booking summary, revenue breakdown, fleet utilization
//   GET    /api/admin/reports/export?format=pdf    → download PDF report
//   GET    /api/admin/reports/export?format=excel  → download Excel report
//
// SETTINGS (Admin)
//   GET    /api/admin/settings          → all settings as key-value pairs
//   PATCH  /api/admin/settings/business       → { business_name, contact_email, ... }
//   PATCH  /api/admin/settings/booking-rules  → { min_days, max_days, advance_booking, ... }
//   PATCH  /api/admin/settings/account        → { name, email, password? }
//
// ── FLUTTER HTTP PACKAGE SETUP ────────────────────────────────────
//
// 1. Add to pubspec.yaml:
//      dependencies:
//        http: ^1.2.0
//        shared_preferences: ^2.2.0    # for storing the Sanctum token
//        file_picker: ^8.0.0           # for image uploads
//
// 2. Create lib/services/api_service.dart:
//      - Singleton that holds the base URL + Sanctum token
//      - Methods: get(), post(), put(), patch(), delete(), upload()
//      - Reads/writes token via SharedPreferences
//
// 3. Replace all _vehicles / _bookings / _customers lists in this file
//    with calls to ApiService when initState() runs.
//
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'login_page.dart';

// ── Color constants (shared with customer_page.dart) ─────────────
const kBg       = Color(0xFF0A1628);
const kBg2      = Color(0xFF0D1A2E);
const kCard     = Color(0xFF1A2744);
const kBorder   = Color(0xFF243357);
const kBlue     = Color(0xFF2D7BF5);
const kBlue2    = Color(0xFF1A5FCC);
const kBlueBg   = Color(0xFF0D1F3C);
const kText     = Color(0xFFF0EDE6);
const kMuted    = Color(0xFF7A8EAD);
const kHint     = Color(0xFF4A5E7A);
const kInput    = Color(0xFF162035);
const kInputBdr = Color(0xFF253A5E);
const kGreen    = Color(0xFF5DCB7A);
const kGreenBg  = Color(0xFF0A2A12);
const kGreenBdr = Color(0xFF1A4A2A);
const kAmber    = Color(0xFFFAC775);
const kAmberBg  = Color(0xFF1A1200);
const kAmberBdr = Color(0xFF3A2800);
const kRed      = Color(0xFFF09595);
const kRedBg    = Color(0xFF2A0A0A);
const kRedBdr   = Color(0xFF4A1A1A);
const kInfo     = Color(0xFF7AB8FF);
const kInfoBg   = Color(0xFF0D1F3C);
const kInfoBdr  = Color(0xFF1A3A6E);

const kSBFull = 230.0;
const kSBMini = 52.0;

const kFast   = Duration(milliseconds: 150);
const kNormal = Duration(milliseconds: 250);
const kPage   = Duration(milliseconds: 320);

// ── Vehicle model ─────────────────────────────────────────────────
// TODO: This model maps to the `vehicles` + `vehicle_images` DB tables.
//       Run: php artisan make:model Vehicle -m
//            php artisan make:model VehicleImage -m
//       Then fill in the migration columns listed at the top of this file.
//       Relationships in Vehicle.php:
//         public function images() { return $this->hasMany(VehicleImage::class); }
//         public function bookings(){ return $this->hasMany(Booking::class); }
class AdminVehicle {
  String id;
  String name;
  String model;
  String year;
  String category;     // Sedan | SUV | Hatchback | Van | Truck
  int    seats;
  String fuel;         // Gasoline | Diesel | Electric | Hybrid
  String transmission; // Automatic | Manual | CVT
  int    dailyRate;
  String plateNumber;
  String status;       // available | rented | maintenance | inactive
  String description;
  // TODO: replace with real image URLs from Laravel storage
  // These are set after admin uploads photos via POST /api/admin/vehicles/{id}/images
  List<String> imageUrls; // [frontUrl, sideUrl, rearUrl, interiorUrl]

  AdminVehicle({
    required this.id,
    required this.name,
    required this.model,
    required this.year,
    required this.category,
    required this.seats,
    required this.fuel,
    required this.transmission,
    required this.dailyRate,
    required this.plateNumber,
    required this.status,
    this.description = '',
    this.imageUrls = const [],
  });
}

// ── Booking model (admin view) ────────────────────────────────────
// TODO: Maps to the `bookings` DB table.
//       Run: php artisan make:model Booking -m
//       Relationships in Booking.php:
//         public function customer() { return $this->belongsTo(Customer::class); }
//         public function vehicle()  { return $this->belongsTo(Vehicle::class); }
//       When status changes to 'Completed', also update vehicle.status = 'available'
//       When status changes to 'Confirmed'/'Active', update vehicle.status = 'rented'
class AdminBooking {
  final String id;
  final String customerName;
  final String customerEmail;
  final String vehicleName;
  final String pickupDate;
  final String returnDate;
  final int    days;
  final int    totalFee;
  String       status; // Pending | Confirmed | Active | Completed | Cancelled

  AdminBooking({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.vehicleName,
    required this.pickupDate,
    required this.returnDate,
    required this.days,
    required this.totalFee,
    required this.status,
  });
}

// ── Customer model (admin view) ───────────────────────────────────
// TODO: Maps to the `customers` DB table (extends the `users` table via user_id FK).
//       Run: php artisan make:model Customer -m
//       Relationships in Customer.php:
//         public function user()     { return $this->belongsTo(User::class); }
//         public function bookings() { return $this->hasMany(Booking::class); }
//       The `users` table (created by default) holds email + hashed password.
//       `customers` holds the extended profile (phone, license, status).
class AdminCustomer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String licenseNo;
  final String memberSince;
  final int    totalBookings;
  String       status; // active | suspended

  AdminCustomer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.licenseNo,
    required this.memberSince,
    required this.totalBookings,
    required this.status,
  });
}

// ================================================================
// AdminPage
// ================================================================
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with TickerProviderStateMixin {

  bool _sbCollapsed = false;
  int  _activePage  = 0;

  // Page transition
  late AnimationController _pageCtrl;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;

  // ── Sample data (replace with API calls) ──────────────────────
  // TODO: _fetchVehicles()  → GET /api/admin/vehicles
  // TODO: _fetchBookings()  → GET /api/admin/bookings
  // TODO: _fetchCustomers() → GET /api/admin/customers
  // TODO: _fetchStats()     → GET /api/admin/dashboard/stats

  final List<AdminVehicle> _vehicles = [
    AdminVehicle(id:'V001', name:'Toyota Vios',        model:'1.3 XLE Variant',      year:'2024', category:'Sedan',    seats:5, fuel:'Gasoline', transmission:'Automatic', dailyRate:1200, plateNumber:'ABC-1234', status:'available'),
    AdminVehicle(id:'V002', name:'Toyota Fortuner',    model:'2.4 G Diesel 4x2 AT',  year:'2024', category:'SUV',      seats:7, fuel:'Diesel',   transmission:'Automatic', dailyRate:2400, plateNumber:'JKL-3456', status:'rented'),
    AdminVehicle(id:'V003', name:'Honda City',         model:'1.5 RS Turbo',         year:'2023', category:'Sedan',    seats:5, fuel:'Gasoline', transmission:'CVT',       dailyRate:1500, plateNumber:'DEF-5678', status:'maintenance'),
    AdminVehicle(id:'V004', name:'Mitsubishi Xpander', model:'GLS Sport AT',         year:'2024', category:'SUV',      seats:7, fuel:'Gasoline', transmission:'Automatic', dailyRate:1700, plateNumber:'GHI-9012', status:'available'),
    AdminVehicle(id:'V005', name:'Honda Jazz',         model:'1.5 V CVT',            year:'2023', category:'Hatchback',seats:5, fuel:'Gasoline', transmission:'CVT',       dailyRate:1100, plateNumber:'MNO-7890', status:'available'),
    AdminVehicle(id:'V006', name:'Mitsubishi Montero', model:'GLS Premium 4WD',      year:'2024', category:'SUV',      seats:7, fuel:'Diesel',   transmission:'Automatic', dailyRate:2200, plateNumber:'PQR-1122', status:'available'),
  ];

  final List<AdminBooking> _bookings = [
    AdminBooking(id:'DRIVO-20260318-A1B2', customerName:'Juan dela Cruz',  customerEmail:'juan@email.com',   vehicleName:'Toyota Vios 2023',    pickupDate:'Mar 18', returnDate:'Mar 24', days:6, totalFee:7200,  status:'Confirmed'),
    AdminBooking(id:'DRIVO-20260325-B2C3', customerName:'Maria Santos',    customerEmail:'maria@email.com',  vehicleName:'Toyota Fortuner',     pickupDate:'Mar 25', returnDate:'Mar 28', days:3, totalFee:7200,  status:'Pending'),
    AdminBooking(id:'DRIVO-20260310-C3D4', customerName:'Pedro Reyes',     customerEmail:'pedro@email.com',  vehicleName:'Mitsubishi Xpander',  pickupDate:'Mar 10', returnDate:'Mar 13', days:3, totalFee:5100,  status:'Completed'),
    AdminBooking(id:'DRIVO-20260301-E5F6', customerName:'Ana Gonzales',    customerEmail:'ana@email.com',    vehicleName:'Honda City',          pickupDate:'Mar 1',  returnDate:'Mar 3',  days:2, totalFee:3000,  status:'Cancelled'),
    AdminBooking(id:'DRIVO-20260215-F6G7', customerName:'Jose Mercado',    customerEmail:'jose@email.com',   vehicleName:'Honda Jazz',          pickupDate:'Feb 15', returnDate:'Feb 17', days:2, totalFee:2200,  status:'Completed'),
    AdminBooking(id:'DRIVO-20260210-G7H8', customerName:'Rosa Villanueva', customerEmail:'rosa@email.com',   vehicleName:'Mitsubishi Montero',  pickupDate:'Feb 10', returnDate:'Feb 14', days:4, totalFee:8800,  status:'Active'),
  ];

  final List<AdminCustomer> _customers = [
    AdminCustomer(id:'C001', firstName:'Juan',  lastName:'dela Cruz',  email:'juan@email.com',   phone:'+63 917 123 4567', licenseNo:'N01-23-456789', memberSince:'Jan 2026', totalBookings:6, status:'active'),
    AdminCustomer(id:'C002', firstName:'Maria', lastName:'Santos',     email:'maria@email.com',  phone:'+63 918 234 5678', licenseNo:'N02-23-567890', memberSince:'Jan 2026', totalBookings:3, status:'active'),
    AdminCustomer(id:'C003', firstName:'Pedro', lastName:'Reyes',      email:'pedro@email.com',  phone:'+63 919 345 6789', licenseNo:'N03-23-678901', memberSince:'Feb 2026', totalBookings:2, status:'active'),
    AdminCustomer(id:'C004', firstName:'Ana',   lastName:'Gonzales',   email:'ana@email.com',    phone:'+63 920 456 7890', licenseNo:'N04-23-789012', memberSince:'Feb 2026', totalBookings:1, status:'suspended'),
    AdminCustomer(id:'C005', firstName:'Jose',  lastName:'Mercado',    email:'jose@email.com',   phone:'+63 921 567 8901', licenseNo:'N05-23-890123', memberSince:'Mar 2026', totalBookings:2, status:'active'),
  ];

  // ── Vehicle form state ────────────────────────────────────────
  final _nameCtrl      = TextEditingController();
  final _modelCtrl     = TextEditingController();
  final _yearCtrl      = TextEditingController();
  final _plateCtrl     = TextEditingController();
  final _rateCtrl      = TextEditingController();
  final _descCtrl      = TextEditingController();
  String _formCategory     = 'Sedan';
  String _formFuel         = 'Gasoline';
  String _formTransmission = 'Automatic';
  int    _formSeats        = 5;
  String _formStatus       = 'available';
  // TODO: image upload state — connect to file picker + upload to Laravel
  // final List<PlatformFile> _pickedImages = [];
  // Use file_picker package: FilePicker.platform.pickFiles(allowMultiple:true, type:FileType.image)
  // Then POST each image to: POST /api/admin/vehicles/{id}/images
  // Response returns: { image_url: 'https://storage.../vehicles/...' }
  final List<String> _mockImageSlots = ['', '', '', '']; // [Front, Side, Rear, Interior]

  AdminVehicle? _editingVehicle; // null = adding new, non-null = editing existing
  bool _showVehicleForm = false;

  // ── Filters ───────────────────────────────────────────────────
  String _vehicleFilter    = 'all';
  String _bookingFilter    = 'all';
  String _customerFilter   = 'all';
  String _vehicleSearch    = '';
  String _bookingSearch    = '';
  String _customerSearch   = '';
  final _vSearchCtrl = TextEditingController();
  final _bSearchCtrl = TextEditingController();
  final _cSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageCtrl  = AnimationController(vsync:this, duration:kPage);
    _pageFade  = CurvedAnimation(parent:_pageCtrl, curve:Curves.easeOut);
    _pageSlide = Tween<Offset>(begin:const Offset(0,.03), end:Offset.zero)
        .animate(CurvedAnimation(parent:_pageCtrl, curve:Curves.easeOut));
    _pageCtrl.forward();

    // ── TODO: Replace sample data with real API calls ─────────────
    // Once ApiService is set up, call these here:
    //
    //   _fetchVehicles();   // GET /api/admin/vehicles
    //   _fetchBookings();   // GET /api/admin/bookings
    //   _fetchCustomers();  // GET /api/admin/customers
    //   _fetchStats();      // GET /api/admin/dashboard/stats
    //
    // Example implementation:
    //
    //   Future<void> _fetchVehicles() async {
    //     setState(() => _vehiclesLoading = true);
    //     final res = await http.get(
    //       Uri.parse('${ApiService.baseUrl}/api/admin/vehicles'),
    //       headers: {'Authorization': 'Bearer ${ApiService.token}',
    //                 'Accept': 'application/json'},
    //     );
    //     if (res.statusCode == 200) {
    //       final data = jsonDecode(res.body)['data'] as List;
    //       setState(() {
    //         _vehicles = data.map((v) => AdminVehicle(
    //           id:           v['id'].toString(),
    //           name:         v['name'],
    //           model:        v['model'],
    //           year:         v['year'].toString(),
    //           category:     v['category'],
    //           seats:        v['seats'],
    //           fuel:         v['fuel_type'],
    //           transmission: v['transmission'],
    //           dailyRate:    (v['daily_rate'] as num).toInt(),
    //           plateNumber:  v['plate_number'],
    //           status:       v['status'],
    //           description:  v['description'] ?? '',
    //           imageUrls:    (v['images'] as List)
    //                           .map((i) => i['image_url'] as String)
    //                           .toList(),
    //         )).toList();
    //         _vehiclesLoading = false;
    //       });
    //     }
    //   }
    // ─────────────────────────────────────────────────────────────
    _pageCtrl.forward();
    _vSearchCtrl.addListener(() => setState(() => _vehicleSearch  = _vSearchCtrl.text.toLowerCase()));
    _bSearchCtrl.addListener(() => setState(() => _bookingSearch  = _bSearchCtrl.text.toLowerCase()));
    _cSearchCtrl.addListener(() => setState(() => _customerSearch = _cSearchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose(); _modelCtrl.dispose(); _yearCtrl.dispose();
    _plateCtrl.dispose(); _rateCtrl.dispose(); _descCtrl.dispose();
    _vSearchCtrl.dispose(); _bSearchCtrl.dispose(); _cSearchCtrl.dispose();
    super.dispose();
  }

  void _navTo(int page) {
    if (page == _activePage) return;
    setState(() { _activePage = page; _showVehicleForm = false; });
    _pageCtrl.forward(from: 0);
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _fmt(int n) => n.toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // Status colors are handled per vehicle/booking - removed duplicates
  Color _bStatusColor(String s) {
    switch(s) { case'Confirmed':return kGreen; case'Pending':return kAmber;
      case'Active':return kBlue; case'Completed':return kInfo;
      default:return kRed; }
  }
  Color _bStatusBg(String s) {
    switch(s) { case'Confirmed':return kGreenBg; case'Pending':return kAmberBg;
      case'Active':return kBlueBg; case'Completed':return kInfoBg;
      default:return kRedBg; }
  }
  Color _bStatusBdr(String s) {
    switch(s) { case'Confirmed':return kGreenBdr; case'Pending':return kAmberBdr;
      case'Active':return kInfoBdr; case'Completed':return kInfoBdr;
      default:return kRedBdr; }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? kRedBg : const Color(0xFF1A4A2A),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: error ? kRedBdr : kGreenBdr),
      ),
    ));
  }

  // ── Vehicle CRUD ──────────────────────────────────────────────
  void _openAddVehicle() {
    _editingVehicle = null;
    _nameCtrl.clear(); _modelCtrl.clear(); _yearCtrl.clear();
    _plateCtrl.clear(); _rateCtrl.clear(); _descCtrl.clear();
    _formCategory = 'Sedan'; _formFuel = 'Gasoline';
    _formTransmission = 'Automatic'; _formSeats = 5;
    _formStatus = 'available';
    for (int i = 0; i < 4; i++) _mockImageSlots[i] = '';
    setState(() => _showVehicleForm = true);
  }

  void _openEditVehicle(AdminVehicle v) {
    _editingVehicle = v;
    _nameCtrl.text  = v.name;
    _modelCtrl.text = v.model;
    _yearCtrl.text  = v.year;
    _plateCtrl.text = v.plateNumber;
    _rateCtrl.text  = v.dailyRate.toString();
    _descCtrl.text  = v.description;
    _formCategory     = v.category;
    _formFuel         = v.fuel;
    _formTransmission = v.transmission;
    _formSeats        = v.seats;
    _formStatus       = v.status;
    for (int i = 0; i < 4; i++) {
      _mockImageSlots[i] = i < v.imageUrls.length ? v.imageUrls[i] : '';
    }
    setState(() => _showVehicleForm = true);
  }

  // ── TODO: Wire _saveVehicle to the Laravel API ───────────────────
  // ADD:    POST   /api/admin/vehicles
  //         Body:  { name, model, year, category, seats, fuel_type,
  //                  transmission, daily_rate, plate_number, status, description }
  //         Then for each image:
  //           POST /api/admin/vehicles/{id}/images
  //           Body: multipart/form-data { angle: 'front'|'side'|'rear'|'interior', image: File }
  //
  // UPDATE: PUT    /api/admin/vehicles/{id}
  //         Body:  same fields as above
  //         Then manage images:
  //           DELETE /api/admin/vehicles/{id}/images/{imageId}  (removed slots)
  //           POST   /api/admin/vehicles/{id}/images            (new slots)
  //
  // Image upload example (using http + file_picker):
  //   final request = http.MultipartRequest(
  //     'POST', Uri.parse('${ApiService.baseUrl}/api/admin/vehicles/$id/images'));
  //   request.headers['Authorization'] = 'Bearer ${ApiService.token}';
  //   request.fields['angle'] = 'front';
  //   request.files.add(await http.MultipartFile.fromPath('image', filePath));
  //   final response = await request.send();
  //   // response body: { "image_url": "https://yourserver.com/storage/vehicles/..." }
  // ─────────────────────────────────────────────────────────────────
  void _saveVehicle() {
    final name  = _nameCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final year  = _yearCtrl.text.trim();
    final plate = _plateCtrl.text.trim();
    final rate  = int.tryParse(_rateCtrl.text.trim()) ?? 0;

    if (name.isEmpty || model.isEmpty || year.isEmpty || plate.isEmpty || rate == 0) {
      _snack('Please fill in all required fields.', error: true);
      return;
    }

    if (_editingVehicle == null) {
      // ── ADD NEW ───────────────────────────────────────────────
      // TODO: POST /api/admin/vehicles with body:
      // { name, model, year, category, seats, fuel, transmission,
      //   daily_rate, plate_number, status, description }
      // Response: { id, ...vehicle fields }
      // Then upload images: POST /api/admin/vehicles/{id}/images
      final newV = AdminVehicle(
        id:           'V${(_vehicles.length + 1).toString().padLeft(3,'0')}',
        name:         name,  model: model,  year: year,
        category:     _formCategory,  seats: _formSeats,
        fuel:         _formFuel,      transmission: _formTransmission,
        dailyRate:    rate,            plateNumber: plate,
        status:       _formStatus,    description: _descCtrl.text.trim(),
        imageUrls:    _mockImageSlots.where((s) => s.isNotEmpty).toList(),
      );
      setState(() { _vehicles.insert(0, newV); _showVehicleForm = false; });
      _snack('Vehicle "${newV.name}" added successfully!');
    } else {
      // ── UPDATE EXISTING ───────────────────────────────────────
      // TODO: PUT /api/admin/vehicles/{id} with updated fields
      // TODO: manage images: DELETE /api/admin/vehicles/{id}/images/{imageId}
      //        and POST /api/admin/vehicles/{id}/images for new ones
      final v = _editingVehicle!;
      setState(() {
        v.name          = name;   v.model       = model;
        v.year          = year;   v.plateNumber = plate;
        v.dailyRate     = rate;   v.description = _descCtrl.text.trim();
        v.category      = _formCategory;
        v.fuel          = _formFuel;
        v.transmission  = _formTransmission;
        v.seats         = _formSeats;
        v.status        = _formStatus;
        v.imageUrls     = _mockImageSlots.where((s) => s.isNotEmpty).toList();
        _showVehicleForm = false;
      });
      _snack('Vehicle "${v.name}" updated successfully!');
    }
  }

  void _deleteVehicle(AdminVehicle v) {
    showDialog(context: context, builder: (_) => _ConfirmDialog(
      title: 'Delete Vehicle',
      message: 'Are you sure you want to delete "${v.name} ${v.model}"? This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
      onConfirm: () {
        // TODO: DELETE /api/admin/vehicles/{id}
        Navigator.pop(context);
        setState(() => _vehicles.removeWhere((x) => x.id == v.id));
        _snack('"${v.name}" deleted.');
      },
    ));
  }

  void _changeVehicleStatus(AdminVehicle v, String newStatus) {
    // TODO: PATCH /api/admin/vehicles/{id}/status  body: { status: newStatus }
    setState(() => v.status = newStatus);
    _snack('${v.name} marked as $newStatus.');
  }

  // ── Booking actions ───────────────────────────────────────────
  // TODO: PATCH /api/admin/bookings/{id}/confirm
  //       Response: updated booking object
  //       Side effect: send confirmation email to customer via Laravel Mail
  void _confirmBooking(AdminBooking b) {
    // TODO: PATCH /api/admin/bookings/{id}/confirm
    setState(() => b.status = 'Confirmed');
    _snack('Booking ${b.id} confirmed.');
  }

  void _cancelBooking(AdminBooking b) {
    showDialog(context: context, builder: (_) => _ConfirmDialog(
      title: 'Cancel Booking',
      message: 'Cancel booking ${b.id} for ${b.customerName}?',
      confirmLabel: 'Cancel Booking',
      danger: true,
      onConfirm: () {
        // TODO: PATCH /api/admin/bookings/{id}/cancel
        Navigator.pop(context);
        setState(() => b.status = 'Cancelled');
        _snack('Booking ${b.id} cancelled.');
      },
    ));
  }

  // TODO: PATCH /api/admin/bookings/{id}/complete
  //       Side effect: set vehicle.status = 'available' in DB
  void _completeBooking(AdminBooking b) {
    // TODO: PATCH /api/admin/bookings/{id}/complete
    setState(() => b.status = 'Completed');
    _snack('Booking ${b.id} marked as completed.');
  }

  // ── Customer actions ──────────────────────────────────────────
  // TODO: PATCH /api/admin/customers/{id}/status
  //       Body: { status: 'active' | 'suspended' }
  //       Suspended customers should be blocked at the API level too:
  //       Add a middleware check in BookingController@store that rejects
  //       requests from customers whose status = 'suspended'
  void _toggleCustomerStatus(AdminCustomer c) {
    final newStatus = c.status == 'active' ? 'suspended' : 'active';
    showDialog(context: context, builder: (_) => _ConfirmDialog(
      title: newStatus == 'suspended' ? 'Suspend Customer' : 'Activate Customer',
      message: newStatus == 'suspended'
          ? 'Suspend ${c.firstName} ${c.lastName}? They will not be able to make bookings.'
          : 'Activate ${c.firstName} ${c.lastName}? They will regain full access.',
      confirmLabel: newStatus == 'suspended' ? 'Suspend' : 'Activate',
      danger: newStatus == 'suspended',
      onConfirm: () {
        // TODO: PATCH /api/admin/customers/{id}/status  body: { status: newStatus }
        Navigator.pop(context);
        setState(() => c.status = newStatus);
        _snack('${c.firstName} ${c.lastName} is now $newStatus.');
      },
    ));
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (_) => _ConfirmDialog(
      title: 'Log Out',
      message: 'Log out of the DRIVO admin panel?',
      confirmLabel: 'Log Out',
      danger: true,
      onConfirm: () {
        Navigator.of(context).pop();
        // TODO: clear admin Sanctum token from storage
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => const LoginPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      },
    ));
  }

  // ── Filtered lists ────────────────────────────────────────────
  List<AdminVehicle> get _filteredVehicles {
    var list = _vehicleFilter == 'all'
        ? _vehicles
        : _vehicles.where((v) => v.status == _vehicleFilter).toList();
    if (_vehicleSearch.isNotEmpty) {
      list = list.where((v) =>
        v.name.toLowerCase().contains(_vehicleSearch) ||
        v.plateNumber.toLowerCase().contains(_vehicleSearch) ||
        v.category.toLowerCase().contains(_vehicleSearch)).toList();
    }
    return list;
  }

  List<AdminBooking> get _filteredBookings {
    var list = _bookingFilter == 'all'
        ? _bookings
        : _bookings.where((b) => b.status == _bookingFilter).toList();
    if (_bookingSearch.isNotEmpty) {
      list = list.where((b) =>
        b.id.toLowerCase().contains(_bookingSearch) ||
        b.customerName.toLowerCase().contains(_bookingSearch) ||
        b.vehicleName.toLowerCase().contains(_bookingSearch)).toList();
    }
    return list;
  }

  List<AdminCustomer> get _filteredCustomers {
    var list = _customerFilter == 'all'
        ? _customers
        : _customers.where((c) => c.status == _customerFilter).toList();
    if (_customerSearch.isNotEmpty) {
      list = list.where((c) =>
        '${c.firstName} ${c.lastName}'.toLowerCase().contains(_customerSearch) ||
        c.email.toLowerCase().contains(_customerSearch)).toList();
    }
    return list;
  }

  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Row(children: [
        _AdminSidebar(
          collapsed:  _sbCollapsed,
          activePage: _activePage,
          onToggle:   () => setState(() => _sbCollapsed = !_sbCollapsed),
          onNavTap:   _navTo,
          onLogout:   _showLogoutDialog,
        ),
        Expanded(child: Column(children: [
          _AdminTopbar(
            title: _pageTitle(),
            onLogout: _showLogoutDialog,
          ),
          Expanded(child: FadeTransition(
            opacity: _pageFade,
            child: SlideTransition(position: _pageSlide, child: _buildPage()),
          )),
        ])),
      ]),
    );
  }

  String _pageTitle() {
    const t = ['Dashboard','Fleet Management','Bookings','Customers','Reports','Settings'];
    return t[_activePage];
  }

  Widget _buildPage() {
    switch (_activePage) {
      case 0: return _buildDashboard();
      case 1: return _buildFleet();
      case 2: return _buildBookings();
      case 3: return _buildCustomers();
      case 4: return _buildReports();
      case 5: return _buildSettings();
      default: return _buildDashboard();
    }
  }

  // ================================================================
  // PAGE: DASHBOARD
  // ================================================================
  Widget _buildDashboard() {
    final totalRevenue = _bookings
        .where((b) => b.status == 'Completed')
        .fold(0, (sum, b) => sum + b.totalFee);
    final activeRentals   = _vehicles.where((v) => v.status == 'rented').length;
    final pendingBookings = _bookings.where((b) => b.status == 'Pending').length;
    final availableVehicles = _vehicles.where((v) => v.status == 'available').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Greeting
        const Text('Welcome back, Admin!',
          style: TextStyle(color:kText, fontSize:16, fontWeight:FontWeight.w500)),
        const SizedBox(height:4),
        const Text('Here is your fleet overview for today.',
          style: TextStyle(color:kMuted, fontSize:12)),
        const SizedBox(height:20),

        // Stat cards
        Row(children: [
          Expanded(child: _AStatCard(label:'Total Revenue', value:'₱${_fmt(totalRevenue)}',
            sub:'Completed bookings', valueColor:kGreen, icon:Icons.payments_outlined)),
          const SizedBox(width:10),
          Expanded(child: _AStatCard(label:'Active Rentals', value:'$activeRentals',
            sub:'Vehicles out now', valueColor:kAmber, icon:Icons.directions_car_outlined)),
          const SizedBox(width:10),
          Expanded(child: _AStatCard(label:'Pending Bookings', value:'$pendingBookings',
            sub:'Awaiting confirmation', valueColor:kInfo, icon:Icons.pending_actions_outlined)),
          const SizedBox(width:10),
          Expanded(child: _AStatCard(label:'Available Fleet', value:'$availableVehicles / ${_vehicles.length}',
            sub:'Ready to rent', valueColor:kGreen, icon:Icons.garage_outlined)),
        ]),
        const SizedBox(height:22),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Recent bookings
          Expanded(flex:3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ASectionHeader(title:'Recent Bookings', linkText:'View all', onLink: () => _navTo(2)),
            ..._bookings.take(5).map((b) => Padding(
              padding: const EdgeInsets.only(bottom:8),
              child: _AdminBookingRow(
                booking: b,
                onConfirm:  b.status == 'Pending'   ? () => _confirmBooking(b) : null,
                onComplete: b.status == 'Active'     ? () => _completeBooking(b) : null,
                onCancel:   (b.status == 'Pending' || b.status == 'Confirmed') ? () => _cancelBooking(b) : null,
              ),
            )),
          ])),
          const SizedBox(width:16),

          // Fleet status pie-style list
          Expanded(flex:2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ASectionHeader(title:'Fleet Status', linkText:'Manage', onLink: () => _navTo(1)),
            _FleetStatusCard(vehicles: _vehicles),
            const SizedBox(height:14),
            _ASectionHeader(title:'Quick Actions'),
            _AQuickAction(icon:Icons.add_circle_outline, label:'Add New Vehicle',
              onTap: () { _navTo(1); _openAddVehicle(); }),
            _AQuickAction(icon:Icons.check_circle_outline, label:'Confirm Pending Bookings',
              onTap: () => _navTo(2)),
            _AQuickAction(icon:Icons.people_outline, label:'View Customers',
              onTap: () => _navTo(3)),
            _AQuickAction(icon:Icons.bar_chart_outlined, label:'View Reports',
              onTap: () => _navTo(4)),
          ])),
        ]),
      ]),
    );
  }

  // ================================================================
  // PAGE: FLEET MANAGEMENT
  // ================================================================
  Widget _buildFleet() {
    final filters = ['all','available','rented','maintenance'];
    return Column(children: [

      // Toolbar
      Padding(
        padding: const EdgeInsets.fromLTRB(22,18,22,0),
        child: Row(children: [
          // Search
          Expanded(child: _SearchField(controller: _vSearchCtrl, hint:'Search vehicles...')),
          const SizedBox(width:12),
          // Category filters
          ...filters.map((f) => Padding(
            padding: const EdgeInsets.only(left:8),
            child: _AFilterChip(
              label: f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
              selected: _vehicleFilter == f,
              onTap: () => setState(() => _vehicleFilter = f),
            ),
          )),
          const SizedBox(width:12),
          // Add button
          _APrimaryBtn(label:'+ Add Vehicle', onTap: _openAddVehicle),
        ]),
      ),
      const SizedBox(height:14),

      // Vehicle form (inline, slides in)
      if (_showVehicleForm)
        Padding(
          padding: const EdgeInsets.fromLTRB(22,0,22,14),
          child: _VehicleForm(
            editing:         _editingVehicle != null,
            nameCtrl:        _nameCtrl,
            modelCtrl:       _modelCtrl,
            yearCtrl:        _yearCtrl,
            plateCtrl:       _plateCtrl,
            rateCtrl:        _rateCtrl,
            descCtrl:        _descCtrl,
            category:        _formCategory,
            fuel:            _formFuel,
            transmission:    _formTransmission,
            seats:           _formSeats,
            status:          _formStatus,
            imageSlots:      _mockImageSlots,
            onCategoryChanged:     (v) => setState(() => _formCategory     = v),
            onFuelChanged:         (v) => setState(() => _formFuel         = v),
            onTransmissionChanged: (v) => setState(() => _formTransmission = v),
            onSeatsChanged:        (v) => setState(() => _formSeats        = v),
            onStatusChanged:       (v) => setState(() => _formStatus       = v),
            onImageSlotTap:        (i) {
              // TODO: open file picker for image slot i
              // Use file_picker package:
              //   final result = await FilePicker.platform.pickFiles(type: FileType.image);
              //   if (result != null) {
              //     // upload to POST /api/admin/vehicles/{id}/images
              //     setState(() => _mockImageSlots[i] = result.files.first.name);
              //   }
              setState(() => _mockImageSlots[i] = 'image_${i+1}_selected.jpg');
              _snack('TODO: Connect file picker to upload to Laravel storage');
            },
            onSave:   _saveVehicle,
            onCancel: () => setState(() => _showVehicleForm = false),
          ),
        ),

      // Vehicle grid
      Expanded(
        child: _filteredVehicles.isEmpty
          ? const Center(child: Text('No vehicles found.', style: TextStyle(color:kHint)))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(22,0,22,22),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 370, // fixed height — enough for image + all card content
              ),
              itemCount: _filteredVehicles.length,
              itemBuilder: (_, i) => _VehicleCard(
                vehicle: _filteredVehicles[i],
                onEdit:   () => _openEditVehicle(_filteredVehicles[i]),
                onDelete: () => _deleteVehicle(_filteredVehicles[i]),
                onStatusChange: (s) => _changeVehicleStatus(_filteredVehicles[i], s),
              ),
            ),
      ),
    ]);
  }

  // ================================================================
  // PAGE: BOOKINGS
  // ================================================================
  Widget _buildBookings() {
    final filters = ['all','Pending','Confirmed','Active','Completed','Cancelled'];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22,18,22,0),
        child: Row(children: [
          Expanded(child: _SearchField(controller: _bSearchCtrl, hint:'Search bookings, customers...')),
          const SizedBox(width:12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: filters.map((f) => Padding(
              padding: const EdgeInsets.only(left:8),
              child: _AFilterChip(
                label: f == 'all' ? 'All' : f,
                selected: _bookingFilter == f,
                onTap: () => setState(() => _bookingFilter = f),
              ),
            )).toList()),
          ),
        ]),
      ),
      const SizedBox(height:14),
      // Table header
      Container(
        margin: const EdgeInsets.symmetric(horizontal:22),
        padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
        decoration: BoxDecoration(
          color: kBlueBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color:kBorder),
        ),
        child: const Row(children: [
          Expanded(flex:3, child: Text('Booking ID',   style: TextStyle(color:kMuted, fontSize:11, fontWeight:FontWeight.w500))),
          Expanded(flex:3, child: Text('Customer',      style: TextStyle(color:kMuted, fontSize:11, fontWeight:FontWeight.w500))),
          Expanded(flex:3, child: Text('Vehicle',       style: TextStyle(color:kMuted, fontSize:11, fontWeight:FontWeight.w500))),
          Expanded(flex:2, child: Text('Dates',         style: TextStyle(color:kMuted, fontSize:11, fontWeight:FontWeight.w500))),
          Expanded(flex:2, child: Text('Fee',           style: TextStyle(color:kMuted, fontSize:11, fontWeight:FontWeight.w500))),
          Expanded(flex:2, child: Text('Status',        style: TextStyle(color:kMuted, fontSize:11, fontWeight:FontWeight.w500))),
          Expanded(flex:2, child: Text('Actions',       style: TextStyle(color:kMuted, fontSize:11, fontWeight:FontWeight.w500))),
        ]),
      ),
      Expanded(
        child: _filteredBookings.isEmpty
          ? const Center(child: Text('No bookings found.', style: TextStyle(color:kHint)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(22,0,22,22),
              itemCount: _filteredBookings.length,
              separatorBuilder: (_,__) => const SizedBox.shrink(),
              itemBuilder: (_, i) => _AdminBookingRow(
                booking: _filteredBookings[i],
                tableStyle: true,
                statusColor:  _bStatusColor(_filteredBookings[i].status),
                statusBg:     _bStatusBg(_filteredBookings[i].status),
                statusBdr:    _bStatusBdr(_filteredBookings[i].status),
                onConfirm:  _filteredBookings[i].status == 'Pending'    ? () => _confirmBooking(_filteredBookings[i])  : null,
                onComplete: _filteredBookings[i].status == 'Active'     ? () => _completeBooking(_filteredBookings[i]) : null,
                onCancel:   (_filteredBookings[i].status == 'Pending' || _filteredBookings[i].status == 'Confirmed')
                              ? () => _cancelBooking(_filteredBookings[i]) : null,
              ),
            ),
      ),
    ]);
  }

  // ================================================================
  // PAGE: CUSTOMERS
  // ================================================================
  Widget _buildCustomers() {
    final filters = ['all','active','suspended'];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22,18,22,0),
        child: Row(children: [
          Expanded(child: _SearchField(controller: _cSearchCtrl, hint:'Search customers...')),
          const SizedBox(width:12),
          ...filters.map((f) => Padding(
            padding: const EdgeInsets.only(left:8),
            child: _AFilterChip(
              label: f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
              selected: _customerFilter == f,
              onTap: () => setState(() => _customerFilter = f),
            ),
          )),
        ]),
      ),
      const SizedBox(height:14),
      Expanded(
        child: _filteredCustomers.isEmpty
          ? const Center(child: Text('No customers found.', style: TextStyle(color:kHint)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(22,0,22,22),
              itemCount: _filteredCustomers.length,
              separatorBuilder: (_,__) => const SizedBox(height:8),
              itemBuilder: (_, i) => _CustomerRow(
                customer: _filteredCustomers[i],
                onToggleStatus: () => _toggleCustomerStatus(_filteredCustomers[i]),
                onViewBookings: () {
                  setState(() {
                    _bookingSearch = _filteredCustomers[i].firstName.toLowerCase();
                    _bSearchCtrl.text = _filteredCustomers[i].firstName;
                    _activePage = 2;
                  });
                  _pageCtrl.forward(from: 0);
                },
              ),
            ),
      ),
    ]);
  }

  // ================================================================
  // PAGE: REPORTS
  // ================================================================
  Widget _buildReports() {
    final totalRevenue  = _bookings.where((b) => b.status == 'Completed').fold(0, (s,b) => s+b.totalFee);
    final totalBookings = _bookings.length;
    final completedB    = _bookings.where((b) => b.status == 'Completed').length;
    final cancelledB    = _bookings.where((b) => b.status == 'Cancelled').length;
    final utilRate      = _vehicles.isEmpty ? 0 : (_vehicles.where((v) => v.status == 'rented').length * 100 / _vehicles.length).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Reports & Analytics', style: TextStyle(color:kText, fontSize:15, fontWeight:FontWeight.w500)),
        const SizedBox(height:4),
        const Text('TODO: Connect to GET /api/admin/reports for real-time analytics',
          style: TextStyle(color:kHint, fontSize:11)),
        const SizedBox(height:20),

        Row(children: [
          Expanded(child: _AStatCard(label:'Total Revenue',     value:'₱${_fmt(totalRevenue)}', icon:Icons.payments_outlined,      valueColor:kGreen)),
          const SizedBox(width:10),
          Expanded(child: _AStatCard(label:'Total Bookings',    value:'$totalBookings',           icon:Icons.calendar_today_outlined, valueColor:kInfo)),
          const SizedBox(width:10),
          Expanded(child: _AStatCard(label:'Completion Rate',   value:'${totalBookings > 0 ? (completedB*100/totalBookings).round() : 0}%', icon:Icons.check_circle_outline, valueColor:kGreen)),
          const SizedBox(width:10),
          Expanded(child: _AStatCard(label:'Fleet Utilization', value:'$utilRate%',               icon:Icons.directions_car_outlined, valueColor:kAmber)),
        ]),
        const SizedBox(height:20),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _ReportCard(
            title: 'Booking Summary',
            rows: [
              _ReportRow(label:'Confirmed', value:'${_bookings.where((b)=>b.status=="Confirmed").length}', color:kGreen),
              _ReportRow(label:'Pending',   value:'${_bookings.where((b)=>b.status=="Pending").length}',   color:kAmber),
              _ReportRow(label:'Active',    value:'${_bookings.where((b)=>b.status=="Active").length}',    color:kBlue),
              _ReportRow(label:'Completed', value:'$completedB',                                            color:kInfo),
              _ReportRow(label:'Cancelled', value:'$cancelledB',                                            color:kRed),
            ],
          )),
          const SizedBox(width:14),
          Expanded(child: _ReportCard(
            title: 'Fleet Overview',
            rows: [
              _ReportRow(label:'Available',   value:'${_vehicles.where((v)=>v.status=="available").length}',   color:kGreen),
              _ReportRow(label:'Rented',      value:'${_vehicles.where((v)=>v.status=="rented").length}',      color:kAmber),
              _ReportRow(label:'Maintenance', value:'${_vehicles.where((v)=>v.status=="maintenance").length}', color:kRed),
              _ReportRow(label:'Total Fleet', value:'${_vehicles.length}',                                      color:kMuted),
            ],
          )),
          const SizedBox(width:14),
          Expanded(child: _ReportCard(
            title: 'Revenue Breakdown',
            rows: [
              _ReportRow(label:'Sedan',     value:'₱${_fmt(_bookings.where((b)=>b.status=="Completed" && _vehicles.any((v)=>v.name==b.vehicleName.split(" ").take(2).join(" ") && v.category=="Sedan")).fold(0,(s,b)=>s+b.totalFee))}',     color:kBlue),
              _ReportRow(label:'SUV',       value:'₱${_fmt(_bookings.where((b)=>b.status=="Completed").fold(0,(s,b)=>s+b.totalFee) ~/ 2)}', color:kAmber),
              _ReportRow(label:'Hatchback', value:'₱${_fmt(_bookings.where((b)=>b.status=="Completed").fold(0,(s,b)=>s+b.totalFee) ~/ 6)}', color:kGreen),
              _ReportRow(label:'Total',     value:'₱${_fmt(totalRevenue)}',                                     color:kText),
            ],
          )),
        ]),
        const SizedBox(height:14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(12), border:Border.all(color:kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Export Reports', style: TextStyle(color:kText, fontSize:13, fontWeight:FontWeight.w500)),
            const SizedBox(height:4),
            const Text('TODO: Connect to GET /api/admin/reports/export?format=pdf|excel',
              style: TextStyle(color:kHint, fontSize:11)),
            const SizedBox(height:14),
            Row(children: [
              _APrimaryBtn(label:'Export PDF',   onTap: () => _snack('TODO: GET /api/admin/reports/export?format=pdf')),
              const SizedBox(width:10),
              _APrimaryBtn(label:'Export Excel', onTap: () => _snack('TODO: GET /api/admin/reports/export?format=excel')),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ================================================================
  // PAGE: SETTINGS
  // ================================================================
  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('System Settings', style: TextStyle(color:kText, fontSize:15, fontWeight:FontWeight.w500)),
        const SizedBox(height:20),

        _SettingsCard(title:'Business Information', children: [
          _FormField(label:'Business Name',    ctrl: TextEditingController(text:'DRIVO Car Rentals')),
          const SizedBox(height:12),
          _FormField(label:'Contact Email',    ctrl: TextEditingController(text:'admin@drivo.com')),
          const SizedBox(height:12),
          _FormField(label:'Contact Phone',    ctrl: TextEditingController(text:'+63 2 123 4567')),
          const SizedBox(height:12),
          _FormField(label:'Business Address', ctrl: TextEditingController(text:'123 Rental St, Metro Manila')),
          const SizedBox(height:14),
          // TODO: PATCH /api/admin/settings/business
          _APrimaryBtn(label:'Save Business Info', onTap: () => _snack('Business info saved!')),
        ]),

        const SizedBox(height:14),

        _SettingsCard(title:'Booking Rules', children: [
          _FormField(label:'Minimum Booking Days',    ctrl: TextEditingController(text:'1')),
          const SizedBox(height:12),
          _FormField(label:'Maximum Booking Days',    ctrl: TextEditingController(text:'30')),
          const SizedBox(height:12),
          _FormField(label:'Advance Booking (days)',  ctrl: TextEditingController(text:'1')),
          const SizedBox(height:12),
          _FormField(label:'Cancellation Policy',     ctrl: TextEditingController(text:'Free cancellation up to 24 hours before pickup')),
          const SizedBox(height:14),
          // TODO: PATCH /api/admin/settings/booking-rules
          _APrimaryBtn(label:'Save Booking Rules', onTap: () => _snack('Booking rules saved!')),
        ]),

        const SizedBox(height:14),

        _SettingsCard(title:'Admin Account', children: [
          _FormField(label:'Admin Name',  ctrl: TextEditingController(text:'DRIVO Admin')),
          const SizedBox(height:12),
          _FormField(label:'Admin Email', ctrl: TextEditingController(text:'admin@drivo.com')),
          const SizedBox(height:12),
          _FormField(label:'New Password',     ctrl: TextEditingController(), obscure:true),
          const SizedBox(height:12),
          _FormField(label:'Confirm Password', ctrl: TextEditingController(), obscure:true),
          const SizedBox(height:14),
          // TODO: PATCH /api/admin/settings/account
          _APrimaryBtn(label:'Update Account', onTap: () => _snack('Account updated!')),
        ]),
      ]),
    );
  }
}

// ================================================================
// ADMIN SIDEBAR
// ================================================================
class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.collapsed, required this.activePage,
    required this.onToggle, required this.onNavTap, required this.onLogout});
  final bool collapsed;
  final int  activePage;
  final VoidCallback onToggle, onLogout;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedContainer(
        duration: kNormal,
        curve: Curves.easeInOut,
        width: collapsed ? kSBMini : kSBFull,
        color: kBg2,
        child: Column(children: [
          // Header
          Container(
            height:56,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 6 : 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                // Logo — only shown when expanded, clipped so it never bleeds
                if (!collapsed)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.admin_panel_settings_outlined, color:kBlue, size:16),
                        SizedBox(width:8),
                        Flexible(
                          child: Text('DRIVO Admin',
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: TextStyle(color:kBlue, fontSize:13, fontWeight:FontWeight.w700, letterSpacing:.5)),
                        ),
                      ],
                    ),
                  ),
                _AHamBtn(onTap: onToggle),
              ],
            ),
          ),

          if (!collapsed) _ASBSection(label:'Main'),
          _ASBItem(icon:Icons.dashboard_outlined,        label:'Dashboard',       idx:0, active:activePage==0, collapsed:collapsed, onTap:()=>onNavTap(0)),
          _ASBItem(icon:Icons.directions_car_outlined,   label:'Fleet',           idx:1, active:activePage==1, collapsed:collapsed, onTap:()=>onNavTap(1)),
          _ASBItem(icon:Icons.calendar_today_outlined,   label:'Bookings',        idx:2, active:activePage==2, collapsed:collapsed, onTap:()=>onNavTap(2)),
          _ASBItem(icon:Icons.people_outline,            label:'Customers',       idx:3, active:activePage==3, collapsed:collapsed, onTap:()=>onNavTap(3)),
          if (!collapsed) _ASBSection(label:'Analytics'),
          _ASBItem(icon:Icons.bar_chart_outlined,        label:'Reports',         idx:4, active:activePage==4, collapsed:collapsed, onTap:()=>onNavTap(4)),
          if (!collapsed) _ASBSection(label:'System'),
          _ASBItem(icon:Icons.settings_outlined,         label:'Settings',        idx:5, active:activePage==5, collapsed:collapsed, onTap:()=>onNavTap(5)),

          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
            child: _ALogoutBtn(collapsed:collapsed, onTap:onLogout),
          ),
        ]),
      ),
    );
  }
}

class _AHamBtn extends StatefulWidget {
  const _AHamBtn({required this.onTap});
  final VoidCallback onTap;
  @override State<_AHamBtn> createState() => _AHamBtnState();
}
class _AHamBtnState extends State<_AHamBtn> {
  bool _h = false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(onTap:widget.onTap,
      child: AnimatedContainer(duration:kFast, width:32, height:32,
        decoration: BoxDecoration(color:_h?kBlueBg:kCard, borderRadius:BorderRadius.circular(7), border:Border.all(color:_h?kBlue:kBorder)),
        child: Column(mainAxisAlignment:MainAxisAlignment.center, crossAxisAlignment:CrossAxisAlignment.center, children:[
          _HamL(h:_h), const SizedBox(height:4), _HamL(h:_h), const SizedBox(height:4), _HamL(h:_h),
        ]),
      ),
    ),
  );
}
class _HamL extends StatelessWidget {
  const _HamL({this.h=false}); final bool h;
  @override Widget build(BuildContext context) => AnimatedContainer(duration:kFast,
    width:14, height:1.5, decoration:BoxDecoration(color:h?kInfo:kMuted, borderRadius:BorderRadius.circular(99)));
}

class _ASBSection extends StatelessWidget {
  const _ASBSection({required this.label}); final String label;
  @override Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.fromLTRB(16,12,16,3),
    child:Text(label.toUpperCase(), overflow:TextOverflow.clip, softWrap:false,
      style:const TextStyle(color:kHint, fontSize:10, fontWeight:FontWeight.w500, letterSpacing:.7)));
}

class _ASBItem extends StatefulWidget {
  const _ASBItem({required this.icon, required this.label, required this.idx,
    required this.active, required this.collapsed, required this.onTap});
  final IconData icon; final String label; final int idx;
  final bool active, collapsed; final VoidCallback onTap;
  @override State<_ASBItem> createState() => _ASBItemState();
}
class _ASBItemState extends State<_ASBItem> {
  bool _h = false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast, height:40,
        clipBehavior: Clip.hardEdge,
        padding:EdgeInsets.symmetric(horizontal:widget.collapsed?0:14),
        decoration:BoxDecoration(
          color:widget.active?kBlueBg:(_h?kCard.withOpacity(.6):Colors.transparent),
          border:Border(left:BorderSide(color:widget.active?kBlue:Colors.transparent, width:2))),
        child:Row(mainAxisAlignment:widget.collapsed?MainAxisAlignment.center:MainAxisAlignment.start, children:[
          Icon(widget.icon, color:widget.active?kInfo:(_h?kText:kMuted), size:16),
          if(!widget.collapsed)...[
            const SizedBox(width:10),
            Flexible(child:Text(widget.label, overflow:TextOverflow.clip, softWrap:false,
              style:TextStyle(color:widget.active?kInfo:(_h?kText:kMuted), fontSize:12,
                fontWeight:widget.active?FontWeight.w500:FontWeight.w400))),
          ],
        ]),
      ),
    ),
  );
}

class _ALogoutBtn extends StatefulWidget {
  const _ALogoutBtn({required this.collapsed, required this.onTap});
  final bool collapsed; final VoidCallback onTap;
  @override State<_ALogoutBtn> createState() => _ALogoutBtnState();
}
class _ALogoutBtnState extends State<_ALogoutBtn> {
  bool _h=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast, height:38,
        clipBehavior: Clip.hardEdge,
        padding:const EdgeInsets.symmetric(horizontal:4),
        decoration:BoxDecoration(color:_h?kRedBg:Colors.transparent, borderRadius:BorderRadius.circular(6)),
        child:Row(mainAxisAlignment:widget.collapsed?MainAxisAlignment.center:MainAxisAlignment.start, children:[
          Icon(Icons.logout, color:_h?kRed:kRed.withOpacity(.7), size:16),
          if(!widget.collapsed)...[
            const SizedBox(width:10),
            Flexible(child:Text('Log Out', overflow:TextOverflow.clip, softWrap:false,
              style:TextStyle(color:_h?kRed:kRed.withOpacity(.7), fontSize:12))),
          ],
        ]),
      ),
    ),
  );
}

// ================================================================
// ADMIN TOPBAR
// ================================================================
class _AdminTopbar extends StatelessWidget {
  const _AdminTopbar({required this.title, required this.onLogout});
  final String title; final VoidCallback onLogout;

  @override Widget build(BuildContext context) => Container(
    height:56, padding:const EdgeInsets.symmetric(horizontal:20),
    decoration:const BoxDecoration(color:kBg2, border:Border(bottom:BorderSide(color:kBorder))),
    child:Row(children:[
      AnimatedSwitcher(duration:kNormal,
        child:Text(title, key:ValueKey(title),
          style:const TextStyle(color:kText, fontSize:14, fontWeight:FontWeight.w500))),
      const Spacer(),
      Container(
        padding:const EdgeInsets.fromLTRB(6,5,14,5),
        decoration:BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(99), border:Border.all(color:kBorder)),
        child:Row(mainAxisSize:MainAxisSize.min, children:[
          Container(width:26, height:26, decoration:const BoxDecoration(color:kBlueBg, shape:BoxShape.circle),
            child:const Icon(Icons.admin_panel_settings_outlined, color:kInfo, size:14)),
          const SizedBox(width:8),
          const Column(crossAxisAlignment:CrossAxisAlignment.start, mainAxisSize:MainAxisSize.min, children:[
            Text('Admin',               style:TextStyle(color:kText, fontSize:12, fontWeight:FontWeight.w500)),
            Text('Administrator',       style:TextStyle(color:kMuted, fontSize:10)),
          ]),
        ]),
      ),
    ]),
  );
}

// ================================================================
// VEHICLE FORM (inline add/edit)
// ================================================================
class _VehicleForm extends StatelessWidget {
  const _VehicleForm({
    required this.editing,
    required this.nameCtrl, required this.modelCtrl, required this.yearCtrl,
    required this.plateCtrl, required this.rateCtrl, required this.descCtrl,
    required this.category, required this.fuel, required this.transmission,
    required this.seats, required this.status, required this.imageSlots,
    required this.onCategoryChanged, required this.onFuelChanged,
    required this.onTransmissionChanged, required this.onSeatsChanged,
    required this.onStatusChanged, required this.onImageSlotTap,
    required this.onSave, required this.onCancel,
  });
  final bool editing;
  final TextEditingController nameCtrl, modelCtrl, yearCtrl, plateCtrl, rateCtrl, descCtrl;
  final String category, fuel, transmission, status;
  final int seats;
  final List<String> imageSlots;
  final ValueChanged<String> onCategoryChanged, onFuelChanged, onTransmissionChanged, onStatusChanged;
  final ValueChanged<int> onSeatsChanged;
  final ValueChanged<int> onImageSlotTap;
  final VoidCallback onSave, onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlue.withOpacity(.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(editing ? 'Edit Vehicle' : 'Add New Vehicle',
            style: const TextStyle(color:kText, fontSize:14, fontWeight:FontWeight.w500)),
          GestureDetector(onTap:onCancel,
            child: Container(width:28,height:28,
              decoration:BoxDecoration(color:kBlueBg,shape:BoxShape.circle,border:Border.all(color:kBorder)),
              child:const Icon(Icons.close,color:kMuted,size:14))),
        ]),
        const Divider(color:kBorder, height:24),

        // Row 1: Name + Model + Year + Plate
        Row(children: [
          Expanded(child: _FormField(label:'Vehicle Name *', ctrl:nameCtrl)),
          const SizedBox(width:12),
          Expanded(child: _FormField(label:'Model Variant *', ctrl:modelCtrl)),
          const SizedBox(width:12),
          SizedBox(width:100, child: _FormField(label:'Year *', ctrl:yearCtrl, keyboard:TextInputType.number)),
          const SizedBox(width:12),
          SizedBox(width:140, child: _FormField(label:'Plate Number *', ctrl:plateCtrl)),
        ]),
        const SizedBox(height:12),

        // Row 2: Category + Fuel + Transmission + Seats + Daily Rate
        Row(children: [
          Expanded(child: _DropField(label:'Category', value:category,
            items:const ['Sedan','SUV','Hatchback','Van','Truck'],
            onChanged:onCategoryChanged)),
          const SizedBox(width:12),
          Expanded(child: _DropField(label:'Fuel Type', value:fuel,
            items:const ['Gasoline','Diesel','Electric','Hybrid'],
            onChanged:onFuelChanged)),
          const SizedBox(width:12),
          Expanded(child: _DropField(label:'Transmission', value:transmission,
            items:const ['Automatic','Manual','CVT'],
            onChanged:onTransmissionChanged)),
          const SizedBox(width:12),
          SizedBox(width:110, child: _DropField(label:'Seats', value:seats.toString(),
            items:const ['2','4','5','7','8','12'],
            onChanged:(v) => onSeatsChanged(int.tryParse(v) ?? 5))),
          const SizedBox(width:12),
          SizedBox(width:140, child: _FormField(label:'Daily Rate (₱) *', ctrl:rateCtrl, keyboard:TextInputType.number)),
          const SizedBox(width:12),
          Expanded(child: _DropField(label:'Status', value:status,
            items:const ['available','rented','maintenance','inactive'],
            onChanged:onStatusChanged)),
        ]),
        const SizedBox(height:12),

        // Description
        _FormField(label:'Description (optional)', ctrl:descCtrl),
        const SizedBox(height:16),

        // Image upload slots
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('VEHICLE PHOTOS', style:TextStyle(color:kMuted, fontSize:10, fontWeight:FontWeight.w500, letterSpacing:.4)),
            SizedBox(width:8),
            Text('(Front, Side, Rear, Interior)', style:TextStyle(color:kHint, fontSize:10)),
          ]),
          const SizedBox(height:4),
          const Text(
            'TODO: Connect to file_picker package + POST /api/admin/vehicles/{id}/images',
            style: TextStyle(color:kHint, fontSize:10, fontStyle:FontStyle.italic)),
          const SizedBox(height:10),
          Row(children: ['Front','Side','Rear','Interior'].asMap().map((i, label) =>
            MapEntry(i, Expanded(child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
              child: _ImageSlot(
                label: label,
                hasImage: imageSlots[i].isNotEmpty,
                imageName: imageSlots[i],
                onTap: () => onImageSlotTap(i),
              ),
            )))
          ).values.toList()),
        ]),
        const SizedBox(height:18),

        // Actions
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _AOutlineBtn(label:'Cancel', onTap:onCancel),
          const SizedBox(width:10),
          _APrimaryBtn(label: editing ? 'Save Changes' : 'Add Vehicle', onTap:onSave),
        ]),
      ]),
    );
  }
}

// ── Image upload slot ─────────────────────────────────────────────
class _ImageSlot extends StatefulWidget {
  const _ImageSlot({required this.label, required this.hasImage,
    required this.imageName, required this.onTap});
  final String label, imageName;
  final bool hasImage;
  final VoidCallback onTap;
  @override State<_ImageSlot> createState() => _ImageSlotState();
}
class _ImageSlotState extends State<_ImageSlot> {
  bool _h = false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast,
        height:90,
        decoration:BoxDecoration(
          color: widget.hasImage ? kGreenBg : (_h ? kBlueBg : kInput),
          borderRadius:BorderRadius.circular(8),
          border:Border.all(
            color: widget.hasImage ? kGreenBdr : (_h ? kBlue : kInputBdr),
            style: widget.hasImage ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
          Icon(
            widget.hasImage ? Icons.check_circle_outline : Icons.add_photo_alternate_outlined,
            color: widget.hasImage ? kGreen : (_h?kBlue:kHint), size:24),
          const SizedBox(height:6),
          Text(widget.label, style:TextStyle(
            color:widget.hasImage?kGreen:(_h?kBlue:kHint), fontSize:11, fontWeight:FontWeight.w500)),
          if(widget.hasImage)
            Padding(padding:const EdgeInsets.symmetric(horizontal:6, vertical:2),
              child:Text(widget.imageName, style:const TextStyle(color:kGreen, fontSize:9),
                overflow:TextOverflow.ellipsis, maxLines:1)),
        ]),
      ),
    ),
  );
}

// ── Vehicle card (fleet grid) ─────────────────────────────────────
class _VehicleCard extends StatefulWidget {
  const _VehicleCard({required this.vehicle, required this.onEdit,
    required this.onDelete, required this.onStatusChange});
  final AdminVehicle vehicle;
  final VoidCallback onEdit, onDelete;
  final ValueChanged<String> onStatusChange;
  @override State<_VehicleCard> createState() => _VehicleCardState();
}
class _VehicleCardState extends State<_VehicleCard> {
  bool _h = false;

  Color _sc(String s) { switch(s) { case'available':return kGreen; case'rented':return kAmber; case'maintenance':return kRed; default:return kMuted; }}
  Color _sb(String s) { switch(s) { case'available':return kGreenBg; case'rented':return kAmberBg; case'maintenance':return kRedBg; default:return kCard; }}
  Color _sd(String s) { switch(s) { case'available':return kGreenBdr; case'rented':return kAmberBdr; case'maintenance':return kRedBdr; default:return kBorder; }}

  @override Widget build(BuildContext context) {
    final v = widget.vehicle;
    return MouseRegion(
      onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
      child:AnimatedContainer(duration:kFast,
        decoration:BoxDecoration(
          color:kCard, borderRadius:BorderRadius.circular(12),
          border:Border.all(color:_h?kBlue.withOpacity(.4):kBorder),
          boxShadow:_h?[BoxShadow(color:kBlue.withOpacity(.06), blurRadius:12, offset:const Offset(0,4))]:const [],
        ),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          // Image area
          Container(
            height:110,
            decoration:BoxDecoration(
              color:kBlueBg,
              borderRadius:const BorderRadius.vertical(top:Radius.circular(11))),
            child: v.imageUrls.isEmpty
              // TODO: replace with Image.network(v.imageUrls[0]) once API connected
              ? Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
                  const Icon(Icons.directions_car, color:kHint, size:48),
                  const SizedBox(height:4),
                  const Text('No photos', style:TextStyle(color:kHint, fontSize:10)),
                ]))
              : ClipRRect(
                  borderRadius:const BorderRadius.vertical(top:Radius.circular(11)),
                  // TODO: Image.network(v.imageUrls[0], fit:BoxFit.cover)
                  child:Container(color:kBlueBg,
                    child:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
                      Icon(Icons.image_outlined, color:kBlue.withOpacity(.4), size:32),
                      Text('${v.imageUrls.length} photo${v.imageUrls.length>1?"s":""}',
                        style:const TextStyle(color:kMuted, fontSize:10)),
                    ])))),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(padding:const EdgeInsets.all(12), child:Column(
            crossAxisAlignment:CrossAxisAlignment.start, children:[
            // Status badge
            Container(
              padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
              decoration:BoxDecoration(color:_sb(v.status), borderRadius:BorderRadius.circular(99), border:Border.all(color:_sd(v.status))),
              child:Text(v.status[0].toUpperCase()+v.status.substring(1),
                style:TextStyle(color:_sc(v.status), fontSize:10, fontWeight:FontWeight.w500))),
            const SizedBox(height:7),
            Text(v.name, style:const TextStyle(color:kText, fontSize:13, fontWeight:FontWeight.w600)),
            Text('${v.model} · ${v.year}', style:const TextStyle(color:kMuted, fontSize:11),
              overflow: TextOverflow.ellipsis),
            const SizedBox(height:3),
            Text('₱${v.dailyRate.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m)=>"${m[1]},")} / day',
              style:const TextStyle(color:kBlue, fontSize:12, fontWeight:FontWeight.w600)),
            const SizedBox(height:2),
            Text('${v.category} · ${v.seats} seats · ${v.fuel}',
              style:const TextStyle(color:kHint, fontSize:10), overflow: TextOverflow.ellipsis),
            Text('Plate: ${v.plateNumber}', style:const TextStyle(color:kHint, fontSize:10)),
            const SizedBox(height:9),

            // Action buttons
            Row(children:[
              Expanded(child:_ASmallBtn(label:'Edit', icon:Icons.edit_outlined, onTap:widget.onEdit)),
              const SizedBox(width:6),
              Expanded(child:_ASmallBtn(label:'Delete', icon:Icons.delete_outline, onTap:widget.onDelete, danger:true)),
            ]),
            const SizedBox(height:6),

            // Status change dropdown
            Container(
              height:34, padding:const EdgeInsets.symmetric(horizontal:10),
              decoration:BoxDecoration(color:kInput, borderRadius:BorderRadius.circular(8), border:Border.all(color:kInputBdr)),
              child:DropdownButtonHideUnderline(child:DropdownButton<String>(
                value:v.status, isExpanded:true,
                dropdownColor:kCard, style:const TextStyle(color:kText,fontSize:11),
                iconEnabledColor:kMuted, iconSize:16,
                items:const [
                  DropdownMenuItem(value:'available',   child:Text('Available')),
                  DropdownMenuItem(value:'rented',      child:Text('Rented')),
                  DropdownMenuItem(value:'maintenance', child:Text('Maintenance')),
                  DropdownMenuItem(value:'inactive',    child:Text('Inactive')),
                ],
                onChanged:(s) { if(s!=null) widget.onStatusChange(s); },
              )),
            ),
          ]))), // Column, Padding, SingleChildScrollView
          ), // Expanded
        ]),
      ),
    );
  }
}

// ── Booking row (shared between dashboard and bookings page) ──────
class _AdminBookingRow extends StatefulWidget {
  const _AdminBookingRow({required this.booking,
    this.tableStyle = false,
    this.statusColor, this.statusBg, this.statusBdr,
    this.onConfirm, this.onComplete, this.onCancel});
  final AdminBooking booking;
  final bool tableStyle;
  final Color? statusColor, statusBg, statusBdr;
  final VoidCallback? onConfirm, onComplete, onCancel;
  @override State<_AdminBookingRow> createState() => _AdminBookingRowState();
}
class _AdminBookingRowState extends State<_AdminBookingRow> {
  bool _h = false;

  Color _sc(String s) { switch(s) { case'Confirmed':return kGreen; case'Pending':return kAmber; case'Active':return kBlue; case'Completed':return kInfo; default:return kRed; }}
  Color _sb(String s) { switch(s) { case'Confirmed':return kGreenBg; case'Pending':return kAmberBg; case'Active':return kBlueBg; case'Completed':return kInfoBg; default:return kRedBg; }}
  Color _sd(String s) { switch(s) { case'Confirmed':return kGreenBdr; case'Pending':return kAmberBdr; case'Active':return kInfoBdr; case'Completed':return kInfoBdr; default:return kRedBdr; }}

  @override Widget build(BuildContext context) {
    final b = widget.booking;
    final sc = widget.statusColor ?? _sc(b.status);
    final sb = widget.statusBg   ?? _sb(b.status);
    final sd = widget.statusBdr  ?? _sd(b.status);

    if (widget.tableStyle) {
      return MouseRegion(
        onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
        child:AnimatedContainer(duration:kFast,
          decoration:BoxDecoration(
            color:_h?kCard.withOpacity(.6):kCard,
            border:Border(
              left:BorderSide(color:kBorder), right:BorderSide(color:kBorder),
              bottom:BorderSide(color:kBorder))),
          child:Padding(padding:const EdgeInsets.symmetric(horizontal:14, vertical:10),
            child:Row(children:[
              Expanded(flex:3, child:Text(b.id, style:const TextStyle(color:kText,fontSize:11,fontWeight:FontWeight.w500), overflow:TextOverflow.ellipsis)),
              Expanded(flex:3, child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(b.customerName, style:const TextStyle(color:kText,fontSize:12,fontWeight:FontWeight.w500)),
                Text(b.customerEmail, style:const TextStyle(color:kMuted,fontSize:10), overflow:TextOverflow.ellipsis),
              ])),
              Expanded(flex:3, child:Text(b.vehicleName, style:const TextStyle(color:kMuted,fontSize:11), overflow:TextOverflow.ellipsis)),
              Expanded(flex:2, child:Text('${b.pickupDate} – ${b.returnDate}', style:const TextStyle(color:kHint,fontSize:10))),
              Expanded(flex:2, child:Text('₱${b.totalFee.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m)=>"${m[1]},")}',
                style:const TextStyle(color:kText,fontSize:12,fontWeight:FontWeight.w600))),
              Expanded(flex:2, child:Container(
                padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
                decoration:BoxDecoration(color:sb, borderRadius:BorderRadius.circular(99), border:Border.all(color:sd)),
                child:Text(b.status, style:TextStyle(color:sc,fontSize:10,fontWeight:FontWeight.w500)))),
              Expanded(flex:2, child:Row(children:[
                if(widget.onConfirm != null)  _AIconBtn(icon:Icons.check, color:kGreen, onTap:widget.onConfirm!),
                if(widget.onComplete != null) _AIconBtn(icon:Icons.done_all, color:kBlue, onTap:widget.onComplete!),
                if(widget.onCancel != null)   _AIconBtn(icon:Icons.close, color:kRed, onTap:widget.onCancel!),
              ])),
            ]),
          ),
        ),
      );
    }

    // Card style (dashboard)
    return MouseRegion(
      onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
      child:AnimatedContainer(duration:kFast,
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(
          color:kCard, borderRadius:BorderRadius.circular(10),
          border:Border.all(color:_h?kBlue.withOpacity(.3):kBorder)),
        child:Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(b.id, style:const TextStyle(color:kText,fontSize:11,fontWeight:FontWeight.w500)),
            Text('${b.customerName} · ${b.vehicleName}', style:const TextStyle(color:kMuted,fontSize:11)),
            Text('${b.pickupDate} – ${b.returnDate} · ₱${b.totalFee.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m)=>"${m[1]},")}',
              style:const TextStyle(color:kHint,fontSize:10)),
          ])),
          Container(
            margin:const EdgeInsets.only(left:8),
            padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
            decoration:BoxDecoration(color:sb, borderRadius:BorderRadius.circular(99), border:Border.all(color:sd)),
            child:Text(b.status, style:TextStyle(color:sc,fontSize:10,fontWeight:FontWeight.w500))),
          if(widget.onConfirm != null)  Padding(padding:const EdgeInsets.only(left:6), child:_AIconBtn(icon:Icons.check, color:kGreen, onTap:widget.onConfirm!)),
          if(widget.onComplete != null) Padding(padding:const EdgeInsets.only(left:6), child:_AIconBtn(icon:Icons.done_all, color:kBlue, onTap:widget.onComplete!)),
          if(widget.onCancel != null)   Padding(padding:const EdgeInsets.only(left:6), child:_AIconBtn(icon:Icons.close, color:kRed, onTap:widget.onCancel!)),
        ]),
      ),
    );
  }
}

// ── Customer row ──────────────────────────────────────────────────
class _CustomerRow extends StatefulWidget {
  const _CustomerRow({required this.customer, required this.onToggleStatus, required this.onViewBookings});
  final AdminCustomer customer;
  final VoidCallback onToggleStatus, onViewBookings;
  @override State<_CustomerRow> createState() => _CustomerRowState();
}
class _CustomerRowState extends State<_CustomerRow> {
  bool _h=false;
  @override Widget build(BuildContext context) {
    final c = widget.customer;
    final active = c.status == 'active';
    return MouseRegion(
      onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
      child:AnimatedContainer(duration:kFast,
        padding:const EdgeInsets.all(14),
        decoration:BoxDecoration(
          color:kCard, borderRadius:BorderRadius.circular(10),
          border:Border.all(color:_h?kBlue.withOpacity(.3):kBorder)),
        child:Row(children:[
          CircleAvatar(radius:20, backgroundColor:kBlueBg,
            child:Text('${c.firstName[0]}${c.lastName[0]}',
              style:const TextStyle(color:kInfo, fontSize:12, fontWeight:FontWeight.w600))),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('${c.firstName} ${c.lastName}', style:const TextStyle(color:kText,fontSize:13,fontWeight:FontWeight.w500)),
            Text(c.email, style:const TextStyle(color:kMuted,fontSize:11)),
            Text('${c.phone} · License: ${c.licenseNo}', style:const TextStyle(color:kHint,fontSize:10)),
          ])),
          Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
            Container(
              padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
              decoration:BoxDecoration(
                color:active?kGreenBg:kRedBg,
                borderRadius:BorderRadius.circular(99),
                border:Border.all(color:active?kGreenBdr:kRedBdr)),
              child:Text(c.status[0].toUpperCase()+c.status.substring(1),
                style:TextStyle(color:active?kGreen:kRed, fontSize:10,fontWeight:FontWeight.w500))),
            const SizedBox(height:4),
            Text('${c.totalBookings} booking${c.totalBookings!=1?"s":""}', style:const TextStyle(color:kHint,fontSize:10)),
            Text('Since ${c.memberSince}', style:const TextStyle(color:kHint,fontSize:10)),
          ]),
          const SizedBox(width:12),
          Column(children:[
            _ASmallBtn(label:'Bookings', icon:Icons.list_alt_outlined, onTap:widget.onViewBookings),
            const SizedBox(height:6),
            _ASmallBtn(
              label: active ? 'Suspend' : 'Activate',
              icon:  active ? Icons.block_outlined : Icons.check_circle_outline,
              onTap: widget.onToggleStatus,
              danger: active,
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Fleet status summary card ─────────────────────────────────────
class _FleetStatusCard extends StatelessWidget {
  const _FleetStatusCard({required this.vehicles});
  final List<AdminVehicle> vehicles;

  @override Widget build(BuildContext context) {
    final avail = vehicles.where((v)=>v.status=='available').length;
    final rented = vehicles.where((v)=>v.status=='rented').length;
    final maint  = vehicles.where((v)=>v.status=='maintenance').length;
    final total  = vehicles.length;

    return Container(
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(10), border:Border.all(color:kBorder)),
      child:Column(children:[
        _FleetBar(label:'Available',   count:avail,  total:total, color:kGreen),
        const SizedBox(height:8),
        _FleetBar(label:'Rented',      count:rented, total:total, color:kAmber),
        const SizedBox(height:8),
        _FleetBar(label:'Maintenance', count:maint,  total:total, color:kRed),
      ]),
    );
  }
}

class _FleetBar extends StatelessWidget {
  const _FleetBar({required this.label, required this.count, required this.total, required this.color});
  final String label; final int count, total; final Color color;
  @override Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(children:[
      SizedBox(width:80, child:Text(label, style:const TextStyle(color:kMuted,fontSize:11))),
      Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(99),
        child:LinearProgressIndicator(value:pct, backgroundColor:kBg, color:color, minHeight:6))),
      const SizedBox(width:8),
      Text('$count', style:TextStyle(color:color,fontSize:12,fontWeight:FontWeight.w600)),
    ]);
  }
}

// ── Quick action row ──────────────────────────────────────────────
class _AQuickAction extends StatefulWidget {
  const _AQuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override State<_AQuickAction> createState() => _AQuickActionState();
}
class _AQuickActionState extends State<_AQuickAction> {
  bool _h=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast,
        margin:const EdgeInsets.only(bottom:6),
        padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
        decoration:BoxDecoration(
          color:_h?kBlueBg:kCard, borderRadius:BorderRadius.circular(8),
          border:Border.all(color:_h?kBlue:kBorder)),
        child:Row(children:[
          Icon(widget.icon, color:_h?kBlue:kMuted, size:15),
          const SizedBox(width:10),
          Text(widget.label, style:TextStyle(color:_h?kText:kMuted, fontSize:12)),
          const Spacer(),
          Icon(Icons.chevron_right, color:_h?kBlue:kHint, size:15),
        ]),
      ),
    ),
  );
}

// ── Report card ───────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.rows});
  final String title; final List<_ReportRow> rows;
  @override Widget build(BuildContext context) => Container(
    padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(12), border:Border.all(color:kBorder)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title, style:const TextStyle(color:kText,fontSize:13,fontWeight:FontWeight.w500)),
      const Divider(color:kBorder, height:18),
      ...rows.map((r) => Padding(padding:const EdgeInsets.only(bottom:8),
        child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text(r.label, style:const TextStyle(color:kMuted,fontSize:12)),
          Text(r.value, style:TextStyle(color:r.color, fontSize:13,fontWeight:FontWeight.w600)),
        ]))),
    ]),
  );
}
class _ReportRow { const _ReportRow({required this.label, required this.value, required this.color}); final String label,value; final Color color; }

// ── Settings card ─────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});
  final String title; final List<Widget> children;
  @override Widget build(BuildContext context) => Container(
    padding:const EdgeInsets.all(20), margin:const EdgeInsets.only(bottom:14),
    decoration:BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(12), border:Border.all(color:kBorder)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title, style:const TextStyle(color:kText,fontSize:13,fontWeight:FontWeight.w500)),
      const Divider(color:kBorder, height:18),
      ...children,
    ]),
  );
}

// ── Confirm dialog ────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.title, required this.message,
    required this.confirmLabel, required this.onConfirm, this.danger=false});
  final String title, message, confirmLabel;
  final VoidCallback onConfirm;
  final bool danger;
  @override Widget build(BuildContext context) => Dialog(
    backgroundColor:kCard,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:const BorderSide(color:kBorder)),
    child:Container(width:360, padding:const EdgeInsets.all(24),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        Container(width:52,height:52,
          decoration:BoxDecoration(color:danger?kRedBg:kBlueBg, shape:BoxShape.circle,
            border:Border.all(color:danger?kRedBdr:kInfoBdr)),
          child:Icon(danger?Icons.warning_amber_outlined:Icons.help_outline,
            color:danger?kRed:kInfo, size:22)),
        const SizedBox(height:14),
        Text(title, style:const TextStyle(color:kText,fontSize:15,fontWeight:FontWeight.w500)),
        const SizedBox(height:8),
        Text(message, textAlign:TextAlign.center, style:const TextStyle(color:kMuted,fontSize:12,height:1.6)),
        const SizedBox(height:20),
        Row(children:[
          Expanded(child:OutlinedButton(
            onPressed:()=>Navigator.pop(context),
            style:OutlinedButton.styleFrom(side:const BorderSide(color:kBorder),foregroundColor:kMuted,
              shape:const StadiumBorder(), padding:const EdgeInsets.symmetric(vertical:10)),
            child:const Text('Cancel'))),
          const SizedBox(width:10),
          Expanded(child:ElevatedButton(
            onPressed:onConfirm,
            style:ElevatedButton.styleFrom(
              backgroundColor:danger?kRedBg:kBlue, foregroundColor:danger?kRed:kText,
              shape:const StadiumBorder(), elevation:0,
              side:BorderSide(color:danger?kRedBdr:kBlue),
              padding:const EdgeInsets.symmetric(vertical:10)),
            child:Text(confirmLabel, style:const TextStyle(fontWeight:FontWeight.w600)))),
        ]),
      ]),
    ),
  );
}

// ================================================================
// Shared small widgets
// ================================================================

class _ASectionHeader extends StatelessWidget {
  const _ASectionHeader({required this.title, this.linkText, this.onLink});
  final String title; final String? linkText; final VoidCallback? onLink;
  @override Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.only(bottom:10),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(title, style:const TextStyle(color:kText,fontSize:13,fontWeight:FontWeight.w500)),
      if(linkText!=null) MouseRegion(cursor:SystemMouseCursors.click,
        child:GestureDetector(onTap:onLink,
          child:Text(linkText!, style:const TextStyle(color:kBlue,fontSize:11)))),
    ]));
}

class _AStatCard extends StatefulWidget {
  const _AStatCard({required this.label, required this.value, required this.icon,
    this.sub, this.valueColor});
  final String label, value; final IconData icon;
  final String? sub; final Color? valueColor;
  @override State<_AStatCard> createState() => _AStatCardState();
}
class _AStatCardState extends State<_AStatCard> {
  bool _h=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    child:AnimatedContainer(duration:kFast,
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        color:_h?kCard.withOpacity(.95):kCard, borderRadius:BorderRadius.circular(12),
        border:Border.all(color:_h?kBlue.withOpacity(.4):kBorder),
        boxShadow:_h?[BoxShadow(color:kBlue.withOpacity(.06),blurRadius:12,offset:const Offset(0,4))]:const[]),
      child:Row(children:[
        Container(width:38,height:38,
          decoration:BoxDecoration(color:kBlueBg, borderRadius:BorderRadius.circular(9), border:Border.all(color:kBorder)),
          child:Icon(widget.icon, color:widget.valueColor??kBlue, size:18)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(widget.label, style:const TextStyle(color:kMuted,fontSize:11)),
          const SizedBox(height:2),
          Text(widget.value, style:TextStyle(color:widget.valueColor??kText, fontSize:18,fontWeight:FontWeight.w600)),
          if(widget.sub!=null) Text(widget.sub!, style:const TextStyle(color:kHint,fontSize:10)),
        ])),
      ]),
    ),
  );
}

class _AFilterChip extends StatefulWidget {
  const _AFilterChip({required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback onTap;
  @override State<_AFilterChip> createState() => _AFilterChipState();
}
class _AFilterChipState extends State<_AFilterChip> {
  bool _h=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast,
        padding:const EdgeInsets.symmetric(horizontal:14,vertical:5),
        decoration:BoxDecoration(
          color:widget.selected?kBlueBg:(_h?kCard.withOpacity(.8):kCard),
          borderRadius:BorderRadius.circular(99),
          border:Border.all(color:widget.selected?kBlue:(_h?kMuted.withOpacity(.6):kBorder))),
        child:Text(widget.label, style:TextStyle(
          color:widget.selected?kInfo:(_h?kText:kMuted), fontSize:11,
          fontWeight:widget.selected?FontWeight.w500:FontWeight.w400)))));
}

class _APrimaryBtn extends StatefulWidget {
  const _APrimaryBtn({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override State<_APrimaryBtn> createState() => _APrimaryBtnState();
}
class _APrimaryBtnState extends State<_APrimaryBtn> {
  bool _h=false, _p=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_){setState(()=>_h=false);setState(()=>_p=false);},
    cursor:SystemMouseCursors.click,
    child:GestureDetector(
      onTapDown:(_)=>setState(()=>_p=true),
      onTapUp:(_){setState(()=>_p=false);widget.onTap();},
      onTapCancel:()=>setState(()=>_p=false),
      child:AnimatedScale(scale:_p?0.96:1.0, duration:kFast,
        child:AnimatedContainer(duration:kFast,
          padding:const EdgeInsets.symmetric(horizontal:18,vertical:9),
          decoration:BoxDecoration(color:_h?kBlue2:kBlue, borderRadius:BorderRadius.circular(8)),
          child:Text(widget.label, style:const TextStyle(color:kText,fontSize:12,fontWeight:FontWeight.w600))))));
}

class _AOutlineBtn extends StatefulWidget {
  const _AOutlineBtn({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override State<_AOutlineBtn> createState() => _AOutlineBtnState();
}
class _AOutlineBtnState extends State<_AOutlineBtn> {
  bool _h=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast,
        padding:const EdgeInsets.symmetric(horizontal:18,vertical:9),
        decoration:BoxDecoration(
          color:_h?kCard:Colors.transparent, borderRadius:BorderRadius.circular(8),
          border:Border.all(color:_h?kMuted.withOpacity(.6):kBorder)),
        child:Text(widget.label, style:TextStyle(color:_h?kText:kMuted, fontSize:12)))));
}

class _ASmallBtn extends StatefulWidget {
  const _ASmallBtn({required this.label, required this.icon, required this.onTap, this.danger=false});
  final String label; final IconData icon; final VoidCallback onTap; final bool danger;
  @override State<_ASmallBtn> createState() => _ASmallBtnState();
}
class _ASmallBtnState extends State<_ASmallBtn> {
  bool _h=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast,
        padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),
        decoration:BoxDecoration(
          color:_h?(widget.danger?kRedBg:kBlueBg):kInput,
          borderRadius:BorderRadius.circular(6),
          border:Border.all(color:_h?(widget.danger?kRedBdr:kBlue):kInputBdr)),
        child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(widget.icon, color:_h?(widget.danger?kRed:kInfo):kMuted, size:12),
          const SizedBox(width:4),
          Text(widget.label, style:TextStyle(color:_h?(widget.danger?kRed:kInfo):kMuted, fontSize:11)),
        ]))));
}

class _AIconBtn extends StatefulWidget {
  const _AIconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon; final Color color; final VoidCallback onTap;
  @override State<_AIconBtn> createState() => _AIconBtnState();
}
class _AIconBtnState extends State<_AIconBtn> {
  bool _h=false;
  @override Widget build(BuildContext context) => MouseRegion(
    onEnter:(_)=>setState(()=>_h=true), onExit:(_)=>setState(()=>_h=false),
    cursor:SystemMouseCursors.click,
    child:GestureDetector(onTap:widget.onTap,
      child:AnimatedContainer(duration:kFast, width:28, height:28,
        decoration:BoxDecoration(
          color:_h?widget.color.withOpacity(.15):Colors.transparent,
          borderRadius:BorderRadius.circular(6),
          border:Border.all(color:_h?widget.color.withOpacity(.4):Colors.transparent)),
        child:Icon(widget.icon, color:_h?widget.color:widget.color.withOpacity(.6), size:14))));
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});
  final TextEditingController controller; final String hint;
  @override Widget build(BuildContext context) => Container(
    height:38,
    decoration:BoxDecoration(color:kInput, borderRadius:BorderRadius.circular(8), border:Border.all(color:kInputBdr)),
    child:TextField(
      controller:controller,
      style:const TextStyle(color:kText, fontSize:12),
      decoration:InputDecoration(
        hintText:hint, hintStyle:const TextStyle(color:kHint,fontSize:12),
        border:InputBorder.none, prefixIcon:const Icon(Icons.search_outlined, color:kHint, size:16),
        contentPadding:const EdgeInsets.symmetric(vertical:10)),
      cursorColor:kBlue),
  );
}

class _FormField extends StatefulWidget {
  const _FormField({required this.label, required this.ctrl, this.keyboard, this.obscure=false});
  final String label; final TextEditingController ctrl;
  final TextInputType? keyboard; final bool obscure;
  @override State<_FormField> createState() => _FormFieldState();
}
class _FormFieldState extends State<_FormField> {
  bool _vis=false, _focused=false;
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment:CrossAxisAlignment.start, children:[
    Text(widget.label.toUpperCase(), style:const TextStyle(color:kMuted,fontSize:10,fontWeight:FontWeight.w500,letterSpacing:.4)),
    const SizedBox(height:4),
    Focus(onFocusChange:(f)=>setState(()=>_focused=f),
      child:AnimatedContainer(duration:kFast, height:40,
        decoration:BoxDecoration(color:kInput, borderRadius:BorderRadius.circular(8),
          border:Border.all(color:_focused?kBlue:kInputBdr)),
        child:TextField(
          controller:widget.ctrl, keyboardType:widget.keyboard,
          obscureText:widget.obscure&&!_vis,
          style:const TextStyle(color:kText,fontSize:12),
          decoration:InputDecoration(border:InputBorder.none,
            contentPadding:const EdgeInsets.symmetric(horizontal:12),
            suffixIcon:widget.obscure?IconButton(
              icon:Icon(_vis?Icons.visibility_off_outlined:Icons.visibility_outlined, color:kMuted,size:16),
              onPressed:()=>setState(()=>_vis=!_vis)):null),
          cursorColor:kBlue))),
  ]);
}

class _DropField extends StatelessWidget {
  const _DropField({required this.label, required this.value, required this.items, required this.onChanged});
  final String label, value; final List<String> items; final ValueChanged<String> onChanged;
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment:CrossAxisAlignment.start, children:[
    Text(label.toUpperCase(), style:const TextStyle(color:kMuted,fontSize:10,fontWeight:FontWeight.w500,letterSpacing:.4)),
    const SizedBox(height:4),
    Container(height:40, padding:const EdgeInsets.symmetric(horizontal:12),
      decoration:BoxDecoration(color:kInput, borderRadius:BorderRadius.circular(8), border:Border.all(color:kInputBdr)),
      child:DropdownButtonHideUnderline(child:DropdownButton<String>(
        value:value, isExpanded:true,
        dropdownColor:kCard, style:const TextStyle(color:kText,fontSize:12),
        iconEnabledColor:kMuted, iconSize:16,
        items:items.map((i)=>DropdownMenuItem(value:i,child:Text(i))).toList(),
        onChanged:(v){if(v!=null)onChanged(v);}))),
  ]);
}