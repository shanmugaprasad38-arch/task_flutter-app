import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VaultApp());
}

class VaultColors {
  static const background = Color(0xFF090D16);
  static const surface = Color(0xFF131B2E);
  static const card = Color(0xFF1E293B);
  static const gold = Color(0xFFD4AF37);
  static const purple = Color(0xFF4F46E5);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
}

class VaultNote {
  String title;
  String content;
  String album;
  DateTime date;
  bool favorite;
  bool deleted;

  VaultNote({
    required this.title,
    required this.content,
    required this.album,
    required this.date,
    this.favorite = false,
    this.deleted = false,
  });
}

class VaultApp extends StatefulWidget {
  const VaultApp({super.key});

  @override
  State<VaultApp> createState() => _VaultAppState();
}

class _VaultAppState extends State<VaultApp> {
  String? pin;
  bool unlocked = false;

  void savePin(String value) {
    setState(() {
      pin = value;
      unlocked = true;
    });
  }

  void unlock() {
    setState(() => unlocked = true);
  }

  void lock() {
    setState(() => unlocked = false);
  }

  void reset() {
    setState(() {
      pin = null;
      unlocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iLockBox',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: VaultColors.background,
        colorScheme: const ColorScheme.dark(
          primary: VaultColors.gold,
          secondary: VaultColors.purple,
          surface: VaultColors.surface,
        ),
        useMaterial3: true,
      ),
      home: unlocked
          ? VaultHome(onLock: lock, onReset: reset)
          : PinScreen(savedPin: pin, onSave: savePin, onUnlock: unlock),
    );
  }
}

// ---------------- PIN SCREEN ----------------

class PinScreen extends StatefulWidget {
  final String? savedPin;
  final ValueChanged<String> onSave;
  final VoidCallback onUnlock;

  const PinScreen({
    super.key,
    required this.savedPin,
    required this.onSave,
    required this.onUnlock,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String entered = '';
  String? firstPin;
  String message = '';
  int attempts = 0;

  void addDigit(String digit) {
    if (entered.length >= 6) return;

    setState(() {
      entered += digit;
      message = '';
    });

    if (entered.length == 6) {
      Future.delayed(const Duration(milliseconds: 250), checkPin);
    }
  }

  void removeDigit() {
    if (entered.isEmpty) return;

    setState(() {
      entered = entered.substring(0, entered.length - 1);
    });
  }

  void checkPin() {
    if (!mounted) return;

    if (widget.savedPin == null) {
      if (firstPin == null) {
        setState(() {
          firstPin = entered;
          entered = '';
          message = 'Confirm your PIN';
        });
      } else if (firstPin == entered) {
        widget.onSave(entered);
      } else {
        setState(() {
          firstPin = null;
          entered = '';
          message = 'PIN does not match. Try again.';
        });
      }
    } else {
      if (entered == widget.savedPin) {
        widget.onUnlock();
      } else {
        setState(() {
          attempts++;
          entered = '';
          message = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = widget.savedPin == null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 75,
                  color: VaultColors.gold,
                ),
                const SizedBox(height: 20),
                const Text(
                  'iLockBox',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  setup ? 'Create your secure PIN' : 'Welcome back',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 12),
                Text(
                  message.isNotEmpty ? message : 'Enter 6-digit PIN',
                  style: const TextStyle(color: VaultColors.gold),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    6,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 9),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < entered.length
                            ? VaultColors.gold
                            : Colors.transparent,
                        border: Border.all(color: VaultColors.gold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                for (final row in [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['⌫', '0', 'C'],
                ])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.map((digit) {
                      return Padding(
                        padding: const EdgeInsets.all(7),
                        child: SizedBox(
                          width: 75,
                          height: 65,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VaultColors.card,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              if (digit == '⌫') {
                                removeDigit();
                              } else if (digit == 'C') {
                                setState(() => entered = '');
                              } else {
                                addDigit(digit);
                              }
                            },
                            child: Text(
                              digit,
                              style: const TextStyle(fontSize: 23),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 15),
                if (attempts > 0)
                  Text(
                    'Incorrect attempts: $attempts',
                    style: const TextStyle(color: VaultColors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- HOME DASHBOARD ----------------

class VaultHome extends StatefulWidget {
  final VoidCallback onLock;
  final VoidCallback onReset;

  const VaultHome({super.key, required this.onLock, required this.onReset});

  @override
  State<VaultHome> createState() => _VaultHomeState();
}

class _VaultHomeState extends State<VaultHome> {
  final List<VaultNote> notes = [];

  final TextEditingController searchController = TextEditingController();

  final List<String> albums = ['Personal', 'Family', 'Travel', 'Study'];

  String selectedAlbum = 'All';
  String search = '';
  int page = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<VaultNote> get filteredNotes {
    return notes.where((note) {
      if (page == 1 && (!note.favorite || note.deleted)) {
        return false;
      }

      if (page == 2 && !note.deleted) return false;
      if (page != 2 && note.deleted) return false;

      if (page == 0 && selectedAlbum != 'All' && note.album != selectedAlbum) {
        return false;
      }

      final query = search.toLowerCase();

      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.album.toLowerCase().contains(query);
    }).toList();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> openNote({VaultNote? note}) async {
    final titleController = TextEditingController(text: note?.title ?? '');

    final contentController = TextEditingController(text: note?.content ?? '');

    String album = note?.album ?? albums.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              backgroundColor: VaultColors.surface,
              title: Text(note == null ? 'New Note' : 'Edit Note'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Write your note',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: album,
                      decoration: const InputDecoration(labelText: 'Album'),
                      items: albums.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          updateDialog(() => album = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        if (note == null) {
          notes.insert(
            0,
            VaultNote(
              title: titleController.text.trim(),
              content: contentController.text.trim(),
              album: album,
              date: DateTime.now(),
            ),
          );
        } else {
          note.title = titleController.text.trim();
          note.content = contentController.text.trim();
          note.album = album;
        }
      });

      showMessage('Note saved successfully.');
    }

    titleController.dispose();
    contentController.dispose();
  }

  Future<void> addAlbum() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: VaultColors.surface,
          title: const Text('Create Album'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Album name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.isEmpty || !mounted) return;

    if (albums.any((a) => a.toLowerCase() == result.toLowerCase())) {
      showMessage('Album already exists.');
      return;
    }

    setState(() => albums.add(result));
    showMessage('Album created.');
  }

  void toggleFavorite(VaultNote note) {
    setState(() => note.favorite = !note.favorite);
  }

  void toggleTrash(VaultNote note) {
    setState(() => note.deleted = !note.deleted);
    showMessage(note.deleted ? 'Moved to Trash.' : 'Restored.');
  }

  Future<void> deleteNote(VaultNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VaultColors.surface,
        title: const Text('Delete permanently?'),
        content: const Text('This note will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: VaultColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => notes.remove(note));
    }
  }

  Widget statCard(String title, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: VaultColors.card,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: VaultColors.gold),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNoteCard(VaultNote note) {
    return Card(
      color: VaultColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: VaultColors.purple.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: VaultColors.gold),
        ),
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.content.isEmpty ? 'No content' : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                '${note.album} • ${note.date.day}/${note.date.month}/${note.date.year}',
                style: const TextStyle(color: VaultColors.gold, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') openNote(note: note);
            if (value == 'favorite') toggleFavorite(note);
            if (value == 'trash') toggleTrash(note);
            if (value == 'delete') deleteNote(note);
          },
          itemBuilder: (context) => [
            if (!note.deleted)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (!note.deleted)
              PopupMenuItem(
                value: 'favorite',
                child: Text(note.favorite ? 'Remove Favorite' : 'Add Favorite'),
              ),
            PopupMenuItem(
              value: 'trash',
              child: Text(note.deleted ? 'Restore' : 'Move to Trash'),
            ),
            if (note.deleted)
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Permanently'),
              ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
        onTap: () => openNote(note: note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = filteredNotes;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: VaultColors.surface,
        title: const Row(
          children: [
            Icon(Icons.shield, color: VaultColors.gold),
            SizedBox(width: 10),
            Text('iLockBox', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lock Vault',
            onPressed: widget.onLock,
            icon: const Icon(Icons.lock_outline),
          ),
          IconButton(
            tooltip: 'Reset PIN',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: VaultColors.surface,
                  title: const Text('Reset Vault?'),
                  content: const Text(
                    'This resets your PIN and removes all notes '
                    'from this session.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        widget.onReset();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: VaultColors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Private Space',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Keep your personal notes organised.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    statCard(
                      'Total Notes',
                      notes.where((n) => !n.deleted).length,
                      Icons.description,
                    ),
                    statCard(
                      'Favorites',
                      notes.where((n) => n.favorite && !n.deleted).length,
                      Icons.favorite,
                    ),
                    statCard(
                      'Trash',
                      notes.where((n) => n.deleted).length,
                      Icons.delete,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => search = value),
                  decoration: InputDecoration(
                    hintText: 'Search your notes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: VaultColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (page == 0)
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedAlbum == 'All',
                    onSelected: (_) {
                      setState(() => selectedAlbum = 'All');
                    },
                  ),
                  ...albums.map(
                    (album) => Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: ChoiceChip(
                        label: Text(album),
                        selected: selectedAlbum == album,
                        onSelected: (_) {
                          setState(() => selectedAlbum = album);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: ActionChip(
                      label: const Text('+ Album'),
                      onPressed: addAlbum,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page == 2
                              ? Icons.delete_outline
                              : Icons.note_alt_outlined,
                          size: 60,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page == 2 ? 'Trash is empty' : 'No notes found',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: visible.length,
                    itemBuilder: (context, index) =>
                        buildNoteCard(visible[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: page == 2
          ? null
          : FloatingActionButton.extended(
              backgroundColor: VaultColors.gold,
              foregroundColor: Colors.black,
              onPressed: () => openNote(),
              icon: const Icon(Icons.add),
              label: const Text('New Note'),
            ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: VaultColors.surface,
        selectedIndex: page,
        onDestinationSelected: (index) {
          setState(() {
            page = index;
            selectedAlbum = 'All';
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.folder), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.delete), label: 'Trash'),
        ],
      ),
    );
  }
}
