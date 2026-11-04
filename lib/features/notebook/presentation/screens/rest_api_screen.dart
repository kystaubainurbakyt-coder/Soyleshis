import 'package:flutter/material.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/notebook/data/remote_post.dart';
import 'package:soyle/features/notebook/data/remote_post_api.dart';
import 'package:soyle/features/notebook/data/remote_post_cache.dart';

class RestApiScreen extends StatefulWidget {
  const RestApiScreen({super.key, this.apiOverride});

  final RemotePostApi? apiOverride;

  @override
  State<RestApiScreen> createState() => _RestApiScreenState();
}

class _RestApiScreenState extends State<RestApiScreen> {
  late final RemotePostApi api;
  late final bool ownsApi;
  RemotePostCache? cache;
  List<RemotePost> posts = [];
  bool loading = true;
  bool busy = false;
  RestApiException? error;

  String get ownerId => AppState.instance.email;

  @override
  void initState() {
    super.initState();
    api = widget.apiOverride ?? RemotePostApi();
    ownsApi = widget.apiOverride == null;
    final repo = AppState.instance.repository;
    if (repo != null) {
      cache = RemotePostCache(repo.hive.box<dynamic>('soyle_v4_remote_posts'));
      posts = cache!.read(ownerId);
    }
    refresh();
  }

  @override
  void dispose() {
    if (ownsApi) api.close();
    super.dispose();
  }

  Future<void> refresh() async {
    final store = cache;
    if (store == null || ownerId.isEmpty) {
      setState(() {
        loading = false;
        error = const RestApiException(RestApiFailure.request);
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final remote = await api.getPosts(ownerId);
      final merged = await store.mergeServerSnapshot(ownerId, remote);
      if (!mounted) return;
      setState(() {
        posts = merged;
        loading = false;
      });
      _message(tr('apiLoaded'));
    } on RestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
        posts = store.read(ownerId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = const RestApiException(RestApiFailure.request);
        loading = false;
        posts = store.read(ownerId);
      });
    }
  }

  Future<void> edit([RemotePost? existing]) async {
    if (busy) return;
    final input = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => _PostEditor(existing: existing),
    );
    if (input == null || !mounted) return;
    setState(() => busy = true);
    try {
      final updated = existing == null
          ? await api.createPost(
              ownerId: ownerId,
              localId: 'local-${DateTime.now().microsecondsSinceEpoch}',
              title: input.title,
              body: input.body,
            )
          : await api.updatePost(
              existing,
              title: input.title,
              body: input.body,
            );
      await cache!.save(updated);
      if (!mounted) return;
      setState(() {
        posts = cache!.read(ownerId);
        error = null;
      });
      _message(tr(existing == null ? 'apiCreated' : 'apiUpdated'));
    } on RestApiException catch (e) {
      if (mounted) setState(() => error = e);
    } catch (_) {
      if (mounted) {
        setState(() => error = const RestApiException(RestApiFailure.request));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove(RemotePost post) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('apiDeleteTitle')),
        content: Text(post.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('noteCancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('noteDelete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await api.deletePost(post);
      await cache!.delete(post);
      if (!mounted) return;
      setState(() {
        posts = cache!.read(ownerId);
        error = null;
      });
      _message(tr('apiDeleted'));
    } on RestApiException catch (e) {
      if (mounted) setState(() => error = e);
    } catch (_) {
      if (mounted) {
        setState(() => error = const RestApiException(RestApiFailure.request));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  String _errorText(RestApiException exception) =>
      tr(switch (exception.failure) {
        RestApiFailure.offline => 'apiOffline',
        RestApiFailure.timeout => 'apiTimeout',
        RestApiFailure.server => 'apiServerError',
        RestApiFailure.invalidData => 'apiBadData',
        RestApiFailure.request => 'apiRequestError',
      });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('restApi')),
      actions: [
        IconButton(
          tooltip: tr('apiRefresh'),
          onPressed: loading || busy ? null : refresh,
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 12),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: loading || busy ? null : () => edit(),
      icon: const Icon(Icons.add),
      label: Text(tr('apiAdd')),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JSONPlaceholder · /posts?userId=1',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(tr('apiEndpoints')),
                  ],
                ),
              ),
            ),
          ),
          if (loading || busy) const LinearProgressIndicator(minHeight: 2),
          if (error != null)
            MaterialBanner(
              content: Text(_errorText(error!)),
              leading: const Icon(Icons.wifi_off_outlined),
              actions: [
                TextButton(
                  onPressed: loading ? null : refresh,
                  child: Text(tr('apiRetry')),
                ),
              ],
            ),
          Expanded(
            child: posts.isEmpty
                ? Center(
                    child: Text(
                      loading ? tr('loading') : tr('apiEmpty'),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      post.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: tr('editNote'),
                                    onPressed: busy ? null : () => edit(post),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: tr('noteDelete'),
                                    onPressed: busy ? null : () => remove(post),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              Text(post.body),
                              const SizedBox(height: 8),
                              Text(
                                'API #${post.serverId} · ${tr('apiLocalAccount')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

class _PostEditor extends StatefulWidget {
  const _PostEditor({this.existing});
  final RemotePost? existing;

  @override
  State<_PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<_PostEditor> {
  final formKey = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.existing?.title ?? '');
  late final body = TextEditingController(text: widget.existing?.body ?? '');

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr(widget.existing == null ? 'apiAdd' : 'editNote')),
    content: SizedBox(
      width: 480,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('api-post-title'),
              controller: title,
              maxLength: 100,
              decoration: InputDecoration(labelText: tr('noteTitle')),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? tr('apiRequired') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('api-post-body'),
              controller: body,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(labelText: tr('noteBody')),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? tr('apiRequired') : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr('noteCancel')),
      ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState?.validate() != true) return;
          Navigator.pop(context, (
            title: title.text.trim(),
            body: body.text.trim(),
          ));
        },
        child: Text(tr('noteSave')),
      ),
    ],
  );
}
