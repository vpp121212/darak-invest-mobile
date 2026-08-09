import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/offer.dart';
import '../services/api_service.dart';

/// حالة الوساطة: المواعيد والعروض وتحديثاتها.
class BrokerageState {
  final List<Booking> bookings;
  final List<Offer> offers;
  final bool isLoading;
  final String? error;

  const BrokerageState({
    this.bookings = const [],
    this.offers = const [],
    this.isLoading = false,
    this.error,
  });

  BrokerageState copyWith({
    List<Booking>? bookings,
    List<Offer>? offers,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BrokerageState(
      bookings: bookings ?? this.bookings,
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BrokerageNotifier extends StateNotifier<BrokerageState> {
  BrokerageNotifier() : super(const BrokerageState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        ApiService.getBookings(),
        ApiService.getOffers(),
      ]);
      state = BrokerageState(
        bookings: results[0] as List<Booking>,
        offers: results[1] as List<Offer>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> book({
    required String propertyId,
    required DateTime scheduledAt,
    String type = 'معاينة',
    String note = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService.createBooking(
        propertyId: propertyId,
        scheduledAt: scheduledAt.toIso8601String(),
        type: type,
        note: note,
      );
      state = state.copyWith(isLoading: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> submitOffer({
    required String propertyId,
    required double amount,
    String paymentMethod = 'نقدي',
    String note = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService.createOffer(
        propertyId: propertyId,
        amount: amount,
        paymentMethod: paymentMethod,
        note: note,
      );
      state = state.copyWith(isLoading: false);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateBookingStatus(String id, String status) async {
    try {
      await ApiService.updateBookingStatus(id: id, status: status);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateOfferStatus(String id, String status) async {
    try {
      await ApiService.updateOfferStatus(id: id, status: status);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final brokerageProvider =
    StateNotifierProvider<BrokerageNotifier, BrokerageState>((ref) {
  return BrokerageNotifier();
});
