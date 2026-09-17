// ---------------------------------------------------------------------------
// TauntBuddy · branding asset generator
//
//   dart run tools/generate_branding_assets.dart
//
// Draws the judgemental-hamster brand mark with a pure-Dart rasteriser
// (no third-party packages, no binary source art in the repo) and writes every
// size the app, the PWA manifest and the Android launcher need.
//
// Output contract — keep docs/BRANDING.md in sync when this changes:
//   android/app/src/main/res/mipmap-*/ic_launcher.png
//   android/app/src/main/res/mipmap-*/ic_launcher_round.png
//   android/app/src/main/res/mipmap-*/ic_launcher_foreground.png   (adaptive)
//   android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png   (themed)
//   web/favicon.png, web/icons/Icon-*.png
//   assets/branding/icon.png, icon-maskable.png, ic_launcher_foreground.png
// ---------------------------------------------------------------------------
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

// ---------------------------------------------------------------- palette ---
class _Rgb {
  const _Rgb(this.r, this.g, this.b, [this.a = 1.0]);
  final double r, g, b, a;
}

// Solid Neon v2 — keep in sync with AppTokens.dark and docs/BRANDING.md.
const _Rgb kBackground = _Rgb(0x13 / 255, 0x11 / 255, 0x20 / 255);
const _Rgb kViolet = _Rgb(0xA8 / 255, 0x55 / 255, 0xF7 / 255);
const _Rgb kMagenta = _Rgb(0xFF / 255, 0x4F / 255, 0xA3 / 255);
const _Rgb kGlow = _Rgb(0xC4 / 255, 0xA2 / 255, 0xFF / 255);
const _Rgb kFur = _Rgb(0xF2 / 255, 0xDC / 255, 0xB8 / 255);
const _Rgb kFurDark = _Rgb(0xE7 / 255, 0xC7 / 255, 0x9C / 255);
const _Rgb kMuzzle = _Rgb(0xFF / 255, 0xFA / 255, 0xF2 / 255);
const _Rgb kOutline = _Rgb(0x3A / 255, 0x27 / 255, 0x52 / 255);
const _Rgb kPink = _Rgb(0xF4 / 255, 0x9A / 255, 0xB4 / 255);
const _Rgb kBlush = _Rgb(0xF4 / 255, 0xA9 / 255, 0xBE / 255);
const _Rgb kInk = _Rgb(0x1B / 255, 0x14 / 255, 0x24 / 255);
const _Rgb kRose = _Rgb(0xE7 / 255, 0x72 / 255, 0x9B / 255);
const _Rgb kWhite = _Rgb(1, 1, 1);

// ------------------------------------------------------------- compositing ---
_Rgb _over(_Rgb dst, _Rgb src) {
  if (src.a <= 0) return dst;
  final double outA = src.a + dst.a * (1 - src.a);
  if (outA <= 0) return const _Rgb(0, 0, 0, 0);
  double mix(double s, double d) => (s * src.a + d * dst.a * (1 - src.a)) / outA;
  return _Rgb(mix(src.r, dst.r), mix(src.g, dst.g), mix(src.b, dst.b), outA);
}

double _circle(double u, double v, double cu, double cv, double r) =>
    math.sqrt(math.pow(u - cu, 2) + math.pow(v - cv, 2)) <= r ? 1 : 0;

bool _roundRect(double x, double y, double radius) {
  final double dx = math.max((x - 0.5).abs() - (0.5 - radius), 0);
  final double dy = math.max((y - 0.5).abs() - (0.5 - radius), 0);
  return math.sqrt(dx * dx + dy * dy) <= radius;
}

bool _ellipse(double u, double v, double cu, double cv, double rx, double ry) {
  final double a = (u - cu) / rx;
  final double b = (v - cv) / ry;
  return a * a + b * b <= 1.0;
}

/// Paints the hamster in design units (head radius 0.30, centred on 0,0).
_Rgb _hamster(double u, double v, double k, {bool mono = false}) {
  _Rgb color = const _Rgb(0, 0, 0, 0);
  final double du = u / k;
  final double dv = v / k;

  if (mono) {
    final bool silhouette = _circle(du, dv, 0, 0, 0.30) >= 1 ||
        _circle(du, dv, -0.185, -0.245, 0.135) >= 1 ||
        _circle(du, dv, 0.185, -0.245, 0.135) >= 1 ||
        _ellipse(du, dv, 0, 0.115, 0.165, 0.115);
    if (silhouette) color = _over(color, kWhite);
    if (_circle(du, dv, -0.115, -0.045, 0.055) >= 1 ||
        _circle(du, dv, 0.115, -0.045, 0.055) >= 1) {
      color = const _Rgb(0, 0, 0, 0);
    }
    if (_circle(du, dv, 0, 0.072, 0.048) >= 1) color = const _Rgb(0, 0, 0, 0);
    if (dv > 0.155 &&
        dv < 0.225 &&
        _ellipse(du, dv, 0, 0.080, 0.140, 0.115)) {
      color = const _Rgb(0, 0, 0, 0);
    }
    return color;
  }

  // Halo behind the ears.
  final double dist = math.sqrt(du * du + dv * dv);
  if (dist > 0.33 && dist < 0.56) {
    final double t = 1 - (dist - 0.33) / 0.23;
    color = _over(color, _Rgb(kGlow.r, kGlow.g, kGlow.b, 0.14 * t * t));
  }

  // Ears: outline, fur, inner pink.
  for (final double sign in <double>[-1, 1]) {
    if (_circle(du, dv, sign * 0.185, -0.245, 0.140) >= 1) {
      color = _over(color, _Rgb(kOutline.r, kOutline.g, kOutline.b, 0.85));
    }
  }
  for (final double sign in <double>[-1, 1]) {
    if (_circle(du, dv, sign * 0.185, -0.245, 0.135) >= 1) {
      color = _over(color, kFurDark);
    }
    if (_circle(du, dv, sign * 0.185, -0.245, 0.078) >= 1) {
      color = _over(color, _Rgb(kPink.r, kPink.g, kPink.b, 0.95));
    }
  }

  // Head outline, head, muzzle.
  if (_circle(du, dv, 0, 0, 0.313) >= 1) {
    color = _over(color, _Rgb(kOutline.r, kOutline.g, kOutline.b, 0.85));
  }
  if (_circle(du, dv, 0, 0, 0.30) >= 1) color = _over(color, kFur);
  if (_ellipse(du, dv, 0, 0.115, 0.165, 0.115)) color = _over(color, kMuzzle);

  // Blush.
  for (final double sign in <double>[-1, 1]) {
    if (_ellipse(du, dv, sign * 0.215, 0.115, 0.078, 0.058)) {
      color = _over(color, _Rgb(kBlush.r, kBlush.g, kBlush.b, 0.45));
    }
  }

  // Eyes + catchlights.
  for (final double sign in <double>[-1, 1]) {
    if (_circle(du, dv, sign * 0.115, -0.045, 0.052) >= 1) {
      color = _over(color, kInk);
    }
    if (_circle(du, dv, sign * 0.133, -0.065, 0.019) >= 1) {
      color = _over(color, _Rgb(1, 1, 1, 0.92));
    }
  }

  // Nose, nose shine, smile.
  if (_circle(du, dv, 0, 0.072, 0.044) >= 1) color = _over(color, kRose);
  if (_circle(du, dv, -0.011, 0.064, 0.014) >= 1) {
    color = _over(color, _Rgb(1, 1, 1, 0.5));
  }
  if (dv > 0.155 && dv < 0.225 && _ellipse(du, dv, 0, 0.080, 0.140, 0.115)) {
    color = _over(color, _Rgb(kInk.r, kInk.g, kInk.b, 0.7));
  }
  return color;
}

/// One supersampled sample: x, y in 0..1 → RGBA.
_Rgb _sample(double x, double y, _Kind kind) {
  switch (kind) {
    case _Kind.foreground:
      return _hamster(x - 0.5, y - 0.5, 0.66);
    case _Kind.monochrome:
      return _hamster(x - 0.5, y - 0.5, 0.72, mono: true);
    case _Kind.icon:
    case _Kind.maskable:
      break;
  }

  final bool maskable = kind == _Kind.maskable;
  final bool inside = maskable || _roundRect(x, y, 0.24);
  if (!inside) return const _Rgb(0, 0, 0, 0);

  _Rgb color = _over(const _Rgb(0, 0, 0, 0), kBackground);
  final double g1 = math.sqrt(math.pow(x - 0.24, 2) + math.pow(y - 0.18, 2));
  if (g1 < 0.88) {
    final double t = 1 - g1 / 0.88;
    color = _over(color, _Rgb(kViolet.r, kViolet.g, kViolet.b, 0.44 * t * t));
  }
  final double g2 = math.sqrt(math.pow(x - 0.80, 2) + math.pow(y - 0.84, 2));
  if (g2 < 0.80) {
    final double t = 1 - g2 / 0.80;
    color = _over(color, _Rgb(kMagenta.r, kMagenta.g, kMagenta.b, 0.24 * t * t));
  }

  final double scale = maskable ? 0.50 : 0.66;
  return _over(color, _hamster(x - 0.5, y - 0.48, scale));
}

enum _Kind { icon, maskable, foreground, monochrome }

/// Renders one square RGBA image with `ss × ss` supersampling.
Uint8List _render(int size, _Kind kind, {int ss = 3}) {
  final Float32List accum = Float32List(size * size * 4);
  final double inv = 1 / (size * ss);

  for (int py = 0; py < size; py++) {
    for (int px = 0; px < size; px++) {
      double r = 0, g = 0, b = 0, a = 0;
      for (int sy = 0; sy < ss; sy++) {
        for (int sx = 0; sx < ss; sx++) {
          final _Rgb c = _sample(
            (px * ss + sx + 0.5) * inv,
            (py * ss + sy + 0.5) * inv,
            kind,
          );
          r += c.r * c.a;
          g += c.g * c.a;
          b += c.b * c.a;
          a += c.a;
        }
      }
      final double n = (ss * ss).toDouble();
      a /= n;
      if (a > 0) {
        r /= a;
        g /= a;
        b /= a;
      }
      final int i = (py * size + px) * 4;
      accum[i] = (r * 255).roundToDouble().clamp(0, 255);
      accum[i + 1] = (g * 255).roundToDouble().clamp(0, 255);
      accum[i + 2] = (b * 255).roundToDouble().clamp(0, 255);
      accum[i + 3] = (a * 255).roundToDouble().clamp(0, 255);
    }
  }

  final Uint8List rgba = Uint8List(size * size * 4);
  for (int i = 0; i < rgba.length; i++) {
    rgba[i] = accum[i].toInt();
  }
  return rgba;
}

// -------------------------------------------------------- PNG (no deps) ---
int _crc32(List<int> bytes, [int crc = 0xFFFFFFFF]) {
  // Standard IEEE polynomial, computed lazily without a global table so the
  // script stays a single self-contained file.
  int value = crc;
  for (final int byte in bytes) {
    value ^= byte;
    for (int i = 0; i < 8; i++) {
      value = (value & 1) == 1 ? (value >> 1) ^ 0xEDB88320 : value >> 1;
    }
  }
  return value & 0xFFFFFFFF;
}

void _writeChunk(BytesBuilder out, String type, List<int> data) {
  final List<int> tag = type.codeUnits;
  out.add(<int>[
    (data.length >> 24) & 0xFF,
    (data.length >> 16) & 0xFF,
    (data.length >> 8) & 0xFF,
    data.length & 0xFF,
  ]);
  out.add(tag);
  out.add(data);
  final int crc = _crc32(<int>[...tag, ...data]) ^ 0xFFFFFFFF;
  out.add(<int>[
    (crc >> 24) & 0xFF,
    (crc >> 16) & 0xFF,
    (crc >> 8) & 0xFF,
    crc & 0xFF,
  ]);
}

void _writePng(String path, int size, Uint8List rgba) {
  final Uint8List raw = Uint8List(size * (size * 4 + 1));
  for (int y = 0; y < size; y++) {
    final int dst = y * (size * 4 + 1);
    raw[dst] = 0; // filter: none
    raw.setRange(dst + 1, dst + 1 + size * 4, rgba, y * size * 4);
  }

  final BytesBuilder png = BytesBuilder();
  png.add(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _writeChunk(png, 'IHDR', <int>[
    (size >> 24) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 8) & 0xFF,
    size & 0xFF,
    (size >> 24) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 8) & 0xFF,
    size & 0xFF,
    8, // bit depth
    6, // colour type: RGBA
    0,
    0,
    0,
  ]);
  _writeChunk(png, 'IDAT', zlib.encode(raw));
  _writeChunk(png, 'IEND', const <int>[]);

  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(png.toBytes(), flush: true);
  final double kb = file.lengthSync() / 1024;
  stdout.writeln('  ${path.padRight(64)} ${size}x$size  ${kb.toStringAsFixed(1)} KB');
}

// ------------------------------------------------------------------ main ---
void main(List<String> args) {
  final Stopwatch watch = Stopwatch()..start();
  stdout.writeln('TauntBuddy · generating branding assets');

  const Map<String, int> mipmaps = <String, int>{
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  const Map<String, int> foregrounds = <String, int>{
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
  };

  mipmaps.forEach((String density, int size) {
    final int ss = size > 96 ? 3 : 4;
    _writePng(
      'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      size,
      _render(size, _Kind.icon, ss: ss),
    );
    _writePng(
      'android/app/src/main/res/mipmap-$density/ic_launcher_round.png',
      size,
      _render(size, _Kind.icon, ss: ss),
    );
  });

  foregrounds.forEach((String density, int size) {
    _writePng(
      'android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png',
      size,
      _render(size, _Kind.foreground, ss: 3),
    );
    _writePng(
      'android/app/src/main/res/mipmap-$density/ic_launcher_monochrome.png',
      size,
      _render(size, _Kind.monochrome, ss: 2),
    );
  });

  _writePng('web/favicon.png', 64, _render(64, _Kind.icon, ss: 4));
  _writePng('web/icons/Icon-192.png', 192, _render(192, _Kind.icon));
  _writePng('web/icons/Icon-512.png', 512, _render(512, _Kind.icon, ss: 2));
  _writePng('web/icons/Icon-maskable-192.png', 192, _render(192, _Kind.maskable));
  _writePng(
    'web/icons/Icon-maskable-512.png',
    512,
    _render(512, _Kind.maskable, ss: 2),
  );

  _writePng('assets/branding/icon.png', 512, _render(512, _Kind.icon, ss: 2));
  _writePng(
    'assets/branding/icon-maskable.png',
    512,
    _render(512, _Kind.maskable, ss: 2),
  );
  _writePng(
    'assets/branding/ic_launcher_foreground.png',
    432,
    _render(432, _Kind.foreground, ss: 2),
  );

  stdout.writeln('done in ${watch.elapsedMilliseconds} ms');
}
