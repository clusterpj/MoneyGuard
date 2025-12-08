import 'package:moneyguard/features/ai_advisor/data/datasources/ai_remote_data_source.dart';
import 'package:moneyguard/features/ai_advisor/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource _dataSource;

  AiRepositoryImpl(this._dataSource);

  @override
  Future<String> sendMessage(String message) async {
    return await _dataSource.sendMessage(message);
  }
}
