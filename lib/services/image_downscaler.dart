import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Downscales picked screenshots to a sane size and strips their metadata
/// before upload.
///
/// Two goals:
///  * **Privacy** — re-encoding a decoded image drops all EXIF/metadata
///    (GPS location, camera make/model, timestamps, etc.) so none of it leaks
///    to the server with a screenshot.
///  * **Size** — capping the resolution and re-encoding as JPEG keeps uploads
///    small, which also lets large screenshots fit under the upload size cap
///    instead of being rejected.
///
/// Processing runs on a background isolate via [compute] so decoding a large
/// image never janks the UI.
class ImageDownscaler {
  const ImageDownscaler._();

  /// Longest edge (in pixels) a processed image is allowed to have. "720p"
  /// here means the shorter edge is capped at 720 and the longer edge at 1280,
  /// matching a 720p frame, while preserving aspect ratio. Images already
  /// smaller than this are never upscaled.
  static const int _maxShortEdge = 720;
  static const int _maxLongEdge = 1280;

  /// JPEG quality for the re-encoded output. 85 is visually lossless for
  /// screenshots while cutting file size substantially.
  static const int _jpegQuality = 85;

  /// Reads [source], downscales it to fit within 720p and strips its metadata,
  /// then writes the result to a new temporary JPEG file and returns it.
  ///
  /// Returns the original [source] unchanged if the bytes can't be decoded as
  /// an image (so a non-image or already-optimal file still uploads rather than
  /// failing outright).
  static Future<File> process(File source) async {
    final Uint8List bytes = await source.readAsBytes();
    final Uint8List? processed = await compute(_downscaleAndStrip, bytes);
    if (processed == null) return source;

    final String dir = source.parent.path;
    final String name =
        'scamwatch_shrunk_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final File out = File(p.join(dir, name));
    return out.writeAsBytes(processed);
  }

  /// Crops a uniform solid-colour border (e.g. the white margin the image
  /// editor bakes into a redacted screenshot) from [source], writes the
  /// trimmed result to a new temporary JPEG and returns it.
  ///
  /// The editor's merge step captures the edited canvas and re-encodes it as
  /// JPEG; sub-pixel rounding at the canvas edge leaves thin transparent
  /// margins that flatten to white in JPEG. This detects an outer frame whose
  /// rows/columns are a single near-constant colour and crops it away, leaving
  /// the real screenshot (and its redaction boxes) untouched.
  ///
  /// Returns [source] unchanged if the bytes can't be decoded or no uniform
  /// border is found, so a normal edit still uploads rather than failing.
  static Future<File> trimUniformBorder(File source) async {
    final Uint8List bytes = await source.readAsBytes();
    final Uint8List? trimmed = await compute(_trimUniformBorder, bytes);
    if (trimmed == null) return source;

    final String dir = source.parent.path;
    final String name =
        'scamwatch_trimmed_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final File out = File(p.join(dir, name));
    return out.writeAsBytes(trimmed);
  }
}

/// Pure function run on a background isolate: decode, detect a uniform
/// solid-colour outer border and crop it. Returns null if the bytes aren't a
/// decodable image or no border is detected (caller keeps the original).
Uint8List? _trimUniformBorder(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final img.Image oriented = img.bakeOrientation(decoded);
  final int w = oriented.width;
  final int h = oriented.height;
  if (w < 4 || h < 4) return null;

  // Per-channel tolerance for "same colour" — JPEG ringing at the seam means
  // the border isn't a perfectly flat value, so allow a small spread.
  const int tol = 16;

  bool rowIsUniform(int y, img.Pixel ref) {
    for (int x = 0; x < w; x++) {
      final img.Pixel px = oriented.getPixel(x, y);
      if ((px.r - ref.r).abs() > tol ||
          (px.g - ref.g).abs() > tol ||
          (px.b - ref.b).abs() > tol) {
        return false;
      }
    }
    return true;
  }

  bool colIsUniform(int x, img.Pixel ref) {
    for (int y = 0; y < h; y++) {
      final img.Pixel px = oriented.getPixel(x, y);
      if ((px.r - ref.r).abs() > tol ||
          (px.g - ref.g).abs() > tol ||
          (px.b - ref.b).abs() > tol) {
        return false;
      }
    }
    return true;
  }

  // Walk inward from each edge while the edge line stays the same colour as
  // the image's own corner pixel (the presumed border colour).
  final img.Pixel topRef = oriented.getPixel(0, 0);
  int top = 0;
  while (top < h - 1 && rowIsUniform(top, topRef)) {
    top++;
  }

  final img.Pixel bottomRef = oriented.getPixel(0, h - 1);
  int bottom = h - 1;
  while (bottom > top && rowIsUniform(bottom, bottomRef)) {
    bottom--;
  }

  final img.Pixel leftRef = oriented.getPixel(0, 0);
  int left = 0;
  while (left < w - 1 && colIsUniform(left, leftRef)) {
    left++;
  }

  final img.Pixel rightRef = oriented.getPixel(w - 1, 0);
  int right = w - 1;
  while (right > left && colIsUniform(right, rightRef)) {
    right--;
  }

  final int cropW = right - left + 1;
  final int cropH = bottom - top + 1;

  // Nothing to trim, or the detection ate (almost) the whole image (which
  // would mean the screenshot itself is near-uniform) — keep the original.
  if (cropW <= 0 || cropH <= 0) return null;
  if (left == 0 && top == 0 && cropW == w && cropH == h) return null;
  if (cropW < w ~/ 2 || cropH < h ~/ 2) return null;

  final img.Image cropped = img.copyCrop(
    oriented,
    x: left,
    y: top,
    width: cropW,
    height: cropH,
  );
  return Uint8List.fromList(
    img.encodeJpg(cropped, quality: ImageDownscaler._jpegQuality),
  );
}

/// Pure function run on a background isolate: decode, downscale to fit 720p,
/// re-encode as JPEG (which drops all EXIF/metadata). Returns null if the
/// bytes aren't a decodable image.
Uint8List? _downscaleAndStrip(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  // Apply any EXIF orientation now, then the re-encode below produces a clean
  // image with no metadata attached.
  final img.Image oriented = img.bakeOrientation(decoded);

  final int w = oriented.width;
  final int h = oriented.height;
  final int shortEdge = w < h ? w : h;
  final int longEdge = w > h ? w : h;

  // Only downscale when the image exceeds either cap; never upscale.
  final bool tooWide =
      shortEdge > ImageDownscaler._maxShortEdge ||
      longEdge > ImageDownscaler._maxLongEdge;

  img.Image result = oriented;
  if (tooWide) {
    // Scale so both caps are satisfied, preserving aspect ratio.
    final double shortScale = ImageDownscaler._maxShortEdge / shortEdge;
    final double longScale = ImageDownscaler._maxLongEdge / longEdge;
    final double scale = shortScale < longScale ? shortScale : longScale;
    final int targetW = (w * scale).round().clamp(1, w);
    final int targetH = (h * scale).round().clamp(1, h);
    result = img.copyResize(
      oriented,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.average,
    );
  }

  return Uint8List.fromList(img.encodeJpg(result, quality: ImageDownscaler._jpegQuality));
}
