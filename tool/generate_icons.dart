import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

/// 간단한 PNG 생성기 (1024x1024 앱 아이콘)
/// 외부 의존성 없이 순수 Dart로 PNG 생성
void main() {
  // 1024x1024 앱 아이콘: 파란 배경 + 흰색 "W"
  final icon = _createIcon(1024, 1024, 0xFF4A6FA5, true);
  File('assets/icon.png').writeAsBytesSync(icon);
  print('Created assets/icon.png');

  // 아이콘 전경 (적응형 아이콘용)
  final foreground = _createIcon(1024, 1024, 0xFF4A6FA5, true);
  File('assets/icon_foreground.png').writeAsBytesSync(foreground);
  print('Created assets/icon_foreground.png');

  // 스플래시 로고: 투명 배경 + 파란 로고
  final splash = _createIcon(512, 512, 0xFF4A6FA5, false);
  File('assets/splash_logo.png').writeAsBytesSync(splash);
  print('Created assets/splash_logo.png');
}

Uint8List _createIcon(int width, int height, int color, bool filled) {
  // RGBA 픽셀 데이터 생성
  final pixels = Uint8List(width * height * 4);
  final r = (color >> 16) & 0xFF;
  final g = (color >> 8) & 0xFF;
  final b = color & 0xFF;

  // 배경
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      if (filled) {
        // 둥근 모서리 배경
        final cornerRadius = width * 0.22;
        if (_isInRoundedRect(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble(), cornerRadius)) {
          pixels[idx] = r;
          pixels[idx + 1] = g;
          pixels[idx + 2] = b;
          pixels[idx + 3] = 255;
        } else {
          pixels[idx + 3] = 0; // 투명
        }
      } else {
        pixels[idx + 3] = 0; // 투명 배경
      }
    }
  }

  // "W" 글자 그리기 (흰색 또는 파란색)
  final letterColor = filled ? [255, 255, 255, 255] : [r, g, b, 255];
  _drawW(pixels, width, height, letterColor);

  return _encodePng(pixels, width, height);
}

bool _isInRoundedRect(double x, double y, double w, double h, double r) {
  if (x >= r && x <= w - r) return true;
  if (y >= r && y <= h - r) return true;
  // 코너 체크
  if (x < r && y < r) return _dist(x, y, r, r) <= r;
  if (x > w - r && y < r) return _dist(x, y, w - r, r) <= r;
  if (x < r && y > h - r) return _dist(x, y, r, h - r) <= r;
  if (x > w - r && y > h - r) return _dist(x, y, w - r, h - r) <= r;
  return false;
}

double _dist(double x1, double y1, double x2, double y2) {
  return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
}

void _drawW(Uint8List pixels, int w, int h, List<int> color) {
  // "W" 좌표를 선분으로 정의 (정규화 0~1)
  final lines = [
    // W의 왼쪽 다리
    [0.2, 0.25, 0.3, 0.75],
    // W의 왼쪽-중앙
    [0.3, 0.75, 0.4, 0.5],
    // W의 중앙-오른쪽
    [0.4, 0.5, 0.5, 0.75],
    // W의 중앙
    [0.5, 0.75, 0.6, 0.5],
    // W의 오른쪽-중앙
    [0.6, 0.5, 0.7, 0.75],
    // W의 오른쪽 다리
    [0.7, 0.75, 0.8, 0.25],
  ];

  final thickness = w * 0.07;

  for (final line in lines) {
    _drawThickLine(
      pixels, w, h,
      (line[0] * w).round(), (line[1] * h).round(),
      (line[2] * w).round(), (line[3] * h).round(),
      thickness.round(), color,
    );
  }
}

void _drawThickLine(Uint8List pixels, int imgW, int imgH, int x1, int y1, int x2, int y2, int thickness, List<int> color) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final steps = max(dx.abs(), dy.abs());
  if (steps == 0) return;

  for (var i = 0; i <= steps; i++) {
    final x = x1 + (dx * i / steps).round();
    final y = y1 + (dy * i / steps).round();

    for (var tx = -thickness ~/ 2; tx <= thickness ~/ 2; tx++) {
      for (var ty = -thickness ~/ 2; ty <= thickness ~/ 2; ty++) {
        final px = x + tx;
        final py = y + ty;
        if (px >= 0 && px < imgW && py >= 0 && py < imgH) {
          final idx = (py * imgW + px) * 4;
          pixels[idx] = color[0];
          pixels[idx + 1] = color[1];
          pixels[idx + 2] = color[2];
          pixels[idx + 3] = color[3];
        }
      }
    }
  }
}

/// 최소 PNG 인코더 (비압축, 필터 None)
Uint8List _encodePng(Uint8List pixels, int width, int height) {
  // IDAT: filter byte (0) + raw RGBA per row
  final rawData = <int>[];
  for (var y = 0; y < height; y++) {
    rawData.add(0); // filter: None
    for (var x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      rawData.addAll([pixels[idx], pixels[idx + 1], pixels[idx + 2], pixels[idx + 3]]);
    }
  }

  final compressed = _deflate(Uint8List.fromList(rawData));

  final out = BytesBuilder();

  // PNG signature
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  final ihdr = BytesBuilder();
  ihdr.add(_uint32(width));
  ihdr.add(_uint32(height));
  ihdr.add([8, 6, 0, 0, 0]); // 8bit RGBA
  _writeChunk(out, 'IHDR', ihdr.toBytes());

  // IDAT
  _writeChunk(out, 'IDAT', compressed);

  // IEND
  _writeChunk(out, 'IEND', Uint8List(0));

  return out.toBytes();
}

Uint8List _uint32(int value) {
  return Uint8List.fromList([
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ]);
}

void _writeChunk(BytesBuilder out, String type, Uint8List data) {
  out.add(_uint32(data.length));
  final typeBytes = type.codeUnits;
  out.add(typeBytes);
  out.add(data);
  // CRC32
  final crcData = Uint8List.fromList([...typeBytes, ...data]);
  out.add(_uint32(_crc32(crcData)));
}

Uint8List _deflate(Uint8List data) {
  // zlib: CMF + FLG + stored blocks + Adler32
  final out = BytesBuilder();
  out.add([0x78, 0x01]); // zlib header (deflate, no dict)

  // Split into 65535-byte stored blocks
  var offset = 0;
  while (offset < data.length) {
    final remaining = data.length - offset;
    final blockSize = remaining > 65535 ? 65535 : remaining;
    final isLast = offset + blockSize >= data.length;
    out.add([isLast ? 1 : 0]);
    out.add([blockSize & 0xFF, (blockSize >> 8) & 0xFF]);
    out.add([(~blockSize) & 0xFF, ((~blockSize) >> 8) & 0xFF]);
    out.add(data.sublist(offset, offset + blockSize));
    offset += blockSize;
  }

  // Adler32
  var a = 1, b = 0;
  for (var i = 0; i < data.length; i++) {
    a = (a + data[i]) % 65521;
    b = (b + a) % 65521;
  }
  out.add(_uint32((b << 16) | a));

  return out.toBytes();
}

int _crc32(Uint8List data) {
  var crc = 0xFFFFFFFF;
  for (var byte in data) {
    crc ^= byte;
    for (var j = 0; j < 8; j++) {
      if (crc & 1 == 1) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
