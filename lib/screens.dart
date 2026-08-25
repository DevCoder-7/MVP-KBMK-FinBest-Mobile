import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'main.dart';

double numberOf(dynamic value) => value is num ? value.toDouble() : 0;

List<Map<String, dynamic>> mapsOf(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : <Map<String, dynamic>>[];

String rupiah(dynamic value, {bool compact = false}) {
  final amount = numberOf(value);
  if (compact) {
    if (amount.abs() >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)} M';
    }
    if (amount.abs() >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)} Jt';
    }
    if (amount.abs() >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)} Rb';
    }
  }
  final digits = amount.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${amount < 0 ? '-' : ''}Rp $grouped';
}

String percent(dynamic value) => '${numberOf(value).toStringAsFixed(1)}%';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.onSignedIn});

  final ApiClient api;
  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController(text: 'demo');
  final password = TextEditingController(text: 'demo');
  bool loading = false;
  bool obscure = true;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (username.text.trim().length < 3 || password.text.length < 4) {
      setState(() => error =
          'Username minimal 3 karakter dan password minimal 4 karakter.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.api.post('/api/auth/signin', {
        'username': username.text.trim(),
        'password': password.text,
      });
      widget.onSignedIn();
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(child: FinBestLogo(size: 56)),
                        const SizedBox(height: 20),
                        Text(
                          'Selamat datang di FinBest AI',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Masuk atau buat akun baru untuk melanjutkan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedText),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: username,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: obscure,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => loading ? null : submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: obscure
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          ErrorNotice(message: error!),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: loading ? null : submit,
                          icon: loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label:
                              Text(loading ? 'Memproses...' : 'Masuk / Daftar'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Demo: username demo, password demo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api, required this.onSignedOut});

  final ApiClient api;
  final VoidCallback onSignedOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selected = 0;
  late final List<Widget> pages;

  static const titles = [
    'Dashboard',
    'Portofolio',
    'Friction Gate',
    'AI Mentor',
    'Edukasi'
  ];

  @override
  void initState() {
    super.initState();
    pages = [
      DashboardScreen(api: widget.api),
      PortfolioScreen(api: widget.api),
      FrictionScreen(api: widget.api),
      AiMentorScreen(api: widget.api),
      EducationScreen(api: widget.api),
    ];
  }

  void openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(api: widget.api, onSignedOut: widget.onSignedOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 58,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: FinBestLogo(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titles[selected],
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const Text('FinBest AI',
                style: TextStyle(fontSize: 11, color: Color(0xFFC8D0FF))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profil',
            onPressed: openProfile,
            icon: const CircleAvatar(
              radius: 17,
              backgroundColor: indigo,
              foregroundColor: Colors.white,
              child: Text('T', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() => selected = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Portofolio'),
          NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Gate'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Mentor'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Belajar'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<Map<String, dynamic>> load() async {
    final results = await Future.wait([
      widget.api.get('/api/portfolio'),
      widget.api.get('/api/dashboard/insights'),
    ]);
    return {'portfolio': results[0], 'insights': results[1]};
  }

  void refresh() => setState(() => future = load());

  @override
  Widget build(BuildContext context) {
    return AsyncPanel(
      future: future,
      onRetry: refresh,
      builder: (data) {
        final portfolio = Map<String, dynamic>.from(data['portfolio'] as Map);
        final insightData = Map<String, dynamic>.from(data['insights'] as Map);
        final summary =
            Map<String, dynamic>.from(portfolio['summary'] as Map? ?? {});
        final user = Map<String, dynamic>.from(portfolio['user'] as Map? ?? {});
        final positions = mapsOf(portfolio['positions']);
        final insights = mapsOf(insightData['insights']);
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Halo, ${user['name'] ?? 'Investor'}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text('Ringkasan portofolio dan insight terbaru.',
                  style: TextStyle(color: mutedText)),
              const SizedBox(height: 16),
              SummaryMetric(
                label: 'Net Asset Value',
                value: rupiah(summary['nav'], compact: true),
                icon: Icons.account_balance_wallet_outlined,
                tone: indigo,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SummaryMetric(
                      label: 'P&L belum terealisasi',
                      value:
                          rupiah(summary['totalUnrealizedPnl'], compact: true),
                      icon: Icons.trending_up,
                      tone: numberOf(summary['totalUnrealizedPnl']) >= 0
                          ? success
                          : danger,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryMetric(
                      label: 'Posisi aktif',
                      value: '${summary['positionCount'] ?? 0}',
                      icon: Icons.layers_outlined,
                      tone: navy,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle(
                  title: 'Posisi utama', subtitle: 'Berdasarkan nilai pasar'),
              const SizedBox(height: 10),
              ...positions.take(3).map(PositionTile.new),
              const SizedBox(height: 18),
              const SectionTitle(
                  title: 'Insight untuk Anda',
                  subtitle: 'Edukasi, bukan rekomendasi transaksi'),
              const SizedBox(height: 10),
              if (insights.isEmpty)
                const EmptyNotice(message: 'Belum ada insight baru.')
              else
                ...insights.take(3).map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading:
                            const Icon(Icons.lightbulb_outline, color: warning),
                        title: Text(item['title']?.toString() ?? 'Insight',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(item['description']?.toString() ?? ''),
                      ),
                    )),
              const NonDiscretionaryNotice(),
            ],
          ),
        );
      },
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<Map<String, dynamic>> future;
  bool showTransactions = false;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/api/portfolio');
  }

  void refresh() => setState(() => future = widget.api.get('/api/portfolio'));

  @override
  Widget build(BuildContext context) {
    return AsyncPanel(
      future: future,
      onRetry: refresh,
      builder: (data) {
        final summary =
            Map<String, dynamic>.from(data['summary'] as Map? ?? {});
        final positions = mapsOf(data['positions']);
        final transactions = mapsOf(data['transactions']);
        final allocations = mapsOf(data['allocationComparison']);
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SummaryMetric(
                label: 'Nilai portofolio',
                value: rupiah(summary['nav'], compact: true),
                icon: Icons.pie_chart_outline,
                tone: indigo,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Alokasi aset'),
                      const SizedBox(height: 14),
                      ...allocations.map((item) => AllocationBar(item: item)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      label: Text('Posisi'),
                      icon: Icon(Icons.layers_outlined)),
                  ButtonSegment(
                      value: true,
                      label: Text('Riwayat'),
                      icon: Icon(Icons.history)),
                ],
                selected: {showTransactions},
                onSelectionChanged: (value) =>
                    setState(() => showTransactions = value.first),
              ),
              const SizedBox(height: 14),
              if (!showTransactions && positions.isEmpty)
                const EmptyNotice(message: 'Belum ada posisi portofolio.')
              else if (!showTransactions)
                ...positions.map(PositionTile.new)
              else if (transactions.isEmpty)
                const EmptyNotice(message: 'Belum ada transaksi tercatat.')
              else
                ...transactions.map(TransactionTile.new),
              const NonDiscretionaryNotice(),
            ],
          ),
        );
      },
    );
  }
}

class SummaryMetric extends StatelessWidget {
  const SummaryMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tone),
            const SizedBox(height: 12),
            Text(label,
                maxLines: 2,
                style: const TextStyle(color: mutedText, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                    color: tone,
                    fontSize: compact ? 20 : 28,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PositionTile extends StatelessWidget {
  const PositionTile(this.position, {super.key});

  final Map<String, dynamic> position;

  @override
  Widget build(BuildContext context) {
    final pnl = numberOf(position['unrealizedPnlPct']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEEEDF8),
          foregroundColor: indigo,
          child: Text((position['ticker']?.toString() ?? '?').substring(0, 1)),
        ),
        title: Text(position['ticker']?.toString() ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            '${position['quantity'] ?? 0} unit · ${rupiah(position['currentPrice'])}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(rupiah(position['marketValue'], compact: true),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(1)}%',
              style: TextStyle(
                  color: pnl >= 0 ? success : danger,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile(this.transaction, {super.key});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction['side'] == 'BUY';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(isBuy ? Icons.south_east : Icons.north_east,
            color: isBuy ? success : danger),
        title: Text(
            '${transaction['ticker'] ?? '-'} · ${isBuy ? 'Beli' : 'Jual'}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${transaction['quantity'] ?? 0} unit @ ${rupiah(transaction['price'])}'),
        trailing: Text(rupiah(transaction['total'], compact: true),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class AllocationBar extends StatelessWidget {
  const AllocationBar({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final actual = numberOf(item['actual']);
    final target = numberOf(item['target']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(item['label']?.toString() ?? '-')),
              Text(
                  '${actual.toStringAsFixed(1)}% / target ${target.toStringAsFixed(0)}%',
                  style: const TextStyle(color: mutedText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (actual / 100).clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: const Color(0xFFEEEDF8),
            color: actual > target + 10 ? warning : indigo,
          ),
        ],
      ),
    );
  }
}

class FrictionScreen extends StatefulWidget {
  const FrictionScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<FrictionScreen> createState() => _FrictionScreenState();
}

class _FrictionScreenState extends State<FrictionScreen> {
  final quantity = TextEditingController();
  List<Map<String, dynamic>> assets = [];
  Map<String, dynamic>? selectedAsset;
  Map<String, dynamic>? result;
  Map<String, dynamic> stats = {};
  String side = 'BUY';
  bool loading = true;
  bool evaluating = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    quantity.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final responses = await Future.wait([
        widget.api.get('/api/assets'),
        widget.api.get('/api/traction/stats'),
      ]);
      final loadedAssets = mapsOf(responses[0]['assets']);
      if (!mounted) return;
      setState(() {
        assets = loadedAssets;
        selectedAsset = loadedAssets.isEmpty ? null : loadedAssets.first;
        stats = responses[1];
      });
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> evaluate() async {
    final parsedQuantity =
        double.tryParse(quantity.text.replaceAll('.', '').replaceAll(',', '.'));
    if (selectedAsset == null ||
        parsedQuantity == null ||
        parsedQuantity <= 0) {
      setState(() => error = 'Pilih aset dan masukkan quantity positif.');
      return;
    }
    setState(() {
      evaluating = true;
      error = null;
    });
    try {
      final response = await widget.api.post('/api/traction/check', {
        'assetId': selectedAsset!['id'],
        'side': side,
        'quantity': parsedQuantity,
      });
      if (!mounted) return;
      setState(() => result = response);
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => evaluating = false);
    }
  }

  void resetResult() {
    setState(() {
      result = null;
      quantity.clear();
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null && assets.isEmpty) {
      return Center(child: ErrorNotice(message: error!, onRetry: load));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryMetric(
                label: 'Skor rata-rata 30 hari',
                value: '${stats['avgScore30d'] ?? 0}',
                icon: Icons.monitor_heart_outlined,
                tone: indigo,
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryMetric(
                label: 'Completion rate',
                value: percent(stats['completionRate']),
                icon: Icons.task_alt,
                tone: success,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  title: 'Evaluasi niat transaksi',
                  subtitle: 'Decision journal non-diskrisioner sebelum order.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedAsset?['id']),
                  initialValue: selectedAsset?['id']?.toString(),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Aset'),
                  items: assets
                      .map((asset) => DropdownMenuItem<String>(
                            value: asset['id']?.toString(),
                            child: Text(
                              '${asset['ticker']} · ${rupiah(asset['price'])}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: result == null
                      ? (id) => setState(() => selectedAsset =
                          assets.firstWhere((asset) => asset['id'] == id))
                      : null,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'BUY',
                        label: Text('BUY'),
                        icon: Icon(Icons.add_shopping_cart)),
                    ButtonSegment(
                        value: 'SELL',
                        label: Text('SELL'),
                        icon: Icon(Icons.sell_outlined)),
                  ],
                  selected: {side},
                  onSelectionChanged: result == null
                      ? (value) => setState(() => side = value.first)
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantity,
                  enabled: result == null,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Quantity', prefixIcon: Icon(Icons.numbers)),
                ),
                if (selectedAsset != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${selectedAsset!['name']} · Volatilitas ${percent(selectedAsset!['volatility30d'])}',
                    style: const TextStyle(color: mutedText, fontSize: 12),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  ErrorNotice(message: error!),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: result == null && !evaluating ? evaluate : null,
                  icon: evaluating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(
                      evaluating ? 'Mengevaluasi...' : 'Evaluasi transaksi'),
                ),
              ],
            ),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 16),
          FrictionResult(
            api: widget.api,
            result: result!,
            onFinished: resetResult,
          ),
        ],
        const NonDiscretionaryNotice(),
      ],
    );
  }
}

class FrictionResult extends StatefulWidget {
  const FrictionResult({
    super.key,
    required this.api,
    required this.result,
    required this.onFinished,
  });

  final ApiClient api;
  final Map<String, dynamic> result;
  final VoidCallback onFinished;

  @override
  State<FrictionResult> createState() => _FrictionResultState();
}

class _FrictionResultState extends State<FrictionResult> {
  Timer? timer;
  late DateTime startedAt;
  late List<String> questions;
  late List<String?> answers;
  bool confirming = false;
  String? error;

  int get coolingMs => numberOf(widget.result['coolingOffMs']).round();
  int get skipMs => numberOf(widget.result['skipAvailableAfterMs']).round();
  int get elapsedMs => DateTime.now().difference(startedAt).inMilliseconds;
  int get remainingSeconds =>
      ((coolingMs - elapsedMs).clamp(0, coolingMs) / 1000).ceil();
  bool get fullyReady => elapsedMs >= coolingMs;
  bool get skipReady => elapsedMs >= skipMs;
  bool get answered => answers.every((answer) => answer != null);

  @override
  void initState() {
    super.initState();
    startedAt =
        DateTime.tryParse(widget.result['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final count = numberOf(widget.result['reflectionCount']).round();
    final isBuy = widget.result['side'] == 'BUY';
    final options = isBuy
        ? [
            'Apakah keputusan BUY ini didukung tesis dan data yang Anda pahami?',
            'Apakah dampak transaksi terhadap alokasi portofolio sudah ditinjau?',
            'Apakah Anda siap jika harga turun setelah pembelian?',
          ]
        : [
            'Apakah keputusan SELL ini didukung perubahan tesis atau rencana exit?',
            'Apakah dampak jual terhadap tujuan dan alokasi sudah ditinjau?',
            'Apakah Anda menjual berdasarkan rencana, bukan panik sesaat?',
          ];
    questions = options.take(count).toList();
    answers = List<String?>.filled(count, null);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      if (fullyReady) timer?.cancel();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> confirm() async {
    final early = !fullyReady;
    setState(() {
      confirming = true;
      error = null;
    });
    try {
      await widget.api.post('/api/traction/confirm', {
        'checkId': widget.result['checkId'],
        'reflections': [
          for (var index = 0; index < questions.length; index++)
            {'question': questions[index], 'answer': answers[index]},
        ],
        'override': early,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Keputusan berhasil dicatat dalam audit trail.')),
      );
      widget.onFinished();
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = numberOf(widget.result['tractionScore']).round();
    final level = widget.result['riskLevel']?.toString() ?? 'GREEN';
    final tone = switch (level) {
      'RED' => danger,
      'ORANGE' => warning,
      'YELLOW' => const Color(0xFF8A6500),
      _ => success,
    };
    final rules = mapsOf(widget.result['rulesTriggered']);
    final canConfirm = answered && (fullyReady || skipReady) && !confirming;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: tone.withValues(alpha: 0.08),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hasil evaluasi Traction',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                          '${widget.result['side']} ${widget.result['asset']?['ticker'] ?? ''} · ${rupiah(widget.result['transactionValue'], compact: true)}'),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: tone, borderRadius: BorderRadius.circular(16)),
                  child: Text('$score · $level',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (rules.isNotEmpty) ...[
                  const Text('Reason codes',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...rules.map((rule) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.warning_amber_rounded, color: tone),
                        title: Text(rule['rule']?.toString() ?? '-'),
                        subtitle: Text(rule['detail']?.toString() ?? ''),
                        trailing: Text('-${rule['penalty'] ?? 0}'),
                      )),
                  const Divider(height: 28),
                ],
                if (coolingMs > 0)
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: tone),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fullyReady
                              ? 'Jeda selesai'
                              : 'Jeda adaptif: $remainingSeconds detik',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                if (questions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Refleksi singkat',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (var index = 0; index < questions.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${index + 1}. ${questions[index]}'),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'Ya', label: Text('Ya')),
                              ButtonSegment(
                                  value: 'Tidak', label: Text('Tidak')),
                            ],
                            emptySelectionAllowed: true,
                            selected:
                                answers[index] == null ? {} : {answers[index]!},
                            onSelectionChanged: (value) =>
                                setState(() => answers[index] = value.first),
                          ),
                        ],
                      ),
                    ),
                ],
                if (error != null) ErrorNotice(message: error!),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: canConfirm ? confirm : null,
                  icon: confirming
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    fullyReady
                        ? 'Catat keputusan'
                        : skipReady
                            ? 'Lanjut dini & catat'
                            : answered
                                ? 'Tunggu $remainingSeconds detik'
                                : 'Jawab refleksi dahulu',
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

class AiMentorScreen extends StatefulWidget {
  const AiMentorScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AiMentorScreen> createState() => _AiMentorScreenState();
}

class _AiMentorScreenState extends State<AiMentorScreen> {
  final query = TextEditingController();
  final scroll = ScrollController();
  final List<Map<String, dynamic>> messages = [];
  String? sessionId;
  bool sending = false;
  String? error;

  @override
  void dispose() {
    query.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? suggestion]) async {
    final content = (suggestion ?? query.text).trim();
    if (content.isEmpty || sending) return;
    query.clear();
    setState(() {
      sending = true;
      error = null;
      messages.add({'role': 'user', 'content': content});
    });
    _scrollDown();
    try {
      final response = await widget.api.post('/api/ai-finbest/chat', {
        if (sessionId != null) 'sessionId': sessionId,
        'query': content,
      });
      if (!mounted) return;
      final assistant =
          Map<String, dynamic>.from(response['assistantMessage'] as Map? ?? {});
      setState(() {
        sessionId = response['sessionId']?.toString();
        messages.add(assistant);
      });
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) {
        setState(() => sending = false);
        _scrollDown();
      }
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 28),
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: indigo,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.auto_awesome, size: 30),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Tanyakan seputar investasi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Mentor menggunakan data portofolio, basis pengetahuan, dan data pasar dari backend FinBest.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedText),
                    ),
                    const SizedBox(height: 24),
                    SuggestionButton(
                        text: 'Analisis saham BBCA berdasarkan data terbaru',
                        onTap: send),
                    SuggestionButton(
                        text: 'Jelaskan risiko konsentrasi portofolio saya',
                        onTap: send),
                    SuggestionButton(
                        text: 'Apa itu Dollar Cost Averaging?', onTap: send),
                  ],
                )
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return ChatBubble(message: messages[index]);
                  },
                ),
        ),
        if (error != null)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ErrorNotice(message: error!)),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: border))),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: query,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                        hintText: 'Tanyakan seputar investasi...'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Kirim',
                  onPressed: sending ? null : send,
                  icon: const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SuggestionButton extends StatelessWidget {
  const SuggestionButton({super.key, required this.text, required this.onTap});

  final String text;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.chat_bubble_outline, color: indigo),
        title: Text(text),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => onTap(text),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    final confidence = numberOf(message['confidence']);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? indigo : Colors.white,
          border: isUser ? null : Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content']?.toString() ?? '',
              style:
                  TextStyle(color: isUser ? Colors.white : navy, height: 1.45),
            ),
            if (!isUser && confidence > 0) ...[
              const SizedBox(height: 10),
              const Divider(),
              Text(
                  'Confidence ${(confidence * 100).round()}% · ${message['intent'] ?? 'Analitik'}',
                  style: const TextStyle(color: mutedText, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/api/edukasi/lessons');
  }

  void refresh() =>
      setState(() => future = widget.api.get('/api/edukasi/lessons'));

  Future<void> openLesson(Map<String, dynamic> lesson) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
          builder: (_) => LessonPage(api: widget.api, lesson: lesson)),
    );
    if (changed == true) refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncPanel(
      future: future,
      onRetry: refresh,
      builder: (data) {
        final lessons = mapsOf(data['lessons']);
        final stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Jalur belajar Anda',
                          subtitle:
                              'Mastery minimal 70% untuk menyelesaikan modul.'),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value:
                            (numberOf(stats['progressPct']) / 100).clamp(0, 1),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        backgroundColor: const Color(0xFFEEEDF8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          '${stats['completed'] ?? 0} dari ${stats['total'] ?? lessons.length} selesai',
                          style: const TextStyle(color: mutedText)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...lessons.map((lesson) {
                final completed = lesson['completed'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => openLesson(lesson),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: completed
                                ? const Color(0xFFE8F7EE)
                                : const Color(0xFFEEEDF8),
                            foregroundColor: completed ? success : indigo,
                            child: Icon(completed
                                ? Icons.check
                                : Icons.school_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lesson['title']?.toString() ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(lesson['description']?.toString() ?? '',
                                    style: const TextStyle(color: mutedText)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    SmallTag(
                                        text:
                                            lesson['difficulty']?.toString() ??
                                                '-'),
                                    SmallTag(
                                        text:
                                            '${lesson['duration'] ?? 0} menit'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.api, required this.lesson});

  final ApiClient api;
  final Map<String, dynamic> lesson;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int? selectedAnswer;
  bool submitting = false;
  String? feedback;

  Future<void> complete() async {
    final quizzes = mapsOf(widget.lesson['quiz']);
    final quiz = quizzes.isEmpty ? null : quizzes.first;
    if (quiz != null && selectedAnswer == null) {
      setState(() => feedback = 'Pilih jawaban kuis terlebih dahulu.');
      return;
    }
    final correct =
        quiz == null || selectedAnswer == numberOf(quiz['correct']).round();
    final score = correct ? 100 : 0;
    setState(() {
      submitting = true;
      feedback = null;
    });
    try {
      final response = await widget.api.post('/api/edukasi/progress', {
        'lessonId': widget.lesson['id'],
        'quizScore': score,
      });
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(response['message']?.toString() ?? 'Materi selesai.')));
        Navigator.of(context).pop(true);
      } else {
        setState(() => feedback =
            '${response['message'] ?? 'Pelajari kembali materi ini.'}\n${quiz?['explanation'] ?? ''}');
      }
    } catch (exception) {
      if (mounted) setState(() => feedback = exception.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.lesson['content'] is List
        ? List<dynamic>.from(widget.lesson['content'] as List)
        : [];
    final keyPoints = widget.lesson['keyPoints'] is List
        ? List<dynamic>.from(widget.lesson['keyPoints'] as List)
        : [];
    final quizzes = mapsOf(widget.lesson['quiz']);
    final quiz = quizzes.isEmpty ? null : quizzes.first;
    final options = quiz?['options'] is List
        ? List<dynamic>.from(quiz!['options'] as List)
        : [];
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.lesson['title']?.toString() ?? 'Materi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.lesson['description']?.toString() ?? '',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: mutedText)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Poin utama',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...keyPoints.map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(Icons.check_circle_outline,
                                      size: 18, color: indigo)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(point.toString())),
                            ]),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...content.map((paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(paragraph.toString(),
                    style: const TextStyle(height: 1.55)),
              )),
          if (quiz != null) ...[
            const Divider(height: 32),
            const Text('Kuis mastery',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            Text(quiz['question']?.toString() ?? ''),
            const SizedBox(height: 8),
            RadioGroup<int>(
              groupValue: selectedAnswer,
              onChanged: (value) => setState(() => selectedAnswer = value),
              child: Column(
                children: [
                  for (var index = 0; index < options.length; index++)
                    RadioListTile<int>(
                      value: index,
                      title: Text(options[index].toString()),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
          if (feedback != null) ErrorNotice(message: feedback!),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: submitting ? null : complete,
            icon: submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.task_alt),
            label: Text(submitting ? 'Menyimpan...' : 'Selesaikan materi'),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen(
      {super.key, required this.api, required this.onSignedOut});

  final ApiClient api;
  final VoidCallback onSignedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/api/profile');
  }

  Future<void> signOut() async {
    try {
      await widget.api.post('/api/auth/signout');
    } catch (_) {
      // Local sign-out must still succeed when the network is unavailable.
    } finally {
      widget.api.clearSession();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onSignedOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: AsyncPanel(
        future: future,
        onRetry: () => setState(() => future = widget.api.get('/api/profile')),
        builder: (data) {
          final user = Map<String, dynamic>.from(data['user'] as Map? ?? {});
          final target =
              Map<String, dynamic>.from(data['targetAllocation'] as Map? ?? {});
          final goals = mapsOf(data['goals']);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const CircleAvatar(
                          radius: 30,
                          backgroundColor: indigo,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.person, size: 30)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['name']?.toString() ?? 'Investor',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 20)),
                            Text(user['email']?.toString() ?? '',
                                style: const TextStyle(color: mutedText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: SummaryMetric(
                          label: 'Skor risiko',
                          value: '${user['riskScore'] ?? 0}',
                          icon: Icons.speed,
                          tone: indigo,
                          compact: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: SummaryMetric(
                          label: 'Profil',
                          value: user['riskProfile']?.toString() ?? '-',
                          icon: Icons.shield_outlined,
                          tone: navy,
                          compact: true)),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Target alokasi'),
                      const SizedBox(height: 12),
                      ProfileRow(
                          label: 'Saham', value: percent(target['saham'])),
                      ProfileRow(
                          label: 'Obligasi',
                          value: percent(target['obligasi'])),
                      ProfileRow(
                          label: 'Reksa dana',
                          value: percent(target['reksadana'])),
                      ProfileRow(label: 'Kas', value: percent(target['kas'])),
                      ProfileRow(label: 'Emas', value: percent(target['emas'])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const SectionTitle(title: 'Tujuan investasi'),
              const SizedBox(height: 10),
              if (goals.isEmpty)
                const EmptyNotice(message: 'Belum ada tujuan investasi.')
              else
                ...goals.map((goal) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal['title']?.toString() ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                                value: (numberOf(goal['progress']) / 100)
                                    .clamp(0, 1),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4)),
                            const SizedBox(height: 6),
                            Text(
                                '${rupiah(goal['currentAmount'], compact: true)} dari ${rupiah(goal['targetAmount'], compact: true)}',
                                style: const TextStyle(color: mutedText)),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: danger,
                    minimumSize: const Size.fromHeight(48)),
                onPressed: signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
              ),
              const NonDiscretionaryNotice(),
            ],
          );
        },
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  const ProfileRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: mutedText))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
      ]),
    );
  }
}

class AsyncPanel extends StatelessWidget {
  const AsyncPanel(
      {super.key,
      required this.future,
      required this.builder,
      required this.onRetry});

  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic>) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorNotice(
                      message: snapshot.error.toString(), onRetry: onRetry)));
        }
        return builder(snapshot.data ?? {});
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!,
              style: const TextStyle(color: mutedText, fontSize: 13)),
        ],
      ],
    );
  }
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: danger))),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class EmptyNotice extends StatelessWidget {
  const EmptyNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(Icons.inbox_outlined, color: mutedText),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedText))
        ]),
      ),
    );
  }
}

class SmallTag extends StatelessWidget {
  const SmallTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFEEEDF8),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: const TextStyle(
              color: indigo, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class NonDiscretionaryNotice extends StatelessWidget {
  const NonDiscretionaryNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: mutedText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'FinBest bersifat edukatif dan non-diskrisioner. Keputusan dan eksekusi investasi tetap di tangan Anda.',
              style: TextStyle(color: mutedText, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
