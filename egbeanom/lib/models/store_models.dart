part of '../main.dart';

enum StoreView {
  shop,
  catalog,
  detail,
  cart,
  checkout,
  account,
  info,
  admin,
  paymentSuccess,
  paymentFailure,
}

enum StoreInfoPage {
  notes,
  ingredients,
  brandProfile,
  recommendations,
  ratings,
  wishlist,
  collections,
  contact,
}

enum MeasurementSystem { standard, metric }

extension MeasurementSystemLabel on MeasurementSystem {
  String get label => this == MeasurementSystem.metric ? 'Metric' : 'Standard';
}
