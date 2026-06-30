part of '../main.dart';

class ShopView extends StatelessWidget {
  const ShopView({
    super.key,
    required this.products,
    required this.shelfTitle,
    required this.categories,
    required this.contentBlocks,
    required this.query,
    required this.onSearch,
    required this.onOpenCatalog,
    required this.onOpenCategory,
    required this.onViewDetails,
    required this.onOpenInfoPage,
    required this.newsItems,
    required this.companyReviews,
    required this.siteStatus,
  });

  final List<Fragrance> products;
  final String shelfTitle;
  final List<Category> categories;
  final List<ContentBlock> contentBlocks;
  final String query;
  final ValueChanged<String> onSearch;
  final VoidCallback onOpenCatalog;
  final ValueChanged<Category> onOpenCategory;
  final ValueChanged<Fragrance> onViewDetails;
  final ValueChanged<StoreInfoPage> onOpenInfoPage;
  final List<NewsItem> newsItems;
  final List<ReviewSummary> companyReviews;
  final SiteStatus siteStatus;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
              child: _HomeBanner(onOpenCatalog: onOpenCatalog),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: _FragranceFinder(
                products: products,
                onViewDetails: onViewDetails,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _HomeSearchBar(
                query: query,
                categories: categories,
                onSearch: onSearch,
                onOpenCategory: onOpenCategory,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: _MarketplaceDepth(
                products: products,
                onOpenInfoPage: onOpenInfoPage,
                siteStatus: siteStatus,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shelfTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 1020
                          ? 4
                          : constraints.maxWidth > 720
                          ? 3
                          : constraints.maxWidth > 480
                          ? 2
                          : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: columns == 1 ? 1.2 : 0.72,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) => ProductCard(
                          product: products[index],
                          onViewDetails: () => onViewDetails(products[index]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              child: Column(
                children: [
                  if (siteStatus.showLatestFragranceNews)
                    _LatestNewsPanel(items: newsItems),
                  if (siteStatus.showLatestFragranceNews &&
                      (siteStatus.showCommunity ||
                          siteStatus.showCompanyReviews))
                    const SizedBox(height: 18),
                  if (siteStatus.showCommunity || siteStatus.showCompanyReviews)
                    _SocialCardsPanel(
                      reviews: companyReviews,
                      showCommunity: siteStatus.showCommunity,
                      showCompanyReviews: siteStatus.showCompanyReviews,
                      onOpenInfoPage: onOpenInfoPage,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBanner extends StatelessWidget {
  const _HomeBanner({required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1933 / 814,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: const DecorationImage(
            image: AssetImage('assets/images/banner.png'),
            fit: BoxFit.cover,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: FractionallySizedBox(
              alignment: Alignment.bottomLeft,
              widthFactor: 0.52,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: OutlinedButton(
                  onPressed: onOpenCatalog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFC88F52),
                      width: 1.2,
                    ),
                    backgroundColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Explore Collection -->'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2DCD2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFC88F52)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatefulWidget {
  const _HomeSearchBar({
    required this.query,
    required this.categories,
    required this.onSearch,
    required this.onOpenCategory,
  });

  final String query;
  final List<Category> categories;
  final ValueChanged<String> onSearch;
  final ValueChanged<Category> onOpenCategory;

  @override
  State<_HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<_HomeSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _HomeSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText:
                    'Search by fragrance, note, vibe, season, or occasion',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search catalog',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => widget.onSearch(_controller.text),
                ),
              ),
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in widget.categories)
                    _FilterChip(
                      label: category.name,
                      selected: false,
                      onTap: () => widget.onOpenCategory(category),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CatalogView extends StatelessWidget {
  const CatalogView({
    super.key,
    required this.products,
    required this.categories,
    required this.filter,
    required this.query,
    required this.sort,
    required this.onFilterChanged,
    required this.onQueryChanged,
    required this.onSortChanged,
    required this.onBack,
    required this.onViewDetails,
  });

  final List<Fragrance> products;
  final List<Category> categories;
  final String filter;
  final String query;
  final String sort;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onBack;
  final ValueChanged<Fragrance> onViewDetails;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to home'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All fragrances',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  _DiscoveryBar(
                    categories: categories,
                    filter: filter,
                    query: query,
                    sort: sort,
                    onFilterChanged: onFilterChanged,
                    onQueryChanged: onQueryChanged,
                    onSortChanged: onSortChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ConstrainedPage(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1020
                      ? 4
                      : constraints.maxWidth > 720
                      ? 3
                      : constraints.maxWidth > 480
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 1.2 : 0.72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) => ProductCard(
                      product: products[index],
                      onViewDetails: () => onViewDetails(products[index]),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoveryBar extends StatelessWidget {
  const _DiscoveryBar({
    required this.categories,
    required this.filter,
    required this.query,
    required this.sort,
    required this.onFilterChanged,
    required this.onQueryChanged,
    required this.onSortChanged,
  });

  final List<Category> categories;
  final String filter;
  final String query;
  final String sort;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                return Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(
                      flex: wide ? 7 : 0,
                      child: TextField(
                        controller: TextEditingController(text: query)
                          ..selection = TextSelection.collapsed(
                            offset: query.length,
                          ),
                        decoration: const InputDecoration(
                          labelText:
                              'Search by fragrance, note, vibe, season, or occasion',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: onQueryChanged,
                      ),
                    ),
                    if (wide)
                      const SizedBox(width: 12)
                    else
                      const SizedBox(height: 12),
                    Expanded(
                      flex: wide ? 3 : 0,
                      child: DropdownButtonFormField<String>(
                        initialValue: sort,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          prefixIcon: Icon(Icons.sort),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Featured',
                            child: Text('Featured'),
                          ),
                          DropdownMenuItem(
                            value: 'Best sellers',
                            child: Text('Best sellers'),
                          ),
                          DropdownMenuItem(
                            value: 'Price low',
                            child: Text('Price low'),
                          ),
                          DropdownMenuItem(
                            value: 'Price high',
                            child: Text('Price high'),
                          ),
                        ],
                        onChanged: (value) => onSortChanged(value ?? sort),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == 'All',
                  onTap: () => onFilterChanged('All'),
                ),
                for (final category in categories)
                  _FilterChip(
                    label: category.name,
                    selected: filter == category.name,
                    onTap: () => onFilterChanged(category.name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FragranceFinder extends StatefulWidget {
  const _FragranceFinder({required this.products, required this.onViewDetails});

  final List<Fragrance> products;
  final ValueChanged<Fragrance> onViewDetails;

  @override
  State<_FragranceFinder> createState() => _FragranceFinderState();
}

class _FragranceFinderState extends State<_FragranceFinder> {
  String _mood = 'Fresh';
  String _wear = 'Office';
  String _season = 'Warm weather';
  String _scene = 'Everyday confidence';
  String _intensity = 'Noticeable';

  @override
  Widget build(BuildContext context) {
    final match = _findMatch();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 820;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 5 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your perfect fragrance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Answer a few shopping cues and get a quick recommendation from the current catalog.',
                      ),
                      const SizedBox(height: 14),
                      _FinderChoices(
                        label: 'Mood',
                        value: _mood,
                        options: const [
                          'Fresh',
                          'Warm',
                          'Bold',
                          'Soft',
                          'Sweet',
                          'Woody',
                        ],
                        onChanged: (value) => setState(() => _mood = value),
                      ),
                      _FinderChoices(
                        label: 'Occasion',
                        value: _wear,
                        options: const [
                          'Office',
                          'Date night',
                          'Gift',
                          'Daily',
                          'Formal',
                          'Vacation',
                        ],
                        onChanged: (value) => setState(() => _wear = value),
                      ),
                      _FinderChoices(
                        label: 'Season',
                        value: _season,
                        options: const [
                          'Warm weather',
                          'Cool weather',
                          'Year-round',
                          'Evening',
                          'Spring',
                          'Summer',
                        ],
                        onChanged: (value) => setState(() => _season = value),
                      ),
                      _FinderChoices(
                        label: 'Scene',
                        value: _scene,
                        options: const [
                          'Everyday confidence',
                          'Close encounter',
                          'Room entrance',
                          'Outdoor heat',
                          'After dark',
                        ],
                        onChanged: (value) => setState(() => _scene = value),
                      ),
                      _FinderChoices(
                        label: 'Strength',
                        value: _intensity,
                        options: const [
                          'Soft trail',
                          'Noticeable',
                          'Statement',
                        ],
                        onChanged: (value) =>
                            setState(() => _intensity = value),
                      ),
                    ],
                  ),
                ),
                if (wide)
                  const SizedBox(width: 18)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: match == null
                      ? const _EmptyState(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Catalog loading',
                          body: 'Recommendations appear once products load.',
                        )
                      : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F4EE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2DCD2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox.square(
                                    dimension: 72,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ProductPhoto(product: match),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          match.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        Text(
                                          '${match.family} • ${match.concentration}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(_matchSummary(match), maxLines: 3),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => widget.onViewDetails(match),
                                icon: const Icon(Icons.auto_awesome_outlined),
                                label: const Text('View match'),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Fragrance? _findMatch() {
    if (widget.products.isEmpty) {
      return null;
    }
    final scored = [...widget.products]
      ..sort((a, b) {
        int score(Fragrance product) {
          final haystack =
              '${product.name} ${product.type} ${product.brand} ${product.description} ${product.vibe} ${product.performance} ${product.comparison} ${product.fragranceProfile} ${product.ingredients} ${product.notes} ${product.topNotes} ${product.heartNotes} ${product.baseNotes} ${product.occasion} ${product.season} ${product.family} ${product.concentration} ${product.gender}'
                  .toLowerCase();
          var value = 0;
          for (final term in _moodTerms[_mood] ?? const <String>[]) {
            if (haystack.contains(term)) {
              value += 10;
            }
          }
          for (final term in _wearTerms[_wear] ?? const <String>[]) {
            if (haystack.contains(term)) {
              value += 8;
            }
          }
          for (final term in _seasonTerms[_season] ?? const <String>[]) {
            if (haystack.contains(term)) {
              value += 8;
            }
          }
          for (final term in _sceneTerms[_scene] ?? const <String>[]) {
            if (haystack.contains(term)) {
              value += 7;
            }
          }
          for (final term in _intensityTerms[_intensity] ?? const <String>[]) {
            if (haystack.contains(term)) {
              value += 6;
            }
          }
          value += (product.rating * 2).round();
          value += product.sold ~/ 20;
          return value;
        }

        return score(b).compareTo(score(a));
      });
    return scored.first;
  }

  String _matchSummary(Fragrance product) {
    for (final value in [
      product.description,
      product.vibe,
      product.fragranceProfile,
      product.performance,
      product.comparison,
      product.notes,
    ]) {
      final clean = value.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return 'Open the fragrance details to review notes, seasons, occasions, and performance.';
  }

  static const _moodTerms = {
    'Fresh': ['citrus', 'mandarin', 'neroli', 'marine', 'tea', 'linen', 'mint'],
    'Warm': ['amber', 'vanilla', 'tonka', 'sandalwood', 'cocoa', 'tobacco'],
    'Bold': ['oud', 'leather', 'pepper', 'smoke', 'patchouli', 'saffron'],
    'Soft': ['musk', 'iris', 'cotton', 'rose', 'powder', 'shea', 'white'],
    'Sweet': ['vanilla', 'fruit', 'pear', 'peach', 'cocoa', 'orange blossom'],
    'Woody': ['cedar', 'birch', 'sandalwood', 'vetiver', 'oakmoss', 'ambroxan'],
  };

  static const _wearTerms = {
    'Office': ['clean', 'musk', 'tea', 'vetiver', 'cedar', 'linen', 'daily'],
    'Date night': ['jasmine', 'amber', 'vanilla', 'orchid', 'rose', 'leather'],
    'Gift': ['vanilla', 'rose', 'citrus', 'musk', 'amber', 'daily'],
    'Daily': ['fresh', 'clean', 'musk', 'citrus', 'daily', 'year-round'],
    'Formal': ['woody', 'amber', 'cedar', 'jasmine', 'oakmoss', 'evening'],
    'Vacation': ['tropical', 'pineapple', 'passionfruit', 'pear', 'citrus'],
  };

  static const _seasonTerms = {
    'Warm weather': ['citrus', 'marine', 'neroli', 'fig', 'tea', 'fresh'],
    'Cool weather': ['amber', 'vanilla', 'tobacco', 'oud', 'spice', 'tonka'],
    'Year-round': ['musk', 'cedar', 'rose', 'vetiver', 'daily', 'year-round'],
    'Evening': ['jasmine', 'amber', 'oud', 'leather', 'orchid', 'smoke'],
    'Spring': ['floral', 'pear', 'bergamot', 'jasmine', 'orange blossom'],
    'Summer': ['tropical', 'pineapple', 'citrus', 'fresh', 'marine'],
  };

  static const _sceneTerms = {
    'Everyday confidence': ['daily', 'fresh', 'clean', 'musk', 'versatile'],
    'Close encounter': ['soft', 'musk', 'vanilla', 'powder', 'skin'],
    'Room entrance': ['bold', 'projection', 'sillage', 'pepper', 'ambroxan'],
    'Outdoor heat': ['citrus', 'tropical', 'fresh', 'bergamot', 'pineapple'],
    'After dark': ['amber', 'vanilla', 'jasmine', 'patchouli', 'cocoa'],
  };

  static const _intensityTerms = {
    'Soft trail': ['musk', 'powder', 'soft', 'skin', 'floral'],
    'Noticeable': ['extrait', 'cedar', 'amber', 'fresh', 'woody'],
    'Statement': ['bold', 'sillage', 'pepper', 'patchouli', 'ambroxan'],
  };
}

class _FinderChoices extends StatelessWidget {
  const _FinderChoices({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          for (final option in options)
            ChoiceChip(
              label: Text(option),
              selected: value == option,
              onSelected: (_) => onChanged(option),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketplaceDepth extends StatelessWidget {
  const _MarketplaceDepth({
    required this.products,
    required this.onOpenInfoPage,
    required this.siteStatus,
  });

  final List<Fragrance> products;
  final ValueChanged<StoreInfoPage> onOpenInfoPage;
  final SiteStatus siteStatus;

  @override
  Widget build(BuildContext context) {
    final notes = products
        .expand(
          (product) => [
            product.topNotes,
            product.heartNotes,
            product.baseNotes,
            product.family,
          ],
        )
        .where((item) => item.trim().isNotEmpty)
        .take(8)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          if (siteStatus.showNoteEncyclopedia)
            (
              Icons.menu_book_outlined,
              'Note encyclopedia',
              notes.isEmpty
                  ? 'Explore top, heart, and base notes by family, mood, and role in a fragrance. Learn what makes citrus sparkle, woods last, florals bloom, and musks soften the dry-down.'
                  : 'Explore top, heart, and base notes by family, mood, and role in a fragrance. Current catalog cues include ${notes.join(' • ')}.',
              StoreInfoPage.notes,
            ),
          if (siteStatus.showIngredientProfiles)
            (
              Icons.science_outlined,
              'Ingredient profiles',
              'Understand formula building blocks: carrier oils, fragrance accords, aroma molecules, fixatives, allergens, and safe-use notes for sprays, oils, and body products.',
              StoreInfoPage.ingredients,
            ),
          if (siteStatus.showBrandProfile)
            (
              Icons.history_edu_outlined,
              'EgbeAnom profile',
              'Read the house story, brand philosophy, catalog focus, and the design language behind EgbeAnom fragrance names, extrait concentration, packaging, and customer experience.',
              StoreInfoPage.brandProfile,
            ),
          if (siteStatus.showRecommendations)
            (
              Icons.compare_arrows_outlined,
              'Recommendations',
              'Compare scent families, seasons, projection levels, and order history signals to discover personal picks for daily wear, evenings, gifting, and signature-scent rotation.',
              StoreInfoPage.recommendations,
            ),
        ];
        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }
        final columns = cards.length == 1
            ? 1
            : cards.length == 2
            ? (constraints.maxWidth > 640 ? 2 : 1)
            : cards.length == 3
            ? (constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 640
                  ? 2
                  : 1)
            : (constraints.maxWidth > 980
                  ? 4
                  : constraints.maxWidth > 640
                  ? 2
                  : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1
              ? 3.8
              : columns == 2
              ? 1.95
              : 1.55,
          children: [
            for (final card in cards)
              Card(
                child: InkWell(
                  onTap: () => onOpenInfoPage(card.$4),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(card.$1, color: const Color(0xFFC88F52)),
                        const SizedBox(height: 10),
                        Text(
                          card.$2,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Expanded(child: Text(card.$3, maxLines: 4)),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LatestNewsPanel extends StatelessWidget {
  const _LatestNewsPanel({required this.items});

  final List<NewsItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest fragrance news',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Live RSS feed is loading. If this remains blank, the browser or RSS source blocked the client-side feed request.',
                ),
              )
            else
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SizedBox(
                      width: 320,
                      child: InkWell(
                        onTap: () => openExternalLink(item.url),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2DCD2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.source,
                                style: const TextStyle(
                                  color: Color(0xFF8A5D29),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  item.summary,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.open_in_new, size: 16),
                                ],
                              ),
                            ],
                          ),
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
}

class _SocialCardsPanel extends StatelessWidget {
  const _SocialCardsPanel({
    required this.reviews,
    required this.showCommunity,
    required this.showCompanyReviews,
    required this.onOpenInfoPage,
  });

  final List<ReviewSummary> reviews;
  final bool showCommunity;
  final bool showCompanyReviews;
  final ValueChanged<StoreInfoPage> onOpenInfoPage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = <Widget>[
          if (showCommunity) _CommunityCard(onOpenInfoPage: onOpenInfoPage),
          if (showCompanyReviews) _CompanyReviewsCard(reviews: reviews),
        ];
        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }
        if (cards.length == 1 || constraints.maxWidth <= 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                Expanded(child: cards[index]),
                if (index != cards.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.onOpenInfoPage});

  final ValueChanged<StoreInfoPage> onOpenInfoPage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Community', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Text(
              'Customer fragrance reviews, wishlists, collection tracking, and recommendation signals.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TrustPill(
                  icon: Icons.star_outline,
                  label: 'Ratings',
                  onTap: () => onOpenInfoPage(StoreInfoPage.ratings),
                ),
                _TrustPill(
                  icon: Icons.favorite_border,
                  label: 'Wishlists',
                  onTap: () => onOpenInfoPage(StoreInfoPage.wishlist),
                ),
                _TrustPill(
                  icon: Icons.collections_bookmark_outlined,
                  label: 'Collections',
                  onTap: () => onOpenInfoPage(StoreInfoPage.collections),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyReviewsCard extends StatelessWidget {
  const _CompanyReviewsCard({required this.reviews});

  final List<ReviewSummary> reviews;

  @override
  Widget build(BuildContext context) {
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold(0.0, (sum, review) => sum + review.rating) /
              reviews.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Company reviews',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (reviews.isNotEmpty)
                  Text(
                    average.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (reviews.isEmpty)
              const Text('No approved company reviews yet.')
            else
              for (final review in reviews.take(4))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.reviews_outlined),
                  title: Text(
                    '${review.title} • ${review.rating.toStringAsFixed(1)}',
                  ),
                  subtitle: Text('${review.author}: ${review.body}'),
                ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onViewDetails,
  });

  final Fragrance product;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final inStock = product.stock > 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: product.featuredColor.withValues(alpha: 0.24),
                child: ProductPhoto(product: product, iconSize: 64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.type,
                        style: const TextStyle(
                          color: Color(0xFF8A5D29),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(product.size),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currency(product.price),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inStock ? '${product.stock} left' : 'Sold out',
                        style: TextStyle(
                          color: inStock ? const Color(0xFF27724E) : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Choose size'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
