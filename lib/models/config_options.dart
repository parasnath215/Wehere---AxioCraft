class ConfigOption {
  final String id;
  final String label;

  ConfigOption({required this.id, required this.label});

  factory ConfigOption.fromJson(Map<String, dynamic> json) {
    return ConfigOption(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

class ConfigLimits {
  final int minPhotos;
  final int maxPhotos;
  final int bioMaxLength;
  final int maxInterests;
  final int maxFeelings;
  final int maxSupportTypes;
  final int locationMaxLength;
  final int pseudonymMaxLength;

  ConfigLimits({
    required this.minPhotos,
    required this.maxPhotos,
    required this.bioMaxLength,
    required this.maxInterests,
    required this.maxFeelings,
    required this.maxSupportTypes,
    required this.locationMaxLength,
    required this.pseudonymMaxLength,
  });

  factory ConfigLimits.fromJson(Map<String, dynamic> json) {
    return ConfigLimits(
      minPhotos: json['minPhotos'] as int? ?? 2,
      maxPhotos: json['maxPhotos'] as int? ?? 6,
      bioMaxLength: json['bioMaxLength'] as int? ?? 500,
      maxInterests: json['maxInterests'] as int? ?? 10,
      maxFeelings: json['maxFeelings'] as int? ?? 10,
      maxSupportTypes: json['maxSupportTypes'] as int? ?? 5,
      locationMaxLength: json['locationMaxLength'] as int? ?? 100,
      pseudonymMaxLength: json['pseudonymMaxLength'] as int? ?? 50,
    );
  }
}
