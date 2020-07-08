import 'package:state_test/state_manager.dart';

enum CounterActions {
  increment,
  decrement,
}

class CounterState extends StateManager<dynamic, int, dynamic> {
  CounterState() : super(state: dynamic, object: 0);
  @override
  Future<void> reducer(action, props) async {
    switch (action) {
      case CounterActions.increment:
        updateState(null, event.object + 1);
        break;
      case CounterActions.decrement:
        updateState(null, event.object - 1);
        break;
      default:
        throw Exception("Invalid action");
    }
  }
}
