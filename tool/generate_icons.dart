import 'dart:io';
import 'package:image/image.dart' as img;

const int SIZE = 256;
const int GOLD = 0xFFE67E22;
const int BRAND_DARK = 0xFF1A5276;
const int WHITE = 0xFFFFFFFF;

final img.Image _canvas = img.Image(width: SIZE, height: SIZE, numChannels: 4);

img.ColorRgba8 _c(int color) =>
    img.ColorRgba8((color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, 255);

void _resetCanvas() {
  img.fill(_canvas, color: img.ColorRgba8(0, 0, 0, 0));
}

void _roundedBg({int color = BRAND_DARK}) {
  img.fillRect(
    _canvas,
    x1: 12,
    y1: 12,
    x2: SIZE - 12,
    y2: SIZE - 12,
    color: _c(color),
    radius: 56,
  );
}

void _fillCircle(int cx, int cy, int r, int color) {
  img.fillCircle(_canvas, x: cx, y: cy, radius: r, color: _c(color));
}

void _ring(int cx, int cy, int r, int color, int innerR) {
  img.fillCircle(_canvas, x: cx, y: cy, radius: r, color: _c(color));
  img.fillCircle(_canvas, x: cx, y: cy, radius: innerR, color: _c(BRAND_DARK));
}

void _fillRect(int x1, int y1, int x2, int y2, int color) {
  img.fillRect(
    _canvas,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: _c(color),
  );
}

void _strokeRect(int x1, int y1, int x2, int y2, int color, {int thickness = 12}) {
  img.drawRect(
    _canvas,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: _c(color),
    thickness: thickness,
  );
}

void _line(int x1, int y1, int x2, int y2, int color, {int thickness = 12}) {
  img.drawLine(
    _canvas,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: _c(color),
    thickness: thickness,
  );
}

void _save(String name) {
  final png = img.encodePng(_canvas);
  final file = File('assets/icons/$name');
  file.writeAsBytesSync(png);
  _resetCanvas();
}

void _home() {
  _roundedBg();
  _line(64, 136, 128, 88, WHITE, thickness: 16);
  _line(128, 88, 192, 136, WHITE, thickness: 16);
  _strokeRect(88, 128, 168, 192, WHITE, thickness: 12);
  _fillRect(112, 156, 144, 192, GOLD);
  _save('icon-home.png');
}

void _report() {
  _roundedBg();
  _strokeRect(72, 64, 184, 192, WHITE, thickness: 12);
  _fillRect(92, 110, 164, 124, WHITE);
  _fillRect(92, 140, 164, 154, WHITE);
  _fillRect(92, 170, 140, 184, WHITE);
  _fillCircle(128, 64, 22, GOLD);
  _save('icon-report.png');
}

void _chat() {
  _roundedBg();
  _ring(128, 118, 60, WHITE, 44);
  _line(112, 168, 94, 196, WHITE, thickness: 14);
  _fillCircle(128, 118, 7, BRAND_DARK);
  _save('icon-chat.png');
}

void _acompanhar() {
  _roundedBg();
  _ring(112, 104, 48, WHITE, 34);
  _line(148, 140, 188, 180, WHITE, thickness: 14);
  _fillRect(94, 92, 130, 116, BRAND_DARK);
  _line(96, 190, 116, 202, GOLD, thickness: 12);
  _line(116, 202, 156, 162, GOLD, thickness: 12);
  _save('icon-acompanhar.png');
}

void _perfil() {
  _roundedBg();
  _fillCircle(128, 100, 34, WHITE);
  _fillCircle(128, 192, 56, WHITE);
  _fillRect(72, 174, 184, 178, BRAND_DARK);
  _fillRect(68, 178, 188, 190, BRAND_DARK);
  _save('icon-perfil.png');
}

void _dashboard() {
  _roundedBg();
  _fillRect(76, 76, 128, 128, GOLD);
  _strokeRect(76, 76, 128, 128, BRAND_DARK, thickness: 8);
  _strokeRect(136, 76, 180, 128, WHITE, thickness: 10);
  _strokeRect(76, 136, 128, 180, WHITE, thickness: 10);
  _strokeRect(136, 136, 180, 180, WHITE, thickness: 10);
  _save('icon-dashboard.png');
}

void _shield() {
  _roundedBg();
  _strokeRect(88, 76, 168, 168, WHITE, thickness: 14);
  _fillRect(116, 56, 140, 80, WHITE);
  _line(104, 134, 120, 150, GOLD, thickness: 14);
  _line(120, 150, 156, 112, GOLD, thickness: 14);
  _save('icon-shield.png');
}

void _megaphone() {
  _roundedBg();
  _line(72, 96, 72, 160, WHITE, thickness: 18);
  _line(72, 96, 168, 70, WHITE, thickness: 12);
  _line(72, 160, 168, 186, WHITE, thickness: 12);
  _fillRect(158, 56, 190, 200, WHITE);
  _fillRect(202, 96, 210, 128, GOLD);
  _fillRect(218, 86, 226, 138, GOLD);
  _fillRect(234, 76, 242, 148, GOLD);
  _save('icon-megaphone.png');
}

void _notification() {
  _roundedBg();
  _fillCircle(128, 60, 40, WHITE);
  _fillRect(88, 92, 168, 168, WHITE);
  _fillCircle(128, 172, 26, WHITE);
  _fillRect(112, 44, 144, 58, BRAND_DARK);
  _fillCircle(168, 96, 16, GOLD);
  _save('icon-notification.png');
}

void _historico() {
  _roundedBg();
  _ring(128, 128, 54, WHITE, 40);
  _line(128, 128, 128, 100, WHITE, thickness: 12);
  _line(128, 128, 152, 140, WHITE, thickness: 12);
  _fillCircle(128, 52, 14, GOLD);
  _fillCircle(128, 204, 14, GOLD);
  _save('icon-historico.png');
}

void _admins() {
  _roundedBg();
  _fillCircle(100, 96, 24, WHITE);
  _fillCircle(100, 148, 38, WHITE);
  _fillRect(62, 122, 138, 128, BRAND_DARK);
  _fillRect(62, 128, 138, 138, BRAND_DARK);
  _fillRect(62, 138, 138, 148, BRAND_DARK);
  _fillCircle(168, 78, 18, GOLD);
  _fillCircle(168, 112, 28, GOLD);
  _fillRect(140, 96, 196, 102, BRAND_DARK);
  _fillRect(140, 102, 196, 112, BRAND_DARK);
  _fillRect(140, 112, 196, 122, BRAND_DARK);
  _save('icon-admins.png');
}

void _logo() {
  _resetCanvas();
  for (int i = 0; i < SIZE; i += 32) {
    img.fillRect(
      _canvas,
      x1: 0,
      y1: i,
      x2: SIZE,
      y2: i + 12,
      color: _c(BRAND_DARK),
    );
  }
  _fillCircle(128, 128, 92, GOLD);
  _ring(128, 128, 92, BRAND_DARK, 82);
  _line(88, 88, 128, 156, WHITE, thickness: 18);
  _line(168, 88, 128, 156, WHITE, thickness: 18);
  _fillCircle(128, 158, 10, WHITE);
  _save('icon-app.png');
}

void main() {
  _home();
  _report();
  _chat();
  _acompanhar();
  _perfil();
  _dashboard();
  _shield();
  _megaphone();
  _notification();
  _historico();
  _admins();
  _logo();
  print('Icones gerados em assets/icons/');
}