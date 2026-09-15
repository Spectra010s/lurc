import '../entities/sample_entity.dart';

abstract class SampleRepository {
  Future<List<SampleEntity>> getSamples();
  Future<SampleEntity> getSampleById(String id);
}
