import 'package:state_test/infinite_scroll/models.dart';
import 'package:state_test/state_manager.dart';
import 'package:state_test/utils.dart';

enum PostActions {
  fetch,
}

class PostState extends StateManager<Status, List<Post>> {
  PostState() : super(state: Status.idle, object: List<Post>());
  int get offset => event.object.length;
  @override
  Future<void> handleAction(action, props) async {
    if (action is PostActions && props is Reply) {
      if (props.status == Status.success) {
        updateState(
            Status.success,
            List<Post>.from([
              ...event.object,
              ...props.data,
            ]));
      } else {
        updateStateWithError(props.error);
      }
    }
  }
}
