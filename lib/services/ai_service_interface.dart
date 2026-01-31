import '../models/passenger_event.dart';
import '../models/alert_event.dart';
import '../models/monitored_entity.dart';
import '../models/video_analysis.dart';

abstract class AiServiceInterface {
  Stream<PassengerEvent> get eventsStream;
  Stream<AlertEvent> get alertsStream;
  List<MonitoredEntity> get monitoredEntities;
  
  /// Simulates or performs AI analysis on a video.
  /// Returns a Future that completes with the analysis result.
  Future<VideoAnalysisResult> analyzeVideo(String videoUrl);

  void dispose();
}
