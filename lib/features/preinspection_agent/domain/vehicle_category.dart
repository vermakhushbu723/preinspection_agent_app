/// Vehicle silhouette category. Port of `VEHICLE_CATEGORIES` in
/// `src/constants/vehicleAssets.js`.
enum VehicleCategory { car, bike, truck }

extension VehicleCategoryX on VehicleCategory {
  String get assetFolder => switch (this) {
    VehicleCategory.car => 'car',
    VehicleCategory.bike => 'bike',
    VehicleCategory.truck => 'truck',
  };
}

/// Maps the "Product" dropdown value (OwnerVehicleDetailsPage) to a vehicle
/// category. Port of `PRODUCT_TO_CATEGORY` in `vehicleAssets.js`.
const Map<String, VehicleCategory> productToCategory = {
  'Private Car': VehicleCategory.car,
  'Taxi': VehicleCategory.car,
  'Two Wheeler': VehicleCategory.bike,
  'Commercial Vehicle': VehicleCategory.truck,
};

VehicleCategory categoryForProduct(String? product) =>
    productToCategory[product] ?? VehicleCategory.car;
