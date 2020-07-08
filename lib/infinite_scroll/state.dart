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
    if (action == PostActions.retry) {
      updateState(Status.loading, event.object);
      return;
    }
    if (action is PostActions && props is Reply) {
      if (props.status == Status.success &&
          (action == PostActions.fetch || action == PostActions.result)) {
        updateState(
          Status.success,
          props.data,
          // List<Post>.from([
          //   ...props.data,
          // ]),
        );
      } else {
        updateStateWithError(props.error);
      }
    }
  }
}
