import 'package:darak_wa_hayk/models/realestate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RealEstateContract', () {
    test('parses the contracts API shape', () {
      final c = RealEstateContract.fromJson(const {
        'id': 4,
        'contract_type': 'إيجار',
        'contract_number': 'CTR-ABC123',
        'first_party': 'م. خالد',
        'second_party': 'أ. نورة',
        'property_desc': 'فيلا في حي الملقا',
        'property_city': 'الرياض',
        'amount': 120000,
        'status': 'draft',
        'is_authenticated': 0,
      });
      expect(c.id, '4');
      expect(c.contractType, 'إيجار');
      expect(c.contractNumber, 'CTR-ABC123');
      expect(c.firstParty, 'م. خالد');
      expect(c.secondParty, 'أ. نورة');
      expect(c.amount, 120000);
      expect(c.isDraft, isTrue);
      expect(c.statusLabel, 'مسودة');
      expect(c.isAuthenticated, isFalse);
    });

    test('flags authenticated contracts', () {
      final c = RealEstateContract.fromJson(const {
        'id': 1,
        'contract_number': 'X',
        'status': 'active',
        'is_authenticated': 1,
      });
      expect(c.isActive, isTrue);
      expect(c.isAuthenticated, isTrue);
      expect(c.statusLabel, 'نشط');
    });
  });

  group('RentalInvoice', () {
    test('parses an invoice row', () {
      final v = RentalInvoice.fromJson(const {
        'id': 9,
        'invoice_number': 'INV-1',
        'tenant_name': 'عبدالله',
        'property_title': 'شقة',
        'period_from': '2026-09-01',
        'rent_amount': 4000,
        'services_fee': 200,
        'tax_amount': 420,
        'total_amount': 4620,
        'payment_method': 'تحويل بنكي',
        'status': 'pending',
      });
      expect(v.id, '9');
      expect(v.tenantName, 'عبدالله');
      expect(v.totalAmount, 4620);
      expect(v.isPaid, isFalse);
      expect(v.statusLabel, 'قيد الانتظار');
    });

    test('status helpers', () {
      RentalInvoice at(String s) => RentalInvoice.fromJson({
            'id': 1,
            'invoice_number': 'X',
            'status': s,
          });
      expect(at('paid').isPaid, isTrue);
      expect(at('overdue').isOverdue, isTrue);
      expect(at('paid').statusLabel, 'مدفوعة');
    });
  });

  group('RealEstateLicense & Deed', () {
    test('parses a license row', () {
      final l = RealEstateLicense.fromJson(const {
        'id': 2,
        'license_type': 'وساطة عقارية',
        'license_number': 'LIC-1',
        'holder_name': 'مكتب الأفق',
        'city': 'الرياض',
        'status': 'active',
      });
      expect(l.isActive, isTrue);
      expect(l.statusLabel, 'نشط');
      expect(l.holderName, 'مكتب الأفق');
    });

    test('parses a deed row', () {
      final d = RealEstateDeed.fromJson(const {
        'id': 3,
        'deed_number': 'DEED-1',
        'property_desc': 'أرض في حي النرجس',
        'area': 750,
        'owner_name': 'سارة',
        'deed_type': 'صك ملكية',
        'issuing_court': 'المحكمة العامة',
      });
      expect(d.deedNumber, 'DEED-1');
      expect(d.area, 750);
      expect(d.ownerName, 'سارة');
      expect(d.deedType, 'صك ملكية');
    });
  });

  group('ManagementStats & InvoiceTotals', () {
    test('parses dashboard stats', () {
      final s = ManagementStats.fromJson(const {
        'licenses': 2,
        'contracts': 5,
        'contracts_authenticated': 3,
        'delivery_forms': 1,
        'invoices': 4,
        'invoice_total': 18480,
        'deeds': 1,
      });
      expect(s.contracts, 5);
      expect(s.contractsAuthenticated, 3);
      expect(s.invoices, 4);
      expect(s.invoiceTotal, 18480);
      expect(s.deeds, 1);
    });

    test('parses invoice totals', () {
      final t = InvoiceTotals.fromJson(const {
        'paid_total': 9240,
        'pending_total': 4620,
        'overdue_total': 4620,
        'count': 4,
      });
      expect(t.paid, 9240);
      expect(t.pending, 4620);
      expect(t.overdue, 4620);
      expect(t.count, 4);
    });
  });

  group('MaintenanceRequest', () {
    test('parses a maintenance row', () {
      final m = MaintenanceRequest.fromJson(const {
        'id': 7,
        'category': 'تكييف',
        'title': 'تبريد ضعيف',
        'description': 'المكيف لا يبرّد',
        'priority': 'high',
        'status': 'in_progress',
        'cost': 350,
        'propertyTitle': 'شقة حي الورود',
        'vendorName': 'مؤسسة التبريد',
      });
      expect(m.id, '7');
      expect(m.category, 'تكييف');
      expect(m.title, 'تبريد ضعيف');
      expect(m.priorityLabel, 'عالية');
      expect(m.isInProgress, isTrue);
      expect(m.statusLabel, 'قيد التنفيذ');
      expect(m.cost, 350);
      expect(m.vendorName, 'مؤسسة التبريد');
    });

    test('status helpers and labels', () {
      MaintenanceRequest at(String s) => MaintenanceRequest.fromJson({'id': 1, 'status': s});
      expect(at('pending').isPending, isTrue);
      expect(at('assigned').isAssigned, isTrue);
      expect(at('completed').isCompleted, isTrue);
      expect(at('cancelled').isCancelled, isTrue);
      expect(at('completed').statusLabel, 'مكتمل');
      expect(at('pending').statusLabel, 'قيد الانتظار');
    });
  });
}
