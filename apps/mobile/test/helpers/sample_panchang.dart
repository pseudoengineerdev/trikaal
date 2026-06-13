/// Builds a realistic /v1/panchang/compute response payload for [dateIso],
/// mirroring the engine output shape for a Friday in Adhika Jyeshtha.
///
/// The named flags let tests exercise the conditional row branches that the
/// default happy-path payload never reaches:
/// - [withAbhijit] false drops the Abhijit window (Wednesday "Not observed").
/// - [withPanchaka] true adds a Mrityu Panchaka window.
/// - [withBhadra] true adds a Bhadra (Vishti) window and marks a karana Vishti.
Map<String, dynamic> samplePanchangResponseJson(
  String dateIso, {
  bool withAbhijit = true,
  bool withPanchaka = false,
  bool withBhadra = false,
}) {
  final date = DateTime.parse(dateIso);
  final nextDate = date.add(const Duration(days: 1));

  String isoFor(DateTime day, String time) {
    final month = day.month.toString().padLeft(2, '0');
    final dayLabel = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-${dayLabel}T$time:00+05:30';
  }

  Map<String, dynamic> bundle(String time, {bool nextDay = false}) {
    final day = nextDay ? nextDate : date;
    return <String, dynamic>{
      'utc_iso': isoFor(day, time),
      'local_iso': isoFor(day, time),
      'local_time': time,
    };
  }

  Map<String, dynamic> window(
    String startTime,
    String endTime, {
    bool startNextDay = false,
    bool endNextDay = false,
  }) {
    return <String, dynamic>{
      'start': bundle(startTime, nextDay: startNextDay),
      'end': bundle(endTime, nextDay: endNextDay),
    };
  }

  return <String, dynamic>{
    'profile': <String, dynamic>{
      'profile_id': 'vedic_lahiri_v1',
      'zodiac_system': 'sidereal',
      'ayanamsha': 'lahiri_chitrapaksha',
      'calculation_method': 'modern_ephemeris',
    },
    'normalized_input': <String, dynamic>{
      'date': dateIso,
      'place_query': 'Vadodara',
    },
    'resolved_place': <String, dynamic>{
      'place_label': 'Vadodara, India',
      'latitude': 22.2994,
      'longitude': 73.2081,
      'timezone': 'Asia/Kolkata',
      'elevation_m': 39.0,
    },
    'panchang': <String, dynamic>{
      'panchang_profile_id': 'vedic_daily_panchang_v1',
      'date': dateIso,
      'timezone': 'Asia/Kolkata',
      'location': <String, dynamic>{
        'latitude': 22.2994,
        'longitude': 73.2081,
        'elevation_m': 39.0,
      },
      'weekday': <String, dynamic>{
        'number': 6,
        'name_vedic': 'Shukravara',
        'name_english': 'Friday',
      },
      'sun': <String, dynamic>{
        'sunrise': bundle('05:56'),
        'sunset': bundle('19:17'),
        'next_sunrise': bundle('05:56', nextDay: true),
        'solar_noon': bundle('12:36'),
        'day_duration': <String, dynamic>{'minutes': 801, 'label': '13h 21m'},
        'night_duration': <String, dynamic>{'minutes': 639, 'label': '10h 39m'},
      },
      'moon': <String, dynamic>{
        'moonrise': bundle('03:44', nextDay: true),
        'moonset': bundle('16:23'),
      },
      'tithi': <Map<String, dynamic>>[
        <String, dynamic>{
          'number': 27,
          'name_vedic': 'Krishna Dvadashi',
          'name_english': 'Waning Dvadashi',
          'paksha': 'Krishna',
          'paksha_english': 'Waning',
          'start': bundle('22:36'),
          'end': bundle('19:37'),
        },
        <String, dynamic>{
          'number': 28,
          'name_vedic': 'Krishna Trayodashi',
          'name_english': 'Waning Trayodashi',
          'paksha': 'Krishna',
          'paksha_english': 'Waning',
          'start': bundle('19:37'),
          'end': bundle('16:08', nextDay: true),
        },
      ],
      'nakshatra': <Map<String, dynamic>>[
        <String, dynamic>{
          'number': 1,
          'name_vedic': 'Ashwini',
          'name_english': 'Ashwini',
          'is_ganda_moola': true,
          'start': bundle('08:17'),
          'end': bundle('06:29'),
        },
        <String, dynamic>{
          'number': 2,
          'name_vedic': 'Bharani',
          'name_english': 'Bharani',
          'is_ganda_moola': false,
          'start': bundle('06:29'),
          'end': bundle('04:06', nextDay: true),
        },
      ],
      'yoga': <Map<String, dynamic>>[
        <String, dynamic>{
          'number': 6,
          'name_vedic': 'Atiganda',
          'name_english': 'Atiganda',
          'start': bundle('01:02'),
          'end': bundle('21:28'),
        },
      ],
      'karana': <Map<String, dynamic>>[
        <String, dynamic>{
          'serial': 53,
          'name_vedic': 'Kaulava',
          'name_english': 'Kaulava',
          'is_vishti': false,
          'start': bundle('22:36'),
          'end': bundle('09:11'),
        },
        <String, dynamic>{
          'serial': 54,
          'name_vedic': withBhadra ? 'Vishti' : 'Taitila',
          'name_english': withBhadra ? 'Vishti' : 'Taitila',
          'is_vishti': withBhadra,
          'start': bundle('09:11'),
          'end': bundle('19:37'),
        },
      ],
      'lunar_month': <String, dynamic>{
        'amanta': 'Jyeshtha (Adhika)',
        'purnimanta': 'Jyeshtha (Adhika)',
        'paksha': 'Krishna',
        'paksha_english': 'Waning',
      },
      'samvat': <String, dynamic>{
        'vikram': 2083,
        'vikram_samvatsara': 'Siddharthi',
        'shaka': 1948,
        'shaka_samvatsara': 'Parabhava',
        'kali': 5127,
      },
      'rashi': <String, dynamic>{
        'moon_rashi': 'Mesha',
        'moon_rashi_change': null,
        'sun_rashi': 'Vrishabha',
        'sun_nakshatra': <String, dynamic>{
          'number': 5,
          'name': 'Mrigashirsha',
          'pada': 2,
        },
        'moon_nakshatra_pada': 4,
      },
      'ayana_ritu': <String, dynamic>{
        'ayana_sayana': 'Uttarayana',
        'ayana_nirayana': 'Uttarayana',
        'ritu_sayana': 'Grishma',
        'ritu_nirayana': 'Grishma',
      },
      'auspicious': <String, dynamic>{
        'abhijit_muhurta': withAbhijit ? window('12:10', '13:03') : null,
        'brahma_muhurta': window('04:31', '05:13'),
        'pratah_sandhya': window('04:52', '05:56'),
        'vijaya_muhurta': window('14:50', '15:43'),
        'godhuli_muhurta': window('19:16', '19:37'),
        'sayahna_sandhya': window('19:17', '20:21'),
        'nishita_muhurta':
            window('00:15', '00:58', startNextDay: true, endNextDay: true),
        'amrit_kalam': <Map<String, dynamic>>[
          window('23:47', '01:13', endNextDay: true),
        ],
      },
      'inauspicious': <String, dynamic>{
        'rahu_kalam': window('10:56', '12:37'),
        'yamaganda': window('15:57', '17:37'),
        'gulikai_kalam': window('07:36', '09:16'),
        'dur_muhurtam': <Map<String, dynamic>>[window('08:36', '09:30')],
        'varjyam': <Map<String, dynamic>>[window('15:08', '16:35')],
        'bhadra': withBhadra
            ? <Map<String, dynamic>>[window('09:11', '19:37')]
            : <Map<String, dynamic>>[],
        'ganda_moola': <Map<String, dynamic>>[
          <String, dynamic>{
            'nakshatra': 'Ashwini',
            'start': bundle('08:17'),
            'end': bundle('06:29'),
          },
        ],
      },
      'advanced': <String, dynamic>{
        'disha_shoola': 'West',
        'chandrabalam': <String>[
          'Mesha',
          'Mithuna',
          'Karka',
          'Tula',
          'Vrischika',
          'Kumbha',
        ],
        'tarabalam': <String>['Bharani', 'Krittika', 'Mrigashirsha'],
        'panchaka': withPanchaka
            ? <String, dynamic>{
                'label': 'Mrityu Panchaka',
                'start': bundle('05:56'),
                'end': bundle('06:29'),
                'active_at_sunrise': true,
              }
            : null,
        'hora_timeline': <Map<String, dynamic>>[
          <String, dynamic>{
            'lord_vedic': 'Shukra',
            'lord_english': 'Venus',
            'is_day': true,
            'start': bundle('05:56'),
            'end': bundle('07:03'),
          },
          <String, dynamic>{
            'lord_vedic': 'Budha',
            'lord_english': 'Mercury',
            'is_day': true,
            'start': bundle('07:03'),
            'end': bundle('08:10'),
          },
        ],
        'choghadiya': <String, dynamic>{
          'day': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Chara',
              'quality': 'auspicious',
              'start': bundle('05:56'),
              'end': bundle('07:36'),
            },
            <String, dynamic>{
              'name': 'Labha',
              'quality': 'auspicious',
              'start': bundle('07:36'),
              'end': bundle('09:16'),
            },
          ],
          'night': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'Roga',
              'quality': 'inauspicious',
              'start': bundle('19:17'),
              'end': bundle('20:37'),
            },
          ],
        },
      },
    },
  };
}
