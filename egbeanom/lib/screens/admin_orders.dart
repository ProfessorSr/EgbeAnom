part of '../main.dart';

class _OrdersSection extends StatefulWidget {
  const _OrdersSection({
    required this.orders,
    required this.customers,
    required this.shippingOptions,
    required this.storeInfo,
    required this.siteStatus,
    required this.onUpdateOrder,
    required this.onSaveCustomer,
    required this.onCreateStripeRefund,
    required this.onCreateShippingLabel,
    required this.onBatchUpdateOrders,
  });

  final List<Order> orders;
  final List<CustomerAccount> customers;
  final List<ShippingOption> shippingOptions;
  final StoreInfo storeInfo;
  final SiteStatus siteStatus;
  final AsyncValueChanged<Order> onUpdateOrder;
  final AsyncValueChanged<CustomerAccount> onSaveCustomer;
  final Future<String> Function(Order order, double amount, String reason)
  onCreateStripeRefund;
  final Future<ShippingLabelResult> Function(Order order) onCreateShippingLabel;
  final void Function(
    List<Order> orders,
    String fulfillmentStatus,
    String labelStatus,
  )
  onBatchUpdateOrders;

  @override
  State<_OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<_OrdersSection> {
  final Set<String> _selectedOrderKeys = {};
  String _shippingFilter = 'All';
  String _paymentFilter = 'All';
  String _statusFilter = 'All';
  String _batchAction = 'Print Pack List';
  String _printPacket = '';
  bool _isApplyingBatchAction = false;

  static const List<String> _shippingFilters =
      AdminOrderWorkflow.shippingFilters;
  static const List<String> _statusFilters = AdminOrderWorkflow.statusFilters;
  static const List<String> _paymentFilters = AdminOrderWorkflow.paymentFilters;

  List<Order> get _visibleOrders => AdminOrderWorkflow.visibleOrders(
    widget.orders,
    shippingFilter: _shippingFilter,
    paymentFilter: _paymentFilter,
    statusFilter: _statusFilter,
  );

  List<Order> _unpaidOrders(List<Order> orders) =>
      AdminOrderWorkflow.unpaidOrders(orders);

  String _orderSelectionKey(Order order) {
    return '${order.id}|${identityHashCode(order)}';
  }

  List<Order> get _selectedOrders => widget.orders
      .where((order) => _selectedOrderKeys.contains(_orderSelectionKey(order)))
      .toList();

  void _toggleAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedOrderKeys
          ..clear()
          ..addAll(_visibleOrders.map(_orderSelectionKey));
      } else {
        _selectedOrderKeys.clear();
      }
    });
  }

  void _printSelected() {
    final orders = _selectedOrders;
    if (orders.isEmpty) {
      return;
    }
    final unpaid = _unpaidOrders(orders);
    if (unpaid.isNotEmpty) {
      _showUnpaidSelectionWarning(unpaid, 'print pack lists');
      return;
    }
    widget.onBatchUpdateOrders(orders, 'Processing', 'Not requested');
    final packet = orders
        .map((order) => _packListHtml(order, widget.storeInfo))
        .join('\n');
    setState(() {
      _printPacket = _buildPrintPacket(orders);
    });
    printHtmlDocument('Egbe Anom pack lists (${orders.length})', packet);
  }

  void _printInvoices() {
    final orders = _selectedOrders;
    if (orders.isEmpty) {
      return;
    }
    final unpaid = _unpaidOrders(orders);
    if (unpaid.isNotEmpty) {
      _showUnpaidSelectionWarning(unpaid, 'print invoices');
      return;
    }
    final packet = orders
        .map(
          (order) => _invoiceHtml(
            order,
            widget.storeInfo,
            printLite: true,
            returnPolicyText: widget.siteStatus.returnPolicy,
          ),
        )
        .join('\n');
    widget.onBatchUpdateOrders(orders, 'Invoice created', 'Not requested');
    setState(() {
      _printPacket = orders.map(_buildInvoicePacket).join('\n\n');
    });
    printHtmlDocument('Egbe Anom invoices (${orders.length})', packet);
  }

  Future<void> _printShippingLabels() async {
    final orders = _selectedOrders;
    if (orders.isEmpty || _isApplyingBatchAction) {
      return;
    }
    final unpaid = _unpaidOrders(orders);
    if (unpaid.isNotEmpty) {
      _showUnpaidSelectionWarning(unpaid, 'print labels');
      return;
    }

    setState(() {
      _isApplyingBatchAction = true;
    });

    final completed = <Order>[];
    final failures = <String>[];
    for (final order in orders) {
      try {
        await widget.onCreateShippingLabel(order);
        completed.add(order);
      } catch (_) {
        failures.add(order.id);
      }
    }

    if (!mounted) {
      return;
    }

    if (completed.isNotEmpty) {
      widget.onBatchUpdateOrders(completed, 'Label created', 'Label created');
    }

    setState(() {
      _isApplyingBatchAction = false;
      _printPacket = _buildStatusPacket(
        completed,
        'Label created',
        'Label created',
      );
    });

    final messenger = ScaffoldMessenger.of(context);
    if (completed.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Created ${completed.length} label(s). Status set to Label created and customer email queued.',
          ),
        ),
      );
    }
    if (failures.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Label creation failed for ${failures.length} order(s): ${failures.join(', ')}',
          ),
        ),
      );
    }
  }

  void _batchStatus(String fulfillmentStatus, String labelStatus) {
    final orders = _selectedOrders;
    if (orders.isEmpty) {
      return;
    }
    final unpaid = _unpaidOrders(orders);
    if (unpaid.isNotEmpty &&
        (fulfillmentStatus == 'Sent' ||
            fulfillmentStatus == 'Shipped' ||
            fulfillmentStatus == 'Label created')) {
      _showUnpaidSelectionWarning(unpaid, 'update fulfillment');
      return;
    }
    widget.onBatchUpdateOrders(orders, fulfillmentStatus, labelStatus);
    setState(() {
      _printPacket = _buildStatusPacket(orders, fulfillmentStatus, labelStatus);
    });
  }

  void _showUnpaidSelectionWarning(List<Order> unpaid, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cannot $action for unpaid order(s): ${unpaid.map((order) => order.id).join(', ')}',
        ),
      ),
    );
  }

  double _requestedReturnProductTotal(Order order) {
    if (order.returnItems.isEmpty) {
      return order.subtotal > 0 ? order.subtotal : order.total;
    }
    return order.returnItems.fold(0.0, (total, item) => total + item.total);
  }

  String _newRmaNumber(Order order) {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    return 'RMA-${order.id}-${suffix.substring(suffix.length - 6)}';
  }

  Future<void> _showReturnDecisionDialog(Order order) async {
    final condition = TextEditingController(text: order.returnCondition);
    final refundReason = TextEditingController(text: order.refundReason);
    final comments = TextEditingController(text: order.returnAdminComment);
    final productTotal = _requestedReturnProductTotal(order);
    final specificAmount = TextEditingController(
      text: order.refundTotal > 0
          ? order.refundTotal.toStringAsFixed(2)
          : productTotal.toStringAsFixed(2),
    );
    final storedRefundOption = order.refundOption.split('•').first.trim();
    var refundOption = storedRefundOption.isEmpty
        ? 'Product plus shipping'
        : storedRefundOption;
    var decision = order.returnStatus == 'Return requested'
        ? 'Approve'
        : 'Receive returned item';
    var refundDestination = 'Payment method';
    var restockItems = order.returnRestocked;
    var processing = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            final amount = switch (refundOption) {
              'Product plus shipping' => productTotal + order.shippingTotal,
              'Just product' => productTotal,
              'Just shipping' => order.shippingTotal,
              _ => double.tryParse(specificAmount.text.trim()) ?? 0,
            };
            return AlertDialog(
              title: Text('Review return ${order.id}'),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (order.returnReason.trim().isNotEmpty)
                        Text('Customer reason: ${order.returnReason}'),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: decision,
                        decoration: const InputDecoration(labelText: 'Action'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Approve',
                            child: Text('Approve return request'),
                          ),
                          DropdownMenuItem(
                            value: 'Deny',
                            child: Text('Deny return request'),
                          ),
                          DropdownMenuItem(
                            value: 'Receive returned item',
                            child: Text('Item received - issue refund'),
                          ),
                        ],
                        onChanged: processing
                            ? null
                            : (value) => setDialogState(
                                () => decision = value ?? decision,
                              ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: condition,
                        enabled: !processing,
                        decoration: const InputDecoration(
                          labelText: 'Return condition',
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: comments,
                        enabled: !processing,
                        decoration: const InputDecoration(
                          labelText: 'Admin comments',
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: refundOption,
                        decoration: const InputDecoration(
                          labelText: 'Refund amount',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Product plus shipping',
                            child: Text('Full: product plus shipping'),
                          ),
                          DropdownMenuItem(
                            value: 'Just product',
                            child: Text('Product only'),
                          ),
                          DropdownMenuItem(
                            value: 'Just shipping',
                            child: Text('Shipping only'),
                          ),
                          DropdownMenuItem(
                            value: 'Specific dollar amount',
                            child: Text('Specific dollar amount'),
                          ),
                        ],
                        onChanged: processing
                            ? null
                            : (value) => setDialogState(
                                () => refundOption = value ?? refundOption,
                              ),
                      ),
                      if (refundOption == 'Specific dollar amount') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: specificAmount,
                          enabled: !processing,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Specific amount',
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ],
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: refundDestination,
                        decoration: const InputDecoration(
                          labelText: 'Refund destination',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Payment method',
                            child: Text('Return to payment method'),
                          ),
                          DropdownMenuItem(
                            value: 'Store credit',
                            child: Text('Apply as store credit'),
                          ),
                        ],
                        onChanged: processing
                            ? null
                            : (value) => setDialogState(
                                () => refundDestination =
                                    value ?? refundDestination,
                              ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: refundReason,
                        enabled: !processing,
                        decoration: const InputDecoration(
                          labelText: 'Refund reason',
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: restockItems,
                        title: const Text('Restock returned items'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: processing
                            ? null
                            : (value) => setDialogState(
                                () => restockItems = value ?? false,
                              ),
                      ),
                      Text(
                        '${refundDestination == 'Store credit' ? 'Store credit' : 'Payment refund'} amount: ${currency(amount)}',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: processing
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: processing
                      ? null
                      : () async {
                          final approved = decision != 'Deny';
                          final amount = switch (refundOption) {
                            'Product plus shipping' =>
                              productTotal + order.shippingTotal,
                            'Just product' => productTotal,
                            'Just shipping' => order.shippingTotal,
                            _ =>
                              double.tryParse(specificAmount.text.trim()) ?? 0,
                          };
                          setDialogState(() => processing = true);
                          try {
                            var refundId = '';
                            if (!approved) {
                              refundId = '';
                            } else if (decision == 'Receive returned item' &&
                                amount > 0 &&
                                refundDestination == 'Payment method') {
                              refundId = await widget.onCreateStripeRefund(
                                order,
                                amount,
                                refundReason.text.trim(),
                              );
                            } else if (decision == 'Receive returned item' &&
                                amount > 0 &&
                                refundDestination == 'Store credit') {
                              await _applyStoreCredit(order, amount);
                              refundId = 'Store credit';
                            }
                            order
                              ..returnStatus = !approved
                                  ? 'Return rejected'
                                  : decision == 'Receive returned item'
                                  ? 'Returned'
                                  : 'Awaiting return item'
                              ..returnCondition = condition.text.trim()
                              ..refundOption =
                                  '$refundOption • $refundDestination'
                              ..refundTotal = approved ? amount : 0
                              ..refundReason = refundReason.text.trim()
                              ..returnAdminComment = comments.text.trim()
                              ..refundStatus = !approved
                                  ? 'Refund denied'
                                  : decision == 'Receive returned item'
                                  ? amount >= order.total - 0.01
                                        ? 'Refunded'
                                        : 'Partially refunded'
                                  : 'Refund pending'
                              ..financialStatus =
                                  approved &&
                                      decision == 'Receive returned item' &&
                                      refundDestination == 'Payment method'
                                  ? amount >= order.total - 0.01
                                        ? 'Refunded'
                                        : 'Partially refunded'
                                  : order.financialStatus
                              ..refundReference = refundId
                              ..stripeRefundId =
                                  refundDestination == 'Payment method'
                                  ? refundId
                                  : ''
                              ..refundedAt =
                                  approved &&
                                      decision == 'Receive returned item' &&
                                      amount > 0
                                  ? DateTime.now()
                                  : order.refundedAt
                              ..returnRestocked = restockItems
                              ..returnedAt = decision == 'Receive returned item'
                                  ? DateTime.now()
                                  : order.returnedAt
                              ..rmaNumber = approved
                                  ? (order.rmaNumber.trim().isEmpty
                                        ? _newRmaNumber(order)
                                        : order.rmaNumber)
                                  : ''
                              ..rmaCreatedAt = approved
                                  ? order.rmaCreatedAt ?? DateTime.now()
                                  : null
                              ..returnDecisionAt = DateTime.now()
                              ..status = !approved
                                  ? order.status
                                  : decision == 'Receive returned item'
                                  ? 'Returned'
                                  : 'Awaiting return item'
                              ..fulfillmentStatus = !approved
                                  ? order.fulfillmentStatus
                                  : decision == 'Receive returned item'
                                  ? 'Delivered'
                                  : 'Awaiting return item';
                            await widget.onUpdateOrder(order);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Refund failed: $error'),
                                ),
                              );
                            }
                            setDialogState(() => processing = false);
                          }
                        },
                  icon: processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_turned_in_outlined),
                  label: Text(processing ? 'Saving' : 'Submit'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      condition.dispose();
      refundReason.dispose();
      specificAmount.dispose();
      comments.dispose();
    }
  }

  Future<void> _applyStoreCredit(Order order, double amount) async {
    final email = order.email.trim().toLowerCase();
    final customer = widget.customers.firstWhere(
      (item) => item.email.trim().toLowerCase() == email,
      orElse: () => CustomerAccount(
        id: email,
        name: order.customer,
        email: email,
        joinedDaysAgo: 0,
        orders: 0,
        lifetimeValue: 0,
        segment: 'Customer',
      ),
    );
    await widget.onSaveCustomer(
      customer.copyWith(referralCredits: customer.referralCredits + amount),
    );
  }

  Future<void> _applyBatchAction() async {
    switch (_batchAction) {
      case 'Print Invoice':
        _printInvoices();
        break;
      case 'Print Pack List':
        _printSelected();
        break;
      case 'Print label':
        await _printShippingLabels();
        break;
      case 'Sent':
        _batchStatus('Shipped', 'Sent');
        break;
      case 'Delivered':
        _batchStatus('Delivered', 'Delivered');
        break;
    }
  }

  String _buildPrintPacket(List<Order> orders) {
    final buffer = StringBuffer()
      ..writeln('EGBE ANOM PICK LIST')
      ..writeln('Orders: ${orders.length}')
      ..writeln('Generated: ${DateTime.now()}')
      ..writeln('')
      ..writeln('ORDER LIST');
    for (final order in orders) {
      buffer.writeln(
        '${order.id} | ${order.customer} | ${order.shippingPriority} | ${order.shippingCarrier} ${order.shippingService} | ${order.itemCount} item(s) | ${currency(order.total)}',
      );
    }
    for (final order in orders) {
      buffer
        ..writeln('')
        ..writeln('----------------------------------------')
        ..writeln('INVOICE / PACKING LIST')
        ..writeln(order.id)
        ..writeln('${order.customer} <${order.email}>')
        ..writeln(
          'Ship: ${order.shippingCarrier} ${order.shippingService} (${order.shippingPriority})',
        )
        ..writeln('Shipping paid: ${currency(order.shippingTotal)}')
        ..writeln('Status: Processing')
        ..writeln('')
        ..writeln('ITEMS');
      if (order.lines.isEmpty) {
        buffer.writeln('${order.itemCount} item(s) from order record');
      } else {
        for (final line in order.lines) {
          buffer.writeln(
            '${line.quantity} x ${line.sku} | ${line.product.name} • ${line.size} | ${line.product.itemLocation} | ${line.product.shippingSize(MeasurementSystem.standard)}',
          );
        }
      }
      buffer
        ..writeln('')
        ..writeln('Picker: ____________  Packed: ____________');
    }
    return buffer.toString();
  }

  String _buildStatusPacket(
    List<Order> orders,
    String fulfillmentStatus,
    String labelStatus,
  ) {
    final buffer = StringBuffer()
      ..writeln('Batch order update')
      ..writeln('Orders: ${orders.length}')
      ..writeln('Fulfillment: $fulfillmentStatus')
      ..writeln('Label: $labelStatus')
      ..writeln('');
    for (final order in orders) {
      buffer.writeln('${order.id} | ${order.customer} | ${order.email}');
    }
    return buffer.toString();
  }

  String _buildInvoicePacket(Order order) {
    final buffer = StringBuffer()
      ..writeln('EGBE ANOM INVOICE')
      ..writeln(order.id)
      ..writeln('${order.customer} <${order.email}>')
      ..writeln('Date: ${order.createdAt ?? DateTime.now()}')
      ..writeln('')
      ..writeln('ITEMS');
    if (order.lines.isEmpty) {
      buffer.writeln('${order.itemCount} item(s) from order record');
    } else {
      for (final line in order.lines) {
        buffer.writeln(
          '${line.quantity} x ${line.sku} | ${line.product.name} | ${currency(line.total)}',
        );
      }
    }
    buffer
      ..writeln('')
      ..writeln('Shipping: ${currency(order.shippingTotal)}')
      ..writeln('Total: ${currency(order.total)}')
      ..writeln('QR: https://egbeanom.com');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _visibleOrders;
    final allVisibleSelected =
        visibleOrders.isNotEmpty &&
        visibleOrders.every(
          (order) => _selectedOrderKeys.contains(_orderSelectionKey(order)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.inventory_outlined,
              'Pending',
              '${widget.orders.where((o) => AdminOrderWorkflow.workflowStatus(o) == 'Pending').length}',
            ),
            _MetricData(
              Icons.payments_outlined,
              'Unpaid',
              '${widget.orders.where((o) => AdminOrderWorkflow.paymentStatus(o) == 'Unpaid').length}',
            ),
            _MetricData(
              Icons.label_important_outline,
              'Label created',
              '${widget.orders.where((o) => AdminOrderWorkflow.workflowStatus(o) == 'Label created').length}',
            ),
            _MetricData(
              Icons.local_shipping_outlined,
              'Shipped',
              '${widget.orders.where((o) => AdminOrderWorkflow.workflowStatus(o) == 'Shipped').length}',
            ),
            _MetricData(
              Icons.assignment_return_outlined,
              'Return requests',
              '${widget.orders.where((o) => o.returnStatus == 'Return requested').length}',
            ),
            _MetricData(
              Icons.check_box_outlined,
              'Selected',
              '${_selectedOrderKeys.length}',
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _shippingFilter,
                        decoration: const InputDecoration(
                          labelText: 'Shipping type',
                        ),
                        items: [
                          for (final option in _shippingFilters)
                            DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => _shippingFilter = value ?? _shippingFilter,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Order status',
                        ),
                        items: [
                          for (final option in _statusFilters)
                            DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => _statusFilter = value ?? _statusFilter,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentFilter,
                        decoration: const InputDecoration(
                          labelText: 'Payment status',
                        ),
                        items: [
                          for (final option in _paymentFilters)
                            DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => _paymentFilter = value ?? _paymentFilter,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _selectedOrderKeys.isEmpty
                          ? null
                          : () => _applyBatchAction(),
                      icon: const Icon(Icons.task_alt_outlined),
                      label: Text(
                        _isApplyingBatchAction
                            ? 'Applying...'
                            : 'Apply to selected',
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _batchAction,
                        decoration: const InputDecoration(
                          labelText: 'Selected orders',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Print Invoice',
                            child: Text('Print Invoice'),
                          ),
                          DropdownMenuItem(
                            value: 'Print Pack List',
                            child: Text('Print Pack List'),
                          ),
                          DropdownMenuItem(
                            value: 'Print label',
                            child: Text('Print label'),
                          ),
                          DropdownMenuItem(value: 'Sent', child: Text('Sent')),
                          DropdownMenuItem(
                            value: 'Delivered',
                            child: Text('Delivered'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _batchAction = value ?? _batchAction,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: allVisibleSelected,
                  onChanged: _toggleAll,
                  title: Text(
                    'Select all visible orders (${visibleOrders.length})',
                  ),
                ),
                const Divider(),
                for (final order in visibleOrders)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: _selectedOrderKeys.contains(
                        _orderSelectionKey(order),
                      ),
                      onChanged: (value) {
                        final key = _orderSelectionKey(order);
                        setState(() {
                          if (value == true) {
                            _selectedOrderKeys.add(key);
                          } else {
                            _selectedOrderKeys.remove(key);
                          }
                        });
                      },
                    ),
                    title: Text('${order.id} • ${order.customer}'),
                    subtitle: Text(
                      '${AdminOrderWorkflow.paymentStatus(order)} • ${AdminOrderWorkflow.shippingType(order)} • ${order.shippingCarrier} ${order.shippingService} • ${AdminOrderWorkflow.workflowStatus(order)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currency(order.total)),
                        Text(
                          AdminOrderWorkflow.paymentStatus(order),
                          style: TextStyle(
                            color: AdminOrderWorkflow.isPaid(order)
                                ? const Color(0xFF27724E)
                                : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                        ),
                        title: const Text('Customer'),
                        subtitle: Text(order.email),
                      ),
                      if (order.lines.isNotEmpty)
                        for (final line in order.lines)
                          ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 8,
                            ),
                            title: Text(line.product.name),
                            subtitle: Text(
                              '${line.quantity} x ${currency(line.unitPrice)} • ${line.size} • ${line.product.itemLocation}',
                            ),
                            trailing: Text(currency(line.total)),
                          ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (order.returnStatus == 'Return requested' ||
                                    order.returnStatus ==
                                        'Awaiting return item' ||
                                    order.returnStatus == 'Return approved')
                                  FilledButton.icon(
                                    onPressed: () =>
                                        _showReturnDecisionDialog(order),
                                    icon: const Icon(
                                      Icons.assignment_turned_in_outlined,
                                    ),
                                    label: Text(
                                      order.returnStatus == 'Return requested'
                                          ? 'Review return request'
                                          : 'Review return / refund',
                                    ),
                                  ),
                              ],
                            ),
                            if (order.returnStatus != 'No return') ...[
                              const SizedBox(height: 10),
                              _ReturnSummaryPanel(order: order),
                            ],
                            const SizedBox(height: 12),
                            _OrderFulfillmentEditor(
                              order: order,
                              onSave: widget.onUpdateOrder,
                              onCreateShippingLabel:
                                  widget.onCreateShippingLabel,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_printPacket.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Printable batch packet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _printPacket,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InvoicesSection extends StatefulWidget {
  const _InvoicesSection({
    required this.orders,
    required this.storeInfo,
    required this.siteStatus,
    required this.onUpdateOrder,
  });

  final List<Order> orders;
  final StoreInfo storeInfo;
  final SiteStatus siteStatus;
  final AsyncValueChanged<Order> onUpdateOrder;

  @override
  State<_InvoicesSection> createState() => _InvoicesSectionState();
}

class _InvoicesSectionState extends State<_InvoicesSection> {
  Order? _selected;
  final _footer = TextEditingController(
    text: 'Thank you for choosing EgbeAnom.',
  );

  @override
  void dispose() {
    _footer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 920;
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
                        'Invoice editor',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _footer,
                        decoration: const InputDecoration(
                          labelText: 'Invoice footer',
                        ),
                        minLines: 2,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      if (widget.orders.isEmpty)
                        const Text('No orders available for invoices.')
                      else
                        for (final order in widget.orders)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            selected: selected == order,
                            title: Text(order.id),
                            subtitle: Text(order.customer),
                            trailing: Text(currency(order.total)),
                            onTap: () => setState(() => _selected = order),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: selected == null
                      ? const _EmptyState(
                          icon: Icons.description_outlined,
                          title: 'Select an order',
                          body:
                              'Choose an order to preview, print, and confirm invoice copy.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InvoiceDocumentPreview(
                              order: selected,
                              storeInfo: widget.storeInfo,
                              thankYouText: _footer.text,
                              returnPolicyText: widget.siteStatus.returnPolicy,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () {
                                selected
                                  ..status = 'Invoice created'
                                  ..fulfillmentStatus = 'Invoice created';
                                widget.onUpdateOrder(selected);
                                printHtmlDocument(
                                  'Invoice ${selected.id}',
                                  _invoiceHtml(
                                    selected,
                                    widget.storeInfo,
                                    thankYouText: _footer.text,
                                    returnPolicyText:
                                        widget.siteStatus.returnPolicy,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.print_outlined),
                              label: const Text('Print invoice'),
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

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews, required this.onUpdateReview});

  final List<ReviewSummary> reviews;
  final Future<void> Function(ReviewSummary review, String status)
  onUpdateReview;

  @override
  Widget build(BuildContext context) {
    final pending = reviews
        .where((review) => review.status == 'pending')
        .length;
    return Column(
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(Icons.rate_review_outlined, 'Pending', '$pending'),
            _MetricData(
              Icons.verified_outlined,
              'Approved',
              '${reviews.where((r) => r.status == 'approved').length}',
            ),
            _MetricData(
              Icons.block_outlined,
              'Rejected',
              '${reviews.where((r) => r.status == 'rejected').length}',
            ),
            _MetricData(Icons.reviews_outlined, 'Total', '${reviews.length}'),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final review in reviews)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      review.status == 'approved'
                          ? Icons.verified_outlined
                          : Icons.rate_review_outlined,
                    ),
                    title: Text(
                      '${review.title} • ${review.rating.toStringAsFixed(1)}',
                    ),
                    subtitle: Text(
                      '${review.scope} • ${review.author} • ${review.status}\n${review.body}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Approve',
                          onPressed: () => onUpdateReview(review, 'approved'),
                          icon: const Icon(Icons.check),
                        ),
                        IconButton.outlined(
                          tooltip: 'Delete',
                          onPressed: () => onUpdateReview(review, 'delete'),
                          icon: const Icon(Icons.delete_outline),
                        ),
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

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection({
    required this.notifications,
    required this.onNotificationRead,
    required this.onNotificationOpen,
  });

  final List<StoreNotification> notifications;
  final ValueChanged<StoreNotification> onNotificationRead;
  final ValueChanged<StoreNotification> onNotificationOpen;

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  StoreNotification? _selected;

  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (notifications.isEmpty)
              const Text('No notifications yet.')
            else
              for (final item in notifications)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.type == 'order'
                        ? Icons.shopping_bag_outlined
                        : item.type == 'return'
                        ? Icons.assignment_return_outlined
                        : item.type == 'email'
                        ? Icons.outgoing_mail
                        : Icons.notifications_outlined,
                    color: const Color(0xFFC88F52),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                  selected: _selected == item,
                  onTap: () {
                    setState(() {
                      _selected = item;
                    });
                    widget.onNotificationRead(item);
                    widget.onNotificationOpen(item);
                  },
                  trailing: Text(
                    '${item.createdAt.month}/${item.createdAt.day} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                ),
            if (_selected != null) ...[
              const Divider(),
              Text(
                _selected!.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(_selected!.message),
              const SizedBox(height: 6),
              Text(_selected!.isRead ? 'Read' : 'Unread'),
            ],
          ],
        ),
      ),
    );
  }
}
