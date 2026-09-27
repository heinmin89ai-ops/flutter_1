import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/localization/enum_l10n.dart';
import '../../../app/widgets/page_header.dart';
import '../../../core/firestore/resilient_query.dart';
import '../../../l10n/app_localizations.dart';
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

  /// Holds a stable error code rather than prose so the message can be
  /// translated with the widget tree's [AppLocalizations] on every rebuild.
  String? _errorCode;

  String get _shopId => widget.user.shopId!;

  String? _errorText(AppLocalizations l10n) => switch (_errorCode) {
    _vehiclesErrorLoad => l10n.vehiclesLoadError,
    _vehiclesErrorSearch => l10n.vehiclesSearchUnavailable,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _vehicleSubscription = resilientQuery(() => widget.repository.watchVehicles(_shopId)).listen((vehicles) {
      if (!mounted || _isSearching) return;
      setState(() {
        _vehicles = vehicles;
        _visibleVehicles = vehicles;
      });
    }, onError: (_) {
      if (mounted) setState(() => _errorCode = _vehiclesErrorLoad);
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
    final l10n = AppLocalizations.of(context);
    final errorText = _errorText(l10n);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeader(
          title: l10n.vehiclesPageTitle,
          subtitle: l10n.vehiclesPageSubtitle,
          action: FilledButton.icon(
            onPressed: _showRegistrationDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.vehiclesRegisterVehicle),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _searchController,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: l10n.vehiclesSearchLabel,
            hintText: l10n.vehiclesSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.vehiclesClearSearch,
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (errorText != null) ...[
          Text(errorText, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
        ],
        if (_visibleVehicles.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.vehiclesEmpty))))
        else
          ..._visibleVehicles.map((vehicle) => _VehicleTile(vehicle: vehicle)),
      ],
    );
  }

  Future<void> _search(String value) async {
    setState(() {
      _isSearching = value.trim().isNotEmpty;
      _errorCode = null;
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
      if (mounted) setState(() => _errorCode = _vehiclesErrorSearch);
    }
  }

  Future<void> _showRegistrationDialog() async {
    final l10n = AppLocalizations.of(context);
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
            title: Text(l10n.vehiclesDialogTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CustomerType>(isExpanded: true,
                      value: customerType,
                      decoration: InputDecoration(labelText: l10n.vehiclesCustomerTypeLabel),
                      items: CustomerType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.localizedLabel(l10n)))).toList(),
                      onChanged: (value) => setDialogState(() => customerType = value ?? CustomerType.individual),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: customerName,
                      decoration: InputDecoration(labelText: l10n.vehiclesCustomerNameLabel),
                      validator: (value) => value == null || value.trim().isEmpty ? l10n.vehiclesValidationCustomerName : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: customerPhone, decoration: InputDecoration(labelText: l10n.vehiclesPhoneLabel)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: plate,
                      decoration: InputDecoration(labelText: l10n.vehiclesPlateLabel),
                      validator: (value) => LicensePlateNormalizer.normalize(value ?? '').isEmpty ? l10n.vehiclesValidationPlate : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: make, decoration: InputDecoration(labelText: l10n.vehiclesMakeLabel)),
                    const SizedBox(height: 12),
                    TextFormField(controller: model, decoration: InputDecoration(labelText: l10n.vehiclesModelLabel)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
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
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(l10n.vehiclesSaveError)));
                    }
                  }
                },
                child: Text(l10n.vehiclesRegisterSubmit),
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

const _vehiclesErrorLoad = 'load';
const _vehiclesErrorSearch = 'search';

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
