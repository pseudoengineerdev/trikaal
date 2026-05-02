import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';
import 'package:trikaal_mobile/features/features/presentation/birth_chart_detail_page.dart';

void main() {
  testWidgets('table tab defaults to D1 and keeps ascendant row first',
      (WidgetTester tester) async {
    final birthInputState = BirthInputState(
      firstName: 'Sahil',
      dateOfBirth: '1999-07-04',
      timeOfBirth: '12:22',
      placeOfBirth: 'Mumbai',
    );
    addTearDown(birthInputState.dispose);
    birthInputState.markReportComputed(
      ComputeReportResponse.fromJson(_sampleReportJson()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BirthChartDetailPage(birthInputState: birthInputState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('table-chart-selector')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('table-D1-degree-sun')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('table-D1-graha-lagna')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('table-chart-status')), findsNothing);
    expect(
        find.byKey(const ValueKey<String>('table-chart-source')), findsNothing);

    final lagnaPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D1-graha-lagna')));
    final sunPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D1-graha-sun')));
    expect(lagnaPosition.dy, lessThan(sunPosition.dy));

    await tester
        .tap(find.byKey(const ValueKey<String>('table-chart-selector')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('table-chart-option-D9')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final d9Degree = tester.widget<Text>(
      find.byKey(const ValueKey<String>('table-D9-degree-sun')),
    );
    expect(d9Degree.data, '18°01\'12"');
    final d9LagnaPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D9-graha-lagna')));
    final d9SunPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D9-graha-sun')));
    expect(d9LagnaPosition.dy, lessThan(d9SunPosition.dy));
    expect(find.byKey(const ValueKey<String>('table-D9-house-sun')),
        findsOneWidget);

    expect(find.byType(DataTable), findsOneWidget);
  });
}

Map<String, dynamic> _sampleReportJson() {
  return <String, dynamic>{
    'profile': <String, dynamic>{
      'profile_id': 'vedic_lahiri_v1',
      'zodiac_system': 'sidereal',
      'ayanamsha': 'lahiri_chitrapaksha',
      'calculation_method': 'modern_ephemeris',
    },
    'normalized_input': <String, dynamic>{
      'local_date': '1999-07-04',
      'local_time': '12:22',
      'place_query': 'Mumbai',
    },
    'resolved_place': <String, dynamic>{
      'place_label': 'Mumbai, Maharashtra, India',
      'latitude': 19.076,
      'longitude': 72.8777,
      'timezone': 'Asia/Kolkata',
      'elevation_m': 14.0,
    },
    'snapshot': <String, dynamic>{
      'meta': <String, dynamic>{
        'status': 'computed',
        'profile_id': 'vedic_lahiri_v1',
        'timezone': 'Asia/Kolkata',
        'utc_iso': '1999-07-04T06:52:00+00:00',
      },
      'panchanga': <String, dynamic>{
        'vara': <String, dynamic>{
          'number': 1,
          'name_vedic': 'Ravivara',
          'name_english': 'Sunday',
        },
        'tithi': <String, dynamic>{
          'number': 21,
          'paksha': 'Krishna',
          'paksha_english': 'Waning',
          'name_vedic': 'Krishna Shashthi',
          'name_english': 'Waning Shashthi',
          'progress_percent': 32.0,
        },
        'nakshatra': <String, dynamic>{
          'number': 25,
          'name_vedic': 'P Bhadrapada',
          'name_english': 'Purva Bhadrapada',
          'pada': 1,
          'progress_percent': 4.0,
        },
        'yoga': <String, dynamic>{
          'number': 3,
          'name_vedic': 'Ayushman',
          'name_english': 'Ayushman',
          'progress_percent': 12.0,
        },
        'karana': <String, dynamic>{
          'serial': 55,
          'name_vedic': 'Garija',
          'name_english': 'Garija',
          'progress_percent': 64.0,
        },
        'sunrise': <String, dynamic>{
          'utc_iso': '1999-07-04T00:33:00+00:00',
          'local_iso': '1999-07-04T06:03:00+05:30',
          'local_time': '06:03',
        },
        'sunset': <String, dynamic>{
          'utc_iso': '1999-07-04T13:43:00+00:00',
          'local_iso': '1999-07-04T19:13:00+05:30',
          'local_time': '19:13',
        },
      },
      'astronomy': _sampleAstronomy(),
      'vedic': _sampleVedic(),
      'bhava': _sampleBhava(),
      'varga': <String, dynamic>{
        'd1': _sampleDivision(lagnaRashi: 'Kany'),
        'd9': _sampleDivision(lagnaRashi: 'Maka'),
      },
      'graha_table': _sampleGrahaTable(),
    },
    'dasha': <String, dynamic>{
      'system': 'Vimshottari',
      'as_of_iso': '1999-07-04T06:52:00+00:00',
      'birth_moon_nakshatra': 'P Bhadrapada',
      'current_maha_dasha': 'Ketu',
      'current_antar_dasha': 'Rahu',
      'active_from': '1995-01-01T00:00:00+00:00',
      'active_until': '2002-01-01T00:00:00+00:00',
      'current_maha_start': '1995-01-01T00:00:00+00:00',
      'current_maha_end': '2002-01-01T00:00:00+00:00',
      'maha_timeline': _sampleTimeline(),
      'antar_timeline_current_maha': _sampleTimeline(),
    },
    'interpretations': <String, dynamic>{
      'version': 'v1',
      'cards': _sampleInterpretationCards(),
    },
    'daily_transit': <String, dynamic>{
      'version': 'v1',
      'as_of_local_iso': '2026-04-01T09:15+05:30',
      'timezone': 'Asia/Kolkata',
      'cards': _sampleDailyTransitCards(),
    },
  };
}

Map<String, dynamic> _sampleAstronomy() {
  const keys = <String>[
    'julian_day_utc',
    'reference_display_offset_deg',
    'reference_lagna_display_offset_deg',
    'sun_sidereal_deg',
    'sun_sidereal_deg_raw',
    'moon_sidereal_deg',
    'moon_sidereal_deg_raw',
    'mangal_sidereal_deg',
    'mangal_sidereal_deg_raw',
    'budha_sidereal_deg',
    'budha_sidereal_deg_raw',
    'guru_sidereal_deg',
    'guru_sidereal_deg_raw',
    'shukra_sidereal_deg',
    'shukra_sidereal_deg_raw',
    'shani_sidereal_deg',
    'shani_sidereal_deg_raw',
    'rahu_sidereal_deg',
    'rahu_sidereal_deg_raw',
    'ketu_sidereal_deg',
    'ketu_sidereal_deg_raw',
    'spashth_rahu_sidereal_deg',
    'spashth_rahu_sidereal_deg_raw',
    'spashth_ketu_sidereal_deg',
    'spashth_ketu_sidereal_deg_raw',
    'lagna_sidereal_deg',
    'lagna_sidereal_deg_raw',
  ];
  final map = <String, dynamic>{for (final key in keys) key: 1.0};
  map['sun_sidereal_deg'] = 78.02;
  map['moon_sidereal_deg'] = 320.35;
  map['lagna_sidereal_deg'] = 163.65;
  return map;
}

Map<String, dynamic> _sampleVedic() {
  const prefixes = <String>[
    'sun',
    'moon',
    'lagna',
    'mangal',
    'budha',
    'guru',
    'shukra',
    'shani',
    'rahu',
    'ketu',
    'spashth_rahu',
    'spashth_ketu',
  ];
  final map = <String, dynamic>{};
  for (final prefix in prefixes) {
    map['${prefix}_rashi'] = 'Kany';
    map['${prefix}_nakshatra'] = 'Hasta';
    map['${prefix}_pada'] = 2;
  }
  map['sun_rashi'] = 'Mitu';
  map['moon_rashi'] = 'Kumb';
  map['lagna_rashi'] = 'Kany';
  map['moon_nakshatra'] = 'P Bhadrapada';
  return map;
}

Map<String, dynamic> _sampleBhava() {
  return <String, dynamic>{
    'lagna_house': 1,
    'sun_house': 10,
    'moon_house': 6,
    'mangal_house': 2,
    'budha_house': 11,
    'guru_house': 8,
    'shukra_house': 12,
    'shani_house': 8,
    'rahu_house': 11,
    'ketu_house': 5,
    'spashth_rahu_house': 11,
    'spashth_ketu_house': 5,
  };
}

Map<String, dynamic> _sampleDivision({required String lagnaRashi}) {
  const zodiac = <String>[
    'Mesh',
    'Vrish',
    'Mitu',
    'Kark',
    'Simh',
    'Kany',
    'Tula',
    'Vrsc',
    'Dhanu',
    'Maka',
    'Kumb',
    'Meen',
  ];
  final lagnaIndex = zodiac.indexOf(lagnaRashi);
  if (lagnaIndex == -1) {
    throw ArgumentError.value(lagnaRashi, 'lagnaRashi');
  }

  final houses = <String, dynamic>{};
  for (int index = 1; index <= 12; index++) {
    final rashi = zodiac[(lagnaIndex + index - 1) % 12];
    houses['$index'] = <String, dynamic>{
      'rashi': rashi,
      'occupants': <String>[],
    };
  }
  houses['1']!['occupants'] = <String>['sun', 'lagna'];
  houses['2']!['occupants'] = <String>['moon'];
  houses['3']!['occupants'] = <String>['mangal'];
  houses['4']!['occupants'] = <String>['budha'];
  houses['5']!['occupants'] = <String>['guru'];
  houses['6']!['occupants'] = <String>['shukra'];
  houses['7']!['occupants'] = <String>['shani'];
  houses['8']!['occupants'] = <String>['rahu'];
  houses['9']!['occupants'] = <String>['ketu'];
  houses['10']!['occupants'] = <String>['spashth_rahu'];
  houses['11']!['occupants'] = <String>['spashth_ketu'];

  String rashiForHouse(int house) => houses['$house']!['rashi'] as String;
  final grahaPositions = <String, dynamic>{
    'sun': <String, dynamic>{
      'rashi': rashiForHouse(1),
      'house': 1,
      'degree_in_sign': 18.02
    },
    'moon': <String, dynamic>{
      'rashi': rashiForHouse(2),
      'house': 2,
      'degree_in_sign': 7.30
    },
    'mangal': <String, dynamic>{
      'rashi': rashiForHouse(3),
      'house': 3,
      'degree_in_sign': 13.11
    },
    'budha': <String, dynamic>{
      'rashi': rashiForHouse(4),
      'house': 4,
      'degree_in_sign': 26.55
    },
    'guru': <String, dynamic>{
      'rashi': rashiForHouse(5),
      'house': 5,
      'degree_in_sign': 1.91
    },
    'shukra': <String, dynamic>{
      'rashi': rashiForHouse(6),
      'house': 6,
      'degree_in_sign': 22.44
    },
    'shani': <String, dynamic>{
      'rashi': rashiForHouse(7),
      'house': 7,
      'degree_in_sign': 5.03
    },
    'rahu': <String, dynamic>{
      'rashi': rashiForHouse(8),
      'house': 8,
      'degree_in_sign': 9.88
    },
    'ketu': <String, dynamic>{
      'rashi': rashiForHouse(9),
      'house': 9,
      'degree_in_sign': 9.88
    },
    'spashth_rahu': <String, dynamic>{
      'rashi': rashiForHouse(10),
      'house': 10,
      'degree_in_sign': 11.21
    },
    'spashth_ketu': <String, dynamic>{
      'rashi': rashiForHouse(11),
      'house': 11,
      'degree_in_sign': 11.21
    },
    'lagna': <String, dynamic>{
      'rashi': lagnaRashi,
      'house': 1,
      'degree_in_sign': 13.65
    },
  };

  return <String, dynamic>{
    'lagna_rashi': lagnaRashi,
    'houses': houses,
    'graha_positions': grahaPositions,
  };
}

Map<String, dynamic> _sampleGrahaTable() {
  const keys = <String>[
    'sun',
    'moon',
    'mangal',
    'budha',
    'guru',
    'shukra',
    'shani',
    'rahu',
    'ketu',
    'spashth_rahu',
    'spashth_ketu',
    'lagna',
  ];
  return <String, dynamic>{
    for (final key in keys) key: _sampleGrahaEntry(key),
  };
}

Map<String, dynamic> _sampleGrahaEntry(String key) {
  return <String, dynamic>{
    'key': key,
    'sidereal_deg': key == 'sun' ? 78.02 : 10.0,
    'sidereal_deg_raw': key == 'sun' ? 78.03 : 10.1,
    'speed_deg_per_day': 1.0,
    'rashi': key == 'sun' ? 'Mitu' : 'Kany',
    'nakshatra': key == 'moon' ? 'P Bhadrapada' : 'Hasta',
    'pada': 2,
    'house': 1,
    'd9_rashi': 'Maka',
    'd9_house': 1,
    'retrograde': key == 'rahu' || key == 'ketu' || key == 'shani',
    'combust': key == 'shukra',
  };
}

List<Map<String, dynamic>> _sampleTimeline() {
  return List<Map<String, dynamic>>.generate(
    9,
    (int index) => <String, dynamic>{
      'lord_key': 'lord_$index',
      'lord': 'Lord$index',
      'start': '1999-01-0${(index % 9) + 1}T00:00:00+00:00',
      'end': '2000-01-0${(index % 9) + 1}T00:00:00+00:00',
      'active': index == 0,
    },
  );
}

List<Map<String, dynamic>> _sampleInterpretationCards() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'card_id': 'yoga_budha_aditya',
      'category': 'yoga',
      'confidence': 'high',
      'strength_score': 0.86,
      'title': <String, dynamic>{
        'english': 'Budha-Aditya Yoga pattern detected',
        'vedic': 'Budha-Aditya yoga pattern detected',
      },
      'summary': <String, dynamic>{
        'english': 'Sun and Mercury are in the same house.',
        'vedic': 'Surya and Budha are in the same bhava.',
      },
      'impact': <String, dynamic>{
        'english': 'This can support clear expression and planning.',
        'vedic': 'This can support buddhi and articulate speech.',
      },
      'evidence': <Map<String, dynamic>>[
        <String, dynamic>{
          'english': 'Sun and Mercury both occupy H10.',
          'vedic': 'Surya and Budha both occupy 10th Bhava.',
        },
      ],
    },
  ];
}

List<Map<String, dynamic>> _sampleDailyTransitCards() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'card_id': 'daily_transit_moon',
      'transit_graha_key': 'moon',
      'transit_house_from_lagna': 6,
      'transit_rashi': 'Kumb',
      'focus_tag': 'Emotions',
      'title': <String, dynamic>{
        'english': 'Transit Moon focus for today',
        'vedic': 'Daily Chandra transit focus',
      },
      'summary': <String, dynamic>{
        'english': 'Transit Moon is in H6 today.',
        'vedic': 'Transit Chandra is in 6th Bhava today.',
      },
      'do_items': <Map<String, dynamic>>[
        <String, dynamic>{
          'english': 'Review emotional decisions after one day.',
          'vedic': 'Review emotional decisions after one day.',
        },
      ],
      'watch_items': <Map<String, dynamic>>[
        <String, dynamic>{
          'english': 'Avoid overreaction to temporary mood shifts.',
          'vedic': 'Avoid overreaction to temporary mood shifts.',
        },
      ],
    },
  ];
}
