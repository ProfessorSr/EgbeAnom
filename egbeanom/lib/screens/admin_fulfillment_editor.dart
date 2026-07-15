part of '../main.dart';

class _OrderFulfillmentEditor extends StatefulWidget {
  const _OrderFulfillmentEditor({
    required this.order,
    required this.onSave,
    required this.onCreateShippingLabel,
  });

  final Order order;
  final AsyncValueChanged<Order> onSave;
  final Future<ShippingLabelResult> Function(Order order) onCreateShippingLabel;

  @override
  State<_OrderFulfillmentEditor> createState() =>
      _OrderFulfillmentEditorState();
}

class _OrderFulfillmentEditorState extends State<_OrderFulfillmentEditor> {
  late TextEditingController _tracking;
  late TextEditingController _refundAmount;
  late TextEditingController _refundReference;
  late TextEditingController _refundReason;
  late TextEditingController _returnReason;
  late TextEditingController _returnAdminComment;
  late TextEditingController _rmaNumber;
  late String _status;
  late String _financialStatus;
  late String _returnStatus;
  late bool _returnRestocked;
  late String _carrier;
  late String _service;
  late String _labelStatus;
  bool _creatingLabel = false;

  @override
  void initState() {
    super.initState();
    _status = _normalizedStatus(widget.order.fulfillmentStatus);
    _financialStatus = _normalizedFinancialStatus(widget.order.financialStatus);
    _carrier = widget.order.shippingCarrier.isEmpty
        ? 'USPS'
        : widget.order.shippingCarrier;
    _service = widget.order.shippingService.isEmpty
        ? 'Ground Advantage'
        : widget.order.shippingService;
    _labelStatus = widget.order.labelStatus;
    _tracking = TextEditingController(text: widget.order.trackingNumber);
    _refundAmount = TextEditingController(
      text: widget.order.refundTotal > 0
          ? widget.order.refundTotal.toStringAsFixed(2)
          : '',
    );
    _refundReference = TextEditingController(
      text: widget.order.refundReference,
    );
    _refundReason = TextEditingController(text: widget.order.refundReason);
    _returnStatus = widget.order.returnStatus.trim().isEmpty
        ? 'No return'
        : widget.order.returnStatus;
    _returnRestocked = widget.order.returnRestocked;
    _returnReason = TextEditingController(text: widget.order.returnReason);
    _returnAdminComment = TextEditingController(
      text: widget.order.returnAdminComment,
    );
    _rmaNumber = TextEditingController(text: widget.order.rmaNumber);
  }

  String _normalizedStatus(String value) {
    final status = value.toLowerCase();
    if (status == 'delivered') {
      return 'Delivered';
    }
    if (status == 'sent' || status == 'shipped') {
      return 'Shipped';
    }
    if (status == 'label printed' ||
        status == 'label created' ||
        status == 'label_created') {
      return 'Label created';
    }
    if (status == 'awaiting return item') {
      return 'Awaiting return item';
    }
    if (status == 'invoice created' || status == 'invoice_created') {
      return 'Invoice created';
    }
    if (status == 'processing' ||
        status == 'being picked' ||
        status == 'packing') {
      return 'Processing';
    }
    if (status == 'cancelled') {
      return 'Cancelled';
    }
    return 'Pending';
  }

  String _normalizedFinancialStatus(String value) {
    final status = value.toLowerCase().replaceAll('_', ' ');
    if (status == 'paid') {
      return 'Paid';
    }
    if (status == 'partially refunded') {
      return 'Partially refunded';
    }
    if (status == 'refunded') {
      return 'Refunded';
    }
    return 'Unpaid';
  }

  @override
  void dispose() {
    _tracking.dispose();
    _refundAmount.dispose();
    _refundReference.dispose();
    _refundReason.dispose();
    _returnReason.dispose();
    _returnAdminComment.dispose();
    _rmaNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paid =
        widget.order.financialStatus.trim().toLowerCase() == 'paid' ||
        widget.order.status.trim().toLowerCase() == 'paid';
    final lockedForFulfillment =
        widget.order.status.trim().toLowerCase() == 'cancelled' ||
        widget.order.status.trim().toLowerCase() == 'refunded' ||
        _financialStatus == 'Refunded';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Order status'),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'Processing',
                    child: Text('Processing'),
                  ),
                  DropdownMenuItem(
                    value: 'Invoice created',
                    child: Text('Invoice created'),
                  ),
                  DropdownMenuItem(
                    value: 'Label created',
                    child: Text('Label created'),
                  ),
                  DropdownMenuItem(
                    value: 'Awaiting return item',
                    child: Text('Awaiting return item'),
                  ),
                  DropdownMenuItem(value: 'Sent', child: Text('Sent')),
                  DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                  DropdownMenuItem(
                    value: 'Delivered',
                    child: Text('Delivered'),
                  ),
                  DropdownMenuItem(
                    value: 'Cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _carrier,
                decoration: const InputDecoration(labelText: 'Carrier'),
                items: const [
                  DropdownMenuItem(value: 'USPS', child: Text('USPS')),
                  DropdownMenuItem(value: 'UPS', child: Text('UPS')),
                  DropdownMenuItem(value: 'FedEx', child: Text('FedEx')),
                  DropdownMenuItem(value: 'DHL', child: Text('DHL')),
                ],
                onChanged: (value) =>
                    setState(() => _carrier = value ?? _carrier),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _financialStatus,
                decoration: const InputDecoration(labelText: 'Payment status'),
                items: const [
                  DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(
                    value: 'Partially refunded',
                    child: Text('Partially refunded'),
                  ),
                  DropdownMenuItem(value: 'Refunded', child: Text('Refunded')),
                ],
                onChanged: (value) => setState(
                  () => _financialStatus = value ?? _financialStatus,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _refundAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Refund amount'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _refundReference,
                decoration: const InputDecoration(
                  labelText: 'Refund reference',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _refundReason,
                decoration: const InputDecoration(labelText: 'Refund reason'),
              ),
            ),
          ],
        ),
        if (_financialStatus == 'Refunded') ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Full refunds automatically return the order items to inventory once.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _returnStatus,
                decoration: const InputDecoration(labelText: 'Return / RMA'),
                items: const [
                  DropdownMenuItem(
                    value: 'No return',
                    child: Text('No return'),
                  ),
                  DropdownMenuItem(
                    value: 'Return requested',
                    child: Text('Return requested'),
                  ),
                  DropdownMenuItem(
                    value: 'Return approved',
                    child: Text('Return approved'),
                  ),
                  DropdownMenuItem(
                    value: 'Awaiting return item',
                    child: Text('Awaiting return item'),
                  ),
                  DropdownMenuItem(value: 'Returned', child: Text('Returned')),
                  DropdownMenuItem(
                    value: 'Return rejected',
                    child: Text('Return rejected'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _returnStatus = value ?? _returnStatus),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _returnRestocked,
                title: const Text('Restock returned items'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: _returnStatus == 'No return'
                    ? null
                    : (value) =>
                          setState(() => _returnRestocked = value ?? false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _returnReason,
          decoration: const InputDecoration(labelText: 'Customer return note'),
          readOnly: widget.order.returnStatus == 'Return requested',
          minLines: 1,
          maxLines: 3,
        ),
        if (widget.order.returnItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Requested return items',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 4),
          for (final item in widget.order.returnItems)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_return_outlined),
              title: Text(item.productName),
              subtitle: Text('${item.quantity} x ${item.size} • ${item.sku}'),
              trailing: Text(currency(item.total)),
            ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rmaNumber,
                decoration: const InputDecoration(labelText: 'RMA number'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _returnAdminComment,
                decoration: const InputDecoration(
                  labelText: 'Admin return decision comment',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _service,
                decoration: const InputDecoration(labelText: 'Service'),
                items: const [
                  DropdownMenuItem(
                    value: 'Ground Advantage',
                    child: Text('Ground Advantage'),
                  ),
                  DropdownMenuItem(
                    value: 'Priority Mail',
                    child: Text('Priority Mail'),
                  ),
                  DropdownMenuItem(value: 'Ground', child: Text('Ground')),
                  DropdownMenuItem(value: '2 Day', child: Text('2 Day')),
                  DropdownMenuItem(value: 'Express', child: Text('Express')),
                ],
                onChanged: (value) =>
                    setState(() => _service = value ?? _service),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _tracking,
                decoration: const InputDecoration(labelText: 'Tracking number'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _creatingLabel
                    ? null
                    : lockedForFulfillment
                    ? null
                    : !paid
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        widget.order.shippingCarrier = _carrier;
                        setState(() => _creatingLabel = true);
                        try {
                          final label = await widget.onCreateShippingLabel(
                            widget.order,
                          );
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _tracking.text = label.trackingNumber;
                            _labelStatus = 'Label created';
                            _status = 'Label created';
                            _service = widget.order.shippingService.isEmpty
                                ? _service
                                : widget.order.shippingService;
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                label.trackingNumber.trim().isNotEmpty
                                    ? '${_carrier.toUpperCase()} label created for ${label.trackingNumber}.'
                                    : '${_carrier.toUpperCase()} address label created (no postage).',
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text('$error')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _creatingLabel = false);
                          }
                        }
                      },
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(
                  !paid
                      ? 'Payment required'
                      : lockedForFulfillment
                      ? 'Fulfillment locked'
                      : _creatingLabel
                      ? 'Creating label'
                      : 'Create label',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  final refundTotal =
                      double.tryParse(_refundAmount.text.trim()) ?? 0;
                  final refundStatus = switch (_financialStatus) {
                    'Refunded' => 'Refunded',
                    'Partially refunded' => 'Partially refunded',
                    _ => 'Not refunded',
                  };
                  final previousReturnStatus = widget.order.returnStatus;
                  final needsRma =
                      _returnStatus == 'Return approved' ||
                      _returnStatus == 'Awaiting return item';
                  final rmaNumber = needsRma
                      ? (_rmaNumber.text.trim().isEmpty
                            ? 'RMA-${widget.order.id}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
                            : _rmaNumber.text.trim())
                      : _rmaNumber.text.trim();
                  widget.order
                    ..financialStatus = _financialStatus
                    ..refundStatus = refundStatus
                    ..refundTotal = refundStatus == 'Not refunded'
                        ? 0
                        : refundTotal
                    ..refundReference = refundStatus == 'Not refunded'
                        ? ''
                        : _refundReference.text.trim()
                    ..refundReason = refundStatus == 'Not refunded'
                        ? ''
                        : _refundReason.text.trim()
                    ..refundedAt = refundStatus == 'Not refunded'
                        ? null
                        : widget.order.refundedAt ?? DateTime.now()
                    ..returnStatus = _returnStatus
                    ..returnReason = _returnStatus == 'No return'
                        ? ''
                        : _returnReason.text.trim()
                    ..returnAdminComment = _returnStatus == 'No return'
                        ? ''
                        : _returnAdminComment.text.trim()
                    ..rmaNumber = _returnStatus == 'No return' ? '' : rmaNumber
                    ..rmaCreatedAt =
                        needsRma && widget.order.rmaCreatedAt == null
                        ? DateTime.now()
                        : widget.order.rmaCreatedAt
                    ..returnDecisionAt =
                        previousReturnStatus != _returnStatus &&
                            (_returnStatus == 'Return approved' ||
                                _returnStatus == 'Awaiting return item' ||
                                _returnStatus == 'Return rejected')
                        ? DateTime.now()
                        : widget.order.returnDecisionAt
                    ..returnRestocked = _returnStatus != 'Returned'
                        ? false
                        : _returnRestocked
                    ..returnedAt = _returnStatus == 'Returned'
                        ? widget.order.returnedAt ?? DateTime.now()
                        : null
                    ..status = _financialStatus == 'Refunded'
                        ? 'Refunded'
                        : _status == 'Cancelled'
                        ? 'Cancelled'
                        : _status == 'Pending'
                        ? 'Paid'
                        : _status == 'Sent'
                        ? 'Shipped'
                        : _status
                    ..fulfillmentStatus = _status == 'Cancelled'
                        ? 'Cancelled'
                        : _financialStatus == 'Refunded'
                        ? 'Cancelled'
                        : _status
                    ..shippingCarrier = _carrier
                    ..shippingService = _service
                    ..trackingNumber = _tracking.text.trim()
                    ..labelStatus = _status == 'Label created'
                        ? 'Label created'
                        : _labelStatus;
                  widget.onSave(widget.order);
                },
                icon: const Icon(Icons.save_outlined),
                label: Text('Save • $_labelStatus'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
