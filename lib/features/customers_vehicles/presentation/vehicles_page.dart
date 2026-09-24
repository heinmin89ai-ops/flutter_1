import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../auth/domain/auth_user.dart';
import '../domain/customer.dart';
import '../domain/customer_vehicle_repository.dart';
import '../domain/license_plate_normalizer.dart';
import '../domain/vehicle.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final CustomerVehicleRepository repository;

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final _searchController = TextEditingController();
  final _uuid = const Uuid();
  StreamSubscription<List<Vehicle>>? _vehicleSubscription;
  List<Vehicle> _vehicles = const [];
  List<Vehicle> _visibleVehicles = const [];
  bool _isSearching = false;
  String? _errorMessage;

  String get _shopId => widget.user.shopId!;

  @override
  void initState() {
    super.initState();
    _vehicleSubscription = widget.repository.watchVehicles(_shopId).listen((vehicles) {
      if (!mounted || _isSearching) return;
      setState(() {
        _vehicles = vehicles;
        _visibleVehicles = vehicles;
      });
    }, onError: (_) {
      if (mounted) setState(() => _errorMessage = 'Unable to load local vehicle records.');
    });
  }

  @override
  void dispose() {
    _vehicleSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicles & customers', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text('Search license plates locally, even when the workshop is offline.'),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _showRegistrationDialog,
              icon: const Icon(Icons.add),
              label: const Text('Register vehicle'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _searchController,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Search license plate',
            hintText: 'e.g. ABC-123',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
          Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
        ],
        if (_visibleVehicles.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No vehicles found.' ))))
        else
          ..._visibleVehicles.map((vehicle) => _VehicleTile(vehicle: vehicle)),
      ],
    );
  }

  Future<void> _search(String value) async {
    setState(() {
      _isSearching = value.trim().isNotEmpty;
      _errorMessage = null;
    });
    if (value.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _visibleVehicles = _vehicles;
      });
      return;
    }
    try {
      final matches = await widget.repository.searchVehicles(shopId: _shopId, licensePlate: value);
      if (mounted) setState(() => _visibleVehicles = matches);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Local search is unavailable.');
    }
  }

  Future<void> _showRegistrationDialog() async {
    final customerName = TextEditingController();
    final customerPhone = TextEditingController();
    final plate = TextEditingController();
    final make = TextEditingController();
    final model = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var customerType = CustomerType.individual;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Register customer and vehicle'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CustomerType>(
                      value: customerType,
                      decoration: const InputDecoration(labelText: 'Customer type'),
                      items: CustomerType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
                      onChanged: (value) => setDialogState(() => customerType = value ?? CustomerType.individual),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: customerName,
                      decoration: const InputDecoration(labelText: 'Customer name'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter a customer name.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: customerPhone, decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: plate,
                      decoration: const InputDecoration(labelText: 'License plate'),
                      validator: (value) => LicensePlateNormalizer.normalize(value ?? '').isEmpty ? 'Enter a license plate.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: make, decoration: const InputDecoration(labelText: 'Make')),
                    const SizedBox(height: 12),
                    TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final customerId = _uuid.v4();
                  final vehicleId = _uuid.v4();
                  try {
                    await widget.repository.createCustomer(Customer(
                      customerId: customerId,
                      shopId: _shopId,
                      type: customerType,
                      name: customerName.text.trim(),
                      phone: customerPhone.text.trim().isEmpty ? null : customerPhone.text.trim(),
                      email: null,
                      address: null,
                      companyName: customerType == CustomerType.company ? customerName.text.trim() : null,
                      taxId: null,
                      notes: null,
                      isActive: true,
                    ));
                    await widget.repository.createVehicle(Vehicle(
                      vehicleId: vehicleId,
                      shopId: _shopId,
                      customerId: customerId,
                      licensePlate: plate.text,
                      normalizedLicensePlate: LicensePlateNormalizer.normalize(plate.text),
                      vin: null,
                      make: make.text.trim().isEmpty ? null : make.text.trim(),
                      model: model.text.trim().isEmpty ? null : model.text.trim(),
                      year: null,
                      color: null,
                      mileage: null,
                      fuelType: null,
                      transmission: null,
                      notes: null,
                    ));
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } catch (_) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Unable to save customer and vehicle.')));
                    }
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      );
    } finally {
      customerName.dispose();
      customerPhone.dispose();
      plate.dispose();
      make.dispose();
      model.dispose();
    }
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.directions_car_outlined)),
        title: Text(vehicle.licensePlate),
        subtitle: Text([vehicle.make, vehicle.model].whereType<String>().where((value) => value.isNotEmpty).join(' ')),
        trailing: Text(vehicle.customerId.substring(0, vehicle.customerId.length > 6 ? 6 : vehicle.customerId.length)),
      ),
    );
  }
}
