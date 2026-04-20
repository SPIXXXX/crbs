// ================================================================
// lib/pages/customer_page.dart
// DRIVO — Car Rental Booking System
// Customer Dashboard — Flutter Web
// v2 — Added animations, hover effects, and polished transitions
// ================================================================

import 'package:flutter/material.dart';
import 'login_page.dart'; // LoginPage — navigated to on logout
// ── Color constants ──────────────────────────────────────────────
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

const kSidebarFull = 220.0;
const kSidebarMini = 52.0;

// ── Duration constants ───────────────────────────────────────────
const kFast   = Duration(milliseconds: 150);
const kNormal = Duration(milliseconds: 250);
const kSlow   = Duration(milliseconds: 400);
const kPage   = Duration(milliseconds: 320);

// ── Models ───────────────────────────────────────────────────────
class Booking {
  final String id, vehicle, category, dateStart, dateEnd;
  final int days, fee;
  String status;
  Booking({required this.id, required this.vehicle, required this.category,
    required this.dateStart, required this.dateEnd,
    required this.days, required this.fee, required this.status});
}

// TODO: Replace with API response model from Laravel GET /api/vehicles
class Vehicle {
  final String name, model, year, category, fuel, transmission, plate, status;
  final int seats, rate;
  const Vehicle({required this.name, required this.model, required this.year,
    required this.category, required this.seats, required this.fuel,
    required this.transmission, required this.rate,
    required this.plate, required this.status});
}

class AppNotif {
  final String icon, title, message, time;
  final Color iconBg, iconColor;
  bool read;
  AppNotif({required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.message, required this.time, this.read = false});
}

// ================================================================
// CustomerPage
// ================================================================
class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});
  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage>
    with TickerProviderStateMixin {

  // ── Sidebar ──────────────────────────────────────────────────
  bool _sidebarCollapsed = false;

  // ── Active page ───────────────────────────────────────────────
  int _activePage = 0;

  // ── Page transition controller ────────────────────────────────
  late AnimationController _pageCtrl;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;

  // ── Dashboard entrance controller ────────────────────────────
  late AnimationController _dashCtrl;
  late Animation<double>   _dashFade;
  late Animation<Offset>   _dashSlide;

  // ── Data ─────────────────────────────────────────────────────
  final List<Booking> _bookings = [
    Booking(id:'DRIVO-20260318-A1B2', vehicle:'Toyota Vios 2023',   category:'Sedan',     dateStart:'Mar 18', dateEnd:'Mar 24', days:6, fee:7200,  status:'Confirmed'),
    Booking(id:'DRIVO-20260325-B2C3', vehicle:'Toyota Fortuner',    category:'SUV',       dateStart:'Mar 25', dateEnd:'Mar 28', days:3, fee:7200,  status:'Pending'),
    Booking(id:'DRIVO-20260310-C3D4', vehicle:'Mitsubishi Xpander', category:'SUV',       dateStart:'Mar 10', dateEnd:'Mar 13', days:3, fee:5100,  status:'Completed'),
    Booking(id:'DRIVO-20260301-E5F6', vehicle:'Honda City',         category:'Sedan',     dateStart:'Mar 1',  dateEnd:'Mar 3',  days:2, fee:3000,  status:'Cancelled'),
    Booking(id:'DRIVO-20260215-F6G7', vehicle:'Honda Jazz',         category:'Hatchback', dateStart:'Feb 15', dateEnd:'Feb 17', days:2, fee:2200,  status:'Completed'),
  ];

  // TODO: Replace with real API call — GET /api/vehicles
  List<Vehicle> _vehicles = [];
  bool   _vehiclesLoading = false;

  final List<AppNotif> _notifs = [
    AppNotif(icon:'C', iconBg:kGreenBg, iconColor:kGreen, title:'Booking Confirmed',  message:'DRIVO-20260318-A1B2 for Toyota Vios confirmed.',         time:'2 hours ago'),
    AppNotif(icon:'R', iconBg:kAmberBg, iconColor:kAmber, title:'Return Reminder',    message:'Your Toyota Vios rental ends on Mar 24.',                 time:'Yesterday'),
    AppNotif(icon:'P', iconBg:kInfoBg,  iconColor:kInfo,  title:'Booking Received',   message:'DRIVO-20260325-B2C3 is pending confirmation.',            time:'Mar 20'),
    AppNotif(icon:'D', iconBg:kCard,    iconColor:kMuted,  title:'Booking Completed', message:'Xpander rental Mar 10–13 completed.',                     time:'Mar 13', read:true),
  ];

  // ── Book form ────────────────────────────────────────────────
  final _firstNameCtrl = TextEditingController(text:'Juan');
  final _lastNameCtrl  = TextEditingController(text:'dela Cruz');
  final _emailCtrl     = TextEditingController(text:'juan@email.com');
  final _phoneCtrl     = TextEditingController(text:'+63 917 123 4567');
  final _locationCtrl  = TextEditingController();
  String?   _selectedVehicleKey;
  DateTime? _pickupDate;
  DateTime? _returnDate;

  // ── Filters ──────────────────────────────────────────────────
  String _bookingFilter = 'all';
  String _vehicleFilter = 'all';

  // ── Vehicles showcase ────────────────────────────────────────
  int  _showcaseIdx = 0;
  bool _detailOpen  = false;
  int  _thumbIdx    = 0;

  // ── Profile ──────────────────────────────────────────────────
  final _profFirstCtrl = TextEditingController(text:'Juan');
  final _profLastCtrl  = TextEditingController(text:'dela Cruz');
  final _profEmailCtrl = TextEditingController(text:'juan@email.com');
  final _profPhoneCtrl = TextEditingController(text:'+63 917 123 4567');
  final _profLicCtrl   = TextEditingController(text:'N01-23-456789');
  DateTime? _licExpiry = DateTime(2027, 12, 31);
  final _curPassCtrl   = TextEditingController();
  final _newPassCtrl   = TextEditingController();
  final _confPassCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Page-switch fade+slide
    _pageCtrl = AnimationController(vsync: this, duration: kPage);
    _pageFade  = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, .03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));
    _pageCtrl.forward();

    // Dashboard stagger
    _dashCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _dashFade  = CurvedAnimation(parent: _dashCtrl, curve: Curves.easeOut);
    _dashSlide = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _dashCtrl, curve: Curves.easeOutCubic));
    _dashCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose(); _dashCtrl.dispose();
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _emailCtrl.dispose();     _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _profFirstCtrl.dispose(); _profLastCtrl.dispose();
    _profEmailCtrl.dispose(); _profPhoneCtrl.dispose();
    _profLicCtrl.dispose();   _curPassCtrl.dispose();
    _newPassCtrl.dispose();   _confPassCtrl.dispose();
    super.dispose();
  }

  // ── Navigation with page animation ───────────────────────────
  void _navTo(int page) {
    if (page == _activePage) return;
    setState(() { _activePage = page; });
    _pageCtrl.forward(from: 0);
    if (page == 0) _dashCtrl.forward(from: 0);
  }

  // ── Helpers ──────────────────────────────────────────────────
  int get _unreadCount => _notifs.where((n) => !n.read).length;

  List<Vehicle> get _filteredVehicles => _vehicleFilter == 'all'
      ? _vehicles : _vehicles.where((v) => v.category == _vehicleFilter).toList();

  List<Booking> get _filteredBookings => _bookingFilter == 'all'
      ? _bookings : _bookings.where((b) => b.status == _bookingFilter).toList();

  int _calcFee() {
    if (_selectedVehicleKey == null || _pickupDate == null || _returnDate == null) return 0;
    final rate = int.tryParse(_selectedVehicleKey!.split('|')[1]) ?? 0;
    return rate * _returnDate!.difference(_pickupDate!).inDays.clamp(1, 9999);
  }

  String _fmt(int n) => n.toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // Status color methods (defined but not yet used in status displays)
  // Color _sColor(String s) {
  //   switch(s) { case'Confirmed':return kGreen; case'Pending':return kAmber;
  //     case'Completed':return kInfo; default:return kRed; }
  // }
  // Color _sBg(String s) {
  //   switch(s) { case'Confirmed':return kGreenBg; case'Pending':return kAmberBg;
  //     case'Completed':return kInfoBg; default:return kRedBg; }
  // }
  // Color _sBdr(String s) {
  //   switch(s) { case'Confirmed':return kGreenBdr; case'Pending':return kAmberBdr;
  //     case'Completed':return kInfoBdr; default:return kRedBdr; }
  // }

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
      duration: const Duration(seconds: 3),
    ));
  }

  void _submitBooking() {
    final v = _selectedVehicleKey; final s = _pickupDate; final e = _returnDate;
    if (v == null || s == null || e == null || _locationCtrl.text.trim().isEmpty) {
      _snack('Please fill in all fields.', error: true); return;
    }
    final parts = v.split('|');
    final days  = e.difference(s).inDays.clamp(1, 9999);
    final fee   = (int.tryParse(parts[1]) ?? 0) * days;
    final ref   = 'DRIVO-${DateTime.now().toIso8601String().substring(0,10).replaceAll('-','')}'
                  '-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(4).toUpperCase()}';
    setState(() {
      _bookings.insert(0, Booking(id:ref, vehicle:parts[0], category:'Sedan',
        dateStart:'${s.month}/${s.day}', dateEnd:'${e.month}/${e.day}',
        days:days, fee:fee, status:'Pending'));
      _selectedVehicleKey = null; _pickupDate = null; _returnDate = null;
      _locationCtrl.clear();
    });
    _snack('Booking submitted! Ref: $ref');
    _navTo(1);
  }

  void _cancelBooking(Booking b) {
    setState(() => b.status = 'Cancelled');
    Navigator.of(context).pop();
    _snack('Booking cancelled successfully.');
  }

  void _openBookingDetail(Booking b) {
    showDialog(context: context, builder: (_) => _BookingDetailModal(
      booking: b, onCancel: () => _cancelBooking(b)));
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (_) => _LogoutModal(onConfirm: () {
      Navigator.of(context).pop();
      // TODO: clear token → Navigator.pushReplacement to LoginPage
      _snack('Logged out successfully.');

      Navigator.of(context).pushAndRemoveUntil(
  PageRouteBuilder(
    pageBuilder: (_, animation, __) => const LoginPage(),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  ),
  (route) => false, // removes all routes below
);
    }));
  }

  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Row(children: [
        _Sidebar(
          collapsed:   _sidebarCollapsed,
          activePage:  _activePage,
          unreadCount: _unreadCount,
          onToggle:    () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          onNavTap:    _navTo,
          onLogout:    _showLogoutDialog,
        ),
        Expanded(child: Column(children: [
          _Topbar(
            title:        _pageTitle(),
            unreadCount:  _unreadCount,
            onNotifTap:   () => _navTo(4),
            onProfileTap: () => _navTo(5),
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
    const t = ['Dashboard','My Bookings','Book a Vehicle','Browse Vehicles','Notifications','My Profile'];
    return t[_activePage];
  }

  Widget _buildPage() {
    switch (_activePage) {
      case 0: return _buildDashboard();
      case 1: return _buildBookings();
      case 2: return _buildBookNow();
      case 3: return _buildVehicles();
      case 4: return _buildNotifications();
      case 5: return _buildProfile();
      default: return _buildDashboard();
    }
  }

  // ================================================================
  // PAGE: DASHBOARD — staggered entrance animation
  // ================================================================
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: FadeTransition(
        opacity: _dashFade,
        child: SlideTransition(
          position: _dashSlide,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Greeting
            const Text('Good morning, Juan!',
              style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('You have 1 active rental and 2 upcoming bookings.',
              style: TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 20),

            // Stat cards — each with its own stagger
            Row(children: [
              Expanded(child: _StaggeredChild(delay: 0, ctrl: _dashCtrl,
                child: _AnimStatCard(label:'Active Rentals', value:'1', sub:'Toyota Vios — returns Mar 24', valueColor: kGreen))),
              const SizedBox(width:10),
              Expanded(child: _StaggeredChild(delay: 80, ctrl: _dashCtrl,
                child: _AnimStatCard(label:'Total Bookings', value:'8', sub:'Since Jan 2026'))),
              const SizedBox(width:10),
              Expanded(child: _StaggeredChild(delay: 160, ctrl: _dashCtrl,
                child: _AnimStatCard(label:'Total Spent', value:'₱24,600', sub:'All time', valueFontSize:18))),
            ]),
            const SizedBox(height: 22),

            _StaggeredChild(delay: 200, ctrl: _dashCtrl,
              child: _SectionHeader(title:'Recent Bookings', linkText:'View all',
                onLink: () => _navTo(1))),

            // Booking cards stagger
            ..._bookings.take(3).toList().asMap().map((i, b) => MapEntry(i,
              _StaggeredChild(delay: 240 + i * 60, ctrl: _dashCtrl,
                child: Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: _BookingCard(booking: b, onTap: () => _openBookingDetail(b))))
            )).values.toList(),

            const SizedBox(height: 10),
            _StaggeredChild(delay: 420, ctrl: _dashCtrl,
              child: _SectionHeader(title:'Available Vehicles', linkText:'Browse all',
                onLink: () => _navTo(3))),
            const SizedBox(height: 8),

            _StaggeredChild(delay: 460, ctrl: _dashCtrl,
              child: _vehiclesLoading
                ? const Center(child: CircularProgressIndicator(color: kBlue))
                : _vehicles.isEmpty
                  ? _EmptyVehicleBox()
                  : Wrap(spacing:10, runSpacing:10,
                      children: _vehicles.take(3).map((v) => _VehicleCard(
                        vehicle: v,
                        onBook: () { setState(() { _selectedVehicleKey='${v.name}|${v.rate}'; }); _navTo(2); },
                      )).toList())),
          ]),
        ),
      ),
    );
  }

  // ================================================================
  // PAGE: MY BOOKINGS
  // ================================================================
  Widget _buildBookings() {
    final filters = ['all','Confirmed','Pending','Completed','Cancelled'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: filters.map((f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: f == 'all' ? 'All' : f,
              selected: _bookingFilter == f,
              onTap: () => setState(() => _bookingFilter = f),
            ),
          )).toList()),
        ),
      ),
      const SizedBox(height: 14),
      Expanded(
        child: _filteredBookings.isEmpty
          ? const Center(child: Text('No bookings found.', style: TextStyle(color: kHint)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              itemCount: _filteredBookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AnimatedListItem(
                index: i,
                child: _BookingCard(
                  booking: _filteredBookings[i],
                  onTap: () => _openBookingDetail(_filteredBookings[i]),
                ),
              ),
            ),
      ),
    ]);
  }

  // ================================================================
  // PAGE: BOOK A VEHICLE
  // ================================================================
  Widget _buildBookNow() {
    final fee  = _calcFee();
    final days = (_pickupDate != null && _returnDate != null)
        ? _returnDate!.difference(_pickupDate!).inDays.clamp(1, 9999) : 0;

    // TODO: replace with dynamic list from _vehicles once API connected
    final opts = [
      {'label':'Toyota Vios 2023 — ₱1,200/day',  'value':'Toyota Vios|1200'},
      {'label':'Honda City 2022 — ₱1,500/day',    'value':'Honda City|1500'},
      {'label':'Mitsubishi Xpander — ₱1,700/day', 'value':'Mitsubishi Xpander|1700'},
      {'label':'Toyota Fortuner — ₱2,400/day',    'value':'Toyota Fortuner|2400'},
      {'label':'Honda Jazz — ₱1,100/day',         'value':'Honda Jazz|1100'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: _FormCard(title:'New Booking', child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _FormField(label:'First Name', controller: _firstNameCtrl)),
            const SizedBox(width:12),
            Expanded(child: _FormField(label:'Last Name',  controller: _lastNameCtrl)),
          ]),
          const SizedBox(height:12),
          _FormField(label:'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
          const SizedBox(height:12),
          _FormField(label:'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
          const SizedBox(height:12),
          // TODO: replace hardcoded opts with _vehicles map once API connected
          _FieldLabel(label:'Select Vehicle'),
          const SizedBox(height:5),
          _DropdownPill(
            value: _selectedVehicleKey,
            hint: '-- Choose a vehicle --',
            items: opts.map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!))).toList(),
            onChanged: (v) => setState(() => _selectedVehicleKey = v),
          ),
          const SizedBox(height:12),
          Row(children: [
            Expanded(child: _DatePickerField(label:'Pickup Date', value:_pickupDate,
              onPicked:(d) => setState(() => _pickupDate = d))),
            const SizedBox(width:12),
            Expanded(child: _DatePickerField(label:'Return Date', value:_returnDate,
              onPicked:(d) => setState(() => _returnDate = d))),
          ]),
          const SizedBox(height:12),
          _FormField(label:'Pickup Location', controller: _locationCtrl),
          const SizedBox(height:16),

          // Fee box — animates when fee changes
          AnimatedContainer(
            duration: kNormal,
            padding: const EdgeInsets.symmetric(horizontal:16, vertical:12),
            decoration: BoxDecoration(
              color: fee > 0 ? kBlueBg : kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: fee > 0 ? kBlue.withOpacity(.4) : kBorder),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Estimated Total Fee', style: TextStyle(color:kMuted, fontSize:11)),
                const SizedBox(height:3),
                Text(
                  fee > 0
                    ? '${_selectedVehicleKey?.split('|')[0]} · ₱${_selectedVehicleKey?.split('|')[1]}/day × $days day${days>1?'s':''}'
                    : 'Select vehicle and dates',
                  style: const TextStyle(color:kHint, fontSize:11)),
              ]),
              AnimatedSwitcher(
                duration: kNormal,
                transitionBuilder: (child, anim) => FadeTransition(opacity:anim,
                  child: SlideTransition(position: Tween<Offset>(begin:const Offset(0,.3), end:Offset.zero).animate(anim), child:child)),
                child: Text(
                  fee > 0 ? '₱${_fmt(fee)}' : '₱ —',
                  key: ValueKey(fee),
                  style: const TextStyle(color:kText, fontSize:18, fontWeight:FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height:16),
          _HoverButton(
            label: 'Confirm Booking',
            onTap: _submitBooking,
          ),
        ],
      )),
    );
  }

  // ================================================================
  // PAGE: BROWSE VEHICLES
  // ================================================================
  Widget _buildVehicles() {
    final filtered = _filteredVehicles;
    final filters  = ['all','Sedan','SUV','Hatchback'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: filters.map((f) => Padding(
            padding: const EdgeInsets.only(right:8),
            child: _FilterChip(
              label: f=='all'?'All':f,
              selected: _vehicleFilter==f,
              onTap: () => setState(() { _vehicleFilter=f; _showcaseIdx=0; _detailOpen=false; }),
            ),
          )).toList()),
        ),
        const SizedBox(height:16),

        // Showcase hero
        AnimatedContainer(
          duration: kNormal,
          height: 290,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _detailOpen ? kBlue.withOpacity(.5) : kBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _vehiclesLoading
              ? const Center(child: CircularProgressIndicator(color: kBlue))
              : filtered.isEmpty
                ? _EmptyShowcase(onLoad: () => _snack('TODO: Call GET /api/vehicles'))
                : Stack(children: [

                    // Big year watermark
                    Positioned.fill(child: Center(
                      child: AnimatedSwitcher(
                        duration: kNormal,
                        child: Text(filtered[_showcaseIdx].year,
                          key: ValueKey('yr${_showcaseIdx}_${_vehicleFilter}'),
                          style: const TextStyle(fontSize:150, fontWeight:FontWeight.w800,
                            color: Color(0xFF141E2E), letterSpacing:-8)),
                      ),
                    )),

                    // Vehicle name — top right, animated switch
                    Positioned(top:32, right:28, child: AnimatedSwitcher(
                      duration: kNormal,
                      switchInCurve: Curves.easeOut,
                      transitionBuilder: (c, a) => FadeTransition(opacity:a,
                        child: SlideTransition(position: Tween<Offset>(begin:const Offset(.1,0), end:Offset.zero).animate(a), child:c)),
                      child: Column(key: ValueKey('name${_showcaseIdx}'),
                        crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(filtered[_showcaseIdx].name,
                          style: const TextStyle(color:kText, fontSize:20, fontWeight:FontWeight.w600, fontStyle:FontStyle.italic)),
                        Text(filtered[_showcaseIdx].model,
                          style: const TextStyle(color:kMuted, fontSize:11)),
                      ]),
                    )),

                    // Car image placeholder — TODO: Image.network(vehicle.imageUrl)
                    Center(child: AnimatedSwitcher(
                      duration: kNormal,
                      transitionBuilder: (c, a) => FadeTransition(opacity:a,
                        child: ScaleTransition(scale: Tween(begin:.92, end:1.0).animate(a), child:c)),
                      child: Icon(Icons.directions_car,
                        key: ValueKey('car${_showcaseIdx}'),
                        color: kBlueBg, size:120),
                    )),

                    // Prev arrow
                    Positioned(left:16, top:0, bottom:0, child: Center(
                      child: _NavArrow(icon:Icons.chevron_left, onTap: () => setState(() {
                        _showcaseIdx = (_showcaseIdx-1+filtered.length)%filtered.length;
                        _detailOpen = false;
                      })),
                    )),

                    // Next arrow
                    Positioned(right:16, top:0, bottom:0, child: Center(
                      child: _NavArrow(icon:Icons.chevron_right, onTap: () => setState(() {
                        _showcaseIdx = (_showcaseIdx+1)%filtered.length;
                        _detailOpen = false;
                      })),
                    )),

                    // Actions
                    Positioned(bottom:20, left:20, child: Row(children: [
                      _HoverButton(label:'Rent Now', small:true, onTap: () {
                        setState(() => _selectedVehicleKey='${filtered[_showcaseIdx].name}|${filtered[_showcaseIdx].rate}');
                        _navTo(2);
                      }),
                      const SizedBox(width:10),
                      _HoverOutlineButton(
                        label: _detailOpen ? 'Close Details' : 'Details',
                        active: _detailOpen,
                        onTap: () => setState(() => _detailOpen = !_detailOpen),
                      ),
                    ])),

                    // Navigation dots
                    Positioned(bottom:24, right:28, child: Row(
                      children: List.generate(filtered.length, (i) => GestureDetector(
                        onTap: () => setState(() { _showcaseIdx=i; _detailOpen=false; }),
                        child: AnimatedContainer(
                          duration: kFast,
                          width: i==_showcaseIdx ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.only(left:5),
                          decoration: BoxDecoration(
                            color: i==_showcaseIdx ? kBlue : kText.withOpacity(.25),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      )),
                    )),
                  ]),
          ),
        ),

        // Detail panel — animated expand
        AnimatedSize(
          duration: kNormal,
          curve: Curves.easeInOut,
          child: _detailOpen && filtered.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top:14),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D1A2E),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Align(alignment: Alignment.centerRight,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(filtered[_showcaseIdx].name,
                              style: const TextStyle(color:kText, fontSize:16, fontWeight:FontWeight.w600, fontStyle:FontStyle.italic)),
                            Text(filtered[_showcaseIdx].model,
                              style: const TextStyle(color:kMuted, fontSize:11)),
                          ]),
                        ),
                        const SizedBox(height:24),
                        // TODO: replace with Image.network(vehicle.imageUrl)
                        const Center(child: Icon(Icons.directions_car, color:kBlueBg, size:90)),
                        const SizedBox(height:16),
                        Row(children: ['Front','Side','Rear','Interior'].asMap().map((i, label) =>
                          MapEntry(i, Padding(padding: const EdgeInsets.only(right:7),
                            child: GestureDetector(
                              onTap: () => setState(() => _thumbIdx = i),
                              child: AnimatedContainer(
                                duration: kFast,
                                padding: const EdgeInsets.symmetric(horizontal:13, vertical:5),
                                decoration: BoxDecoration(
                                  color: _thumbIdx==i ? kAmberBg : kBlueBg.withOpacity(.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _thumbIdx==i ? kAmber : kBorder),
                                ),
                                child: Text(label, style: TextStyle(
                                  color: _thumbIdx==i ? kAmber : kMuted, fontSize:11)),
                              ),
                            ),
                          ))
                        ).values.toList()),
                        const SizedBox(height:14),
                        _HoverButton(label:'Rent Now', small:true, onTap: () {
                          setState(() => _selectedVehicleKey='${filtered[_showcaseIdx].name}|${filtered[_showcaseIdx].rate}');
                          _navTo(2);
                        }),
                      ]),
                    )),
                    // TODO: spec values from filtered[_showcaseIdx] once API populates _vehicles
                    Expanded(child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: kCard,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15), bottomRight: Radius.circular(15))),
                      child: Column(children: [
                        _SpecRow(label:'Category',     value: filtered[_showcaseIdx].category),
                        _SpecRow(label:'Daily Rate',   value: '₱${_fmt(filtered[_showcaseIdx].rate)}', valueColor:kAmber),
                        _SpecRow(label:'Fuel Type',    value: filtered[_showcaseIdx].fuel),
                        _SpecRow(label:'Transmission', value: filtered[_showcaseIdx].transmission),
                        _SpecRow(label:'Seating',      value: '${filtered[_showcaseIdx].seats} passengers'),
                        _SpecRow(label:'Status',       value: filtered[_showcaseIdx].status == 'available' ? 'Available' : 'Rented',
                          valueColor: filtered[_showcaseIdx].status=='available' ? kGreen : kRed),
                        _SpecRow(label:'Plate No.',    value: filtered[_showcaseIdx].plate),
                      ]),
                    )),
                  ]),
                ),
              )
            : const SizedBox.shrink(),
        ),

        const SizedBox(height:16),
        const Text('All Vehicles', style: TextStyle(color:kText, fontSize:13, fontWeight:FontWeight.w500)),
        const SizedBox(height:10),

        // Small grid
        filtered.isEmpty
          ? _EmptyVehicleBox()
          : Wrap(spacing:10, runSpacing:10,
              children: filtered.asMap().map((i, v) => MapEntry(i,
                _AnimatedListItem(index: i, child: GestureDetector(
                  onTap: () => setState(() { _showcaseIdx=i; _detailOpen=false; }),
                  child: _HoverContainer(
                    border: Border.all(color: i==_showcaseIdx ? kBlue : kBorder),
                    color:  i==_showcaseIdx ? kBlueBg : kCard,
                    hoverColor: kCard.withOpacity(.8),
                    hoverBorder: Border.all(color: kBlue.withOpacity(.5)),
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.all(12),
                    width: 160,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // TODO: replace Icon with Image.network(v.imageUrl)
                      const Icon(Icons.directions_car, color:kBlueBg, size:44),
                      const SizedBox(height:7),
                      Text(v.name, style: const TextStyle(color:kText, fontSize:12, fontWeight:FontWeight.w500)),
                      Text(v.category, style: const TextStyle(color:kMuted, fontSize:10)),
                      const SizedBox(height:4),
                      Text('₱${_fmt(v.rate)}/day', style: const TextStyle(color:kBlue, fontSize:12, fontWeight:FontWeight.w600)),
                    ]),
                  ),
                ))
              )).values.toList()),
      ]),
    );
  }

  // ================================================================
  // PAGE: MY PROFILE
  // ================================================================
  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        _FormCard(title:'', child: Column(children: [
          Row(children: [
            CircleAvatar(radius:27, backgroundColor:kBlueBg,
              child: const Text('JD', style: TextStyle(color:kInfo, fontWeight:FontWeight.w600, fontSize:16))),
            const SizedBox(width:14),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Juan dela Cruz', style: TextStyle(color:kText, fontSize:14, fontWeight:FontWeight.w500)),
              Text('Customer · Member since Jan 2026', style: TextStyle(color:kMuted, fontSize:11)),
            ]),
          ]),
          const SizedBox(height:16),
          const Divider(color:kBorder),
          const SizedBox(height:12),
          Row(children: [
            Expanded(child: _FormField(label:'First Name', controller:_profFirstCtrl)),
            const SizedBox(width:12),
            Expanded(child: _FormField(label:'Last Name',  controller:_profLastCtrl)),
          ]),
          const SizedBox(height:12),
          _FormField(label:'Email', controller:_profEmailCtrl, keyboardType:TextInputType.emailAddress),
          const SizedBox(height:12),
          _FormField(label:'Phone', controller:_profPhoneCtrl, keyboardType:TextInputType.phone),
          const SizedBox(height:12),
          Row(children: [
            Expanded(child: _FormField(label:'License No.', controller:_profLicCtrl)),
            const SizedBox(width:12),
            Expanded(child: _DatePickerField(label:'License Expiry', value:_licExpiry,
              onPicked:(d) => setState(() => _licExpiry=d))),
          ]),
          const SizedBox(height:14),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _HoverOutlineButton(label:'Cancel', onTap: (){}),
            const SizedBox(width:8),
            // TODO: call PATCH /api/auth/user
            _HoverButton(label:'Save Changes', onTap: () => _snack('Profile updated!')),
          ]),
        ])),
        const SizedBox(height:14),
        _FormCard(title:'Change Password', child: Column(children: [
          _FormField(label:'Current Password', controller:_curPassCtrl, obscure:true),
          const SizedBox(height:12),
          _FormField(label:'New Password',     controller:_newPassCtrl, obscure:true),
          const SizedBox(height:12),
          _FormField(label:'Confirm Password', controller:_confPassCtrl, obscure:true),
          const SizedBox(height:14),
          Align(alignment: Alignment.centerRight,
            // TODO: call POST /api/auth/change-password
            child: _HoverButton(label:'Update Password', onTap: () => _snack('Password changed!'))),
        ])),
      ]),
    );
  }

  // ================================================================
  // PAGE: NOTIFICATIONS
  // ================================================================
  Widget _buildNotifications() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22,18,22,12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Notifications', style: TextStyle(color:kText, fontSize:13, fontWeight:FontWeight.w500)),
          GestureDetector(
            onTap: () => setState(() { for (final n in _notifs) n.read = true; }),
            child: const Text('Mark all read', style: TextStyle(color:kBlue, fontSize:11))),
        ]),
      ),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(22,0,22,22),
        itemCount: _notifs.length,
        separatorBuilder: (_,__) => const SizedBox(height:8),
        itemBuilder: (_, i) {
          final n = _notifs[i];
          return _AnimatedListItem(index:i, child: AnimatedContainer(
            duration: kNormal,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: n.read ? kBorder : const Color(0xFF2A3A6E)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius:17, backgroundColor:n.iconBg,
                child: Text(n.icon, style: TextStyle(color:n.iconColor, fontSize:12, fontWeight:FontWeight.w600))),
              const SizedBox(width:12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title, style: const TextStyle(color:kText, fontSize:12, fontWeight:FontWeight.w500)),
                const SizedBox(height:2),
                Text(n.message, style: const TextStyle(color:kMuted, fontSize:11, height:1.5)),
                const SizedBox(height:4),
                Text(n.time, style: const TextStyle(color:kHint, fontSize:10)),
              ])),
              if (!n.read)
                Container(width:7, height:7, margin:const EdgeInsets.only(top:4, left:8),
                  decoration: const BoxDecoration(color:kBlue, shape:BoxShape.circle)),
            ]),
          ));
        },
      )),
    ]);
  }
}

// ================================================================
// ANIMATED HELPERS
// ================================================================

/// Staggered entrance — delays fade+slide by [delay] ms
class _StaggeredChild extends StatelessWidget {
  const _StaggeredChild({required this.delay, required this.ctrl, required this.child});
  final int delay;
  final AnimationController ctrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start  = (delay / 700).clamp(0.0, 0.95);
    final end    = (start + 0.4).clamp(0.0, 1.0);
    final curved = CurvedAnimation(parent: ctrl, curve: Interval(start, end, curve: Curves.easeOut));
    final fade   = curved;
    final slide  = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(curved);
    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
  }
}

/// List items that fade+slide in based on their index
class _AnimatedListItem extends StatefulWidget {
  const _AnimatedListItem({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}
class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _f;
  late Animation<Offset>   _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _f = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _s = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _c.forward();
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _f, child: SlideTransition(position: _s, child: widget.child));
}

/// Animated stat card with hover lift
class _AnimStatCard extends StatefulWidget {
  const _AnimStatCard({required this.label, required this.value, this.sub, this.valueColor, this.valueFontSize = 22});
  final String label, value;
  final String? sub;
  final Color? valueColor;
  final double valueFontSize;
  @override
  State<_AnimStatCard> createState() => _AnimStatCardState();
}
class _AnimStatCardState extends State<_AnimStatCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: kFast,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hovered ? kCard.withOpacity(.95) : kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hovered ? kBlue.withOpacity(.4) : kBorder),
        boxShadow: _hovered ? [BoxShadow(color: kBlue.withOpacity(.08), blurRadius:12, offset:const Offset(0,4))] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label, style: const TextStyle(color:kMuted, fontSize:11)),
        const SizedBox(height:5),
        Text(widget.value, style: TextStyle(color: widget.valueColor ?? kText,
          fontSize: widget.valueFontSize, fontWeight: FontWeight.w600)),
        if (widget.sub != null) ...[
          const SizedBox(height:4),
          Text(widget.sub!, style: const TextStyle(color:kHint, fontSize:11)),
        ],
      ]),
    ),
  );
}

/// Generic hover container
class _HoverContainer extends StatefulWidget {
  const _HoverContainer({required this.child, required this.color,
    required this.border, required this.hoverColor, required this.hoverBorder,
    required this.borderRadius, required this.padding, this.width});
  final Widget child;
  final Color color, hoverColor;
  final BoxBorder border, hoverBorder;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final double? width;
  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}
class _HoverContainerState extends State<_HoverContainer> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: kFast,
      width: widget.width,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _hovered ? widget.hoverColor : widget.color,
        borderRadius: widget.borderRadius,
        border: _hovered ? widget.hoverBorder : widget.border,
      ),
      child: widget.child,
    ),
  );
}

/// Primary filled button with hover + press scale
class _HoverButton extends StatefulWidget {
  const _HoverButton({required this.label, required this.onTap, this.small = false});
  final String label;
  final VoidCallback onTap;
  final bool small;
  @override
  State<_HoverButton> createState() => _HoverButtonState();
}
class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .96 : 1.0,
        duration: kFast,
        child: AnimatedContainer(
          duration: kFast,
          padding: widget.small
            ? const EdgeInsets.symmetric(horizontal:20, vertical:9)
            : const EdgeInsets.symmetric(horizontal:28, vertical:13),
          decoration: BoxDecoration(
            color: _hovered ? kBlue2 : kBlue,
            borderRadius: BorderRadius.circular(widget.small ? 8 : 99),
          ),
          child: Text(widget.label, style: TextStyle(
            color: kText,
            fontSize: widget.small ? 12 : 14,
            fontWeight: FontWeight.w700,
          )),
        ),
      ),
    ),
  );
}

/// Outline button with hover
class _HoverOutlineButton extends StatefulWidget {
  const _HoverOutlineButton({required this.label, required this.onTap, this.active = false});
  final String label;
  final VoidCallback onTap;
  final bool active;
  @override
  State<_HoverOutlineButton> createState() => _HoverOutlineButtonState();
}
class _HoverOutlineButtonState extends State<_HoverOutlineButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        padding: const EdgeInsets.symmetric(horizontal:20, vertical:9),
        decoration: BoxDecoration(
          color: widget.active
            ? kBlueBg.withOpacity(.3)
            : _hovered ? kCard.withOpacity(.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.active ? kBlue : (_hovered ? kMuted.withOpacity(.6) : kMuted.withOpacity(.35)),
          ),
        ),
        child: Text(widget.label, style: TextStyle(
          color: widget.active ? kInfo : (_hovered ? kText : kText),
          fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ),
    ),
  );
}

// ================================================================
// _Sidebar
// ================================================================
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.collapsed, required this.activePage,
    required this.unreadCount, required this.onToggle,
    required this.onNavTap, required this.onLogout});
  final bool collapsed;
  final int activePage, unreadCount;
  final VoidCallback onToggle, onLogout;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedContainer(
      duration: kNormal,
      curve: Curves.easeInOut,
      width: collapsed ? kSidebarMini : kSidebarFull,
      color: kBg2,
      child: Column(children: [
        // Header
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal:12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
          child: collapsed
              ? Center(child: _HamburgerBtn(onTap: onToggle))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DRIVO',
                      style: TextStyle(color:kBlue, fontSize:14, fontWeight:FontWeight.w700, letterSpacing:1)),
                    _HamburgerBtn(onTap: onToggle),
                  ],
                ),
        ),

        if (!collapsed) _SidebarSection(label:'Main'),
        _NavItem(icon: Icons.grid_view_rounded,       label:'Dashboard',       idx:0, active:activePage==0, collapsed:collapsed, onTap:() => onNavTap(0)),
        _NavItem(icon: Icons.calendar_today_outlined, label:'My Bookings',     idx:1, active:activePage==1, collapsed:collapsed, onTap:() => onNavTap(1)),
        _NavItem(icon: Icons.access_time_outlined,    label:'Book a Vehicle',  idx:2, active:activePage==2, collapsed:collapsed, onTap:() => onNavTap(2)),
        _NavItem(icon: Icons.directions_car_outlined, label:'Browse Vehicles', idx:3, active:activePage==3, collapsed:collapsed, onTap:() => onNavTap(3)),
        if (!collapsed) _SidebarSection(label:'Account'),
        _NavItem(icon: Icons.notifications_outlined,  label:'Notifications',   idx:4, active:activePage==4, collapsed:collapsed, onTap:() => onNavTap(4),
          badge: unreadCount > 0 ? unreadCount.toString() : null),

        const Spacer(),

        // Logout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
          child: _LogoutBtn(collapsed: collapsed, onTap: onLogout),
        ),
      ]),
    )); // closes AnimatedContainer + ClipRect
  }
}

class _HamburgerBtn extends StatefulWidget {
  const _HamburgerBtn({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_HamburgerBtn> createState() => _HamburgerBtnState();
}
class _HamburgerBtnState extends State<_HamburgerBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _hovered ? kBlueBg : kCard,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _hovered ? kBlue : kBorder),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _HamLine(hovered: _hovered),
          const SizedBox(height: 4),
          _HamLine(hovered: _hovered),
          const SizedBox(height: 4),
          _HamLine(hovered: _hovered),
        ]),
      ),
    ),
  );
}

class _HamLine extends StatelessWidget {
  const _HamLine({this.hovered = false});
  final bool hovered;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: kFast,
    width: 14, height: 1.5,
    decoration: BoxDecoration(
      color: hovered ? kInfo : kMuted,
      borderRadius: BorderRadius.circular(99),
    ),
  );
}

class _LogoutBtn extends StatefulWidget {
  const _LogoutBtn({required this.collapsed, required this.onTap});
  final bool collapsed;
  final VoidCallback onTap;
  @override
  State<_LogoutBtn> createState() => _LogoutBtnState();
}
class _LogoutBtnState extends State<_LogoutBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _hovered ? kRedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(Icons.logout, color: _hovered ? kRed : kRed.withOpacity(.7), size: 16),
            if (!widget.collapsed) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text('Log Out',
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(
                    color: _hovered ? kRed : kRed.withOpacity(.7), fontSize: 12))),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16,12,16,3),
    child: Text(label.toUpperCase(),
      overflow: TextOverflow.clip,
      softWrap: false,
      style: const TextStyle(color:kHint, fontSize:10, fontWeight:FontWeight.w500, letterSpacing:.7)),
  );
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.icon, required this.label, required this.idx,
    required this.active, required this.collapsed, required this.onTap, this.badge});
  final IconData icon;
  final String label;
  final int idx;
  final bool active, collapsed;
  final VoidCallback onTap;
  final String? badge;
  @override
  State<_NavItem> createState() => _NavItemState();
}
class _NavItemState extends State<_NavItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 0 : 14),
        decoration: BoxDecoration(
          color: widget.active ? kBlueBg : (_hovered ? kCard.withOpacity(.6) : Colors.transparent),
          border: Border(left: BorderSide(
            color: widget.active ? kBlue : Colors.transparent, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(widget.icon,
              color: widget.active ? kInfo : (_hovered ? kText : kMuted),
              size: 16),
            if (!widget.collapsed) ...[ 
              const SizedBox(width: 10),
              Flexible(
                child: Text(widget.label,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(
                  color: widget.active ? kInfo : (_hovered ? kText : kMuted),
                  fontSize: 12,
                  fontWeight: widget.active ? FontWeight.w500 : FontWeight.w400,
                ))),
              if (widget.badge != null)
                AnimatedContainer(
                  duration: kFast,
                  padding: const EdgeInsets.symmetric(horizontal:6, vertical:1),
                  decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(99)),
                  child: Text(widget.badge!, style: const TextStyle(color:Colors.white, fontSize:9, fontWeight:FontWeight.w600)),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ================================================================
// _Topbar
// ================================================================
class _Topbar extends StatelessWidget {
  const _Topbar({required this.title, required this.unreadCount,
    required this.onNotifTap, required this.onProfileTap});
  final String title;
  final int unreadCount;
  final VoidCallback onNotifTap, onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal:20),
      decoration: const BoxDecoration(
        color: kBg2,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(children: [
        AnimatedSwitcher(
          duration: kNormal,
          child: Text(title, key: ValueKey(title),
            style: const TextStyle(color:kText, fontSize:14, fontWeight:FontWeight.w500)),
        ),
        const Spacer(),
        // Notification button
        _TopbarIconBtn(
          icon: Icons.notifications_outlined,
          badge: unreadCount > 0,
          onTap: onNotifTap,
        ),
        const SizedBox(width:8),
        // Profile pill
        _ProfilePill(onTap: onProfileTap),
      ]),
    );
  }
}

class _TopbarIconBtn extends StatefulWidget {
  const _TopbarIconBtn({required this.icon, required this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  @override
  State<_TopbarIconBtn> createState() => _TopbarIconBtnState();
}
class _TopbarIconBtnState extends State<_TopbarIconBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        AnimatedContainer(
          duration: kFast,
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _hovered ? kBlueBg : kCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _hovered ? kBlue : kBorder),
          ),
          child: Icon(widget.icon, color: _hovered ? kInfo : kMuted, size: 16),
        ),
        if (widget.badge)
          Positioned(top:5, right:5,
            child: Container(width:7, height:7,
              decoration: BoxDecoration(color:kBlue, shape:BoxShape.circle,
                border: Border.all(color:kBg2, width:1.5)))),
      ]),
    ),
  );
}

class _ProfilePill extends StatefulWidget {
  const _ProfilePill({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_ProfilePill> createState() => _ProfilePillState();
}
class _ProfilePillState extends State<_ProfilePill> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        padding: const EdgeInsets.fromLTRB(6,5,14,5),
        decoration: BoxDecoration(
          color: _hovered ? kBlueBg : kCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _hovered ? kBlue : kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius:13, backgroundColor:kBlueBg,
            child: const Text('JD', style: TextStyle(color:kInfo, fontSize:10, fontWeight:FontWeight.w600))),
          const SizedBox(width:8),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Juan dela Cruz', style: TextStyle(color:kText, fontSize:12, fontWeight:FontWeight.w500)),
            Text('Customer',       style: TextStyle(color:kMuted, fontSize:10)),
          ]),
        ]),
      ),
    ),
  );
}

// ================================================================
// Booking Detail Modal
// ================================================================
class _BookingDetailModal extends StatelessWidget {
  const _BookingDetailModal({required this.booking, required this.onCancel});
  final Booking booking;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final canCancel = booking.status == 'Confirmed' || booking.status == 'Pending';
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kBorder)),
      child: Container(
        width: 360, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Booking Details', style: TextStyle(color:kText, fontSize:15, fontWeight:FontWeight.w500)),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width:28, height:28,
                decoration: BoxDecoration(color:kBlueBg, shape:BoxShape.circle, border:Border.all(color:kBorder)),
                child: const Icon(Icons.close, color:kMuted, size:14))),
          ]),
          const SizedBox(height:4),
          Text(booking.id, style: const TextStyle(color:kMuted, fontSize:12)),
          const SizedBox(height:16),
          _DetailRow(label:'Vehicle',  value: booking.vehicle),
          _DetailRow(label:'Category', value: booking.category),
          _DetailRow(label:'Period',   value: '${booking.dateStart} – ${booking.dateEnd}'),
          _DetailRow(label:'Duration', value: '${booking.days} day${booking.days>1?'s':''}'),
          _DetailRow(label:'Fee',      value: '₱${booking.fee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
          _DetailRow(label:'Status',   value: booking.status, isLast: true),
          if (canCancel) ...[
            const SizedBox(height:14),
            SizedBox(width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color:kRedBdr), foregroundColor:kRed,
                  backgroundColor:kRedBg, shape:const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical:10)),
                child: const Text('Cancel This Booking', style: TextStyle(fontWeight:FontWeight.w600)))),
          ],
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});
  final String label, value;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical:8),
    decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: kBorder))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color:kMuted, fontSize:12)),
      Text(value,  style: const TextStyle(color:kText,  fontSize:12, fontWeight:FontWeight.w500)),
    ]),
  );
}

// ================================================================
// Logout Modal
// ================================================================
class _LogoutModal extends StatelessWidget {
  const _LogoutModal({required this.onConfirm});
  final VoidCallback onConfirm;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kBorder)),
    child: Container(
      width: 320, padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width:52, height:52,
          decoration: BoxDecoration(color:kRedBg, shape:BoxShape.circle, border:Border.all(color:kRedBdr)),
          child: const Icon(Icons.logout, color:kRed, size:22)),
        const SizedBox(height:16),
        const Text('Log out of DRIVO?', style: TextStyle(color:kText, fontSize:15, fontWeight:FontWeight.w500)),
        const SizedBox(height:6),
        const Text('You will be returned to the login page.\nAny unsaved changes will be lost.',
          textAlign: TextAlign.center,
          style: TextStyle(color:kMuted, fontSize:12, height:1.6)),
        const SizedBox(height:20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(side: const BorderSide(color:kBorder),
              foregroundColor:kMuted, shape:const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical:10)),
            child: const Text('Cancel'))),
          const SizedBox(width:10),
          Expanded(child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(backgroundColor:kRedBg, foregroundColor:kRed,
              shape:const StadiumBorder(), elevation:0,
              side: const BorderSide(color:kRedBdr),
              padding: const EdgeInsets.symmetric(vertical:10)),
            child: const Text('Log Out', style: TextStyle(fontWeight:FontWeight.w600)))),
        ]),
      ]),
    ),
  );
}

// ================================================================
// Shared small widgets
// ================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.linkText, this.onLink});
  final String title;
  final String? linkText;
  final VoidCallback? onLink;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom:10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(color:kText, fontSize:13, fontWeight:FontWeight.w500)),
      if (linkText != null)
        MouseRegion(cursor: SystemMouseCursors.click,
          child: GestureDetector(onTap: onLink,
            child: Text(linkText!, style: const TextStyle(color:kBlue, fontSize:11)))),
    ]),
  );
}

class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;
  @override
  State<_BookingCard> createState() => _BookingCardState();
}
class _BookingCardState extends State<_BookingCard> {
  bool _hovered = false;

  Color _sColor(String s) { switch(s) { case'Confirmed':return kGreen; case'Pending':return kAmber; case'Completed':return kInfo; default:return kRed; }}
  Color _sBg(String s)    { switch(s) { case'Confirmed':return kGreenBg; case'Pending':return kAmberBg; case'Completed':return kInfoBg; default:return kRedBg; }}
  Color _sBdr(String s)   { switch(s) { case'Confirmed':return kGreenBdr; case'Pending':return kAmberBdr; case'Completed':return kInfoBdr; default:return kRedBdr; }}

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? kCard.withOpacity(.95) : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hovered ? kBlue.withOpacity(.4) : kBorder),
          boxShadow: _hovered ? [BoxShadow(color:kBlue.withOpacity(.06), blurRadius:10, offset:const Offset(0,3))] : [],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: kFast,
            width:38, height:38,
            decoration: BoxDecoration(
              color: _hovered ? kBlue.withOpacity(.15) : kBlueBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _hovered ? kBlue.withOpacity(.4) : kBorder),
            ),
            child: Icon(Icons.directions_car_outlined, color: _hovered ? kBlue : kHint, size:18)),
          const SizedBox(width:12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.booking.id, style: const TextStyle(color:kText, fontSize:12, fontWeight:FontWeight.w500)),
            Text('${widget.booking.vehicle} · ${widget.booking.category}', style: const TextStyle(color:kMuted, fontSize:11)),
            Text('${widget.booking.dateStart} – ${widget.booking.dateEnd}, 2026', style: const TextStyle(color:kHint, fontSize:11)),
            const SizedBox(height:4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
              decoration: BoxDecoration(color:_sBg(widget.booking.status), borderRadius:BorderRadius.circular(99),
                border: Border.all(color:_sBdr(widget.booking.status))),
              child: Text(widget.booking.status, style: TextStyle(color:_sColor(widget.booking.status), fontSize:10, fontWeight:FontWeight.w500))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₱${widget.booking.fee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              style: const TextStyle(color:kText, fontSize:13, fontWeight:FontWeight.w600)),
            Text('${widget.booking.days} day${widget.booking.days>1?'s':''}', style: const TextStyle(color:kHint, fontSize:11)),
          ]),
        ]),
      ),
    ),
  );
}

class _VehicleCard extends StatefulWidget {
  const _VehicleCard({required this.vehicle, required this.onBook});
  final Vehicle vehicle;
  final VoidCallback onBook;
  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}
class _VehicleCardState extends State<_VehicleCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: kFast,
      width: 180, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hovered ? kCard.withOpacity(.95) : kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _hovered ? kBlue.withOpacity(.4) : kBorder),
        boxShadow: _hovered ? [BoxShadow(color:kBlue.withOpacity(.07), blurRadius:10, offset:const Offset(0,3))] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // TODO: replace Icon with Image.network(vehicle.imageUrl) from API
        Icon(Icons.directions_car, color: _hovered ? kBlue.withOpacity(.4) : kBlueBg, size:54),
        const SizedBox(height:8),
        Text(widget.vehicle.name, style: const TextStyle(color:kText, fontSize:12, fontWeight:FontWeight.w500)),
        Text(widget.vehicle.category, style: const TextStyle(color:kMuted, fontSize:11)),
        const SizedBox(height:4),
        Text('₱${widget.vehicle.rate.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} / day',
          style: const TextStyle(color:kBlue, fontSize:12, fontWeight:FontWeight.w600)),
        const SizedBox(height:8),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.vehicle.status == 'available' ? widget.onBook : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue, foregroundColor: kText,
              disabledBackgroundColor: kHint,
              shape: const StadiumBorder(), elevation:0,
              padding: const EdgeInsets.symmetric(vertical:6)),
            child: Text(widget.vehicle.status == 'available' ? 'Book Now' : 'Unavailable',
              style: const TextStyle(fontSize:11, fontWeight:FontWeight.w600)))),
      ]),
    ),
  );
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_FilterChip> createState() => _FilterChipState();
}
class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        padding: const EdgeInsets.symmetric(horizontal:14, vertical:5),
        decoration: BoxDecoration(
          color: widget.selected ? kBlueBg : (_hovered ? kCard.withOpacity(.8) : kCard),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: widget.selected ? kBlue : (_hovered ? kMuted.withOpacity(.6) : kBorder)),
        ),
        child: Text(widget.label, style: TextStyle(
          color: widget.selected ? kInfo : (_hovered ? kText : kMuted),
          fontSize:11,
          fontWeight: widget.selected ? FontWeight.w500 : FontWeight.w400,
        )),
      ),
    ),
  );
}

class _NavArrow extends StatefulWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<_NavArrow> createState() => _NavArrowState();
}
class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: kFast,
        width:30, height:30,
        decoration: BoxDecoration(
          color: _hovered ? kCard : const Color(0xD81A2744),
          shape: BoxShape.circle,
          border: Border.all(color: _hovered ? kBlue.withOpacity(.5) : kBorder),
        ),
        child: Icon(widget.icon, color: _hovered ? kInfo : kMuted, size:16),
      ),
    ),
  );
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value, this.valueColor});
  final String label, value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical:11),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color:kMuted, fontSize:10, fontWeight:FontWeight.w500, letterSpacing:.6)),
      const SizedBox(height:3),
      Text(value, style: TextStyle(color: valueColor ?? kText, fontSize:14, fontWeight:FontWeight.w500)),
    ]),
  );
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(12), border:Border.all(color:kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: const TextStyle(color:kText, fontSize:14, fontWeight:FontWeight.w500)),
        const SizedBox(height:14),
        const Divider(color:kBorder),
        const SizedBox(height:12),
      ],
      child,
    ]),
  );
}

class _DropdownPill extends StatelessWidget {
  const _DropdownPill({required this.value, required this.hint, required this.items, required this.onChanged});
  final String? value, hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height:46,
    padding: const EdgeInsets.symmetric(horizontal:16),
    decoration: BoxDecoration(color:kInput, borderRadius:BorderRadius.circular(99), border:Border.all(color:kInputBdr)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: value,
      hint: Text(hint!, style: const TextStyle(color:kHint, fontSize:13)),
      dropdownColor: kCard, style: const TextStyle(color:kText, fontSize:13),
      isExpanded: true, iconEnabledColor: kMuted,
      items: items,
      onChanged: onChanged,
    )),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label.toUpperCase(),
    style: const TextStyle(color:kMuted, fontSize:10, fontWeight:FontWeight.w500, letterSpacing:.4));
}

class _FormField extends StatefulWidget {
  const _FormField({required this.label, required this.controller, this.keyboardType, this.obscure = false});
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  @override
  State<_FormField> createState() => _FormFieldState();
}
class _FormFieldState extends State<_FormField> {
  bool _visible = false;
  bool _focused = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label: widget.label),
      const SizedBox(height:5),
      Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: AnimatedContainer(
          duration: kFast,
          height:46,
          decoration: BoxDecoration(
            color: _focused ? kInput.withOpacity(.8) : kInput,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _focused ? kBlue : kInputBdr),
          ),
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscure && !_visible,
            style: const TextStyle(color:kText, fontSize:13),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal:16),
              suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color:kMuted, size:18),
                    onPressed: () => setState(() => _visible = !_visible))
                : null,
            ),
            cursorColor: kBlue,
          ),
        ),
      ),
    ],
  );
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.value, required this.onPicked});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label: label),
      const SizedBox(height:5),
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days:365)),
            builder: (ctx, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(primary:kBlue, surface:kCard)),
              child: child!),
          );
          if (picked != null) onPicked(picked);
        },
        child: Container(
          height:46, padding: const EdgeInsets.symmetric(horizontal:16),
          decoration: BoxDecoration(color:kInput, borderRadius:BorderRadius.circular(99), border:Border.all(color:kInputBdr)),
          child: Row(children: [
            Expanded(child: Text(
              value != null ? '${value!.month}/${value!.day}/${value!.year}' : 'Select date',
              style: TextStyle(color: value != null ? kText : kHint, fontSize:13))),
            const Icon(Icons.calendar_today_outlined, color:kMuted, size:16),
          ]),
        ),
      ),
    ],
  );
}

// Empty state helpers
class _EmptyVehicleBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color:kCard, borderRadius:BorderRadius.circular(12), border:Border.all(color:kBorder)),
    child: const Text(
      'No vehicles available.\nTODO: Connect to Laravel API → GET /api/vehicles',
      textAlign: TextAlign.center,
      style: TextStyle(color:kHint, fontSize:12, height:1.7)));
}

class _EmptyShowcase extends StatelessWidget {
  const _EmptyShowcase({required this.onLoad});
  final VoidCallback onLoad;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.directions_car_outlined, color:kHint, size:48),
      const SizedBox(height:12),
      const Text('Vehicles will appear here',
        style: TextStyle(color:kText, fontSize:14, fontWeight:FontWeight.w500)),
      const SizedBox(height:6),
      const Text('TODO: Connect to GET /api/vehicles',
        style: TextStyle(color:kHint, fontSize:11)),
      const SizedBox(height:16),
      OutlinedButton(
        // TODO: call _fetchVehicles() here
        onPressed: onLoad,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color:kBlue),
          foregroundColor: kInfo,
          shape: const StadiumBorder()),
        child: const Text('Load Vehicles')),
    ]),
  );
}