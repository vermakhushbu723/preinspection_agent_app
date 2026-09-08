import '../vehicle_category.dart';

/// Form data captured on OwnerVehicleDetailsPage. Port of the form state in
/// `OwnerVehicleDetailsPage.jsx`.
///
/// Screens further down the flow (DamageReview, InspectionDetails,
/// VehicleInformation) read from this instead of showing hardcoded mock
/// data like the web app does.
class OwnerVehicleDetails {
  const OwnerVehicleDetails({
    required this.surveyType,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.odometer,
    required this.registrationNumber,
    required this.state,
    required this.registrationDate,
    required this.product,
    required this.make,
    required this.model,
    required this.variant,
    required this.manufacturingYear,
    required this.ownerSerialNumber,
    required this.idv,
  });

  /// 'pre inspection' or 'Valuation' -- preinspection-only radio group.
  final String surveyType;
  final String ownerName;
  final String mobile;
  final String email;
  final String odometer;
  final String registrationNumber;
  final String state;
  final String registrationDate;
  final String product;
  final String make;
  final String model;
  final String variant;
  final String manufacturingYear;
  final String ownerSerialNumber;

  /// Present market value / IDV, in rupees.
  final String idv;

  VehicleCategory get vehicleCategory => categoryForProduct(product);

  static const empty = OwnerVehicleDetails(
    surveyType: 'pre inspection',
    ownerName: '',
    mobile: '',
    email: '',
    odometer: '',
    registrationNumber: '',
    state: '',
    registrationDate: '',
    product: '',
    make: '',
    model: '',
    variant: '',
    manufacturingYear: '',
    ownerSerialNumber: '',
    idv: '',
  );
}
