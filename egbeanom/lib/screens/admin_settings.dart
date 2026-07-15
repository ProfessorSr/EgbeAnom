part of '../main.dart';

class _SiteStatusSection extends StatefulWidget {
  const _SiteStatusSection({
    required this.status,
    required this.products,
    required this.onSave,
  });

  final SiteStatus status;
  final List<Fragrance> products;
  final AsyncValueChanged<SiteStatus> onSave;

  @override
  State<_SiteStatusSection> createState() => _SiteStatusSectionState();
}

class _SiteStatusSectionState extends State<_SiteStatusSection> {
  late final TextEditingController _message;
  late final TextEditingController _returnPolicy;
  late final TextEditingController _googleAnalyticsId;
  late bool _isLive;
  late MeasurementSystem _measurementSystem;
  late bool _showNoteEncyclopedia;
  late bool _showIngredientProfiles;
  late bool _showBrandProfile;
  late bool _showRecommendations;
  late bool _showLatestFragranceNews;
  late bool _showCommunity;
  late bool _showCompanyReviews;
  late bool _showMailingListSignup;
  late bool _showLiveChat;
  late String _homeShelfMode;
  late Set<int> _featuredProductIds;

  @override
  void initState() {
    super.initState();
    _isLive = widget.status.isLive;
    _measurementSystem = widget.status.measurementSystem;
    _showNoteEncyclopedia = widget.status.showNoteEncyclopedia;
    _showIngredientProfiles = widget.status.showIngredientProfiles;
    _showBrandProfile = widget.status.showBrandProfile;
    _showRecommendations = widget.status.showRecommendations;
    _showLatestFragranceNews = widget.status.showLatestFragranceNews;
    _showCommunity = widget.status.showCommunity;
    _showCompanyReviews = widget.status.showCompanyReviews;
    _showMailingListSignup = widget.status.showMailingListSignup;
    _showLiveChat = widget.status.showLiveChat;
    _homeShelfMode = widget.status.homeShelfMode;
    _featuredProductIds = widget.status.featuredProductIds.toSet();
    _message = TextEditingController(text: widget.status.message);
    _returnPolicy = TextEditingController(text: widget.status.returnPolicy);
    _googleAnalyticsId = TextEditingController(
      text: widget.status.googleAnalyticsMeasurementId,
    );
  }

  @override
  void dispose() {
    _message.dispose();
    _returnPolicy.dispose();
    _googleAnalyticsId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 840;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 4 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Storefront status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isLive ? 'Site is live' : 'Site is offline',
                        ),
                        subtitle: Text(
                          _isLive
                              ? 'Customers can shop normally.'
                              : 'Customers see the upgrade greeting.',
                        ),
                        value: _isLive,
                        onChanged: (value) => setState(() => _isLive = value),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<MeasurementSystem>(
                        initialValue: _measurementSystem,
                        decoration: const InputDecoration(
                          labelText: 'Measurement system',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: MeasurementSystem.standard,
                            child: Text('Standard (oz / in)'),
                          ),
                          DropdownMenuItem(
                            value: MeasurementSystem.metric,
                            child: Text('Metric (g / cm)'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () =>
                              _measurementSystem = value ?? _measurementSystem,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _message,
                        decoration: const InputDecoration(
                          labelText: 'Offline greeting',
                          prefixIcon: Icon(Icons.favorite_border),
                        ),
                        minLines: 3,
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _returnPolicy,
                        decoration: const InputDecoration(
                          labelText: 'Return policy',
                          prefixIcon: Icon(Icons.replay_outlined),
                        ),
                        minLines: 3,
                        maxLines: 6,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _googleAnalyticsId,
                        decoration: const InputDecoration(
                          labelText: 'Google Analytics measurement ID',
                          prefixIcon: Icon(Icons.analytics_outlined),
                          helperText: 'Example: G-XXXXXXXXXX',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Storefront sections',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _homeShelfMode,
                        decoration: const InputDecoration(
                          labelText: 'Home product shelf',
                          prefixIcon: Icon(Icons.view_carousel_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Featured products',
                            child: Text('Featured products'),
                          ),
                          DropdownMenuItem(
                            value: 'Best sellers',
                            child: Text('Best sellers'),
                          ),
                          DropdownMenuItem(
                            value: 'Most favorited',
                            child: Text('Most favorited'),
                          ),
                          DropdownMenuItem(
                            value: 'Top rated',
                            child: Text('Top rated'),
                          ),
                          DropdownMenuItem(
                            value: 'Newest',
                            child: Text('Newest'),
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
                        onChanged: (value) => setState(
                          () => _homeShelfMode = value ?? _homeShelfMode,
                        ),
                      ),
                      if (_homeShelfMode == 'Featured products') ...[
                        const SizedBox(height: 10),
                        Text(
                          'Featured products',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        for (final product
                            in widget.products
                                .where((product) => product.isActive)
                                .take(24))
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _featuredProductIds.contains(product.id),
                            title: Text(product.name),
                            subtitle: Text(product.sku),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  if (_featuredProductIds.length < 4) {
                                    _featuredProductIds.add(product.id);
                                  }
                                } else {
                                  _featuredProductIds.remove(product.id);
                                }
                              });
                            },
                          ),
                      ],
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Note encyclopedia'),
                        value: _showNoteEncyclopedia,
                        onChanged: (value) =>
                            setState(() => _showNoteEncyclopedia = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ingredient profiles'),
                        value: _showIngredientProfiles,
                        onChanged: (value) =>
                            setState(() => _showIngredientProfiles = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('EgbeAnom profile'),
                        value: _showBrandProfile,
                        onChanged: (value) =>
                            setState(() => _showBrandProfile = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Recommendations'),
                        value: _showRecommendations,
                        onChanged: (value) =>
                            setState(() => _showRecommendations = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Latest fragrance news'),
                        value: _showLatestFragranceNews,
                        onChanged: (value) =>
                            setState(() => _showLatestFragranceNews = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Community'),
                        value: _showCommunity,
                        onChanged: (value) =>
                            setState(() => _showCommunity = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Company reviews'),
                        value: _showCompanyReviews,
                        onChanged: (value) =>
                            setState(() => _showCompanyReviews = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mailing list signup'),
                        value: _showMailingListSignup,
                        onChanged: (value) =>
                            setState(() => _showMailingListSignup = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Live chat help'),
                        subtitle: Text(
                          _showLiveChat
                              ? 'Open for customer messages'
                              : 'Closed and hidden from customers',
                        ),
                        value: _showLiveChat,
                        onChanged: (value) =>
                            setState(() => _showLiveChat = value),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await widget.onSave(
                              SiteStatus(
                                isLive: _isLive,
                                measurementSystem: _measurementSystem,
                                message: _message.text.trim().isEmpty
                                    ? SiteStatus().message
                                    : _message.text.trim(),
                                returnPolicy: _returnPolicy.text.trim().isEmpty
                                    ? SiteStatus().returnPolicy
                                    : _returnPolicy.text.trim(),
                                googleAnalyticsMeasurementId: _googleAnalyticsId
                                    .text
                                    .trim(),
                                showNoteEncyclopedia: _showNoteEncyclopedia,
                                showIngredientProfiles: _showIngredientProfiles,
                                showBrandProfile: _showBrandProfile,
                                showRecommendations: _showRecommendations,
                                showLatestFragranceNews:
                                    _showLatestFragranceNews,
                                showCommunity: _showCommunity,
                                showCompanyReviews: _showCompanyReviews,
                                showMailingListSignup: _showMailingListSignup,
                                showLiveChat: _showLiveChat,
                                homeShelfMode: _homeShelfMode,
                                featuredProductIds: _featuredProductIds
                                    .toList(),
                              ),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Site settings saved.'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Site settings save failed: $error',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save site status'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 5 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 170,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something beautiful is being prepared',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_message.text, textAlign: TextAlign.center),
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

class _StoreInfoSection extends StatefulWidget {
  const _StoreInfoSection({
    required this.storeInfo,
    required this.onSave,
    required this.onUploadAsset,
  });

  final StoreInfo storeInfo;
  final AsyncValueChanged<StoreInfo> onSave;
  final Future<String> Function(UploadedImageFile file) onUploadAsset;

  @override
  State<_StoreInfoSection> createState() => _StoreInfoSectionState();
}

class _StoreInfoSectionState extends State<_StoreInfoSection> {
  bool _uploadingBanner = false;
  late final _storeName = TextEditingController(
    text: widget.storeInfo.storeName,
  );
  late final _displayName = TextEditingController(
    text: widget.storeInfo.displayName,
  );
  late final _bannerUrl = TextEditingController(
    text: widget.storeInfo.bannerUrl,
  );
  late final _logoUrl = TextEditingController(text: widget.storeInfo.logoUrl);
  late final _address1 = TextEditingController(
    text: widget.storeInfo.addressLine1,
  );
  late final _address2 = TextEditingController(
    text: widget.storeInfo.addressLine2,
  );
  late final _city = TextEditingController(text: widget.storeInfo.city);
  late final _county = TextEditingController(text: widget.storeInfo.county);
  late final _state = TextEditingController(text: widget.storeInfo.state);
  late final _postal = TextEditingController(text: widget.storeInfo.postalCode);
  late final _country = TextEditingController(text: widget.storeInfo.country);
  late final _email = TextEditingController(text: widget.storeInfo.email);
  late final _phone = TextEditingController(text: widget.storeInfo.phone);
  late final _fax = TextEditingController(text: widget.storeInfo.fax);
  late final _facebook = TextEditingController(
    text: widget.storeInfo.facebookUrl,
  );
  late final _instagram = TextEditingController(
    text: widget.storeInfo.instagramUrl,
  );
  late final _tiktok = TextEditingController(text: widget.storeInfo.tiktokUrl);
  late final _x = TextEditingController(text: widget.storeInfo.xUrl);
  late final _youtube = TextEditingController(
    text: widget.storeInfo.youtubeUrl,
  );

  @override
  void dispose() {
    for (final controller in [
      _storeName,
      _displayName,
      _bannerUrl,
      _logoUrl,
      _address1,
      _address2,
      _city,
      _county,
      _state,
      _postal,
      _country,
      _email,
      _phone,
      _fax,
      _facebook,
      _instagram,
      _tiktok,
      _x,
      _youtube,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Store info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _responsiveFields([
              TextField(
                controller: _storeName,
                decoration: const InputDecoration(
                  labelText: 'Legal store name',
                ),
              ),
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(
                  labelText: 'Website display name',
                ),
              ),
              TextField(
                controller: _bannerUrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Uploaded banner image',
                  suffixIcon: _uploadingBanner
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Upload banner',
                          onPressed: _uploadBanner,
                          icon: const Icon(Icons.upload_file_outlined),
                        ),
                ),
              ),
              TextField(
                controller: _logoUrl,
                decoration: const InputDecoration(labelText: 'Logo URL'),
              ),
              TextField(
                controller: _address1,
                decoration: const InputDecoration(labelText: 'Address line 1'),
              ),
              TextField(
                controller: _address2,
                decoration: const InputDecoration(labelText: 'Address line 2'),
              ),
              TextField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: _county,
                decoration: const InputDecoration(labelText: 'County'),
              ),
              TextField(
                controller: _state,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              TextField(
                controller: _postal,
                decoration: const InputDecoration(labelText: 'ZIP / Postal'),
              ),
              TextField(
                controller: _country,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: _fax,
                decoration: const InputDecoration(labelText: 'Fax'),
              ),
              TextField(
                controller: _facebook,
                decoration: const InputDecoration(labelText: 'Facebook URL'),
              ),
              TextField(
                controller: _instagram,
                decoration: const InputDecoration(labelText: 'Instagram URL'),
              ),
              TextField(
                controller: _tiktok,
                decoration: const InputDecoration(labelText: 'TikTok URL'),
              ),
              TextField(
                controller: _x,
                decoration: const InputDecoration(labelText: 'X URL'),
              ),
              TextField(
                controller: _youtube,
                decoration: const InputDecoration(labelText: 'YouTube URL'),
              ),
            ]),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save store info'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsiveFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 820
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final field in fields) SizedBox(width: width, child: field),
          ],
        );
      },
    );
  }

  Future<void> _uploadBanner() async {
    try {
      final files = await pickProductImages();
      if (files.isEmpty) {
        return;
      }
      setState(() => _uploadingBanner = true);
      final url = await widget.onUploadAsset(files.first);
      if (!mounted) {
        return;
      }
      setState(() => _bannerUrl.text = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Banner image uploaded.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Banner upload failed: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingBanner = false);
      }
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSave(
        StoreInfo(
          storeName: _storeName.text.trim(),
          displayName: _displayName.text.trim(),
          bannerUrl: _bannerUrl.text.trim(),
          logoUrl: _logoUrl.text.trim(),
          addressLine1: _address1.text.trim(),
          addressLine2: _address2.text.trim(),
          city: _city.text.trim(),
          county: _county.text.trim(),
          state: _state.text.trim(),
          postalCode: _postal.text.trim(),
          country: _country.text.trim().isEmpty ? 'US' : _country.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          fax: _fax.text.trim(),
          facebookUrl: _facebook.text.trim(),
          instagramUrl: _instagram.text.trim(),
          tiktokUrl: _tiktok.text.trim(),
          xUrl: _x.text.trim(),
          youtubeUrl: _youtube.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Store info saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Store info save failed: $error')),
      );
    }
  }
}

class _TaxRulesSection extends StatefulWidget {
  const _TaxRulesSection({
    required this.taxRules,
    required this.storeInfo,
    required this.onSave,
    required this.onDelete,
  });

  final List<TaxRule> taxRules;
  final StoreInfo storeInfo;
  final AsyncValueChanged<TaxRule> onSave;
  final AsyncValueChanged<TaxRule> onDelete;

  @override
  State<_TaxRulesSection> createState() => _TaxRulesSectionState();
}

class _TaxRulesSectionState extends State<_TaxRulesSection> {
  TaxRule? _editing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 920;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: _HorizontalTableScroller(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('State')),
                      DataColumn(label: Text('County')),
                      DataColumn(label: Text('City')),
                      DataColumn(label: Text('ZIP')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Rate')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final rule in widget.taxRules)
                        DataRow(
                          cells: [
                            DataCell(Text(rule.name)),
                            DataCell(Text(rule.state)),
                            DataCell(Text(rule.county)),
                            DataCell(Text(rule.city)),
                            DataCell(Text(rule.postalCodePrefix)),
                            DataCell(Text(_taxRuleScopeLabel(rule))),
                            DataCell(
                              Text('${(rule.rate * 100).toStringAsFixed(3)}%'),
                            ),
                            DataCell(Text(rule.isEnabled ? 'Enabled' : 'Off')),
                            DataCell(
                              SizedBox(
                                width: 96,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 42,
                                            height: 42,
                                          ),
                                      tooltip: 'Edit',
                                      onPressed: () =>
                                          setState(() => _editing = rule),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 42,
                                            height: 42,
                                          ),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                              context: this.context,
                                              builder: (dialogContext) =>
                                                  AlertDialog(
                                                    title: const Text(
                                                      'Delete tax rule?',
                                                    ),
                                                    content: Text(
                                                      'This will permanently delete "${rule.name}".',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              dialogContext,
                                                            ).pop(false),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      FilledButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              dialogContext,
                                                            ).pop(true),
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            ) ??
                                            false;
                                        if (!confirmed) {
                                          return;
                                        }
                                        try {
                                          await widget.onDelete(rule);
                                          if (_editing?.id == rule.id) {
                                            setState(() => _editing = null);
                                          }
                                          if (!mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Tax rule "${rule.name}" deleted.',
                                              ),
                                            ),
                                          );
                                        } catch (error) {
                                          if (!mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Tax rule delete failed: $error',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: _TaxRuleEditor(
                key: ValueKey(_editing?.id ?? 'tax-editor-new'),
                rule: _editing,
                storeInfo: widget.storeInfo,
                onSave: (rule) async {
                  await widget.onSave(rule);
                  setState(() => _editing = null);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

String _taxRuleScopeLabel(TaxRule rule) {
  final type = rule.taxType.trim().toLowerCase();
  if (type == 'state') {
    return 'State tax';
  }
  if (type == 'county') {
    return 'County tax';
  }
  if (type == 'city') {
    return 'City tax';
  }
  if (type == 'other') {
    return 'Other tax';
  }
  if (type == 'vat') {
    return 'VAT / import tax';
  }
  if (rule.city.trim().isNotEmpty) {
    return 'City tax';
  }
  if (rule.county.trim().isNotEmpty) {
    return 'County tax';
  }
  if (rule.state.trim().isNotEmpty) {
    return 'State tax';
  }
  return 'Unassigned';
}

class _TaxRuleEditor extends StatefulWidget {
  const _TaxRuleEditor({
    super.key,
    required this.rule,
    required this.storeInfo,
    required this.onSave,
  });

  final TaxRule? rule;
  final StoreInfo storeInfo;
  final AsyncValueChanged<TaxRule> onSave;

  @override
  State<_TaxRuleEditor> createState() => _TaxRuleEditorState();
}

class _TaxRuleEditorState extends State<_TaxRuleEditor> {
  late final _name = TextEditingController(
    text: widget.rule?.name ?? 'New tax rule',
  );
  late final _rate = TextEditingController(
    text: ((widget.rule?.rate ?? 0.082) * 100).toStringAsFixed(3),
  );
  late String _taxScope = _scopeForRule(widget.rule);
  late String _vatCountry = _countryForRule(widget.rule);
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _enabled = widget.rule?.isEnabled ?? true;
  }

  @override
  void didUpdateWidget(covariant _TaxRuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule?.id != widget.rule?.id) {
      _name.text = widget.rule?.name ?? 'New tax rule';
      _rate.text = ((widget.rule?.rate ?? 0.082) * 100).toStringAsFixed(3);
      _taxScope = _scopeForRule(widget.rule);
      _vatCountry = _countryForRule(widget.rule);
      _enabled = widget.rule?.isEnabled ?? true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _rate]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _scopeForRule(TaxRule? rule) {
    final type = rule?.taxType.trim().toLowerCase();
    if (type == 'other') {
      return 'other';
    }
    if (type == 'vat') {
      return 'vat';
    }
    if (type == 'city' || rule?.city.trim().isNotEmpty == true) {
      return 'city';
    }
    if (type == 'county' || rule?.county.trim().isNotEmpty == true) {
      return 'county';
    }
    return 'state';
  }

  String _countryForRule(TaxRule? rule) {
    final normalized = normalizeCountryCode(rule?.country ?? '');
    if (normalized.isNotEmpty && normalized != 'US') {
      return normalized;
    }
    return standardInternationalTaxRates.first.code;
  }

  String get _scopeLabel => switch (_taxScope) {
    'city' => 'City tax',
    'county' => 'County tax',
    'other' => 'Other tax',
    'vat' => 'VAT / import tax',
    _ => 'State tax',
  };

  String get _locationSummary {
    final store = widget.storeInfo;
    final values = switch (_taxScope) {
      'city' => [
        if (store.state.trim().isNotEmpty) store.state.trim().toUpperCase(),
        if (store.county.trim().isNotEmpty) store.county.trim(),
        if (store.city.trim().isNotEmpty) store.city.trim(),
      ],
      'county' => [
        if (store.state.trim().isNotEmpty) store.state.trim().toUpperCase(),
        if (store.county.trim().isNotEmpty) store.county.trim(),
      ],
      'other' => ['Not tied to customer location'],
      'vat' => ['Destination country: ${countryNameForCode(_vatCountry)}'],
      _ => [
        if (store.state.trim().isNotEmpty) store.state.trim().toUpperCase(),
      ],
    };
    return values.isEmpty
        ? 'Complete the store address on the Site Info page.'
        : values.join(' / ');
  }

  String get _missingStoreLocationMessage {
    if (_taxScope == 'other' || _taxScope == 'vat') {
      return '';
    }
    final store = widget.storeInfo;
    if (store.state.trim().isEmpty) {
      return 'Add the store state on the Site Info page before saving taxes.';
    }
    if ((_taxScope == 'county' || _taxScope == 'city') &&
        store.county.trim().isEmpty) {
      return 'Add the store county on the Site Info page before saving this tax.';
    }
    if (_taxScope == 'city' && store.city.trim().isEmpty) {
      return 'Add the store city on the Site Info page before saving this tax.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tax rule', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _taxScope,
              decoration: const InputDecoration(labelText: 'Tax type'),
              items: const [
                DropdownMenuItem(value: 'state', child: Text('State tax')),
                DropdownMenuItem(value: 'county', child: Text('County tax')),
                DropdownMenuItem(value: 'city', child: Text('City tax')),
                DropdownMenuItem(value: 'other', child: Text('Other tax')),
                DropdownMenuItem(value: 'vat', child: Text('VAT / import tax')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _taxScope = value;
                  if (_name.text.trim().isEmpty ||
                      _name.text == 'New tax rule' ||
                      _name.text == 'State tax' ||
                      _name.text == 'County tax' ||
                      _name.text == 'City tax' ||
                      _name.text == 'Other tax' ||
                      _name.text == 'VAT / import tax') {
                    _name.text = _scopeLabel;
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            if (_taxScope == 'vat') ...[
              DropdownButtonFormField<String>(
                initialValue: _vatCountry,
                decoration: const InputDecoration(
                  labelText: 'Destination country',
                ),
                items: [
                  for (final rate in standardInternationalTaxRates)
                    DropdownMenuItem(
                      value: rate.code,
                      child: Text(rate.country),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _vatCountry = value);
                },
              ),
              const SizedBox(height: 10),
            ],
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Store location used',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              child: Text(_locationSummary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rate,
              decoration: const InputDecoration(labelText: 'Rate percent'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save tax rule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final missingStoreLocation = _missingStoreLocationMessage;
    if (missingStoreLocation.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(missingStoreLocation)));
      return;
    }
    final store = widget.storeInfo;
    final state = _taxScope == 'other' || _taxScope == 'vat'
        ? ''
        : store.state.trim().toUpperCase();
    final county = _taxScope == 'county' || _taxScope == 'city'
        ? store.county.trim()
        : '';
    final city = _taxScope == 'city' ? store.city.trim() : '';
    try {
      await widget.onSave(
        TaxRule(
          id: widget.rule?.id ?? 'tax-${DateTime.now().millisecondsSinceEpoch}',
          name: _name.text.trim().isEmpty ? _scopeLabel : _name.text.trim(),
          country: _taxScope == 'vat'
              ? _vatCountry
              : (store.country.trim().isEmpty ? 'US' : store.country.trim()),
          state: state,
          county: county,
          city: city,
          postalCodePrefix: '',
          taxType: _taxScope,
          rate: (double.tryParse(_rate.text) ?? 0) / 100,
          isVat: false,
          isEnabled: _enabled,
          sortOrder:
              widget.rule?.sortOrder ??
              switch (_taxScope) {
                'county' => 20,
                'city' => 30,
                'other' => 40,
                'vat' => 50,
                _ => 10,
              },
        ),
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Tax rule saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Tax rule save failed: $error')),
      );
    }
  }
}

class _BackendUsersSection extends StatefulWidget {
  const _BackendUsersSection({
    required this.users,
    required this.onSave,
    required this.onBlockIp,
  });

  final List<BackendUser> users;
  final AsyncValueChanged<BackendUser> onSave;
  final ValueChanged<String> onBlockIp;

  @override
  State<_BackendUsersSection> createState() => _BackendUsersSectionState();
}

class _BackendUsersSectionState extends State<_BackendUsersSection> {
  BackendUser? _editing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: _HorizontalTableScroller(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Last IP')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final user in widget.users)
                        DataRow(
                          cells: [
                            DataCell(Text(user.name)),
                            DataCell(Text(user.email)),
                            DataCell(Text(user.role)),
                            DataCell(
                              Text(
                                user.isBlocked
                                    ? 'Blocked'
                                    : user.isActive
                                    ? 'Active'
                                    : 'Disabled',
                              ),
                            ),
                            DataCell(Text(user.lastLoginIp)),
                            DataCell(
                              IconButton(
                                tooltip: 'Edit user',
                                onPressed: () =>
                                    setState(() => _editing = user),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: BackendUserEditor(
                user: _editing,
                onNew: () => setState(() => _editing = null),
                onBlockIp: widget.onBlockIp,
                onSave: (user) async {
                  await widget.onSave(user);
                  setState(() => _editing = null);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class BackendUserEditor extends StatefulWidget {
  const BackendUserEditor({
    super.key,
    required this.user,
    required this.onNew,
    required this.onBlockIp,
    required this.onSave,
  });

  final BackendUser? user;
  final VoidCallback onNew;
  final ValueChanged<String> onBlockIp;
  final AsyncValueChanged<BackendUser> onSave;

  @override
  State<BackendUserEditor> createState() => _BackendUserEditorState();
}

class _BackendUserEditorState extends State<BackendUserEditor> {
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _blockedReason;
  late String _role;
  late bool _active;
  late bool _blocked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BackendUserEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.id != widget.user?.id) {
      _name.dispose();
      _email.dispose();
      _blockedReason.dispose();
      _load();
    }
  }

  void _load() {
    _name = TextEditingController(text: widget.user?.name ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _blockedReason = TextEditingController(
      text: widget.user?.blockedReason ?? '',
    );
    _role = widget.user?.role ?? 'staff';
    _active = widget.user?.isActive ?? true;
    _blocked = widget.user?.isBlocked ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _blockedReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Backend user', style: Theme.of(context).textTheme.titleLarge),
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
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline),
              title: Text('Supabase Auth manages passwords'),
              subtitle: Text(
                'Create or reset this user in Supabase Auth, then keep this profile email and role in sync here.',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'owner', child: Text('Owner')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
              ],
              onChanged: (value) => setState(() => _role = value ?? _role),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Authorized for backend access'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Blocked account'),
              value: _blocked,
              onChanged: (value) => setState(() => _blocked = value),
            ),
            TextField(
              controller: _blockedReason,
              decoration: const InputDecoration(
                labelText: 'Blocked reason',
                prefixIcon: Icon(Icons.report_gmailerrorred_outlined),
              ),
            ),
            if ((widget.user?.lastLoginIp ?? '').isNotEmpty ||
                (widget.user?.createdIp ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((widget.user?.lastLoginIp ?? '').isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.public, size: 18),
                      label: Text('Last IP ${widget.user!.lastLoginIp}'),
                    ),
                  if ((widget.user?.createdIp ?? '').isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text('Created from ${widget.user!.createdIp}'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (widget.user?.lastLoginIp ?? '').trim().isEmpty
                    ? null
                    : () => widget.onBlockIp(widget.user!.lastLoginIp),
                icon: const Icon(Icons.public_off_outlined),
                label: const Text('Block last IP'),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNew,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onSave(
                      BackendUser(
                        id:
                            widget.user?.id ??
                            'ADM-${DateTime.now().millisecondsSinceEpoch}',
                        name: _name.text.trim().isEmpty
                            ? 'Backend user'
                            : _name.text.trim(),
                        email: _email.text.trim().toLowerCase(),
                        role: _role,
                        isActive: _active,
                        isBlocked: _blocked,
                        createdIp: widget.user?.createdIp ?? '',
                        lastLoginIp: widget.user?.lastLoginIp ?? '',
                        blockedReason: _blockedReason.text.trim(),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
