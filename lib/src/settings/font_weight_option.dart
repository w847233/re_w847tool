import 'package:flutter/material.dart';

class AppFontWeightOption {
  const AppFontWeightOption({
    required this.label,
    required this.value,
    required this.weight,
  });

  final String label;
  final int value;
  final FontWeight weight;
}

const fontWeightOptions = <AppFontWeightOption>[
  AppFontWeightOption(label: '细体', value: 100, weight: FontWeight.w100),
  AppFontWeightOption(label: '轻体', value: 300, weight: FontWeight.w300),
  AppFontWeightOption(label: '常规', value: 400, weight: FontWeight.w400),
  AppFontWeightOption(label: '中等', value: 500, weight: FontWeight.w500),
  AppFontWeightOption(label: '粗体', value: 700, weight: FontWeight.w700),
  AppFontWeightOption(label: '黑体', value: 900, weight: FontWeight.w900),
];

const defaultFontWeightOption = AppFontWeightOption(
  label: '常规',
  value: 400,
  weight: FontWeight.w400,
);

AppFontWeightOption fontWeightOptionFromValue(int value) {
  return fontWeightOptions.firstWhere(
    (option) => option.value == value,
    orElse: () => defaultFontWeightOption,
  );
}
