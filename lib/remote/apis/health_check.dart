import 'package:json_annotation/json_annotation.dart';

part 'health_check.g.dart';

@JsonSerializable()
class LivezResponse {
  final bool isAlive;

  LivezResponse({required this.isAlive});

  factory LivezResponse.fromJson(Map<String, dynamic> json) => _$LivezResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LivezResponseToJson(this);
}
