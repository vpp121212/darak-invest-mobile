import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/realestate.dart';
import '../services/api_service.dart';

class ManagementState {
  final ManagementStats stats;
  final List<RealEstateContract> contracts;
  final List<RentalInvoice> invoices;
  final InvoiceTotals invoiceTotals;
  final List<RealEstateLicense> licenses;
  final List<RealEstateDeed> deeds;
  final List<MaintenanceRequest> maintenance;
  final bool isLoading;
  final String? error;

  const ManagementState({
    this.stats = const ManagementStats(),
    this.contracts = const [],
    this.invoices = const [],
    this.invoiceTotals = const InvoiceTotals(),
    this.licenses = const [],
    this.deeds = const [],
    this.maintenance = const [],
    this.isLoading = false,
    this.error,
  });

  ManagementState copyWith({
    ManagementStats? stats,
    List<RealEstateContract>? contracts,
    List<RentalInvoice>? invoices,
    InvoiceTotals? invoiceTotals,
    List<RealEstateLicense>? licenses,
    List<RealEstateDeed>? deeds,
    List<MaintenanceRequest>? maintenance,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ManagementState(
      stats: stats ?? this.stats,
      contracts: contracts ?? this.contracts,
      invoices: invoices ?? this.invoices,
      invoiceTotals: invoiceTotals ?? this.invoiceTotals,
      licenses: licenses ?? this.licenses,
      deeds: deeds ?? this.deeds,
      maintenance: maintenance ?? this.maintenance,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ManagementNotifier extends StateNotifier<ManagementState> {
  ManagementNotifier() : super(const ManagementState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        ApiService.getManagementStats(),
        ApiService.getContracts(),
        ApiService.getInvoices(),
        ApiService.getLicenses(),
        ApiService.getDeeds(),
        ApiService.getMaintenanceRequests(),
      ]);
      state = ManagementState(
        stats: results[0] as ManagementStats,
        contracts: results[1] as List<RealEstateContract>,
        invoices: (results[2] as (List<RentalInvoice>, InvoiceTotals)).$1,
        invoiceTotals: (results[2] as (List<RentalInvoice>, InvoiceTotals)).$2,
        licenses: results[3] as List<RealEstateLicense>,
        deeds: results[4] as List<RealEstateDeed>,
        maintenance: results[5] as List<MaintenanceRequest>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addContract(Map<String, dynamic> data) async {
    try {
      await ApiService.createContract(data);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> authenticateContract(String id) async {
    try {
      await ApiService.authenticateContract(id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateContract(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateContract(id, data);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addInvoice(Map<String, dynamic> data) async {
    try {
      await ApiService.createInvoice(data);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> payInvoice(String id) async {
    try {
      await ApiService.payInvoice(id);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addLicense(Map<String, dynamic> data) async {
    try {
      await ApiService.createLicense(data);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addDeed(Map<String, dynamic> data) async {
    try {
      await ApiService.createDeed(data);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addMaintenance(Map<String, dynamic> data) async {
    try {
      await ApiService.createMaintenanceRequest(data);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateMaintenanceStatus(String id, String status) async {
    try {
      await ApiService.updateMaintenanceStatus(id, status);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final managementProvider =
    StateNotifierProvider<ManagementNotifier, ManagementState>((ref) {
  return ManagementNotifier();
});
