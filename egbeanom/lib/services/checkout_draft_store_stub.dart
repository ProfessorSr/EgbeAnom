Map<String, dynamic>? _draft;

void savePendingCheckoutDraft(Map<String, dynamic> draft) {
  _draft = Map<String, dynamic>.from(draft);
}

Map<String, dynamic>? loadPendingCheckoutDraft() {
  final draft = _draft;
  if (draft == null) {
    return null;
  }
  return Map<String, dynamic>.from(draft);
}

void clearPendingCheckoutDraft() {
  _draft = null;
}