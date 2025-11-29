import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import 'package:flutter/material.dart';

class IndicatorCalculator {
  static List<FlSpot> calculateSma(List<FlSpot> data, int period) {
    if (data.length < period) return [];
    List<FlSpot> smaValues = [];
    for (int i = 0; i <= data.length - period; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += data[i + j].y;
      }
      smaValues.add(FlSpot(data[i + period - 1].x, sum / period));
    }
    return smaValues;
  }

  static List<FlSpot> calculateEma(List<FlSpot> data, int period) {
    if (data.length < period) return [];
    List<FlSpot> emaValues = [];
    double multiplier = 2 / (period + 1);
    double initialSma = 0;
    for (int i = 0; i < period; i++) {
      initialSma += data[i].y;
    }
    double previousEma = initialSma / period;
    emaValues.add(FlSpot(data[period - 1].x, previousEma));

    for (int i = period; i < data.length; i++) {
      double ema = (data[i].y - previousEma) * multiplier + previousEma;
      emaValues.add(FlSpot(data[i].x, ema));
      previousEma = ema;
    }
    return emaValues;
  }

  static List<LineChartBarData> calculateBb(List<FlSpot> data, int period) {
    if (data.length < period) return [];
    List<FlSpot> middleBand = calculateSma(data, period);
    List<FlSpot> upperBand = [];
    List<FlSpot> lowerBand = [];

    for (int i = 0; i <= data.length - period; i++) {
      double stdDev = 0;
      double mean = middleBand[i].y;
      for (int j = 0; j < period; j++) {
        stdDev += pow(data[i + j].y - mean, 2);
      }
      stdDev = sqrt(stdDev / period);
      upperBand.add(FlSpot(middleBand[i].x, mean + 2 * stdDev));
      lowerBand.add(FlSpot(middleBand[i].x, mean - 2 * stdDev));
    }

    return [
      LineChartBarData(
        spots: upperBand,
        isCurved: true,
        barWidth: 2,
        color: Colors.lightBlue,
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: middleBand,
        isCurved: true,
        barWidth: 2,
        color: Colors.indigo,
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: lowerBand,
        isCurved: true,
        barWidth: 2,
        color: Colors.lightBlue,
        dotData: const FlDotData(show: false),
      ),
    ];
  }
}