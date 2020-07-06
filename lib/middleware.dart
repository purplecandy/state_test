import 'package:state_test/utils.dart';

abstract class MiddleWare {
  Future<Reply> run(props);
}
