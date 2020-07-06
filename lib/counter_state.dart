import 'package:state_test/state_manager.dart';

enum CounterActions {
  increment,
  decrement,
}

class CounterState extends StateManager<dynamic, int> {
  CounterState() : super(state: dynamic, object: 0);
  @override
  Future<void> handleAction(action, props) async {
    switch (action) {
      case CounterActions.increment:
        var count = event.object + 1;
        updateState(null, count);
        break;
      case CounterActions.decrement:
        var count = event.object - 1;
        updateState(null, count);
        break;
      default:
        throw Exception("Invalid action");
    }
  }
}
