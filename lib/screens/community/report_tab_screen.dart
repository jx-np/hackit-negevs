import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/api/api_exception.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/models/api/community_models.dart';
import 'package:scamwatch_mobile_app/models/api/detection_models.dart';
import 'package:scamwatch_mobile_app/screens/community/post_detail_screen.dart';
import 'package:scamwatch_mobile_app/services/api/community_service.dart';
import 'package:scamwatch_mobile_app/services/api/detection_service.dart';
import 'package:scamwatch_mobile_app/services/image_downscaler.dart';
import 'package:scamwatch_mobile_app/state/posts_refresh_signal.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/auth/require_login.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';

/// The lifecycle of a single attached screenshot.
///
/// Every picked image begins uploading immediately in parallel
/// ([_UploadStatus.uploading]). When its upload finishes it does NOT start its
/// detection check right away — to keep load off the server only one check runs
/// at a time. Instead it becomes [_UploadStatus.queued] (uploaded, waiting its
/// turn) and the check driver works through the queue LIFO (last-picked first).
/// When an image reaches the front it moves to [_UploadStatus.processing] and
/// polls the owner-only `GET /uploads/{upload_id}` until it is
/// [_UploadStatus.ready] or [_UploadStatus.failed]; only then does the next
/// queued image start its check.
enum _UploadStatus { uploading, queued, processing, ready, failed }

/// Tracks one picked screenshot through upload + detection so the UI can show
/// per-image progress and the submit step can collect the ready `upload_id`s.
class _ImageUpload {
  _ImageUpload(this.file);

  /// The on-disk image shown in the grid. Mutable so an edited version can
  /// replace the original after it's re-uploaded through `/uploads`.
  XFile file;

  /// The stored upload returned by `/uploads`. Null until it responds. This is
  /// what gets attached to the post via `upload_ids`, and the key used to poll
  /// the owner-only `GET /uploads/{upload_id}` for processing status.
  String? uploadId;

  _UploadStatus status = _UploadStatus.uploading;

  /// How many times a `failed` check has been retried. Capped at one retry.
  int retries = 0;

  /// Active poll timer for this image; cancelled when the image resolves or is
  /// removed.
  Timer? pollTimer;

  /// Deadline after which polling gives up and the image is treated as failed.
  DateTime? pollDeadline;

  /// The last error that pushed this image toward failure, surfaced to the user
  /// and logged so a silent drop becomes diagnosable (bad type, network, or the
  /// backend's screenshot check resolving to `failed`).
  String? failureReason;

  /// True while an edited version of this image is being re-uploaded through
  /// `/uploads`. Shown as a distinct overlay so the user knows the edit is
  /// saving. The image keeps its [_UploadStatus.ready] status throughout since
  /// an edited re-upload is trusted and not re-checked.
  bool reuploading = false;

  /// The server's redacted derivative of this upload, downloaded from the
  /// owner-only `GET /uploads/{upload_id}/redacted-image` once [status] is
  /// [_UploadStatus.ready]. This is what the user actually reviews and edits —
  /// never the raw local [file], which still contains the un-redacted PII.
  /// Null until the derivative has been fetched (or if that fetch failed).
  File? redactedFile;

  /// In-flight redacted-image download, tracked so concurrent callers (the
  /// on-ready prefetch and a tap-to-edit) share one request instead of hitting
  /// the owner-only endpoint twice. Cleared on failure so a later attempt can
  /// retry.
  Future<File?>? redactedFuture;

  /// The image shown in the grid and opened in the editor: the server-redacted
  /// derivative when it has landed, otherwise the local file (still uploading /
  /// processing, or the derivative fetch failed).
  File get displayFile => redactedFile ?? File(file.path);

  /// True once the upload has a server-side id that is safe to attach to a
  /// post. A re-uploading image is NOT ready: its edited bytes are still in
  /// flight and [uploadId] still points at the stale pre-edit upload, so
  /// [_submit] must skip it until the re-upload lands.
  bool get isReady => status == _UploadStatus.ready && !reuploading;

  /// True while the image is still working toward a terminal state: uploading,
  /// waiting in the check queue, being checked, or re-uploading an edit.
  /// [_waitForImages] and [_submit] block until every image is out of this set
  /// (ready or failed).
  bool get isPending =>
      reuploading ||
      status == _UploadStatus.uploading ||
      status == _UploadStatus.queued ||
      status == _UploadStatus.processing;

  /// True once the upload has finished and the image is waiting in the check
  /// queue for its turn (no check is running for it yet).
  bool get isQueued => status == _UploadStatus.queued;
}

class ReportTabScreen extends StatefulWidget {
  const ReportTabScreen({
    super.key,
    required this.client,
    this.prefillTitle,
    this.prefillText,
    this.numberReport = false,
    this.prefillNumber,
    this.onReported,
  });

  final ApiClient client;
  final String? prefillTitle;
  final String? prefillText;
  final bool numberReport;
  final String? prefillNumber;

  /// Called once the report has been posted successfully. Used by callers that
  /// opened this screen for a detected scam so they can clear that alert from
  /// the recent-alerts list (and its count) instead of leaving it behind.
  final Future<void> Function()? onReported;

  @override
  State<ReportTabScreen> createState() => _ReportTabScreenState();
}

class _ReportTabScreenState extends State<ReportTabScreen> {
  /// Matches the server's hard `/uploads` cap (10 MiB). Keeping this in sync
  /// with [DetectionService.maxUploadBytes] means a file rejected here is the
  /// same one the server would reject with `413`.
  static const int _maxImageBytes = DetectionService.maxUploadBytes;

  late final CommunityService _community = CommunityService(widget.client);
  late final DetectionService _detection = DetectionService(widget.client);
  final ImagePicker _imagePicker = ImagePicker();

  static const List<String> _reasons = <String>['spam', 'scam', 'other'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  String _reason = 'scam';

  final List<_ImageUpload> _images = <_ImageUpload>[];

  /// How often to poll a processing detection check.
  static const Duration _pollInterval = Duration(seconds: 3);

  /// How long to keep polling a single check before giving up (treated as
  /// failed, which then follows the retry-once-then-drop path). Screenshot
  /// analysis runs OCR plus a separate PII-redaction service, so over a slow
  /// tunnel it can take well over a minute; keep polling for a few minutes
  /// before giving up so a slow-but-working backend isn't treated as a failure.
  static const Duration _pollTimeout = Duration(minutes: 3);

  bool _submitting = false;
  String? _error;
  bool _justShared = false;

  /// True while the final `createPost` request is in flight. Drives the
  /// center-of-screen posting overlay (distinct from the per-image progress and
  /// the bottom button spinner).
  bool _posting = false;

  /// The post returned by `createPost`, kept so the success view can redirect
  /// the user into it (opening its detail screen under "My posts").
  PostDetail? _createdPost;

  /// Set once the user ticks the "I've reviewed the images" checkbox. The Share
  /// button only becomes enabled/primary after this is true (when images are
  /// attached). Reset whenever the set of images changes so a late edit or a
  /// newly added photo forces a fresh review.
  bool _reviewed = false;

  /// Attached to the review checkbox so we can scroll it into view once the
  /// images are ready.
  final GlobalKey _reviewKey = GlobalKey();

  /// True when at least one screenshot is attached.
  bool get _hasImages => _images.isNotEmpty;

  /// True when every attached image has finished analysis (ready) and is not
  /// mid re-upload of an edit. An empty list counts as ready so a text-only
  /// post can be shared immediately.
  bool get _allImagesReady => _images.every((image) => image.isReady);

  /// True when any attached image is still uploading, queued, or processing.
  bool get _anyImagePending => _images.any((image) => image.isPending);

  @override
  void initState() {
    super.initState();
    final prefillTitle = widget.prefillTitle;
    final prefillText = widget.prefillText;
    final prefillNumber = widget.prefillNumber;
    if (prefillTitle != null) _titleController.text = prefillTitle;
    if (prefillText != null) _textController.text = prefillText;
    if (prefillNumber != null) _numberController.text = prefillNumber;
  }

  @override
  void dispose() {
    for (final _ImageUpload image in _images) {
      image.pollTimer?.cancel();
    }
    _titleController.dispose();
    _textController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    // Attaching photos runs a detection check we later poll via an
    // owner-only endpoint, so it requires an account. Prompt sign-in before
    // picking anything; bail quietly if the user backs out.
    final bool signedIn = await requireLogin(context);
    if (!signedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportTabSignInToAddPhotos)),
      );
      return;
    }
    // `requireLogin` only confirms the UI "signed in" flag. The detection
    // check is created under whatever identity the upload carries, and it can
    // only be polled back by its authenticated owner — so make sure a bearer
    // token is physically present before uploading, otherwise the check would
    // be created anonymously and poll forever as "check not found".
    final bool hasToken = await widget.client.hasAccessToken();
    if (!mounted) return;
    if (!hasToken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportTabSignInToAddPhotos)),
      );
      return;
    }
    final List<XFile> picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;
    final List<XFile> accepted = <XFile>[];
    bool rejected = false;
    for (final XFile file in picked) {
      // Downscale to 720p and strip metadata (EXIF/GPS/camera info) before the
      // size check. Re-encoding to JPEG drops all metadata and shrinks the
      // file, which also lets large screenshots fit under [_maxImageBytes]
      // instead of being rejected outright.
      final File shrunk = await ImageDownscaler.process(File(file.path));
      final int length = await shrunk.length();
      if (length > _maxImageBytes) {
        rejected = true;
        continue;
      }
      accepted.add(XFile(shrunk.path));
    }
    if (!mounted) return;
    final List<_ImageUpload> added = <_ImageUpload>[];
    setState(() {
      for (final XFile file in accepted) {
        final _ImageUpload upload = _ImageUpload(file);
        _images.add(upload);
        added.add(upload);
      }
      // New photos invalidate any prior review — the user must look again.
      _reviewed = false;
    });
    if (rejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonImageTooLarge)),
      );
    }
    // Start every upload right away, in parallel — uploads are cheap on the
    // server. The detection *checks* are what we serialize: as each upload
    // finishes the image joins the check queue, and [_processNextCheck] runs
    // them one at a time, last-picked first.
    for (final _ImageUpload upload in added) {
      unawaited(_startUpload(upload));
    }
  }

  void _removePhoto(_ImageUpload image) {
    image.pollTimer?.cancel();
    // Also drop the server-side upload, so its raw + redacted blobs are purged
    // now instead of lingering until the 24 h retention reaper. Best-effort:
    // the local removal must never be blocked by a failed delete.
    unawaited(_discardUpload(image.uploadId));
    setState(() {
      _images.remove(image);
      // Changing the image set invalidates the review confirmation.
      _reviewed = false;
    });
    // Removing the image that was being checked (or waiting at the top) frees
    // the single check slot — let the driver promote the next queued image.
    _processNextCheck();
  }

  /// Uploads a single image to `POST /uploads`. Uploads run in parallel. The
  /// upload auto-schedules a detection check, but we do NOT start polling it
  /// here — instead the image moves to [_UploadStatus.queued] and waits its
  /// turn so only one check runs at a time. [_processNextCheck] drives the
  /// queue (last-picked first). A client-side validation or network failure
  /// marks the image failed via the retry-once path.
  Future<void> _startUpload(_ImageUpload image) async {
    try {
      final Upload upload = await _detection.uploadImage(File(image.file.path));
      // If the image was removed (or the screen went away) while the bytes were
      // still in flight, nothing will ever reference this upload — purge it
      // rather than leaving an orphan to expire on its own.
      if (!mounted || !_images.contains(image)) {
        unawaited(_discardUpload(upload.uploadId));
        return;
      }
      setState(() {
        image.uploadId = upload.uploadId;
        // Uploaded, but wait in the check queue rather than polling now.
        image.status = _UploadStatus.queued;
      });
      _processNextCheck();
    } on ApiException catch (e) {
      debugPrint('Image upload failed: ${e.statusCode} ${e.code} ${e.message}');
      image.failureReason = e.message;
      _markFailed(image);
    }
  }

  /// Serial driver for detection checks. Only one check runs at a time to keep
  /// load off the server. Images are checked in reverse pick order (LIFO): the
  /// most recently picked image has priority.
  ///
  /// Priority is strict — if the top (last-picked) image is still uploading,
  /// the driver waits for it rather than checking an earlier image that already
  /// uploaded. It is re-invoked whenever an upload finishes or a check settles,
  /// so the queue keeps draining until every image is terminal.
  void _processNextCheck() {
    if (!mounted) return;
    // A check is already running (exactly one image is ever `processing`).
    if (_images.any((image) => image.status == _UploadStatus.processing)) {
      return;
    }
    // The top of the stack is the last-picked image still needing a check,
    // i.e. the highest-index image that is queued or still uploading.
    _ImageUpload? top;
    for (final _ImageUpload image in _images) {
      if (image.status == _UploadStatus.queued ||
          image.status == _UploadStatus.uploading) {
        top = image; // keep the last match → highest index → last picked
      }
    }
    if (top == null) return; // nothing left to check
    if (top.status == _UploadStatus.uploading) {
      // The highest-priority image hasn't finished uploading yet. Wait for it;
      // _startUpload will call us again when it lands in the queue. Do NOT
      // skip ahead to an earlier image.
      return;
    }
    // Promote the queued top image to a running check.
    setState(() {
      top!.status = _UploadStatus.processing;
      top.pollDeadline = DateTime.now().add(_pollTimeout);
    });
    _startPolling(top);
  }

  /// Begins (or restarts) periodic polling of a processing image's detection
  /// check until it is ready, failed, or the poll deadline passes.
  void _startPolling(_ImageUpload image) {
    image.pollTimer?.cancel();
    image.pollTimer = Timer.periodic(_pollInterval, (_) => _poll(image));
    // Poll once immediately so a fast check doesn't wait a full interval.
    unawaited(_poll(image));
  }

  Future<void> _poll(_ImageUpload image) async {
    final String? uploadId = image.uploadId;
    if (uploadId == null || !mounted || !_images.contains(image)) {
      image.pollTimer?.cancel();
      return;
    }
    final DateTime? deadline = image.pollDeadline;
    if (deadline != null && DateTime.now().isAfter(deadline)) {
      debugPrint('Upload $uploadId timed out while processing');
      image.failureReason = 'Analysis timed out';
      _markFailed(image);
      return;
    }
    try {
      // Only the upload's processing status matters here (not a verdict): once
      // it is `ready` the redacted screenshot can be attached to a post. Poll
      // the owner-only `GET /uploads/{id}` progress endpoint by upload id.
      final UploadProgress progress = await _detection.uploadStatus(uploadId);
      if (!mounted || !_images.contains(image)) return;
      // Log the raw status each tick so a slow backend vs. a terminal failure
      // (and any unexpected status string) is visible when running attached.
      debugPrint('Upload $uploadId status: "${progress.status}"');
      if (progress.isReady) {
        image.pollTimer?.cancel();
        setState(() => image.status = _UploadStatus.ready);
        // Fetch the server-redacted derivative now so the grid (and the editor)
        // show the censored image rather than the raw local file. Best-effort:
        // a failure leaves the original on screen and a tap-to-edit retries.
        unawaited(_ensureRedacted(image));
        // Once the last image is ready, lead the user to the review tick.
        if (_allImagesReady && !_anyImagePending && !_reviewed) {
          _guideToReview();
        }
        // Slot freed — let the next queued image start its check.
        _processNextCheck();
      } else if (progress.isFailed) {
        // The server resolves an upload to `failed` when its PII redaction
        // service can't process the image (e.g. PII_SERVICE_URL unset) — the
        // upload succeeded but the redacted derivative could not be produced.
        debugPrint('Upload $uploadId resolved to failed on the server');
        image.failureReason = 'Analysis could not complete';
        _markFailed(image);
      }
      // Otherwise still processing; keep polling until ready/failed/timeout.
    } on ApiException catch (e) {
      if (e.isNotFound || e.isForbidden || e.isUnauthorized) {
        // Terminal: the upload can't be read by this caller (e.g. it was
        // created under a different identity, or the session is gone).
        // Retrying can't fix that, so stop immediately instead of spinning
        // until the deadline. _markFailed re-uploads once, which also
        // re-creates the upload under the current (authenticated) identity.
        debugPrint(
          'Upload $uploadId poll failed terminally: '
          '${e.statusCode} ${e.code} ${e.message}',
        );
        image.failureReason = e.message;
        _markFailed(image);
        return;
      }
      // Transient errors (network, 5xx) shouldn't kill the whole image — let
      // polling retry on the next tick; the deadline guard eventually gives up.
      debugPrint('Upload $uploadId poll error (will retry): ${e.message}');
    }
  }

  /// Ensures [image]'s server-redacted derivative is on disk and returns it,
  /// downloading it once if needed. Concurrent calls for the same image share a
  /// single in-flight request. Returns null if the derivative can't be fetched.
  Future<File?> _ensureRedacted(_ImageUpload image) {
    final File? already = image.redactedFile;
    if (already != null) return Future<File?>.value(already);
    final Future<File?>? inFlight = image.redactedFuture;
    if (inFlight != null) return inFlight;
    final Future<File?> future = _downloadRedacted(image);
    image.redactedFuture = future;
    return future;
  }

  /// Downloads [image]'s redacted derivative from the owner-only
  /// `GET /uploads/{id}/redacted-image` and caches it to a temp file. The
  /// in-flight marker is cleared on failure so a later attempt can retry.
  Future<File?> _downloadRedacted(_ImageUpload image) async {
    final String? uploadId = image.uploadId;
    if (uploadId == null) return null;
    try {
      final Uint8List bytes = await _detection.fetchRedactedImage(uploadId);
      // The image may have been removed or re-uploaded (new id) while we
      // waited; a stale derivative must never be shown against a new upload.
      if (!mounted || !_images.contains(image) || image.uploadId != uploadId) {
        return null;
      }
      final String path =
          '${Directory.systemTemp.path}/scamwatch_redacted_$uploadId.jpg';
      final File file = await File(path).writeAsBytes(bytes, flush: true);
      if (!mounted || !_images.contains(image) || image.uploadId != uploadId) {
        return null;
      }
      setState(() => image.redactedFile = file);
      return file;
    } on ApiException catch (e) {
      // Non-fatal: the grid keeps showing the local original and a tap-to-edit
      // re-attempts the download.
      debugPrint(
        'Redacted image fetch failed for upload $uploadId: '
        '${e.statusCode} ${e.code} ${e.message}',
      );
      image.redactedFuture = null;
      return null;
    } catch (error) {
      // Any non-API failure (e.g. a disk error writing the cache) is equally
      // non-fatal — surface it and let a later tap retry.
      debugPrint('Redacted image fetch failed for upload $uploadId: $error');
      image.redactedFuture = null;
      return null;
    }
  }

  /// Best-effort server-side cleanup of an upload the user is done with: the
  /// owner-only `DELETE /uploads/{id}` purges its raw + redacted blobs.
  ///
  /// Never surfaced to the user — a failed delete (already gone, offline) is
  /// only logged, since the blobs expire on their own after 24 h anyway. Pass
  /// null for an image that never got a server id; it's then a no-op.
  Future<void> _discardUpload(String? uploadId) async {
    if (uploadId == null) return;
    try {
      await _detection.deleteUpload(uploadId);
    } on ApiException catch (e) {
      debugPrint(
        'Discarding upload $uploadId failed: '
        '${e.statusCode} ${e.code} ${e.message}',
      );
    } catch (error) {
      debugPrint('Discarding upload $uploadId failed: $error');
    }
  }

  /// Handles a failed (or timed-out) detection check: retry the upload once
  /// automatically, then leave the image in the grid marked [_UploadStatus.failed]
  /// so the user can see it and decide at submit time whether to retry again or
  /// post without it. The image is NOT auto-dropped — [_submit] prompts about
  /// any failed images so a post never silently drops the user's screenshots.
  void _markFailed(_ImageUpload image) {
    image.pollTimer?.cancel();
    if (!mounted || !_images.contains(image)) return;
    if (image.retries < 1) {
      // Retry once automatically: re-upload from scratch (a new check is
      // scheduled). A manual retry from the submit dialog resets this counter.
      setState(() {
        image.retries += 1;
        image.uploadId = null;
        image.status = _UploadStatus.uploading;
        image.pollDeadline = null;
        image.failureReason = null;
        // The retry re-uploads from scratch (a new id), so any redacted
        // derivative tied to the previous upload is stale.
        image.redactedFile = null;
        image.redactedFuture = null;
      });
      unawaited(_startUpload(image));
      // This image left the check slot (back to uploading). Let the driver
      // advance: if a lower-priority image was queued it can run now, unless
      // this (higher-priority) image is still the top, in which case the
      // driver waits for its re-upload.
      _processNextCheck();
      return;
    }
    // Already retried once — keep the image visible with a failed badge. The
    // submit flow surfaces these so the user chooses retry vs. post-without.
    setState(() => image.status = _UploadStatus.failed);
    // Terminal: free the check slot so the next queued image can run.
    _processNextCheck();
  }

  /// Re-uploads every image currently marked failed, resetting its retry
  /// counter so the automatic one-retry path applies again. Used by the submit
  /// dialog's "Retry" action; the user stays on the report page.
  void _retryFailedImages() {
    final List<_ImageUpload> failed = <_ImageUpload>[
      for (final _ImageUpload image in _images)
        if (image.status == _UploadStatus.failed) image,
    ];
    if (failed.isEmpty) return;
    setState(() {
      for (final _ImageUpload image in failed) {
        image.retries = 0;
        image.uploadId = null;
        image.status = _UploadStatus.uploading;
        image.pollDeadline = null;
        image.failureReason = null;
        // Re-upload gets a new id; discard any derivative from the failed one.
        image.redactedFile = null;
        image.redactedFuture = null;
      }
    });
    for (final _ImageUpload image in failed) {
      unawaited(_startUpload(image));
    }
  }

  /// Drops every failed image from the grid. Used by the submit dialog's
  /// "Post without photos" action so the post proceeds with only ready images.
  void _dropFailedImages() {
    setState(() {
      _images.removeWhere((image) => image.status == _UploadStatus.failed);
    });
  }

  /// Opens the image editor on a ready screenshot so the user can fix the PII
  /// redaction (e.g. paint over anything the automatic censor missed). On save,
  /// the edited bytes are re-uploaded through `/uploads`, producing a brand-new
  /// upload the server must redact afresh. The image re-enters the check queue
  /// and is polled back to `ready` before it can be attached to a post — the
  /// server rejects a post whose `upload_id` has not finished redaction. Editing
  /// resets the review flag so the user re-confirms the final images.
  Future<void> _editImage(_ImageUpload image) async {
    final l10n = AppLocalizations.of(context);
    // Only ready images can be edited; a pending/failed image has nothing
    // stable to show in the editor.
    if (image.status != _UploadStatus.ready || image.reuploading) return;

    // Edit the *redacted* derivative the server produced, not the raw local
    // file — otherwise the editor would show (and later re-upload) the
    // un-censored PII. Fetch it on demand if the on-ready prefetch hasn't
    // landed yet.
    final File? redacted = await _ensureRedacted(image);
    if (!mounted) return;
    if (redacted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportTabEditorLoadFailed)),
      );
      return;
    }
    final Uint8List bytes = await redacted.readAsBytes();
    if (!mounted) return;

    final Uint8List? edited = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (_) => ImageEditor(image: bytes),
      ),
    );
    if (!mounted || edited == null) return;

    // Persist the edited bytes to a temp file (uploadImage takes a File). A
    // unique name avoids clobbering a previous edit of the same image.
    final String tempPath =
        '${Directory.systemTemp.path}/scamwatch_edit_'
        '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final File tempFile = await File(tempPath).writeAsBytes(edited);

    setState(() {
      image.reuploading = true;
      // A fresh edit must be reviewed again before sharing.
      _reviewed = false;
    });

    // Tracks the upload this edit supersedes. Hoisted so the failure path knows
    // the image may no longer be pointing at a live upload.
    String? replacedUploadId;
    // The downscaled edited bytes, kept so a failed re-upload can resume from
    // them instead of falling back to the pre-edit original.
    File? editedFile;
    try {
      // The editor bakes a thin uniform (white) border into the merged JPEG;
      // crop it off before anything else so the re-upload matches the original
      // framing. Falls back to the untrimmed file if no border is detected.
      final File trimmed = await ImageDownscaler.trimUniformBorder(tempFile);
      // Downscale to 720p and strip metadata from the edited bytes too, so an
      // edited re-upload gets the same privacy/size treatment as a fresh pick.
      final File shrunk = await ImageDownscaler.process(trimmed);
      editedFile = shrunk;
      // Delete the upload this edit replaces *before* creating its replacement,
      // so the old raw + redacted blobs are purged now rather than lingering
      // until the 24 h retention reaper. Best-effort: an already-gone (404) or
      // transiently failing delete must not block the edit.
      replacedUploadId = image.uploadId;
      await _discardUpload(replacedUploadId);
      final Upload up = await _detection.uploadImage(
        shrunk,
        requireAuth: true,
      );
      if (!mounted || !_images.contains(image)) {
        // The image (or the whole form) went away while the edited bytes were
        // uploading — purge the fresh upload instead of orphaning it.
        unawaited(_discardUpload(up.uploadId));
        return;
      }
      setState(() {
        // Point the thumbnail at the edited file and attach the new upload.
        image.file = XFile(shrunk.path);
        image.uploadId = up.uploadId;
        // The edit is a brand-new upload with its own redacted derivative;
        // drop the stale one so the grid/editor refetch for the new id.
        image.redactedFile = null;
        image.redactedFuture = null;
        // The edit produced a brand-new upload the server still has to redact.
        // Its `upload_id` is NOT valid for a post until `GET /uploads/{id}`
        // reports `ready` (POST /community/posts rejects a not-yet-redacted
        // upload and creates no post). So re-enter the normal check queue and
        // poll for redaction instead of trusting it ready immediately — exactly
        // like a freshly picked image.
        image.status = _UploadStatus.queued;
        image.pollDeadline = null;
        image.failureReason = null;
        image.reuploading = false;
      });
      // Drive the serial check queue so the re-uploaded image gets polled to
      // `ready` (or `failed`) before it can be attached to a post.
      _processNextCheck();
    } on ApiException catch (e) {
      debugPrint('Edited image re-upload failed: ${e.message}');
      if (!mounted) return;
      final File? shrunk = editedFile;
      if (replacedUploadId != null) {
        // The superseded upload has already been deleted, so leaving this image
        // on its stale id would attach a dead `upload_id` to the post. Keep the
        // user's edit instead and re-enter the normal upload flow with it; the
        // retry-once path in [_startUpload]/[_markFailed] covers a second
        // failure.
        setState(() {
          if (shrunk != null) image.file = XFile(shrunk.path);
          image.uploadId = null;
          image.redactedFile = null;
          image.redactedFuture = null;
          image.status = _UploadStatus.uploading;
          image.pollDeadline = null;
          image.failureReason = null;
          image.reuploading = false;
        });
        unawaited(_startUpload(image));
      } else {
        // Nothing was deleted — the pre-edit upload is still valid, so just drop
        // the "saving" overlay and leave the image as it was.
        setState(() => image.reuploading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportTabEditorSaveFailed)),
      );
    }
  }

  /// Scrolls the review checkbox into view so the user sees the tick they need
  /// to press before sharing. Waits a frame so a just-ready image has laid out.
  void _guideToReview() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? target = _reviewKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.6,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _pasteMessage() async {
    final l10n = AppLocalizations.of(context);
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final String text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportTabPasteEmpty)),
      );
      return;
    }
    _textController.text = text;
    _textController.selection =
        TextSelection.collapsed(offset: _textController.text.length);
  }

  /// Runs the caller's [ReportTabScreen.onReported] hook after a successful
  /// post. A failure to clear the alert must never turn a successful report
  /// into an error screen, so it is swallowed after logging.
  Future<void> _notifyReported() async {
    final onReported = widget.onReported;
    if (onReported == null) return;
    try {
      await onReported();
    } catch (error) {
      debugPrint('[ScamShield] could not clear the reported alert: $error');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Capture before the awaits so we don't touch `context` across async gaps.
    // A content post adds to the user's "My posts"; a number report does not.
    final postsSignal = widget.numberReport
        ? null
        : context.read<PostsRefreshSignal>();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (widget.numberReport) {
        await _community.reportNumber(
          number: _numberController.text.trim(),
          reason: _reason,
        );
      } else {
        // Screenshots are uploaded + polled as they're picked. The post must
        // never go out with an unresolved image, so loop until every image is
        // in a terminal state: first block on a progress overlay while any are
        // pending (uploading or mid auto-retry), then — once nothing is pending
        // — surface any that failed and let the user retry or post without
        // them. A "Retry" re-uploads the failed images (putting them back into
        // `pending`), so we loop around and wait again. The loop only exits,
        // falling through to `createPost`, once nothing is pending AND nothing
        // is failed. This closes the race where the overlay could pop on a
        // transient "nothing pending" snapshot while a failing image was briefly
        // back in `uploading`, letting an empty post slip through.
        while (true) {
          if (_images.any((image) => image.isPending)) {
            await _waitForImages();
            if (!mounted) return;
            // Re-check from the top: a retry triggered while waiting may have
            // put images back into `pending`.
            continue;
          }
          if (_images.any((image) => image.status == _UploadStatus.failed)) {
            final bool proceed = await _resolveFailedImages();
            if (!mounted) return;
            if (!proceed) {
              // User chose to retry (or dismissed): return to the report page
              // without posting. The failed images are re-uploading now.
              setState(() => _submitting = false);
              return;
            }
            // "Post without photos" dropped the failed images; loop once more
            // to confirm nothing is pending or failed before posting.
            continue;
          }
          // Nothing pending, nothing failed — safe to create the post.
          break;
        }
        // Collect the upload IDs for every image that finished analysis; any
        // failed ones were dropped by the "post without photos" choice above.
        // The post attaches screenshots by `upload_id`.
        final List<String> uploadIds = <String>[
          for (final _ImageUpload image in _images)
            if (image.isReady && image.uploadId != null) image.uploadId!,
        ];
        // The user has reviewed the images; now actually create the post. Show
        // a center-of-screen posting overlay (distinct from the per-image
        // progress) until the server responds with the created post.
        setState(() => _posting = true);
        final PostDetail detail = await _community.createPost(
          title: _titleController.text.trim(),
          redactedText: _textController.text.trim(),
          uploadIds: uploadIds,
        );
        // Tell "My posts" to reload once; it ignores all other visits.
        postsSignal?.notifyPostCreated();
        await _notifyReported();
        if (!mounted) return;
        setState(() {
          _posting = false;
          _submitting = false;
          _createdPost = detail;
          _justShared = true;
        });
        return;
      }
      await _notifyReported();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _justShared = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
        _posting = false;
      });
    }
  }

  /// Opens the just-created post in its own detail screen (under "My posts"),
  /// loading any attached images. Used by the success view's redirect button.
  Future<void> _openCreatedPost() async {
    final PostDetail? detail = _createdPost;
    if (detail == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(
          client: widget.client,
          postId: detail.postId,
        ),
      ),
    );
  }

  /// Blocks with a modal progress overlay until every pending image resolves
  /// (ready, or dropped after the retry-once path). The uploads and polling are
  /// already running from `_addPhoto`; this just waits for them to settle while
  /// keeping the user from closing the app mid-processing.
  Future<void> _waitForImages() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProcessingDialog(
        isDone: () => _images.every((image) => !image.isPending),
      ),
    );
  }

  /// Prompts the user about images that failed to upload or analyze. Returns
  /// `true` only when the post should proceed (the user chose "Post without
  /// photos", so the failed images are dropped first). Returns `false` when the
  /// user chose "Retry" (the failed images start re-uploading and the user
  /// stays on the report page) or dismissed the dialog without deciding.
  Future<bool> _resolveFailedImages() async {
    final l10n = AppLocalizations.of(context);
    final int failedCount =
        _images.where((image) => image.status == _UploadStatus.failed).length;
    final String? choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reportTabFailedDialogTitle),
        content: Text(l10n.reportTabFailedDialogBody(failedCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('retry'),
            child: Text(l10n.reportTabFailedRetry),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('post'),
            child: Text(l10n.reportTabFailedPostWithout),
          ),
        ],
      ),
    );
    if (choice == 'post') {
      _dropFailedImages();
      return true;
    }
    // "retry" or dismissed: re-upload the failed images and stay on the page.
    if (choice == 'retry') {
      _retryFailedImages();
    }
    return false;
  }

  void _reportAnother() {
    for (final _ImageUpload image in _images) {
      image.pollTimer?.cancel();
    }
    setState(() {
      _justShared = false;
      _error = null;
      _posting = false;
      _createdPost = null;
      _reviewed = false;
      _reason = 'scam';
      _titleController.clear();
      _textController.clear();
      _numberController.clear();
      _images.clear();
    });
  }

  String? _validateNumber(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).reportTabNumberRequired;
    }
    return null;
  }

  String? _validateTitle(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).createAddTitle;
    }
    return null;
  }

  String? _validateText(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).createAddMessage;
    }
    return null;
  }

  List<_ReasonOption> _reasonOptions(AppLocalizations l10n) {
    return <_ReasonOption>[
      for (final String reason in _reasons)
        switch (reason) {
          'spam' => _ReasonOption(
              value: reason,
              icon: LucideIcons.megaphone,
              label: l10n.reportSpam,
              description: l10n.reportTabReasonSpamBody,
            ),
          'scam' => _ReasonOption(
              value: reason,
              icon: LucideIcons.shieldAlert,
              label: l10n.reportScam,
              description: l10n.reportTabReasonScamBody,
            ),
          _ => _ReasonOption(
              value: reason,
              icon: LucideIcons.circleHelp,
              label: l10n.reportOther,
              description: l10n.reportTabReasonOtherBody,
            ),
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_justShared) {
      final bool canPop = Navigator.of(context).canPop();
      return AppScreen(
        title: l10n.reportTabTitle,
        body: _SuccessView(
          message: widget.numberReport
              ? l10n.reportTabThankYou
              : l10n.reportTabTrackIt,
          reportAnotherLabel: l10n.reportTabReportAnother,
          onReportAnother: _reportAnother,
          doneLabel: l10n.reportTabDone,
          onDone: canPop ? () => Navigator.of(context).pop() : null,
          // Only content posts create a viewable post; number reports don't.
          openPostLabel: l10n.reportTabViewPost,
          onOpenPost: _createdPost != null ? _openCreatedPost : null,
        ),
      );
    }

    final _SubmitPhase phase;
    final String submitLabel;
    if (!_hasImages || widget.numberReport) {
      // Text-only posts (or number reports) can share immediately.
      phase = _SubmitPhase.ready;
      submitLabel = _submitting ? l10n.commonSharing : l10n.commonShare;
    } else if (!_allImagesReady || _anyImagePending) {
      // Images still uploading/analyzing: block until all are ready.
      phase = _SubmitPhase.waiting;
      submitLabel = l10n.reportTabWaitForImages;
    } else if (!_reviewed) {
      // All ready but not yet reviewed: nudge the user to check the images.
      phase = _SubmitPhase.review;
      submitLabel = l10n.reportTabCheckImages;
    } else {
      phase = _SubmitPhase.ready;
      submitLabel = _submitting ? l10n.commonSharing : l10n.commonShare;
    }

    final Widget screen = AppScreen(
      title: l10n.reportTabTitle,
      bottomBar: _SubmitButton(
        phase: phase,
        submitting: _submitting,
        label: submitLabel,
        // In the review phase the button points the user at the tick instead
        // of posting; sharing only happens once the images are reviewed.
        onPressed: phase == _SubmitPhase.review ? _guideToReview : _submit,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(
              // Spotlit by the app tour's "Report" step. Attached to the top
              // card so it is visible without scrolling when the tab opens.
              // Exactly one mounted widget carries this key.
              key: CoachMarkTargets.keyOf(context, TourTarget.reportCreate),
              icon: widget.numberReport
                  ? LucideIcons.phone
                  : LucideIcons.messageSquareWarning,
              title: widget.numberReport
                  ? l10n.reportTabNumberHeroTitle
                  : l10n.reportTabHeroTitle,
              body: widget.numberReport
                  ? l10n.reportTabNumberHeroBody
                  : l10n.commonShareIntro,
            ),
            const _SectionGap(),
            if (widget.numberReport)
              ..._buildNumberFields(l10n)
            else
              ..._buildPostFields(l10n),
            if (_error != null) ...[
              const _SectionGap(),
              _ErrorNote(message: _error!),
            ],
          ],
        ),
      ),
    );

    // While the post is being created, cover the screen with a blocking
    // center-of-screen loader so the user can't double-submit or navigate away.
    if (!_posting) return screen;
    return Stack(
      children: [
        screen,
        const ModalBarrier(dismissible: false, color: Colors.black54),
        _PostingOverlay(message: l10n.reportTabPosting),
      ],
    );
  }

  List<Widget> _buildNumberFields(AppLocalizations l10n) {
    final tokens = context.tokens;
    return [
      _FieldLabel(l10n.reportTabNumberLabel),
      SizedBox(height: tokens.space.md),
      TextFormField(
        controller: _numberController,
        validator: _validateNumber,
        enabled: !_submitting,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        style: _fieldTextStyle(context, emphasis: true),
        decoration: _fieldDecoration(
          context,
          l10n.reportTabNumberHint,
          prefixIcon: LucideIcons.phone,
        ),
      ),
      const _SectionGap(),
      _FieldLabel(l10n.reportTabReasonLabel),
      SizedBox(height: tokens.space.md),
      for (final _ReasonOption option in _reasonOptions(l10n)) ...[
        _ReasonTile(
          option: option,
          selected: option.value == _reason,
          onTap: _submitting
              ? null
              : () => setState(() => _reason = option.value),
        ),
        SizedBox(height: tokens.space.md),
      ],
    ];
  }

  List<Widget> _buildPostFields(AppLocalizations l10n) {
    final tokens = context.tokens;
    return [
      _FieldLabel(l10n.commonTitle),
      SizedBox(height: tokens.space.md),
      TextFormField(
        controller: _titleController,
        validator: _validateTitle,
        enabled: !_submitting,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        style: _fieldTextStyle(context, emphasis: true),
        decoration: _fieldDecoration(context, l10n.commonTitleHint),
      ),
      const _SectionGap(),
      Row(
        children: [
          Expanded(child: _FieldLabel(l10n.commonMessage)),
          TextButton.icon(
            onPressed: _submitting ? null : _pasteMessage,
            icon: const Icon(LucideIcons.clipboardPaste, size: 24),
            label: Text(
              l10n.reportTabPaste,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.symmetric(horizontal: tokens.space.md),
            ),
          ),
        ],
      ),
      SizedBox(height: tokens.space.sm),
      TextFormField(
        controller: _textController,
        validator: _validateText,
        enabled: !_submitting,
        minLines: 5,
        maxLines: 12,
        textCapitalization: TextCapitalization.sentences,
        style: _fieldTextStyle(context),
        decoration: _fieldDecoration(context, l10n.commonMessageHint),
      ),
      const _SectionGap(),
      _FieldLabel(l10n.commonPhotos),
      SizedBox(height: tokens.space.md),
      _PhotoGrid(
        images: _images,
        enabled: !_submitting,
        addLabel: l10n.commonAddPhoto,
        removeLabel: l10n.commonRemovePhoto,
        processingLabel: l10n.reportTabPhotoProcessing,
        failedLabel: l10n.reportTabPhotoFailed,
        editLabel: l10n.reportTabEditImage,
        reuploadingLabel: l10n.reportTabReuploading,
        onAdd: _addPhoto,
        onRemove: _removePhoto,
        onEdit: _editImage,
      ),
      // Review gate: once every attached image is ready, the user confirms
      // they've looked over the (PII-redacted) screenshots before the post can
      // be shared. Ticking this flips the submit button to its ready state.
      if (_hasImages) ...[
        const _SectionGap(),
        // Spotlit by the app tour's review step when photos are attached;
        // otherwise the tour falls back to the Report nav tab.
        KeyedSubtree(
          key: CoachMarkTargets.keyOf(context, TourTarget.reportReview),
          child: _ReviewCheckbox(
            key: _reviewKey,
            value: _reviewed,
            label: l10n.reportTabReviewCheckbox,
            enabled: _allImagesReady && !_anyImagePending && !_submitting,
            onChanged: (bool value) => setState(() => _reviewed = value),
          ),
        ),
      ],
    ];
  }
}

TextStyle? _fieldTextStyle(BuildContext context, {bool emphasis = false}) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyLarge?.copyWith(
    fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
    height: 1.4,
  );
}

InputDecoration _fieldDecoration(
  BuildContext context,
  String hint, {
  IconData? prefixIcon,
}) {
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  final OutlineInputBorder base = OutlineInputBorder(
    borderRadius: tokens.radii.mdRadius,
    borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
  );
  final textTheme = Theme.of(context).textTheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
    errorStyle: textTheme.bodyMedium?.copyWith(color: context.tokens.risk.danger),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 24, color: scheme.onSurfaceVariant),
    border: base,
    enabledBorder: base,
    focusedBorder: base.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 2),
    ),
    errorBorder: base.copyWith(
      borderSide: BorderSide(color: tokens.risk.danger, width: 1.5),
    ),
    focusedErrorBorder: base.copyWith(
      borderSide: BorderSide(color: tokens.risk.danger, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: tokens.space.lg,
      vertical: tokens.space.lg + tokens.space.xs,
    ),
  );
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: context.tokens.space.xl2);
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return AppCard(
      color: scheme.primary.withValues(alpha: 0.06),
      border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: scheme.primary),
          ),
          SizedBox(width: tokens.space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.space.sm),
                Text(
                  body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReasonOption {
  const _ReasonOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
  });

  final String value;
  final IconData icon;
  final String label;
  final String description;
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ReasonOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(tokens.space.lg),
        color: selected ? scheme.primary.withValues(alpha: 0.08) : null,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1.5,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.16)
                    : scheme.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option.icon,
                size: 26,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: tokens.space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.space.xs),
                  Text(
                    option.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(LucideIcons.check, size: 20, color: scheme.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.images,
    required this.enabled,
    required this.addLabel,
    required this.removeLabel,
    required this.processingLabel,
    required this.failedLabel,
    required this.editLabel,
    required this.reuploadingLabel,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
  });

  final List<_ImageUpload> images;
  final bool enabled;
  final String addLabel;
  final String removeLabel;

  /// Shown over a thumbnail while it is still uploading or being analyzed.
  final String processingLabel;

  /// Shown over a thumbnail whose upload/analysis failed after the auto-retry.
  final String failedLabel;

  /// Tooltip/label for the edit affordance on a ready thumbnail.
  final String editLabel;

  /// Shown over a thumbnail while its edited version is being re-uploaded.
  final String reuploadingLabel;
  final VoidCallback onAdd;
  final ValueChanged<_ImageUpload> onRemove;

  /// Opens the image editor for a ready thumbnail so the user can fix the
  /// redaction before posting.
  final ValueChanged<_ImageUpload> onEdit;

  static const double _tileSize = 104;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Wrap(
      spacing: tokens.space.md,
      runSpacing: tokens.space.md,
      children: [
        for (final _ImageUpload image in images)
          _PhotoThumbnail(
            // Key by the logical image identity (not list position) so widget
            // state tracks the image when one is removed from the middle.
            key: ObjectKey(image),
            image: image,
            size: _tileSize,
            removeLabel: removeLabel,
            processingLabel: processingLabel,
            failedLabel: failedLabel,
            editLabel: editLabel,
            reuploadingLabel: reuploadingLabel,
            onRemove: enabled ? () => onRemove(image) : null,
            onEdit: enabled ? () => onEdit(image) : null,
          ),
        _AddPhotoTile(
          size: _tileSize,
          label: addLabel,
          onTap: enabled ? onAdd : null,
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.size,
    required this.label,
    required this.onTap,
  });

  final double size;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: scheme.primary.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: tokens.radii.mdRadius,
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.imagePlus, size: 32, color: scheme.primary),
              SizedBox(height: tokens.space.sm),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.space.xs),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    super.key,
    required this.image,
    required this.size,
    required this.removeLabel,
    required this.processingLabel,
    required this.failedLabel,
    required this.editLabel,
    required this.reuploadingLabel,
    required this.onRemove,
    required this.onEdit,
  });

  final _ImageUpload image;
  final double size;
  final String removeLabel;
  final String processingLabel;
  final String failedLabel;
  final String editLabel;
  final String reuploadingLabel;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bool showReuploading = image.reuploading;
    // `isPending` now includes the re-uploading state so submit waits for it,
    // but the thumbnail shows a dedicated re-uploading overlay for that case,
    // so suppress the generic processing overlay while re-uploading to avoid
    // stacking two identical spinners.
    final bool showProcessing = image.isPending && !showReuploading;
    final bool showFailed = image.status == _UploadStatus.failed;
    // A ready image can be tapped to open the editor and fix the redaction,
    // but not while it's re-uploading an edit or still processing.
    final bool canEdit = onEdit != null &&
        image.status == _UploadStatus.ready &&
        !image.reuploading;
    // The tile is a fixed-size thumbnail, so cap text scaling for its small
    // status overlays to keep them inside the square.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: tokens.radii.mdRadius,
            child: Image.file(
              image.displayFile,
              key: ValueKey<String>(image.displayFile.path),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          // Tap target for editing a ready image. Sits above the image but
          // below the overlays and corner buttons.
          if (canEdit)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: tokens.radii.mdRadius,
                ),
              ),
            ),
          if (showProcessing)
            ClipRRect(
              borderRadius: tokens.radii.mdRadius,
              child: ColoredBox(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(height: tokens.space.sm),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.space.xs,
                      ),
                      child: Text(
                        processingLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showReuploading)
            ClipRRect(
              borderRadius: tokens.radii.mdRadius,
              child: ColoredBox(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(height: tokens.space.sm),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.space.xs,
                      ),
                      child: Text(
                        reuploadingLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showFailed)
            ClipRRect(
              borderRadius: tokens.radii.mdRadius,
              child: ColoredBox(
                color: tokens.risk.danger.withValues(alpha: 0.72),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.circleAlert,
                      size: 24,
                      color: Colors.white,
                    ),
                    SizedBox(height: tokens.space.sm),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.space.xs,
                      ),
                      child: Text(
                        failedLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Edit hint badge on a ready, editable image (bottom-left).
          if (canEdit)
            Positioned(
              bottom: tokens.space.xs,
              left: tokens.space.xs,
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.space.sm,
                    vertical: tokens.space.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: tokens.radii.smRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.pencil,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: tokens.space.xs),
                      Text(
                        editLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: removeLabel,
              onPressed: onRemove,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(tokens.space.lg),
        decoration: BoxDecoration(
          color: tokens.risk.dangerContainer,
          borderRadius: tokens.radii.mdRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.circleAlert, size: 26, color: tokens.risk.danger),
            SizedBox(width: tokens.space.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.risk.onDangerContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The visual/behavioural state the submit button is in.
enum _SubmitPhase {
  /// Images are attached but still uploading/analyzing. Button is greyed out
  /// and non-tappable until every image is ready.
  waiting,

  /// Every attached image is ready but the user hasn't confirmed they reviewed
  /// them yet. Button pulses slowly to invite the review.
  review,

  /// No images attached, or all images are ready and reviewed. Button is the
  /// normal primary/purple action and submits the post.
  ready,
}

/// The bottom submit button. Its appearance and behaviour depend on the state
/// of any attached screenshots:
/// - [_SubmitPhase.waiting]: greyed out, label "Wait for images to be
///   processed", shows an inline spinner, not tappable.
/// - [_SubmitPhase.review]: pulses slowly, label "Check images", tappable so
///   the user is nudged to look over the (now ready) images and tick the review
///   checkbox before posting.
/// - [_SubmitPhase.ready]: normal primary action, label "Share" (or "Sharing..."
///   while posting), submits the post.
class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.phase,
    required this.submitting,
    required this.label,
    required this.onPressed,
  });

  final _SubmitPhase phase;
  final bool submitting;
  final String label;

  /// Tapped when the button is enabled. Ignored while [_SubmitPhase.waiting] or
  /// while [submitting] (the button is disabled in those cases).
  final VoidCallback onPressed;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final Animation<double> _pulse = Tween<double>(
    begin: 1.0,
    end: 0.55,
  ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _SubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _syncPulse();
  }

  /// Runs the slow pulse only while in the review phase; stops it elsewhere so
  /// the button sits at full opacity.
  void _syncPulse() {
    if (widget.phase == _SubmitPhase.review) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bool waiting = widget.phase == _SubmitPhase.waiting;
    // Disabled while images are still processing, or while a post is in flight.
    final bool enabled = !waiting && !widget.submitting;

    final Widget icon = widget.submitting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : waiting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(
                widget.phase == _SubmitPhase.review
                    ? LucideIcons.scanEye
                    : LucideIcons.send,
                size: 24,
              );

    final Widget button = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: FilledButton.icon(
        onPressed: enabled ? widget.onPressed : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: tokens.radii.lgRadius),
        ),
        icon: icon,
        label: Text(
          widget.label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );

    if (widget.phase != _SubmitPhase.review) return button;
    // Slow pulse to draw the eye to the "Check images" prompt.
    return FadeTransition(opacity: _pulse, child: button);
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.message,
    required this.reportAnotherLabel,
    required this.onReportAnother,
    required this.doneLabel,
    required this.onDone,
    required this.openPostLabel,
    required this.onOpenPost,
  });

  final String message;
  final String reportAnotherLabel;
  final VoidCallback onReportAnother;
  final String doneLabel;
  final VoidCallback? onDone;

  /// Label for the "view your post" redirect button.
  final String openPostLabel;

  /// Opens the just-created post under "My posts". Null for number reports or
  /// when no post was created, in which case the redirect button is hidden.
  final VoidCallback? onOpenPost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(top: tokens.space.xl3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: tokens.risk.safeContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tokens.risk.safe.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.circleCheck,
                  size: 64,
                  color: tokens.risk.safe,
                ),
              ),
            ),
          ),
          SizedBox(height: tokens.space.xl2),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.reportTabSuccessTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: tokens.space.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.space.xl3),
          if (onOpenPost != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: FilledButton.icon(
                onPressed: onOpenPost,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: tokens.radii.lgRadius,
                  ),
                ),
                icon: const Icon(LucideIcons.arrowRight, size: 24),
                label: Text(
                  openPostLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: tokens.space.md),
          ],
          if (onDone != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: onOpenPost != null
                  ? OutlinedButton(
                      onPressed: onDone,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: tokens.radii.lgRadius,
                        ),
                        side: BorderSide(color: scheme.primary, width: 1.5),
                      ),
                      child: Text(
                        doneLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: onDone,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: tokens.radii.lgRadius,
                        ),
                      ),
                      child: Text(
                        doneLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: tokens.space.md),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: OutlinedButton.icon(
              onPressed: onReportAnother,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: tokens.radii.lgRadius,
                ),
                side: BorderSide(color: scheme.primary, width: 1.5),
              ),
              icon: const Icon(LucideIcons.rotateCcw, size: 24),
              label: Text(
                reportAnotherLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom-of-form review gate. Once every attached screenshot is ready the
/// user ticks this to confirm they've looked over the redacted images; only
/// then does the submit button leave its pulsing "Check images" state and
/// become the normal "Share" action. Disabled (greyed) until images are ready.
class _ReviewCheckbox extends StatelessWidget {
  const _ReviewCheckbox({
    super.key,
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    final Color textColor =
        enabled ? scheme.onSurface : scheme.onSurfaceVariant.withValues(alpha: 0.6);
    return Material(
      color: enabled
          ? scheme.primary.withValues(alpha: 0.06)
          : scheme.onSurface.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: tokens.radii.mdRadius,
        // Ready but not yet ticked: draw a thicker primary border so the
        // checkbox stands out as the next thing to do.
        side: BorderSide(
          color: enabled ? scheme.primary : scheme.outlineVariant,
          width: enabled && !value ? 2.5 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: Padding(
          padding: EdgeInsets.all(tokens.space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                onChanged:
                    enabled ? (bool? v) => onChanged(v ?? false) : null,
              ),
              SizedBox(width: tokens.space.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen centered loader shown over the report form while the post is
/// being created. Paired with a [ModalBarrier] in `build` so the user can't
/// interact with the form or double-submit while the request is in flight.
class _PostingOverlay extends StatelessWidget {
  const _PostingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Center(
      child: Container(
        padding: EdgeInsets.all(tokens.space.xl2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: tokens.radii.lgRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: tokens.space.xl2),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocking modal shown while attached screenshots finish uploading and being
/// analyzed. It is non-dismissible: the user is asked not to close the app
/// mid-processing. A short timer polls [isDone]; once every image has settled
/// (ready, or dropped after the retry-once path) the dialog pops itself so
/// `_submit` can continue creating the post. The trailing dots animate
/// (`.`/`..`/`...`) to signal ongoing work.
class _ProcessingDialog extends StatefulWidget {
  const _ProcessingDialog({required this.isDone});

  /// Returns true once no attached image is still pending.
  final bool Function() isDone;

  @override
  State<_ProcessingDialog> createState() => _ProcessingDialogState();
}

class _ProcessingDialogState extends State<_ProcessingDialog> {
  static const Duration _tick = Duration(milliseconds: 500);

  Timer? _timer;
  int _dots = 0;

  @override
  void initState() {
    super.initState();
    // Guard against the race where everything settled before the dialog even
    // mounted (e.g. uploads finished during the frame it took to show).
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    _timer = Timer.periodic(_tick, (_) => _check());
  }

  void _check() {
    if (!mounted) return;
    if (widget.isDone()) {
      _timer?.cancel();
      Navigator.of(context).pop();
      return;
    }
    setState(() => _dots = (_dots + 1) % 3);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    // 1, 2, or 3 trailing dots so the title reads as "Processing..." in motion.
    final String trailing = '.' * (_dots + 1);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: tokens.space.xl2),
            Semantics(
              liveRegion: true,
              child: Text(
                '${l10n.reportTabProcessingTitle}$trailing',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
