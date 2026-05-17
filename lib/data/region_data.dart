// Region bounding boxes for coverage calculation.
// Coordinates are approximate based on official administrative boundaries.

class RegionData {
  final String id;
  final String name;
  final String parentId;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final int approximateTiles;

  const RegionData({
    required this.id,
    required this.name,
    required this.parentId,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.approximateTiles,
  });
}

// ── 대한민국 ─────────────────────────────────────────────────────────────────

const regionKorea = RegionData(
  id: 'KR', name: '대한민국', parentId: 'world',
  minLat: 33.1, maxLat: 38.6, minLon: 124.6, maxLon: 131.9,
  approximateTiles: 780000,
);

// ── 시도 (17개) ───────────────────────────────────────────────────────────────

const regionSeoul = RegionData(
  id: 'KR-11', name: '서울특별시', parentId: 'KR',
  minLat: 37.413, maxLat: 37.701, minLon: 126.734, maxLon: 127.183,
  approximateTiles: 2800,
);

const regionBusan = RegionData(
  id: 'KR-26', name: '부산광역시', parentId: 'KR',
  minLat: 35.040, maxLat: 35.400, minLon: 128.740, maxLon: 129.330,
  approximateTiles: 14000,
);

const regionDaegu = RegionData(
  id: 'KR-27', name: '대구광역시', parentId: 'KR',
  minLat: 35.748, maxLat: 36.054, minLon: 128.325, maxLon: 128.752,
  approximateTiles: 13000,
);

const regionIncheon = RegionData(
  id: 'KR-28', name: '인천광역시', parentId: 'KR',
  minLat: 37.264, maxLat: 37.800, minLon: 125.898, maxLon: 126.792,
  approximateTiles: 22000,
);

const regionGwangju = RegionData(
  id: 'KR-29', name: '광주광역시', parentId: 'KR',
  minLat: 35.076, maxLat: 35.283, minLon: 126.718, maxLon: 127.003,
  approximateTiles: 6000,
);

const regionDaejeon = RegionData(
  id: 'KR-30', name: '대전광역시', parentId: 'KR',
  minLat: 36.193, maxLat: 36.485, minLon: 127.275, maxLon: 127.563,
  approximateTiles: 8500,
);

const regionUlsan = RegionData(
  id: 'KR-31', name: '울산광역시', parentId: 'KR',
  minLat: 35.298, maxLat: 35.723, minLon: 128.984, maxLon: 129.467,
  approximateTiles: 11000,
);

const regionSejong = RegionData(
  id: 'KR-36', name: '세종특별자치시', parentId: 'KR',
  minLat: 36.393, maxLat: 36.756, minLon: 127.183, maxLon: 127.460,
  approximateTiles: 9000,
);

const regionGyeonggi = RegionData(
  id: 'KR-41', name: '경기도', parentId: 'KR',
  minLat: 36.950, maxLat: 38.305, minLon: 126.296, maxLon: 127.907,
  approximateTiles: 200000,
);

const regionGangwon = RegionData(
  id: 'KR-42', name: '강원특별자치도', parentId: 'KR',
  minLat: 37.000, maxLat: 38.620, minLon: 127.490, maxLon: 129.375,
  approximateTiles: 180000,
);

const regionChungbuk = RegionData(
  id: 'KR-43', name: '충청북도', parentId: 'KR',
  minLat: 36.378, maxLat: 37.362, minLon: 127.557, maxLon: 128.577,
  approximateTiles: 68000,
);

const regionChungnam = RegionData(
  id: 'KR-44', name: '충청남도', parentId: 'KR',
  minLat: 35.967, maxLat: 37.003, minLon: 126.106, maxLon: 127.430,
  approximateTiles: 82000,
);

const regionJeonbuk = RegionData(
  id: 'KR-45', name: '전북특별자치도', parentId: 'KR',
  minLat: 35.348, maxLat: 36.183, minLon: 126.405, maxLon: 127.757,
  approximateTiles: 73000,
);

const regionJeonnam = RegionData(
  id: 'KR-46', name: '전라남도', parentId: 'KR',
  minLat: 33.784, maxLat: 35.222, minLon: 125.768, maxLon: 127.754,
  approximateTiles: 110000,
);

const regionGyeongbuk = RegionData(
  id: 'KR-47', name: '경상북도', parentId: 'KR',
  minLat: 35.470, maxLat: 37.558, minLon: 128.230, maxLon: 130.924,
  approximateTiles: 200000,
);

const regionGyeongnam = RegionData(
  id: 'KR-48', name: '경상남도', parentId: 'KR',
  minLat: 34.609, maxLat: 35.933, minLon: 127.837, maxLon: 129.333,
  approximateTiles: 115000,
);

const regionJeju = RegionData(
  id: 'KR-50', name: '제주특별자치도', parentId: 'KR',
  minLat: 33.100, maxLat: 33.560, minLon: 126.146, maxLon: 126.978,
  approximateTiles: 18000,
);

const List<RegionData> koreaProvinces = [
  regionSeoul, regionBusan, regionDaegu, regionIncheon,
  regionGwangju, regionDaejeon, regionUlsan, regionSejong,
  regionGyeonggi, regionGangwon, regionChungbuk, regionChungnam,
  regionJeonbuk, regionJeonnam, regionGyeongbuk, regionGyeongnam, regionJeju,
];

// ── 서울특별시 25구 ────────────────────────────────────────────────────────────

const seoulDistricts = <RegionData>[
  RegionData(id: 'KR-11-110', name: '종로구', parentId: 'KR-11', minLat: 37.549, maxLat: 37.609, minLon: 126.942, maxLon: 127.006, approximateTiles: 96),
  RegionData(id: 'KR-11-140', name: '중구', parentId: 'KR-11', minLat: 37.538, maxLat: 37.570, minLon: 126.961, maxLon: 127.002, approximateTiles: 40),
  RegionData(id: 'KR-11-170', name: '용산구', parentId: 'KR-11', minLat: 37.512, maxLat: 37.556, minLon: 126.950, maxLon: 127.002, approximateTiles: 56),
  RegionData(id: 'KR-11-200', name: '성동구', parentId: 'KR-11', minLat: 37.536, maxLat: 37.578, minLon: 127.012, maxLon: 127.066, approximateTiles: 56),
  RegionData(id: 'KR-11-215', name: '광진구', parentId: 'KR-11', minLat: 37.534, maxLat: 37.566, minLon: 127.059, maxLon: 127.104, approximateTiles: 40),
  RegionData(id: 'KR-11-230', name: '동대문구', parentId: 'KR-11', minLat: 37.564, maxLat: 37.604, minLon: 127.012, maxLon: 127.058, approximateTiles: 48),
  RegionData(id: 'KR-11-260', name: '중랑구', parentId: 'KR-11', minLat: 37.580, maxLat: 37.640, minLon: 127.060, maxLon: 127.107, approximateTiles: 72),
  RegionData(id: 'KR-11-290', name: '성북구', parentId: 'KR-11', minLat: 37.584, maxLat: 37.644, minLon: 126.946, maxLon: 127.024, approximateTiles: 90),
  RegionData(id: 'KR-11-305', name: '강북구', parentId: 'KR-11', minLat: 37.634, maxLat: 37.692, minLon: 127.002, maxLon: 127.054, approximateTiles: 72),
  RegionData(id: 'KR-11-320', name: '도봉구', parentId: 'KR-11', minLat: 37.660, maxLat: 37.714, minLon: 127.021, maxLon: 127.071, approximateTiles: 66),
  RegionData(id: 'KR-11-350', name: '노원구', parentId: 'KR-11', minLat: 37.640, maxLat: 37.697, minLon: 127.055, maxLon: 127.103, approximateTiles: 66),
  RegionData(id: 'KR-11-380', name: '은평구', parentId: 'KR-11', minLat: 37.600, maxLat: 37.679, minLon: 126.895, maxLon: 126.961, approximateTiles: 100),
  RegionData(id: 'KR-11-410', name: '서대문구', parentId: 'KR-11', minLat: 37.550, maxLat: 37.600, minLon: 126.918, maxLon: 126.967, approximateTiles: 60),
  RegionData(id: 'KR-11-440', name: '마포구', parentId: 'KR-11', minLat: 37.540, maxLat: 37.584, minLon: 126.889, maxLon: 126.951, approximateTiles: 66),
  RegionData(id: 'KR-11-470', name: '양천구', parentId: 'KR-11', minLat: 37.510, maxLat: 37.551, minLon: 126.840, maxLon: 126.896, approximateTiles: 56),
  RegionData(id: 'KR-11-500', name: '강서구', parentId: 'KR-11', minLat: 37.530, maxLat: 37.598, minLon: 126.797, maxLon: 126.872, approximateTiles: 100),
  RegionData(id: 'KR-11-530', name: '구로구', parentId: 'KR-11', minLat: 37.481, maxLat: 37.530, minLon: 126.829, maxLon: 126.898, approximateTiles: 66),
  RegionData(id: 'KR-11-545', name: '금천구', parentId: 'KR-11', minLat: 37.449, maxLat: 37.494, minLon: 126.883, maxLon: 126.916, approximateTiles: 36),
  RegionData(id: 'KR-11-560', name: '영등포구', parentId: 'KR-11', minLat: 37.511, maxLat: 37.553, minLon: 126.882, maxLon: 126.952, approximateTiles: 56),
  RegionData(id: 'KR-11-590', name: '동작구', parentId: 'KR-11', minLat: 37.487, maxLat: 37.531, minLon: 126.934, maxLon: 126.996, approximateTiles: 56),
  RegionData(id: 'KR-11-620', name: '관악구', parentId: 'KR-11', minLat: 37.450, maxLat: 37.499, minLon: 126.932, maxLon: 126.999, approximateTiles: 66),
  RegionData(id: 'KR-11-650', name: '서초구', parentId: 'KR-11', minLat: 37.470, maxLat: 37.527, minLon: 126.990, maxLon: 127.063, approximateTiles: 80),
  RegionData(id: 'KR-11-680', name: '강남구', parentId: 'KR-11', minLat: 37.494, maxLat: 37.541, minLon: 127.027, maxLon: 127.102, approximateTiles: 70),
  RegionData(id: 'KR-11-710', name: '송파구', parentId: 'KR-11', minLat: 37.490, maxLat: 37.537, minLon: 127.095, maxLon: 127.181, approximateTiles: 80),
  RegionData(id: 'KR-11-740', name: '강동구', parentId: 'KR-11', minLat: 37.527, maxLat: 37.575, minLon: 127.103, maxLon: 127.182, approximateTiles: 72),
];

// ── 부산광역시 16구/군 ─────────────────────────────────────────────────────────

const busanDistricts = <RegionData>[
  RegionData(id: 'KR-26-110', name: '중구', parentId: 'KR-26', minLat: 35.093, maxLat: 35.118, minLon: 129.016, maxLon: 129.048, approximateTiles: 24),
  RegionData(id: 'KR-26-140', name: '서구', parentId: 'KR-26', minLat: 35.082, maxLat: 35.118, minLon: 128.984, maxLon: 129.028, approximateTiles: 42),
  RegionData(id: 'KR-26-170', name: '동구', parentId: 'KR-26', minLat: 35.098, maxLat: 35.137, minLon: 129.029, maxLon: 129.074, approximateTiles: 44),
  RegionData(id: 'KR-26-200', name: '영도구', parentId: 'KR-26', minLat: 35.062, maxLat: 35.109, minLon: 128.988, maxLon: 129.077, approximateTiles: 54),
  RegionData(id: 'KR-26-230', name: '부산진구', parentId: 'KR-26', minLat: 35.139, maxLat: 35.194, minLon: 129.013, maxLon: 129.075, approximateTiles: 84),
  RegionData(id: 'KR-26-260', name: '동래구', parentId: 'KR-26', minLat: 35.179, maxLat: 35.232, minLon: 129.047, maxLon: 129.113, approximateTiles: 88),
  RegionData(id: 'KR-26-290', name: '남구', parentId: 'KR-26', minLat: 35.109, maxLat: 35.154, minLon: 129.053, maxLon: 129.118, approximateTiles: 72),
  RegionData(id: 'KR-26-320', name: '북구', parentId: 'KR-26', minLat: 35.190, maxLat: 35.261, minLon: 128.975, maxLon: 129.046, approximateTiles: 126),
  RegionData(id: 'KR-26-350', name: '해운대구', parentId: 'KR-26', minLat: 35.139, maxLat: 35.211, minLon: 129.106, maxLon: 129.222, approximateTiles: 168),
  RegionData(id: 'KR-26-380', name: '사하구', parentId: 'KR-26', minLat: 35.062, maxLat: 35.133, minLon: 128.897, maxLon: 128.990, approximateTiles: 162),
  RegionData(id: 'KR-26-410', name: '금정구', parentId: 'KR-26', minLat: 35.217, maxLat: 35.329, minLon: 129.035, maxLon: 129.123, approximateTiles: 216),
  RegionData(id: 'KR-26-440', name: '강서구', parentId: 'KR-26', minLat: 35.059, maxLat: 35.248, minLon: 128.737, maxLon: 128.944, approximateTiles: 490),
  RegionData(id: 'KR-26-470', name: '연제구', parentId: 'KR-26', minLat: 35.162, maxLat: 35.202, minLon: 129.062, maxLon: 129.114, approximateTiles: 52),
  RegionData(id: 'KR-26-500', name: '수영구', parentId: 'KR-26', minLat: 35.133, maxLat: 35.173, minLon: 129.087, maxLon: 129.150, approximateTiles: 62),
  RegionData(id: 'KR-26-530', name: '사상구', parentId: 'KR-26', minLat: 35.127, maxLat: 35.198, minLon: 128.934, maxLon: 128.994, approximateTiles: 104),
  RegionData(id: 'KR-26-710', name: '기장군', parentId: 'KR-26', minLat: 35.214, maxLat: 35.401, minLon: 129.095, maxLon: 129.332, approximateTiles: 490),
];

// ── 대구광역시 8구/군 ──────────────────────────────────────────────────────────

const daeguDistricts = <RegionData>[
  RegionData(id: 'KR-27-110', name: '중구', parentId: 'KR-27', minLat: 35.854, maxLat: 35.888, minLon: 128.570, maxLon: 128.615, approximateTiles: 40),
  RegionData(id: 'KR-27-140', name: '동구', parentId: 'KR-27', minLat: 35.832, maxLat: 36.054, minLon: 128.593, maxLon: 128.752, approximateTiles: 550),
  RegionData(id: 'KR-27-170', name: '서구', parentId: 'KR-27', minLat: 35.845, maxLat: 35.912, minLon: 128.527, maxLon: 128.588, approximateTiles: 100),
  RegionData(id: 'KR-27-200', name: '남구', parentId: 'KR-27', minLat: 35.834, maxLat: 35.870, minLon: 128.569, maxLon: 128.634, approximateTiles: 56),
  RegionData(id: 'KR-27-230', name: '북구', parentId: 'KR-27', minLat: 35.876, maxLat: 36.021, minLon: 128.528, maxLon: 128.637, approximateTiles: 330),
  RegionData(id: 'KR-27-260', name: '수성구', parentId: 'KR-27', minLat: 35.813, maxLat: 35.886, minLon: 128.601, maxLon: 128.729, approximateTiles: 186),
  RegionData(id: 'KR-27-290', name: '달서구', parentId: 'KR-27', minLat: 35.805, maxLat: 35.886, minLon: 128.492, maxLon: 128.580, approximateTiles: 176),
  RegionData(id: 'KR-27-710', name: '달성군', parentId: 'KR-27', minLat: 35.744, maxLat: 35.997, minLon: 128.322, maxLon: 128.613, approximateTiles: 1080),
];

// ── 인천광역시 10구/군 ─────────────────────────────────────────────────────────

const incheonDistricts = <RegionData>[
  RegionData(id: 'KR-28-110', name: '중구', parentId: 'KR-28', minLat: 37.430, maxLat: 37.495, minLon: 126.397, maxLon: 126.520, approximateTiles: 156),
  RegionData(id: 'KR-28-140', name: '동구', parentId: 'KR-28', minLat: 37.460, maxLat: 37.492, minLon: 126.562, maxLon: 126.622, approximateTiles: 48),
  RegionData(id: 'KR-28-177', name: '미추홀구', parentId: 'KR-28', minLat: 37.437, maxLat: 37.475, minLon: 126.619, maxLon: 126.691, approximateTiles: 68),
  RegionData(id: 'KR-28-185', name: '연수구', parentId: 'KR-28', minLat: 37.379, maxLat: 37.461, minLon: 126.615, maxLon: 126.735, approximateTiles: 192),
  RegionData(id: 'KR-28-200', name: '남동구', parentId: 'KR-28', minLat: 37.409, maxLat: 37.485, minLon: 126.686, maxLon: 126.796, approximateTiles: 204),
  RegionData(id: 'KR-28-237', name: '부평구', parentId: 'KR-28', minLat: 37.469, maxLat: 37.532, minLon: 126.684, maxLon: 126.780, approximateTiles: 152),
  RegionData(id: 'KR-28-245', name: '계양구', parentId: 'KR-28', minLat: 37.509, maxLat: 37.576, minLon: 126.688, maxLon: 126.783, approximateTiles: 158),
  RegionData(id: 'KR-28-260', name: '서구', parentId: 'KR-28', minLat: 37.488, maxLat: 37.631, minLon: 126.586, maxLon: 126.740, approximateTiles: 430),
  RegionData(id: 'KR-28-710', name: '강화군', parentId: 'KR-28', minLat: 37.577, maxLat: 37.800, minLon: 126.314, maxLon: 126.622, approximateTiles: 730),
  RegionData(id: 'KR-28-720', name: '옹진군', parentId: 'KR-28', minLat: 37.262, maxLat: 37.663, minLon: 125.895, maxLon: 126.333, approximateTiles: 780),
];

// ── 광주광역시 5구 ─────────────────────────────────────────────────────────────

const gwangjuDistricts = <RegionData>[
  RegionData(id: 'KR-29-110', name: '동구', parentId: 'KR-29', minLat: 35.125, maxLat: 35.178, minLon: 126.875, maxLon: 126.967, approximateTiles: 120),
  RegionData(id: 'KR-29-140', name: '서구', parentId: 'KR-29', minLat: 35.122, maxLat: 35.192, minLon: 126.819, maxLon: 126.907, approximateTiles: 152),
  RegionData(id: 'KR-29-170', name: '남구', parentId: 'KR-29', minLat: 35.074, maxLat: 35.152, minLon: 126.875, maxLon: 126.972, approximateTiles: 186),
  RegionData(id: 'KR-29-200', name: '북구', parentId: 'KR-29', minLat: 35.168, maxLat: 35.285, minLon: 126.831, maxLon: 127.004, approximateTiles: 500),
  RegionData(id: 'KR-29-230', name: '광산구', parentId: 'KR-29', minLat: 35.128, maxLat: 35.254, minLon: 126.714, maxLon: 126.897, approximateTiles: 540),
];

// ── 대전광역시 5구 ─────────────────────────────────────────────────────────────

const daejeonDistricts = <RegionData>[
  RegionData(id: 'KR-30-110', name: '동구', parentId: 'KR-30', minLat: 36.256, maxLat: 36.400, minLon: 127.408, maxLon: 127.562, approximateTiles: 420),
  RegionData(id: 'KR-30-140', name: '중구', parentId: 'KR-30', minLat: 36.281, maxLat: 36.366, minLon: 127.374, maxLon: 127.437, approximateTiles: 128),
  RegionData(id: 'KR-30-170', name: '서구', parentId: 'KR-30', minLat: 36.298, maxLat: 36.434, minLon: 127.333, maxLon: 127.422, approximateTiles: 296),
  RegionData(id: 'KR-30-200', name: '유성구', parentId: 'KR-30', minLat: 36.322, maxLat: 36.485, minLon: 127.272, maxLon: 127.451, approximateTiles: 560),
  RegionData(id: 'KR-30-230', name: '대덕구', parentId: 'KR-30', minLat: 36.334, maxLat: 36.428, minLon: 127.404, maxLon: 127.517, approximateTiles: 258),
];

// ── 울산광역시 4구/1군 ─────────────────────────────────────────────────────────

const ulsanDistricts = <RegionData>[
  RegionData(id: 'KR-31-110', name: '중구', parentId: 'KR-31', minLat: 35.548, maxLat: 35.597, minLon: 129.281, maxLon: 129.340, approximateTiles: 68),
  RegionData(id: 'KR-31-140', name: '남구', parentId: 'KR-31', minLat: 35.488, maxLat: 35.577, minLon: 129.274, maxLon: 129.388, approximateTiles: 196),
  RegionData(id: 'KR-31-170', name: '동구', parentId: 'KR-31', minLat: 35.484, maxLat: 35.560, minLon: 129.352, maxLon: 129.467, approximateTiles: 178),
  RegionData(id: 'KR-31-200', name: '북구', parentId: 'KR-31', minLat: 35.555, maxLat: 35.648, minLon: 129.270, maxLon: 129.388, approximateTiles: 270),
  RegionData(id: 'KR-31-710', name: '울주군', parentId: 'KR-31', minLat: 35.295, maxLat: 35.685, minLon: 128.982, maxLon: 129.408, approximateTiles: 3600),
];

// ── 경기도 31시/군 ─────────────────────────────────────────────────────────────

const gyeonggiDistricts = <RegionData>[
  RegionData(id: 'KR-41-111', name: '수원시', parentId: 'KR-41', minLat: 37.215, maxLat: 37.332, minLon: 126.950, maxLon: 127.063, approximateTiles: 320),
  RegionData(id: 'KR-41-131', name: '성남시', parentId: 'KR-41', minLat: 37.362, maxLat: 37.470, minLon: 127.074, maxLon: 127.178, approximateTiles: 280),
  RegionData(id: 'KR-41-150', name: '의정부시', parentId: 'KR-41', minLat: 37.687, maxLat: 37.797, minLon: 127.018, maxLon: 127.115, approximateTiles: 262),
  RegionData(id: 'KR-41-171', name: '안양시', parentId: 'KR-41', minLat: 37.366, maxLat: 37.450, minLon: 126.900, maxLon: 126.985, approximateTiles: 218),
  RegionData(id: 'KR-41-190', name: '부천시', parentId: 'KR-41', minLat: 37.464, maxLat: 37.537, minLon: 126.727, maxLon: 126.833, approximateTiles: 190),
  RegionData(id: 'KR-41-210', name: '광명시', parentId: 'KR-41', minLat: 37.419, maxLat: 37.487, minLon: 126.848, maxLon: 126.916, approximateTiles: 112),
  RegionData(id: 'KR-41-220', name: '평택시', parentId: 'KR-41', minLat: 36.917, maxLat: 37.172, minLon: 126.974, maxLon: 127.250, approximateTiles: 1680),
  RegionData(id: 'KR-41-250', name: '동두천시', parentId: 'KR-41', minLat: 37.858, maxLat: 37.972, minLon: 127.020, maxLon: 127.108, approximateTiles: 248),
  RegionData(id: 'KR-41-271', name: '안산시', parentId: 'KR-41', minLat: 37.262, maxLat: 37.421, minLon: 126.751, maxLon: 126.928, approximateTiles: 680),
  RegionData(id: 'KR-41-281', name: '고양시', parentId: 'KR-41', minLat: 37.598, maxLat: 37.762, minLon: 126.752, maxLon: 126.992, approximateTiles: 850),
  RegionData(id: 'KR-41-290', name: '과천시', parentId: 'KR-41', minLat: 37.418, maxLat: 37.460, minLon: 126.975, maxLon: 127.026, approximateTiles: 52),
  RegionData(id: 'KR-41-310', name: '구리시', parentId: 'KR-41', minLat: 37.573, maxLat: 37.621, minLon: 127.109, maxLon: 127.161, approximateTiles: 60),
  RegionData(id: 'KR-41-360', name: '남양주시', parentId: 'KR-41', minLat: 37.588, maxLat: 37.778, minLon: 127.135, maxLon: 127.403, approximateTiles: 1200),
  RegionData(id: 'KR-41-370', name: '오산시', parentId: 'KR-41', minLat: 37.120, maxLat: 37.189, minLon: 126.975, maxLon: 127.052, approximateTiles: 128),
  RegionData(id: 'KR-41-390', name: '시흥시', parentId: 'KR-41', minLat: 37.308, maxLat: 37.436, minLon: 126.722, maxLon: 126.857, approximateTiles: 416),
  RegionData(id: 'KR-41-410', name: '군포시', parentId: 'KR-41', minLat: 37.338, maxLat: 37.396, minLon: 126.911, maxLon: 126.975, approximateTiles: 90),
  RegionData(id: 'KR-41-430', name: '의왕시', parentId: 'KR-41', minLat: 37.342, maxLat: 37.412, minLon: 126.946, maxLon: 127.012, approximateTiles: 112),
  RegionData(id: 'KR-41-450', name: '하남시', parentId: 'KR-41', minLat: 37.507, maxLat: 37.594, minLon: 127.159, maxLon: 127.271, approximateTiles: 230),
  RegionData(id: 'KR-41-461', name: '용인시', parentId: 'KR-41', minLat: 37.178, maxLat: 37.445, minLon: 127.000, maxLon: 127.354, approximateTiles: 2000),
  RegionData(id: 'KR-41-480', name: '파주시', parentId: 'KR-41', minLat: 37.739, maxLat: 37.990, minLon: 126.579, maxLon: 126.896, approximateTiles: 1600),
  RegionData(id: 'KR-41-500', name: '이천시', parentId: 'KR-41', minLat: 37.159, maxLat: 37.373, minLon: 127.338, maxLon: 127.624, approximateTiles: 1400),
  RegionData(id: 'KR-41-550', name: '안성시', parentId: 'KR-41', minLat: 36.978, maxLat: 37.175, minLon: 127.154, maxLon: 127.458, approximateTiles: 1360),
  RegionData(id: 'KR-41-570', name: '김포시', parentId: 'KR-41', minLat: 37.568, maxLat: 37.714, minLon: 126.567, maxLon: 126.788, approximateTiles: 740),
  RegionData(id: 'KR-41-590', name: '화성시', parentId: 'KR-41', minLat: 37.042, maxLat: 37.345, minLon: 126.618, maxLon: 127.102, approximateTiles: 3200),
  RegionData(id: 'KR-41-610', name: '광주시', parentId: 'KR-41', minLat: 37.340, maxLat: 37.582, minLon: 127.183, maxLon: 127.494, approximateTiles: 1560),
  RegionData(id: 'KR-41-630', name: '양주시', parentId: 'KR-41', minLat: 37.753, maxLat: 37.980, minLon: 126.966, maxLon: 127.195, approximateTiles: 1200),
  RegionData(id: 'KR-41-650', name: '포천시', parentId: 'KR-41', minLat: 37.814, maxLat: 38.158, minLon: 127.055, maxLon: 127.405, approximateTiles: 2480),
  RegionData(id: 'KR-41-670', name: '여주시', parentId: 'KR-41', minLat: 37.192, maxLat: 37.500, minLon: 127.514, maxLon: 127.744, approximateTiles: 1560),
  RegionData(id: 'KR-41-800', name: '연천군', parentId: 'KR-41', minLat: 37.954, maxLat: 38.275, minLon: 126.865, maxLon: 127.291, approximateTiles: 2640),
  RegionData(id: 'KR-41-820', name: '가평군', parentId: 'KR-41', minLat: 37.733, maxLat: 38.027, minLon: 127.329, maxLon: 127.829, approximateTiles: 3120),
  RegionData(id: 'KR-41-830', name: '양평군', parentId: 'KR-41', minLat: 37.366, maxLat: 37.646, minLon: 127.368, maxLon: 127.783, approximateTiles: 2440),
];

// ── 강원특별자치도 18시/군 ─────────────────────────────────────────────────────

const gangwonDistricts = <RegionData>[
  RegionData(id: 'KR-42-110', name: '춘천시', parentId: 'KR-42', minLat: 37.726, maxLat: 37.975, minLon: 127.596, maxLon: 128.023, approximateTiles: 2400),
  RegionData(id: 'KR-42-130', name: '원주시', parentId: 'KR-42', minLat: 37.220, maxLat: 37.595, minLon: 127.756, maxLon: 128.215, approximateTiles: 3400),
  RegionData(id: 'KR-42-150', name: '강릉시', parentId: 'KR-42', minLat: 37.577, maxLat: 37.934, minLon: 128.664, maxLon: 129.130, approximateTiles: 3400),
  RegionData(id: 'KR-42-170', name: '동해시', parentId: 'KR-42', minLat: 37.453, maxLat: 37.606, minLon: 129.041, maxLon: 129.220, approximateTiles: 560),
  RegionData(id: 'KR-42-190', name: '태백시', parentId: 'KR-42', minLat: 37.112, maxLat: 37.271, minLon: 128.918, maxLon: 129.027, approximateTiles: 340),
  RegionData(id: 'KR-42-210', name: '속초시', parentId: 'KR-42', minLat: 38.089, maxLat: 38.232, minLon: 128.476, maxLon: 128.622, approximateTiles: 320),
  RegionData(id: 'KR-42-230', name: '삼척시', parentId: 'KR-42', minLat: 37.120, maxLat: 37.459, minLon: 128.960, maxLon: 129.267, approximateTiles: 2200),
  RegionData(id: 'KR-42-720', name: '홍천군', parentId: 'KR-42', minLat: 37.580, maxLat: 38.063, minLon: 127.695, maxLon: 128.461, approximateTiles: 7600),
  RegionData(id: 'KR-42-730', name: '횡성군', parentId: 'KR-42', minLat: 37.376, maxLat: 37.692, minLon: 127.830, maxLon: 128.246, approximateTiles: 2800),
  RegionData(id: 'KR-42-750', name: '영월군', parentId: 'KR-42', minLat: 37.019, maxLat: 37.479, minLon: 128.139, maxLon: 128.806, approximateTiles: 5400),
  RegionData(id: 'KR-42-760', name: '평창군', parentId: 'KR-42', minLat: 37.305, maxLat: 37.864, minLon: 128.234, maxLon: 128.792, approximateTiles: 6400),
  RegionData(id: 'KR-42-770', name: '정선군', parentId: 'KR-42', minLat: 37.130, maxLat: 37.547, minLon: 128.558, maxLon: 129.063, approximateTiles: 4400),
  RegionData(id: 'KR-42-780', name: '철원군', parentId: 'KR-42', minLat: 38.010, maxLat: 38.441, minLon: 127.093, maxLon: 127.574, approximateTiles: 4200),
  RegionData(id: 'KR-42-790', name: '화천군', parentId: 'KR-42', minLat: 38.010, maxLat: 38.312, minLon: 127.385, maxLon: 128.072, approximateTiles: 3960),
  RegionData(id: 'KR-42-800', name: '양구군', parentId: 'KR-42', minLat: 38.006, maxLat: 38.391, minLon: 127.773, maxLon: 128.261, approximateTiles: 3400),
  RegionData(id: 'KR-42-810', name: '인제군', parentId: 'KR-42', minLat: 37.867, maxLat: 38.461, minLon: 127.910, maxLon: 128.472, approximateTiles: 6400),
  RegionData(id: 'KR-42-820', name: '고성군', parentId: 'KR-42', minLat: 38.135, maxLat: 38.620, minLon: 128.254, maxLon: 128.660, approximateTiles: 3200),
  RegionData(id: 'KR-42-830', name: '양양군', parentId: 'KR-42', minLat: 37.820, maxLat: 38.184, minLon: 128.474, maxLon: 128.921, approximateTiles: 2960),
];

// ── 충청북도 11시/군 ──────────────────────────────────────────────────────────

const chungbukDistricts = <RegionData>[
  RegionData(id: 'KR-43-111', name: '청주시', parentId: 'KR-43', minLat: 36.485, maxLat: 36.744, minLon: 127.336, maxLon: 127.684, approximateTiles: 2240),
  RegionData(id: 'KR-43-130', name: '충주시', parentId: 'KR-43', minLat: 36.833, maxLat: 37.104, minLon: 127.770, maxLon: 128.235, approximateTiles: 2800),
  RegionData(id: 'KR-43-150', name: '제천시', parentId: 'KR-43', minLat: 36.977, maxLat: 37.217, minLon: 128.009, maxLon: 128.444, approximateTiles: 2160),
  RegionData(id: 'KR-43-720', name: '보은군', parentId: 'KR-43', minLat: 36.447, maxLat: 36.737, minLon: 127.638, maxLon: 127.917, approximateTiles: 1880),
  RegionData(id: 'KR-43-730', name: '옥천군', parentId: 'KR-43', minLat: 36.205, maxLat: 36.460, minLon: 127.498, maxLon: 127.793, approximateTiles: 1640),
  RegionData(id: 'KR-43-740', name: '영동군', parentId: 'KR-43', minLat: 36.023, maxLat: 36.389, minLon: 127.622, maxLon: 127.973, approximateTiles: 2400),
  RegionData(id: 'KR-43-745', name: '증평군', parentId: 'KR-43', minLat: 36.732, maxLat: 36.823, minLon: 127.537, maxLon: 127.663, approximateTiles: 280),
  RegionData(id: 'KR-43-750', name: '진천군', parentId: 'KR-43', minLat: 36.717, maxLat: 36.940, minLon: 127.388, maxLon: 127.594, approximateTiles: 1040),
  RegionData(id: 'KR-43-760', name: '괴산군', parentId: 'KR-43', minLat: 36.685, maxLat: 37.036, minLon: 127.667, maxLon: 128.047, approximateTiles: 2560),
  RegionData(id: 'KR-43-770', name: '음성군', parentId: 'KR-43', minLat: 36.836, maxLat: 37.020, minLon: 127.417, maxLon: 127.660, approximateTiles: 1040),
  RegionData(id: 'KR-43-800', name: '단양군', parentId: 'KR-43', minLat: 36.831, maxLat: 37.138, minLon: 128.157, maxLon: 128.578, approximateTiles: 2520),
];

// ── 충청남도 15시/군 ──────────────────────────────────────────────────────────

const chungnamDistricts = <RegionData>[
  RegionData(id: 'KR-44-131', name: '천안시', parentId: 'KR-44', minLat: 36.671, maxLat: 36.887, minLon: 127.054, maxLon: 127.386, approximateTiles: 1680),
  RegionData(id: 'KR-44-150', name: '공주시', parentId: 'KR-44', minLat: 36.349, maxLat: 36.649, minLon: 126.891, maxLon: 127.232, approximateTiles: 2240),
  RegionData(id: 'KR-44-180', name: '보령시', parentId: 'KR-44', minLat: 36.175, maxLat: 36.512, minLon: 126.426, maxLon: 126.815, approximateTiles: 2320),
  RegionData(id: 'KR-44-200', name: '아산시', parentId: 'KR-44', minLat: 36.683, maxLat: 36.887, minLon: 126.905, maxLon: 127.137, approximateTiles: 1160),
  RegionData(id: 'KR-44-210', name: '서산시', parentId: 'KR-44', minLat: 36.736, maxLat: 36.922, minLon: 126.258, maxLon: 126.732, approximateTiles: 2000),
  RegionData(id: 'KR-44-230', name: '논산시', parentId: 'KR-44', minLat: 36.042, maxLat: 36.278, minLon: 127.038, maxLon: 127.327, approximateTiles: 1280),
  RegionData(id: 'KR-44-250', name: '계룡시', parentId: 'KR-44', minLat: 36.225, maxLat: 36.332, minLon: 127.196, maxLon: 127.294, approximateTiles: 260),
  RegionData(id: 'KR-44-270', name: '당진시', parentId: 'KR-44', minLat: 36.782, maxLat: 37.001, minLon: 126.477, maxLon: 126.836, approximateTiles: 1760),
  RegionData(id: 'KR-44-710', name: '금산군', parentId: 'KR-44', minLat: 36.042, maxLat: 36.224, minLon: 127.421, maxLon: 127.718, approximateTiles: 840),
  RegionData(id: 'KR-44-760', name: '부여군', parentId: 'KR-44', minLat: 36.129, maxLat: 36.434, minLon: 126.845, maxLon: 127.133, approximateTiles: 1840),
  RegionData(id: 'KR-44-770', name: '서천군', parentId: 'KR-44', minLat: 35.999, maxLat: 36.271, minLon: 126.591, maxLon: 126.884, approximateTiles: 1280),
  RegionData(id: 'KR-44-790', name: '청양군', parentId: 'KR-44', minLat: 36.347, maxLat: 36.579, minLon: 126.779, maxLon: 127.074, approximateTiles: 1240),
  RegionData(id: 'KR-44-800', name: '홍성군', parentId: 'KR-44', minLat: 36.470, maxLat: 36.702, minLon: 126.461, maxLon: 126.799, approximateTiles: 1360),
  RegionData(id: 'KR-44-810', name: '예산군', parentId: 'KR-44', minLat: 36.527, maxLat: 36.770, minLon: 126.701, maxLon: 127.001, approximateTiles: 1360),
  RegionData(id: 'KR-44-825', name: '태안군', parentId: 'KR-44', minLat: 36.555, maxLat: 37.013, minLon: 126.105, maxLon: 126.625, approximateTiles: 1760),
];

// ── 전북특별자치도 14시/군 ────────────────────────────────────────────────────

const jeonbukDistricts = <RegionData>[
  RegionData(id: 'KR-45-111', name: '전주시', parentId: 'KR-45', minLat: 35.765, maxLat: 35.892, minLon: 127.029, maxLon: 127.188, approximateTiles: 480),
  RegionData(id: 'KR-45-130', name: '군산시', parentId: 'KR-45', minLat: 35.884, maxLat: 36.081, minLon: 126.511, maxLon: 126.924, approximateTiles: 1680),
  RegionData(id: 'KR-45-140', name: '익산시', parentId: 'KR-45', minLat: 35.936, maxLat: 36.082, minLon: 126.817, maxLon: 127.056, approximateTiles: 800),
  RegionData(id: 'KR-45-180', name: '정읍시', parentId: 'KR-45', minLat: 35.441, maxLat: 35.793, minLon: 126.689, maxLon: 127.027, approximateTiles: 2560),
  RegionData(id: 'KR-45-190', name: '남원시', parentId: 'KR-45', minLat: 35.349, maxLat: 35.694, minLon: 127.211, maxLon: 127.622, approximateTiles: 3040),
  RegionData(id: 'KR-45-210', name: '김제시', parentId: 'KR-45', minLat: 35.733, maxLat: 35.979, minLon: 126.698, maxLon: 126.942, approximateTiles: 1400),
  RegionData(id: 'KR-45-710', name: '완주군', parentId: 'KR-45', minLat: 35.792, maxLat: 36.079, minLon: 127.031, maxLon: 127.396, approximateTiles: 2240),
  RegionData(id: 'KR-45-720', name: '진안군', parentId: 'KR-45', minLat: 35.643, maxLat: 35.960, minLon: 127.320, maxLon: 127.706, approximateTiles: 2560),
  RegionData(id: 'KR-45-730', name: '무주군', parentId: 'KR-45', minLat: 35.821, maxLat: 36.136, minLon: 127.603, maxLon: 127.937, approximateTiles: 2160),
  RegionData(id: 'KR-45-740', name: '장수군', parentId: 'KR-45', minLat: 35.511, maxLat: 35.814, minLon: 127.434, maxLon: 127.774, approximateTiles: 2080),
  RegionData(id: 'KR-45-750', name: '임실군', parentId: 'KR-45', minLat: 35.456, maxLat: 35.763, minLon: 127.065, maxLon: 127.472, approximateTiles: 2320),
  RegionData(id: 'KR-45-770', name: '순창군', parentId: 'KR-45', minLat: 35.315, maxLat: 35.543, minLon: 127.006, maxLon: 127.380, approximateTiles: 1680),
  RegionData(id: 'KR-45-790', name: '고창군', parentId: 'KR-45', minLat: 35.378, maxLat: 35.668, minLon: 126.401, maxLon: 126.754, approximateTiles: 1840),
  RegionData(id: 'KR-45-800', name: '부안군', parentId: 'KR-45', minLat: 35.592, maxLat: 35.780, minLon: 126.400, maxLon: 126.781, approximateTiles: 1360),
];

// ── 전라남도 22시/군 ──────────────────────────────────────────────────────────

const jeonnamDistricts = <RegionData>[
  RegionData(id: 'KR-46-110', name: '목포시', parentId: 'KR-46', minLat: 34.749, maxLat: 34.831, minLon: 126.334, maxLon: 126.471, approximateTiles: 224),
  RegionData(id: 'KR-46-130', name: '여수시', parentId: 'KR-46', minLat: 34.613, maxLat: 34.854, minLon: 127.598, maxLon: 127.892, approximateTiles: 1360),
  RegionData(id: 'KR-46-150', name: '순천시', parentId: 'KR-46', minLat: 34.840, maxLat: 35.072, minLon: 127.342, maxLon: 127.678, approximateTiles: 2240),
  RegionData(id: 'KR-46-170', name: '나주시', parentId: 'KR-46', minLat: 34.869, maxLat: 35.160, minLon: 126.597, maxLon: 126.988, approximateTiles: 2480),
  RegionData(id: 'KR-46-230', name: '광양시', parentId: 'KR-46', minLat: 34.879, maxLat: 35.130, minLon: 127.547, maxLon: 127.824, approximateTiles: 1440),
  RegionData(id: 'KR-46-710', name: '담양군', parentId: 'KR-46', minLat: 35.135, maxLat: 35.418, minLon: 126.820, maxLon: 127.055, approximateTiles: 1520),
  RegionData(id: 'KR-46-720', name: '곡성군', parentId: 'KR-46', minLat: 35.046, maxLat: 35.330, minLon: 127.151, maxLon: 127.503, approximateTiles: 2160),
  RegionData(id: 'KR-46-730', name: '구례군', parentId: 'KR-46', minLat: 35.063, maxLat: 35.351, minLon: 127.382, maxLon: 127.717, approximateTiles: 2000),
  RegionData(id: 'KR-46-770', name: '고흥군', parentId: 'KR-46', minLat: 34.487, maxLat: 34.907, minLon: 127.097, maxLon: 127.541, approximateTiles: 3520),
  RegionData(id: 'KR-46-780', name: '보성군', parentId: 'KR-46', minLat: 34.651, maxLat: 34.975, minLon: 127.001, maxLon: 127.400, approximateTiles: 2560),
  RegionData(id: 'KR-46-790', name: '화순군', parentId: 'KR-46', minLat: 34.854, maxLat: 35.138, minLon: 126.849, maxLon: 127.169, approximateTiles: 2080),
  RegionData(id: 'KR-46-800', name: '장흥군', parentId: 'KR-46', minLat: 34.494, maxLat: 34.912, minLon: 126.765, maxLon: 127.180, approximateTiles: 3120),
  RegionData(id: 'KR-46-810', name: '강진군', parentId: 'KR-46', minLat: 34.505, maxLat: 34.788, minLon: 126.590, maxLon: 126.950, approximateTiles: 1680),
  RegionData(id: 'KR-46-820', name: '해남군', parentId: 'KR-46', minLat: 34.265, maxLat: 34.729, minLon: 126.391, maxLon: 126.823, approximateTiles: 3520),
  RegionData(id: 'KR-46-830', name: '영암군', parentId: 'KR-46', minLat: 34.666, maxLat: 34.935, minLon: 126.525, maxLon: 126.876, approximateTiles: 1680),
  RegionData(id: 'KR-46-840', name: '무안군', parentId: 'KR-46', minLat: 34.837, maxLat: 35.055, minLon: 126.332, maxLon: 126.628, approximateTiles: 1280),
  RegionData(id: 'KR-46-860', name: '함평군', parentId: 'KR-46', minLat: 35.013, maxLat: 35.249, minLon: 126.447, maxLon: 126.724, approximateTiles: 1280),
  RegionData(id: 'KR-46-870', name: '영광군', parentId: 'KR-46', minLat: 35.196, maxLat: 35.440, minLon: 126.427, maxLon: 126.760, approximateTiles: 1440),
  RegionData(id: 'KR-46-880', name: '장성군', parentId: 'KR-46', minLat: 35.185, maxLat: 35.501, minLon: 126.713, maxLon: 127.020, approximateTiles: 2000),
  RegionData(id: 'KR-46-890', name: '완도군', parentId: 'KR-46', minLat: 33.782, maxLat: 34.441, minLon: 126.481, maxLon: 127.058, approximateTiles: 3760),
  RegionData(id: 'KR-46-900', name: '진도군', parentId: 'KR-46', minLat: 34.174, maxLat: 34.533, minLon: 125.866, maxLon: 126.429, approximateTiles: 2160),
  RegionData(id: 'KR-46-910', name: '신안군', parentId: 'KR-46', minLat: 33.787, maxLat: 34.989, minLon: 125.765, maxLon: 126.468, approximateTiles: 4320),
];

// ── 경상북도 23시/군 ──────────────────────────────────────────────────────────

const gyeongbukDistricts = <RegionData>[
  RegionData(id: 'KR-47-111', name: '포항시', parentId: 'KR-47', minLat: 35.840, maxLat: 36.179, minLon: 129.104, maxLon: 129.532, approximateTiles: 3040),
  RegionData(id: 'KR-47-130', name: '경주시', parentId: 'KR-47', minLat: 35.611, maxLat: 36.085, minLon: 128.955, maxLon: 129.528, approximateTiles: 5280),
  RegionData(id: 'KR-47-150', name: '김천시', parentId: 'KR-47', minLat: 35.998, maxLat: 36.318, minLon: 127.999, maxLon: 128.305, approximateTiles: 2160),
  RegionData(id: 'KR-47-170', name: '안동시', parentId: 'KR-47', minLat: 36.399, maxLat: 36.789, minLon: 128.570, maxLon: 128.994, approximateTiles: 3680),
  RegionData(id: 'KR-47-190', name: '구미시', parentId: 'KR-47', minLat: 36.073, maxLat: 36.358, minLon: 128.237, maxLon: 128.545, approximateTiles: 1920),
  RegionData(id: 'KR-47-210', name: '영주시', parentId: 'KR-47', minLat: 36.712, maxLat: 37.043, minLon: 128.421, maxLon: 128.769, approximateTiles: 2400),
  RegionData(id: 'KR-47-230', name: '영천시', parentId: 'KR-47', minLat: 35.877, maxLat: 36.133, minLon: 128.779, maxLon: 129.130, approximateTiles: 2000),
  RegionData(id: 'KR-47-250', name: '상주시', parentId: 'KR-47', minLat: 36.177, maxLat: 36.621, minLon: 127.924, maxLon: 128.375, approximateTiles: 4400),
  RegionData(id: 'KR-47-260', name: '문경시', parentId: 'KR-47', minLat: 36.500, maxLat: 37.011, minLon: 127.993, maxLon: 128.408, approximateTiles: 4560),
  RegionData(id: 'KR-47-290', name: '경산시', parentId: 'KR-47', minLat: 35.759, maxLat: 35.993, minLon: 128.660, maxLon: 128.921, approximateTiles: 1440),
  RegionData(id: 'KR-47-720', name: '군위군', parentId: 'KR-47', minLat: 36.127, maxLat: 36.411, minLon: 128.430, maxLon: 128.709, approximateTiles: 1760),
  RegionData(id: 'KR-47-730', name: '의성군', parentId: 'KR-47', minLat: 36.185, maxLat: 36.724, minLon: 128.540, maxLon: 128.947, approximateTiles: 4400),
  RegionData(id: 'KR-47-740', name: '청송군', parentId: 'KR-47', minLat: 36.259, maxLat: 36.707, minLon: 128.927, maxLon: 129.282, approximateTiles: 3360),
  RegionData(id: 'KR-47-750', name: '영양군', parentId: 'KR-47', minLat: 36.457, maxLat: 36.879, minLon: 129.031, maxLon: 129.390, approximateTiles: 2640),
  RegionData(id: 'KR-47-760', name: '영덕군', parentId: 'KR-47', minLat: 36.307, maxLat: 36.818, minLon: 129.099, maxLon: 129.475, approximateTiles: 3520),
  RegionData(id: 'KR-47-770', name: '청도군', parentId: 'KR-47', minLat: 35.588, maxLat: 35.882, minLon: 128.668, maxLon: 128.957, approximateTiles: 1840),
  RegionData(id: 'KR-47-780', name: '고령군', parentId: 'KR-47', minLat: 35.649, maxLat: 35.842, minLon: 128.193, maxLon: 128.467, approximateTiles: 1040),
  RegionData(id: 'KR-47-790', name: '성주군', parentId: 'KR-47', minLat: 35.819, maxLat: 36.069, minLon: 128.035, maxLon: 128.396, approximateTiles: 1840),
  RegionData(id: 'KR-47-800', name: '칠곡군', parentId: 'KR-47', minLat: 35.892, maxLat: 36.099, minLon: 128.375, maxLon: 128.640, approximateTiles: 1120),
  RegionData(id: 'KR-47-820', name: '예천군', parentId: 'KR-47', minLat: 36.517, maxLat: 36.817, minLon: 128.205, maxLon: 128.613, approximateTiles: 2560),
  RegionData(id: 'KR-47-830', name: '봉화군', parentId: 'KR-47', minLat: 36.824, maxLat: 37.292, minLon: 128.607, maxLon: 129.052, approximateTiles: 4240),
  RegionData(id: 'KR-47-840', name: '울진군', parentId: 'KR-47', minLat: 36.638, maxLat: 37.047, minLon: 129.061, maxLon: 129.491, approximateTiles: 3520),
  RegionData(id: 'KR-47-920', name: '울릉군', parentId: 'KR-47', minLat: 37.437, maxLat: 37.563, minLon: 130.770, maxLon: 130.924, approximateTiles: 320),
];

// ── 경상남도 18시/군 ──────────────────────────────────────────────────────────

const gyeongnamDistricts = <RegionData>[
  RegionData(id: 'KR-48-121', name: '창원시', parentId: 'KR-48', minLat: 35.137, maxLat: 35.352, minLon: 128.499, maxLon: 128.838, approximateTiles: 1840),
  RegionData(id: 'KR-48-170', name: '진주시', parentId: 'KR-48', minLat: 35.063, maxLat: 35.320, minLon: 127.896, maxLon: 128.252, approximateTiles: 2560),
  RegionData(id: 'KR-48-220', name: '통영시', parentId: 'KR-48', minLat: 34.737, maxLat: 34.898, minLon: 128.358, maxLon: 128.633, approximateTiles: 560),
  RegionData(id: 'KR-48-240', name: '사천시', parentId: 'KR-48', minLat: 34.896, maxLat: 35.128, minLon: 127.940, maxLon: 128.197, approximateTiles: 880),
  RegionData(id: 'KR-48-250', name: '김해시', parentId: 'KR-48', minLat: 35.199, maxLat: 35.395, minLon: 128.696, maxLon: 128.915, approximateTiles: 1040),
  RegionData(id: 'KR-48-270', name: '밀양시', parentId: 'KR-48', minLat: 35.288, maxLat: 35.631, minLon: 128.710, maxLon: 129.072, approximateTiles: 2880),
  RegionData(id: 'KR-48-310', name: '거제시', parentId: 'KR-48', minLat: 34.737, maxLat: 34.969, minLon: 128.537, maxLon: 128.815, approximateTiles: 880),
  RegionData(id: 'KR-48-330', name: '양산시', parentId: 'KR-48', minLat: 35.290, maxLat: 35.568, minLon: 128.969, maxLon: 129.273, approximateTiles: 1920),
  RegionData(id: 'KR-48-720', name: '의령군', parentId: 'KR-48', minLat: 35.223, maxLat: 35.470, minLon: 128.131, maxLon: 128.451, approximateTiles: 1600),
  RegionData(id: 'KR-48-730', name: '함안군', parentId: 'KR-48', minLat: 35.215, maxLat: 35.421, minLon: 128.358, maxLon: 128.624, approximateTiles: 1280),
  RegionData(id: 'KR-48-740', name: '창녕군', parentId: 'KR-48', minLat: 35.338, maxLat: 35.644, minLon: 128.346, maxLon: 128.688, approximateTiles: 2240),
  RegionData(id: 'KR-48-750', name: '고성군', parentId: 'KR-48', minLat: 34.809, maxLat: 35.107, minLon: 128.188, maxLon: 128.473, approximateTiles: 1280),
  RegionData(id: 'KR-48-760', name: '남해군', parentId: 'KR-48', minLat: 34.747, maxLat: 35.030, minLon: 127.763, maxLon: 128.108, approximateTiles: 960),
  RegionData(id: 'KR-48-770', name: '하동군', parentId: 'KR-48', minLat: 35.006, maxLat: 35.335, minLon: 127.524, maxLon: 127.969, approximateTiles: 2560),
  RegionData(id: 'KR-48-780', name: '산청군', parentId: 'KR-48', minLat: 35.194, maxLat: 35.640, minLon: 127.720, maxLon: 128.107, approximateTiles: 3360),
  RegionData(id: 'KR-48-790', name: '함양군', parentId: 'KR-48', minLat: 35.435, maxLat: 35.803, minLon: 127.556, maxLon: 127.934, approximateTiles: 2880),
  RegionData(id: 'KR-48-800', name: '거창군', parentId: 'KR-48', minLat: 35.562, maxLat: 35.887, minLon: 127.835, maxLon: 128.132, approximateTiles: 2080),
  RegionData(id: 'KR-48-810', name: '합천군', parentId: 'KR-48', minLat: 35.410, maxLat: 35.762, minLon: 127.915, maxLon: 128.410, approximateTiles: 3680),
];

// ── 제주특별자치도 2시 ─────────────────────────────────────────────────────────

const jejuDistricts = <RegionData>[
  RegionData(id: 'KR-50-110', name: '제주시', parentId: 'KR-50', minLat: 33.205, maxLat: 33.563, minLon: 126.144, maxLon: 126.706, approximateTiles: 3600),
  RegionData(id: 'KR-50-130', name: '서귀포시', parentId: 'KR-50', minLat: 33.098, maxLat: 33.468, minLon: 126.375, maxLon: 126.980, approximateTiles: 4000),
];

// ── 세종특별자치시 (단일 시) ──────────────────────────────────────────────────

const sejongDistricts = <RegionData>[
  RegionData(id: 'KR-36-110', name: '세종시', parentId: 'KR-36', minLat: 36.393, maxLat: 36.757, minLon: 127.183, maxLon: 127.462, approximateTiles: 2200),
];

// ── 지역 → 하위 지역 맵 ──────────────────────────────────────────────────────

const Map<String, List<RegionData>> provinceDistrictsMap = {
  'KR-11': seoulDistricts,
  'KR-26': busanDistricts,
  'KR-27': daeguDistricts,
  'KR-28': incheonDistricts,
  'KR-29': gwangjuDistricts,
  'KR-30': daejeonDistricts,
  'KR-31': ulsanDistricts,
  'KR-36': sejongDistricts,
  'KR-41': gyeonggiDistricts,
  'KR-42': gangwonDistricts,
  'KR-43': chungbukDistricts,
  'KR-44': chungnamDistricts,
  'KR-45': jeonbukDistricts,
  'KR-46': jeonnamDistricts,
  'KR-47': gyeongbukDistricts,
  'KR-48': gyeongnamDistricts,
  'KR-50': jejuDistricts,
};

List<RegionData> getDistrictsOf(String provinceId) =>
    provinceDistrictsMap[provinceId] ?? [];

List<RegionData> getAllRegions() {
  final all = <RegionData>[regionKorea, ...koreaProvinces];
  for (final districts in provinceDistrictsMap.values) {
    all.addAll(districts);
  }
  return all;
}
