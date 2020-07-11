import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:state_test/counter/counter_state.dart';
import 'package:state_test/infinite_scroll/middlewares.dart';
import 'package:state_test/middleware.dart';
import 'package:state_test/utils.dart';

class DelayMiddleware extends MiddleWare {
  @override
  Future<Reply> run(state, action, props) async {
    await Future.delayed(Duration(seconds: 3));
    print("Delay ended");
    return Reply.success(props, allowNull: true);
  }
}

void main() {
  group("Counter Test", () {
    runZoned(() {
      final counter = CounterState();
      test("Increment test", () {
        // counter.setDefaultMiddlewares([LoggerMiddleWare()]);
        expect(counter.rawStream, emitsInOrder([0, 1, 2, 3]));
        counter.dispatch(
          CounterActions.increment,
          pre: [DelayMiddleware()],
          onError: (e, stack) => print(stack),
          onSuccess: () => print(counter.state),
        );
        counter.dispatch(CounterActions.increment,
            onSuccess: () => print(counter.state));
        counter.dispatch(CounterActions.increment,
            onSuccess: () => print(counter.state));
        print("Actions dispatched");
      });
    });
  });
}
