import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/database_helper.dart';
import '../services/supabase_service.dart';
import '../widgets/chat_bubble.dart';
import 'search_screen.dart';

/// Layar Asisten AI (Chat Rekomendasi Komik)
/// Sesuai SRS 2.6.3, FR-AI, TC-11 & TC-12
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true;
  bool _isTyping = false;
  String? _lastFailedMessage;
  String? _errorMessage;

  // Daftar saran pertanyaan cepat (quick prompt chips)
  final List<String> _quickPrompts = [
    'Rekomendasi komik aksi seru',
    'Komik mirip yang terakhir kubaca',
    'Rekomendasi komik komedi lucu',
    'Manhwa bertema dungeon dan leveling',
    'Manga romantis rating tinggi',
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Mengambil riwayat percakapan dari database lokal SQLite (FR-AI-09)
  Future<void> _loadChatHistory() async {
    final userId = SupabaseService.instance.currentUser?.id ?? '';
    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
      return;
    }

    try {
      final history = await DatabaseHelper.instance.getRecentChatMessages(userId, limit: 50);
      if (!mounted) return;
      setState(() {
        _messages = history;
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  /// Menggulir ListView chat ke pesan paling bawah
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Mengirim pesan ke asisten AI (FR-AI-01, FR-AI-02, FR-AI-07)
  Future<void> _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isTyping) return;

    final userId = SupabaseService.instance.currentUser?.id ?? '';
    final userMessage = ChatMessage(
      userId: userId,
      role: 'user',
      content: trimmedText,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _errorMessage = null;
      _lastFailedMessage = null;
    });

    _textController.clear();
    _scrollToBottom();

    // Simpan pesan pengguna ke SQLite
    if (userId.isNotEmpty) {
      await DatabaseHelper.instance.addChatMessage(userMessage);
    }

    try {
      final reply = await AiService.instance.chat(trimmedText);

      final assistantMessage = ChatMessage(
        userId: userId,
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Simpan balasan asisten ke SQLite
      if (userId.isNotEmpty) {
        await DatabaseHelper.instance.addChatMessage(assistantMessage);
      }

      if (!mounted) return;
      setState(() {
        _messages.add(assistantMessage);
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isTyping = false;
        _errorMessage = errorText;
        _lastFailedMessage = trimmedText;
      });
      _scrollToBottom();
    }
  }

  /// Menghapus seluruh riwayat percakapan pengguna (FR-AI-09)
  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Percakapan?'),
        content: const Text('Seluruh riwayat chat dengan asisten AI akan dihapus dari perangkat ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userId = SupabaseService.instance.currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        await DatabaseHelper.instance.clearChatMessages(userId);
      }
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _errorMessage = null;
        _lastFailedMessage = null;
      });
    }
  }

  /// Membuka halaman pencarian MangaDex dengan judul yang diketuk (FR-AI-06)
  void _openComicSearch(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialQuery: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.deepOrange, size: 22),
            SizedBox(width: 8),
            Text('Asisten KomikKu'),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus riwayat chat',
              onPressed: _clearConversation,
            ),
        ],
      ),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Area List Pesan Chat
                Expanded(
                  child: _messages.isEmpty && !_isTyping && _errorMessage == null
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          itemCount: _messages.length + (_isTyping ? 1 : 0) + (_errorMessage != null ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _messages.length) {
                              return ChatBubble(
                                message: _messages[index],
                                onComicTap: _openComicSearch,
                              );
                            }

                            // Tampilkan typing indicator jika asisten sedang berpikir (FR-AI-07)
                            if (_isTyping && index == _messages.length) {
                              return _buildTypingIndicator();
                            }

                            // Tampilkan pesan error dan tombol ulangi jika gagal (FR-AI-07, TC-12)
                            return _buildErrorCard();
                          },
                        ),
                ),

                // Baris Saran Pertanyaan Cepat (Chips)
                if (!_isTyping) _buildQuickPromptsBar(),

                // Input Bar (TextField + Tombol Kirim)
                _buildInputBar(),
              ],
            ),
    );
  }

  /// Tampilan awal kosong dengan informasi asisten dan contoh pertanyaan
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.auto_awesome,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Halo! Aku Asisten KomikKu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aku dapat membantu merekomendasikan komik, manga, atau manhwa sesuai seleramu.\nSilakan pilih topik di bawah atau ketik pertanyaanmu.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((prompt) {
                return ActionChip(
                  avatar: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(prompt),
                  onPressed: () => _sendMessage(prompt),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Indikator sedang mengetik (FR-AI-07)
  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Asisten sedang mengetik...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu error dengan tombol coba lagi (FR-AI-07 & TC-12)
  Widget _buildErrorCard() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage ?? 'Terjadi kesalahan saat memproses permintaan AI.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_lastFailedMessage != null) ...[
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  final msg = _lastFailedMessage!;
                  setState(() {
                    _errorMessage = null;
                    _lastFailedMessage = null;
                  });
                  _sendMessage(msg);
                },
                child: const Text('Ulangi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Baris chip pertanyaan cepat horizontal
  Widget _buildQuickPromptsBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  /// Input bar di bagian bawah layar
  Widget _buildInputBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Tanyakan rekomendasi komik...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isTyping ? null : () => _sendMessage(_textController.text),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
