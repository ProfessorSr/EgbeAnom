part of '../main.dart';

class InfoView extends StatelessWidget {
  const InfoView({
    super.key,
    required this.page,
    required this.notes,
    required this.ingredients,
    required this.brand,
    required this.customer,
    required this.orders,
    required this.recommendations,
    required this.onBack,
    required this.onOpenProduct,
    required this.onOpenAccount,
    required this.onSendContactMessage,
  });

  final StoreInfoPage page;
  final List<FragranceNoteGuide> notes;
  final List<IngredientGuide> ingredients;
  final BrandProfile brand;
  final CustomerAccount? customer;
  final List<Order> orders;
  final List<Fragrance> recommendations;
  final VoidCallback onBack;
  final ValueChanged<Fragrance> onOpenProduct;
  final VoidCallback onOpenAccount;
  final void Function(String name, String email, String subject, String message)
  onSendContactMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _StorefrontPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to shop'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _content(context),
          ],
        ),
      ),
    );
  }

  String get _title {
    return switch (page) {
      StoreInfoPage.notes => 'Note Encyclopedia',
      StoreInfoPage.ingredients => 'Ingredient Profiles',
      StoreInfoPage.brandProfile => 'EgbeAnom profile',
      StoreInfoPage.recommendations => 'Recommendations',
      StoreInfoPage.ratings => 'Ratings',
      StoreInfoPage.wishlist => 'Wishlists',
      StoreInfoPage.collections => 'Collections',
      StoreInfoPage.contact => 'Contact Us',
    };
  }

  Widget _content(BuildContext context) {
    return switch (page) {
      StoreInfoPage.notes => _NoteGuideGrid(notes: notes),
      StoreInfoPage.ingredients => _IngredientGuideGrid(
        ingredients: ingredients,
      ),
      StoreInfoPage.brandProfile => _BrandProfilePage(brand: brand),
      StoreInfoPage.recommendations => _RecommendationPanel(
        customer: customer,
        orders: orders,
        recommendations: recommendations,
        onOpenProduct: onOpenProduct,
        onOpenAccount: onOpenAccount,
      ),
      StoreInfoPage.ratings => const _CommunityInfoCard(
        icon: Icons.star_outline,
        title: 'Ratings',
        body:
            'Ratings help tune future recommendations and give shoppers confidence. Product and company reviews now route through admin approval before they appear publicly.',
      ),
      StoreInfoPage.wishlist => const _CommunityInfoCard(
        icon: Icons.favorite_border,
        title: 'Wishlists',
        body:
            'Wishlists are ready for customer account storage. The next step is saving chosen products to each customer profile so they can return to favorites later.',
      ),
      StoreInfoPage.collections => const _CommunityInfoCard(
        icon: Icons.collections_bookmark_outlined,
        title: 'Collections',
        body:
            'Collections let customers track fragrances they own, gift ideas, and scents they want to compare. This area is prepared for account-linked collection items.',
      ),
      StoreInfoPage.contact => _ContactUsPage(
        customer: customer,
        onSend: onSendContactMessage,
      ),
    };
  }
}

class _NoteGuideGrid extends StatelessWidget {
  const _NoteGuideGrid({required this.notes});

  final List<FragranceNoteGuide> notes;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<FragranceNoteGuide>>{};
    for (final note in notes) {
      final key = note.family.trim().isEmpty ? note.tier : note.family;
      grouped
          .putIfAbsent(key.trim().isEmpty ? 'General' : key, () => [])
          .add(note);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries)
          _GuideExpansionSection(
            title: entry.key,
            child: _InfoGrid(
              children: [
                for (final note in entry.value)
                  _GuideCard(
                    icon: Icons.local_florist_outlined,
                    title: note.name,
                    subtitle: '${note.tier} • ${note.family}',
                    body: note.description,
                    footer: note.pairings.trim().isEmpty
                        ? 'Explore pairings in the catalog'
                        : 'Pairs with: ${note.pairings}',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IngredientGuideGrid extends StatelessWidget {
  const _IngredientGuideGrid({required this.ingredients});

  final List<IngredientGuide> ingredients;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<IngredientGuide>>{};
    for (final ingredient in ingredients) {
      final key = ingredient.role.trim().isEmpty
          ? 'Ingredient'
          : ingredient.role;
      grouped.putIfAbsent(key, () => []).add(ingredient);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries)
          _GuideExpansionSection(
            title: entry.key,
            child: _InfoGrid(
              children: [
                for (final ingredient in entry.value)
                  _GuideCard(
                    icon: Icons.science_outlined,
                    title: ingredient.name,
                    subtitle: ingredient.role,
                    body: ingredient.profile,
                    footer: ingredient.safety,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GuideExpansionSection extends StatelessWidget {
  const _GuideExpansionSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.42),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [child],
        ),
      ),
    );
  }
}

class _BrandProfilePage extends StatelessWidget {
  const _BrandProfilePage({required this.brand});

  final BrandProfile brand;

  @override
  Widget build(BuildContext context) {
    final history = brand.history.trim().isEmpty
        ? 'EgbeAnom is built as a single-house fragrance experience. Every perfume, cologne, oil, and recommendation belongs to one catalog and one point of view.'
        : brand.history;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    brand.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              brand.description.isEmpty
                  ? 'Perfume, cologne, and body oil designed around the EgbeAnom house identity.'
                  : brand.description,
            ),
            const SizedBox(height: 14),
            Text('House Story', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(history),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ProfilePill(label: 'Origin', value: brand.country),
                _ProfilePill(
                  label: 'Founded',
                  value: brand.foundedYear?.toString() ?? 'Developing',
                ),
                const _ProfilePill(label: 'Catalog', value: 'EgbeAnom only'),
                const _ProfilePill(label: 'Focus', value: 'Fragrance rituals'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.customer,
    required this.orders,
    required this.recommendations,
    required this.onOpenProduct,
    required this.onOpenAccount,
  });

  final CustomerAccount? customer;
  final List<Order> orders;
  final List<Fragrance> recommendations;
  final ValueChanged<Fragrance> onOpenProduct;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    if (customer == null || orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommendations unlock after an order',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Once you place an order, this page compares your fragrance families, notes, and occasions to suggest what to try next.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onOpenAccount,
                icon: const Icon(Icons.person_outline),
                label: const Text('Go to account'),
              ),
            ],
          ),
        ),
      );
    }
    if (recommendations.isEmpty) {
      return const _EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No recommendations yet',
        body: 'Add more catalog items or order history to generate matches.',
      );
    }
    return _InfoGrid(
      children: [
        for (final product in recommendations)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onOpenProduct(product),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: product.featuredColor.withValues(alpha: 0.18),
                      child: ProductPhoto(product: product, iconSize: 52),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('${product.family} • ${product.occasion}'),
                        const SizedBox(height: 8),
                        Text(currency(product.price)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CommunityInfoCard extends StatelessWidget {
  const _CommunityInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFC88F52)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactUsPage extends StatefulWidget {
  const _ContactUsPage({required this.customer, required this.onSend});

  final CustomerAccount? customer;
  final void Function(String name, String email, String subject, String message)
  onSend;

  @override
  State<_ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<_ContactUsPage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _status = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer?.name ?? '');
    _email = TextEditingController(text: widget.customer?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: Color(0xFFC88F52)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Send a message to the store',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _subject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.subject),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Message',
                prefixIcon: Icon(Icons.message_outlined),
              ),
              minLines: 4,
              maxLines: 6,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Send message'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
      setState(() => _status = 'Please fill in every field.');
      return;
    }
    widget.onSend(name, email, subject, message);
    _subject.clear();
    _message.clear();
    setState(() => _status = 'Message sent to the store.');
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 920
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth > 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFC88F52), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body),
            const SizedBox(height: 6),
            Text(footer, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
