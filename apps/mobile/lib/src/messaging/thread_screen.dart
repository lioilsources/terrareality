import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_api/api.dart';

import '../../l10n/gen/app_localizations.dart';
import 'messaging_repository.dart';

const _contactFlags = [MessageFlag.contactPhone, MessageFlag.contactEmail, MessageFlag.contactBankAccount];

/// One conversation with realtime updates and read receipts.
class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ConversationDetail? _detail;
  List<Message> _messages = [];
  DateTime? _peerReadAt;
  StreamSubscription<RealtimeEvent>? _events;
  bool _sending = false;

  MessagingRepository get _repo => ref.read(messagingRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
    _events = _repo.events(widget.id).listen(_onEvent, onError: (_) {});
  }

  @override
  void dispose() {
    _events?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await _repo.detail(widget.id);
    final messages = await _repo.messages(widget.id);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _messages = messages;
      _peerReadAt = detail.peerReadAt;
    });
    unawaited(_repo.markRead(widget.id));
    _scrollDown();
  }

  bool _mine(Message m) {
    final c = _detail?.conversation;
    if (c == null || m.senderId == null) return false;
    return c.role == ConversationRole.seeker ? m.senderId == c.seekerId : m.senderId != c.seekerId;
  }

  void _add(Message m) {
    if (_messages.any((x) => x.id == m.id)) return;
    setState(() => _messages = [..._messages, m]);
    _scrollDown();
    if (!_mine(m)) unawaited(_repo.markRead(widget.id));
  }

  void _onEvent(RealtimeEvent e) {
    switch (e.type) {
      case 'message':
        if (e.message != null) _add(e.message!);
      case 'read':
        if (e.at != null && _detail != null && !_isMe(e.userId)) setState(() => _peerReadAt = e.at);
      default:
        _load();
    }
  }

  // Read events from the caller's own side (other devices or colleagues) do
  // not count as a receipt: the seeker id tells the sides apart.
  bool _isMe(String? userId) {
    final c = _detail!.conversation;
    final fromSeeker = userId == c.seekerId;
    return (c.role == ConversationRole.seeker) == fromSeeker;
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      _add(await _repo.send(widget.id, text));
      _input.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _report() async {
    final t = AppLocalizations.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in [('scam', t.reportScam), ('harassment', t.reportHarassment), ('other', t.reportOther)])
              ListTile(title: Text(r.$2), onTap: () => Navigator.pop(c, r.$1)),
          ],
        ),
      ),
    );
    if (reason == null) return;
    await _repo.report(widget.id, reason, '');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.reportSent)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = _detail?.conversation;
    final ownIds = _messages.where(_mine).map((m) => m.id).toList();
    final lastRead =
        ownIds.isNotEmpty && _peerReadAt != null && !_messages.lastWhere(_mine).createdAt.isAfter(_peerReadAt!)
        ? ownIds.last
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(c == null ? '' : (c.role == ConversationRole.seeker ? c.orgName : c.seekerName)),
        actions: [IconButton(icon: const Icon(Icons.flag_outlined), tooltip: t.report, onPressed: _report)],
      ),
      body: Column(
        children: [
          MaterialBanner(content: Text(t.safetyNote), actions: const [SizedBox.shrink()]),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) =>
                  _Bubble(message: _messages[i], mine: _mine(_messages[i]), read: _messages[i].id == lastRead),
            ),
          ),
          if (c?.blocked ?? false)
            Padding(padding: const EdgeInsets.all(16), child: Text(t.blocked))
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 4000,
                        decoration: InputDecoration(hintText: t.messageHint, counterText: ''),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      tooltip: t.messageSend,
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, required this.read});

  final Message message;
  final bool mine;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final advance = !message.removed && message.flags.contains(MessageFlag.advancePayment);
    final contact = mine && message.flags.any(_contactFlags.contains);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: mine ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.removed ? t.messageRemoved : message.body,
                style: TextStyle(color: mine ? scheme.onPrimary : scheme.onSurface),
              ),
            ),
            if (advance)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(t.flagAdvance, style: TextStyle(color: scheme.error, fontSize: 12)),
              ),
            if (contact)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(t.flagContact, style: TextStyle(color: scheme.tertiary, fontSize: 12)),
              ),
            if (read) Text(t.messageRead, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
