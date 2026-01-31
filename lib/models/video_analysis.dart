
class VideoAnalysisResult {
  final String videoId;
  final Duration duration;
  final List<DetectedObject> objects;
  final int totalPeopleCount;

  VideoAnalysisResult({
    required this.videoId,
    required this.duration,
    required this.objects,
    required this.totalPeopleCount,
  });
}

class DetectedObject {
  final String id;
  final String label; // e.g., "Person"
  final double confidence;
  final List<ObjectFrame> frames;

  DetectedObject({
    required this.id,
    required this.label,
    required this.confidence,
    required this.frames,
  });
}

class ObjectFrame {
  final Duration timeOffset;
  final NormalizedBoundingBox boundingBox;

  ObjectFrame({
    required this.timeOffset,
    required this.boundingBox,
  });
}

class NormalizedBoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const NormalizedBoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
  
  // Helper to convert to absolute pixel coordinates
  // Rect toRect(Size size) {
  //   return Rect.fromLTRB(
  //     left * size.width, 
  //     top * size.height, 
  //     right * size.width, 
  //     bottom * size.height
  //   );
  // }
}
