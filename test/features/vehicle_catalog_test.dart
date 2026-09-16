import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/features/preinspection_agent/data/vehicle_catalog.dart';

void main() {
  group('dependent lists', () {
    test('makes follow the product', () {
      expect(makesFor('Private Car'), contains('Maruti Suzuki'));
      expect(makesFor('Two Wheeler'), contains('Royal Enfield'));
      expect(makesFor('Two Wheeler'), isNot(contains('Maruti Suzuki')));
      expect(makesFor('Commercial Vehicle'), contains('Ashok Leyland'));
      // Taxis are cars.
      expect(makesFor('Taxi'), makesFor('Private Car'));
    });

    test('models follow the make and variants follow the model', () {
      expect(modelsFor('Private Car', 'Mahindra'), contains('Scorpio-N'));
      expect(modelsFor('Private Car', 'Hyundai'), isNot(contains('Scorpio-N')));
      expect(variantsFor('Private Car', 'Mahindra', 'Scorpio-N'), [
        'Z2',
        'Z4',
        'Z6',
        'Z8',
        'Z8L',
      ]);
    });

    test('nothing is offered until the parent is chosen', () {
      expect(modelsFor('Private Car', null), isEmpty);
      expect(variantsFor('Private Car', 'Mahindra', null), isEmpty);
    });
  });

  group('depreciation schedule', () {
    test('follows the IRDAI slabs for the first five years', () {
      expect(depreciationFor(0), 0.05);
      expect(depreciationFor(6), 0.05);
      expect(depreciationFor(7), 0.15);
      expect(depreciationFor(12), 0.15);
      expect(depreciationFor(24), 0.20);
      expect(depreciationFor(36), 0.30);
      expect(depreciationFor(48), 0.40);
      expect(depreciationFor(60), 0.50);
    });

    test('keeps stepping down after five years', () {
      expect(depreciationFor(61), 0.55);
      expect(depreciationFor(120), 0.65);
      expect(depreciationFor(200), 0.75);
    });

    test('age is counted in whole months and never negative', () {
      expect(ageInMonths(DateTime(2023, 3), DateTime(2026, 9)), 42);
      expect(ageInMonths(DateTime(2027, 1), DateTime(2026, 9)), 0);
    });
  });

  group('estimateMarketValue', () {
    test('depreciates the selected variant by the vehicle age', () {
      final estimate = estimateMarketValue(
        product: 'Private Car',
        make: 'Mahindra',
        model: 'Scorpio-N',
        variant: 'Z8',
        manufactured: DateTime(2023, 3),
        now: DateTime(2026, 9),
      )!;

      expect(estimate.exShowroom, 1890000);
      expect(estimate.ageInMonths, 42);
      expect(estimate.depreciation, 0.40);
      expect(estimate.value, 1134000); // 18,90,000 less 40%
    });

    test('a different selection gives a different value', () {
      final top = estimateMarketValue(
        product: 'Private Car',
        make: 'Mahindra',
        model: 'Scorpio-N',
        variant: 'Z8L',
        manufactured: DateTime(2025, 9),
        now: DateTime(2026, 9),
      )!;
      final base = estimateMarketValue(
        product: 'Private Car',
        make: 'Mahindra',
        model: 'Scorpio-N',
        variant: 'Z2',
        manufactured: DateTime(2025, 9),
        now: DateTime(2026, 9),
      )!;
      expect(top.value, greaterThan(base.value));
    });

    test('rounds to the nearest hundred rupees', () {
      final estimate = estimateMarketValue(
        product: 'Two Wheeler',
        make: 'Honda',
        model: 'Activa 6G',
        variant: 'DLX',
        manufactured: DateTime(2026, 5),
        now: DateTime(2026, 9),
      )!;
      // 82,000 less 5% = 77,900
      expect(estimate.value, 77900);
      expect(estimate.value % 100, 0);
    });

    test('is null until the variant and manufacturing date are both known', () {
      expect(
        estimateMarketValue(
          product: 'Private Car',
          make: 'Mahindra',
          model: 'Scorpio-N',
          variant: null,
          manufactured: DateTime(2023),
        ),
        isNull,
      );
      expect(
        estimateMarketValue(
          product: 'Private Car',
          make: 'Mahindra',
          model: 'Scorpio-N',
          variant: 'Z2',
          manufactured: null,
        ),
        isNull,
      );
    });
  });
}
