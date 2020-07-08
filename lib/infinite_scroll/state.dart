import 'package:state_test/infinite_scroll/models.dart';
import 'package:state_test/state_manager.dart';
import 'package:state_test/utils.dart';

enum PostActions {
  fetch,
  retry,
  result,
}

class PostState extends StateManager<Status, List<Post>, PostActions> {
  PostState() : super(state: Status.idle, object: List<Post>());
  int get offset => event.object.length;
  @override
  Future<void> reducer(action, props) async {
    if (props is Reply) {
      switch (action) {
        case PostActions.fetch:
          return updateState(
            Status.success,
            List<Post>.from([
              ...event.object,
              ...props.data,
            ]),
          );
          break;
        case PostActions.result:
          updateState(
            Status.success,
            props.data,
          );
          break;
        default:
          updateState(Status.loading, event.object);
      }
    } else {
      updateStateWithError(props.error);
    }
  }
}
