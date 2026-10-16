import 'package:flutter/foundation.dart';

/// Lightweight cross-screen signal that fires when the user creates a community
/// post. The Report tab calls [notifyPostCreated] after a successful submit;
/// the profile's "My posts" list listens and reloads once in response.
///
/// This keeps "My posts" from refetching on every visit: the list loads once
/// when the screen first opens, then only reloads after a post is made (this
/// signal) or when the user pulls to refresh.
class PostsRefreshSignal extends ChangeNotifier {
  /// Monotonic counter bumped on each new post. Listeners can compare it to a
  /// value they last handled to coalesce rapid signals into a single reload.
  int get revision => _revision;
  int _revision = 0;

  void notifyPostCreated() {
    _revision++;
    notifyListeners();
  }
}
