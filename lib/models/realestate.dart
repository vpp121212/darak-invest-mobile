/// نماذج وحدة إدارة العقارات المتصلة بـ /api/realestate.
library;

class ManagementStats {
  final int licenses;
  final int contracts;
  final int contractsAuthenticated;
  final int deliveryForms;
  final int invoices;
  final double invoiceTotal;
  final int deeds;

  const ManagementStats({
    this.licenses = 0,
    this.contracts = 0,
    this.contractsAuthenticated = 0,
    this.deliveryForms = 0,
    this.invoices = 0,
    this.invoiceTotal = 0,
    this.deeds = 0,
  });

  factory ManagementStats.fromJson(Map<String, dynamic> json) {
    return ManagementStats(
      licenses: (json['licenses'] ?? 0),
      contracts: (json['contracts'] ?? 0),
      contractsAuthenticated: (json['contracts_authenticated'] ?? 0),
      deliveryForms: (json['delivery_forms'] ?? 0),
      invoices: (json['invoices'] ?? 0),
      invoiceTotal: (json['invoice_total'] ?? 0).toDouble(),
      deeds: (json['deeds'] ?? 0),
    );
  }
}

String _str(dynamic v) => v == null ? '' : v.toString();

class RealEstateContract {
  final String id;
  final String contractType;
  final String contractNumber;
  final String firstParty;
  final String secondParty;
  final String propertyDesc;
  final String propertyCity;
  final String propertyDistrict;
  final double amount;
  final String paymentTerms;
  final String duration;
  final String status;
  final bool isAuthenticated;
  final String createdAt;

  const RealEstateContract({
    required this.id,
    this.contractType = 'إيجار',
    required this.contractNumber,
    this.firstParty = '',
    this.secondParty = '',
    this.propertyDesc = '',
    this.propertyCity = '',
    this.propertyDistrict = '',
    this.amount = 0,
    this.paymentTerms = '',
    this.duration = '',
    this.status = 'draft',
    this.isAuthenticated = false,
    this.createdAt = '',
  });

  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel => switch (status) {
        'draft' => 'مسودة',
        'active' => 'نشط',
        'completed' => 'مكتمل',
        'cancelled' => 'ملغي',
        _ => status,
      };

  factory RealEstateContract.fromJson(Map<String, dynamic> json) {
    return RealEstateContract(
      id: (json['id'] ?? '').toString(),
      contractType: _str(json['contract_type']),
      contractNumber: _str(json['contract_number']),
      firstParty: _str(json['first_party']),
      secondParty: _str(json['second_party']),
      propertyDesc: _str(json['property_desc']),
      propertyCity: _str(json['property_city']),
      propertyDistrict: _str(json['property_district']),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentTerms: _str(json['payment_terms']),
      duration: _str(json['duration']),
      status: _str(json['status']),
      isAuthenticated: (json['is_authenticated'] ?? 0) == 1,
      createdAt: _str(json['createdAt']),
    );
  }
}

class RentalInvoice {
  final String id;
  final String invoiceNumber;
  final String tenantName;
  final String propertyTitle;
  final String periodFrom;
  final String periodTo;
  final double rentAmount;
  final double servicesFee;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String status;

  const RentalInvoice({
    required this.id,
    required this.invoiceNumber,
    this.tenantName = '',
    this.propertyTitle = '',
    this.periodFrom = '',
    this.periodTo = '',
    this.rentAmount = 0,
    this.servicesFee = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.paymentMethod = 'نقدي',
    this.status = 'pending',
  });

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';

  String get statusLabel => switch (status) {
        'paid' => 'مدفوعة',
        'pending' => 'قيد الانتظار',
        'overdue' => 'متأخرة',
        'cancelled' => 'ملغاة',
        _ => status,
      };

  factory RentalInvoice.fromJson(Map<String, dynamic> json) {
    return RentalInvoice(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: _str(json['invoice_number']),
      tenantName: _str(json['tenant_name']),
      propertyTitle: _str(json['property_title']),
      periodFrom: _str(json['period_from']),
      periodTo: _str(json['period_to']),
      rentAmount: (json['rent_amount'] ?? 0).toDouble(),
      servicesFee: (json['services_fee'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentMethod: _str(json['payment_method']),
      status: _str(json['status']),
    );
  }
}

class RealEstateLicense {
  final String id;
  final String licenseType;
  final String licenseNumber;
  final String holderName;
  final String city;
  final String status;
  final String expiryDate;

  const RealEstateLicense({
    required this.id,
    required this.licenseNumber,
    this.licenseType = 'وساطة عقارية',
    this.holderName = '',
    this.city = '',
    this.status = 'pending',
    this.expiryDate = '',
  });

  bool get isActive => status == 'active';

  String get statusLabel => switch (status) {
        'active' => 'نشط',
        'pending' => 'قيد المراجعة',
        'rejected' => 'مرفوض',
        _ => status,
      };

  factory RealEstateLicense.fromJson(Map<String, dynamic> json) {
    return RealEstateLicense(
      id: (json['id'] ?? '').toString(),
      licenseType: _str(json['license_type']),
      licenseNumber: _str(json['license_number']),
      holderName: _str(json['holder_name']),
      city: _str(json['city']),
      status: _str(json['status']),
      expiryDate: _str(json['expiry_date']),
    );
  }
}

class RealEstateDeed {
  final String id;
  final String deedNumber;
  final String propertyDesc;
  final String propertyCity;
  final String propertyDistrict;
  final double area;
  final String ownerName;
  final String deedType;
  final String issuingCourt;
  final String issueDate;

  const RealEstateDeed({
    required this.id,
    required this.deedNumber,
    this.propertyDesc = '',
    this.propertyCity = '',
    this.propertyDistrict = '',
    this.area = 0,
    this.ownerName = '',
    this.deedType = 'صك ملكية',
    this.issuingCourt = '',
    this.issueDate = '',
  });

  factory RealEstateDeed.fromJson(Map<String, dynamic> json) {
    return RealEstateDeed(
      id: (json['id'] ?? '').toString(),
      deedNumber: _str(json['deed_number']),
      propertyDesc: _str(json['property_desc']),
      propertyCity: _str(json['property_city']),
      propertyDistrict: _str(json['property_district']),
      area: (json['area'] ?? 0).toDouble(),
      ownerName: _str(json['owner_name']),
      deedType: _str(json['deed_type']),
      issuingCourt: _str(json['issuing_court']),
      issueDate: _str(json['issue_date']),
    );
  }
}

class InvoiceTotals {
  final double paid;
  final double pending;
  final double overdue;
  final int count;

  const InvoiceTotals({
    this.paid = 0,
    this.pending = 0,
    this.overdue = 0,
    this.count = 0,
  });

  factory InvoiceTotals.fromJson(Map<String, dynamic> json) {
    return InvoiceTotals(
      paid: (json['paid_total'] ?? 0).toDouble(),
      pending: (json['pending_total'] ?? 0).toDouble(),
      overdue: (json['overdue_total'] ?? 0).toDouble(),
      count: (json['count'] ?? 0),
    );
  }
}
