/// Make → model → variant catalogue for the Owner & Vehicle Details form,
/// with an indicative ex-showroom price for every variant.
///
/// The prices are approximate list prices used only to *suggest* a present
/// market value on a valuation survey — the agent can always overwrite the
/// suggested figure. Replace this table with the insurer's own rate master
/// when one is available; nothing else in the app depends on the numbers.
library;

/// `variant name → ex-showroom price in rupees`.
typedef VariantPrices = Map<String, int>;

/// `model name → its variants`.
typedef ModelCatalog = Map<String, VariantPrices>;

/// `make → its models`.
typedef MakeCatalog = Map<String, ModelCatalog>;

const MakeCatalog _cars = {
  'Maruti Suzuki': {
    'Swift': {'LXi': 649000, 'VXi': 729000, 'ZXi': 829000, 'ZXi+': 900000},
    'Baleno': {
      'Sigma': 666000,
      'Delta': 750000,
      'Zeta': 843000,
      'Alpha': 938000,
    },
    'Brezza': {'LXi': 834000, 'VXi': 970000, 'ZXi': 1114000, 'ZXi+': 1264000},
  },
  'Hyundai': {
    'i20': {'Era': 704000, 'Magna': 779000, 'Sportz': 833000, 'Asta': 938000},
    'Creta': {'E': 1100000, 'S': 1350000, 'SX': 1550000, 'SX(O)': 1750000},
    'Verna': {'EX': 1100000, 'S': 1200000, 'SX': 1360000, 'SX(O)': 1520000},
  },
  'Tata': {
    'Nexon': {
      'Smart': 800000,
      'Pure': 900000,
      'Creative': 1050000,
      'Fearless': 1250000,
    },
    'Punch': {
      'Pure': 600000,
      'Adventure': 700000,
      'Accomplished': 800000,
      'Creative': 920000,
    },
  },
  'Mahindra': {
    'Scorpio-N': {
      'Z2': 1385000,
      'Z4': 1540000,
      'Z6': 1670000,
      'Z8': 1890000,
      'Z8L': 2090000,
    },
    'XUV 700': {'MX': 1400000, 'AX3': 1640000, 'AX5': 1800000, 'AX7': 2150000},
    'Thar': {'AX(O)': 1135000, 'LX': 1450000},
  },
  'Honda': {
    'City': {'SV': 1180000, 'V': 1270000, 'VX': 1390000, 'ZX': 1540000},
    'Amaze': {'E': 720000, 'S': 810000, 'VX': 900000},
  },
  'Toyota': {
    'Innova Crysta': {'GX': 1990000, 'VX': 2450000, 'ZX': 2630000},
    'Glanza': {'E': 690000, 'S': 780000, 'G': 880000, 'V': 980000},
  },
  'Kia': {
    'Seltos': {'HTE': 1100000, 'HTK': 1250000, 'HTX': 1550000, 'GTX+': 1950000},
    'Sonet': {'HTE': 800000, 'HTK': 900000, 'HTX': 1100000},
  },
};

const MakeCatalog _twoWheelers = {
  'Honda': {
    'Activa 6G': {'Standard': 76000, 'DLX': 82000},
    'Shine': {'Drum': 80000, 'Disc': 85000},
  },
  'Hero': {
    'Splendor Plus': {'Drum': 76000, 'i3S': 78000},
    'HF Deluxe': {'Kick Start': 60000, 'Self Start': 67000},
  },
  'Bajaj': {
    'Pulsar 150': {'Single Disc': 110000, 'Twin Disc': 116000},
    'Platina 110': {'Drum': 70000, 'ABS': 80000},
  },
  'TVS': {
    'Apache RTR 160': {'Drum': 120000, 'Disc': 125000},
    'Jupiter': {'Base': 74000, 'ZX': 85000},
  },
  'Royal Enfield': {
    'Classic 350': {
      'Redditch': 193000,
      'Halcyon': 201000,
      'Signals': 216000,
      'Chrome': 225000,
    },
  },
};

const MakeCatalog _commercial = {
  'Tata': {
    'Ace Gold': {'Petrol': 550000, 'Diesel': 650000},
    'Intra V30': {'Standard': 800000},
    'LPT 1618': {'Cab Chassis': 2500000},
  },
  'Mahindra': {
    'Bolero Pik-Up': {'1.3T': 900000, '1.7T': 1000000},
    'Supro': {'Mini Truck': 650000},
  },
  'Ashok Leyland': {
    'Dost': {'Strong': 780000, 'Plus': 820000},
    'Ecomet 1615': {'Cab Chassis': 2400000},
  },
  'Eicher': {
    'Pro 2049': {'Standard': 1550000},
  },
};

/// Catalogue for a "Select Product" value. Taxis are cars; anything unknown
/// falls back to cars too, matching `categoryForProduct`.
MakeCatalog catalogForProduct(String? product) => switch (product) {
  'Two Wheeler' => _twoWheelers,
  'Commercial Vehicle' => _commercial,
  _ => _cars,
};

/// Makes on offer for [product], in catalogue order.
List<String> makesFor(String? product) =>
    catalogForProduct(product).keys.toList();

/// Models of [make] for [product] (empty until a make is chosen).
List<String> modelsFor(String? product, String? make) =>
    catalogForProduct(product)[make]?.keys.toList() ?? const [];

/// Variants of [model] (empty until a model is chosen).
List<String> variantsFor(String? product, String? make, String? model) =>
    catalogForProduct(product)[make]?[model]?.keys.toList() ?? const [];

/// Indicative ex-showroom price of a variant, or null if it isn't catalogued.
int? exShowroomPrice(
  String? product,
  String? make,
  String? model,
  String? variant,
) => catalogForProduct(product)[make]?[model]?[variant];

/// Depreciation applied to the ex-showroom price for a vehicle of [ageInMonths].
///
/// Up to five years this is the IRDAI motor-tariff IDV schedule (5% under six
/// months, then 15/20/30/40/50%). Beyond five years the tariff leaves the
/// value to agreement between insurer and insured, so the schedule simply
/// keeps stepping down to give the agent a sensible starting figure.
double depreciationFor(int ageInMonths) {
  if (ageInMonths <= 6) return 0.05;
  if (ageInMonths <= 12) return 0.15;
  if (ageInMonths <= 24) return 0.20;
  if (ageInMonths <= 36) return 0.30;
  if (ageInMonths <= 48) return 0.40;
  if (ageInMonths <= 60) return 0.50;
  if (ageInMonths <= 84) return 0.55;
  if (ageInMonths <= 120) return 0.65;
  return 0.75;
}

/// Whole months between [manufactured] and [now] (never negative).
int ageInMonths(DateTime manufactured, DateTime now) {
  final months =
      (now.year - manufactured.year) * 12 + (now.month - manufactured.month);
  return months < 0 ? 0 : months;
}

/// A suggested present market value and how it was arrived at.
class MarketValueEstimate {
  const MarketValueEstimate({
    required this.exShowroom,
    required this.ageInMonths,
    required this.depreciation,
    required this.value,
  });

  final int exShowroom;
  final int ageInMonths;

  /// Fraction knocked off the ex-showroom price, e.g. `0.3` for 30%.
  final double depreciation;

  /// Suggested value in rupees, rounded to the nearest hundred.
  final int value;
}

/// Suggests a present market value for the selected vehicle, or null while
/// the variant or manufacturing date is still missing.
MarketValueEstimate? estimateMarketValue({
  required String? product,
  required String? make,
  required String? model,
  required String? variant,
  required DateTime? manufactured,
  DateTime? now,
}) {
  final price = exShowroomPrice(product, make, model, variant);
  if (price == null || manufactured == null) return null;

  final months = ageInMonths(manufactured, now ?? DateTime.now());
  final depreciation = depreciationFor(months);
  final raw = price * (1 - depreciation);
  return MarketValueEstimate(
    exShowroom: price,
    ageInMonths: months,
    depreciation: depreciation,
    value: (raw / 100).round() * 100,
  );
}
