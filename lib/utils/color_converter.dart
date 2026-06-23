import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class HexColorConverter implements JsonConverter<Color, String> {
  const HexColorConverter();

  @override
  Color fromJson(String json) => HexColor(json);

  @override
  String toJson(Color object) => object.toHex();
}

class HexColorListConverter implements JsonConverter<List<Color>, String> {
  const HexColorListConverter();
  @override
  List<Color> fromJson(String json) => json.split(',').map((s) => HexColor(s)).toList();
  @override
  String toJson(List<Color> object) => object.map((c) => c.toHex()).join(',');
}
