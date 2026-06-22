part of '../main.dart';

List<CustomerAccount> buildSeedCustomers() {
  return [];
}

List<DailyMetric> buildSeedDailyMetrics() {
  return const [];
}

List<NewsItem> buildSeedNewsItems() {
  return const [];
}

List<ShippingOption> buildSeedShippingOptions() {
  return [
    ShippingOption(
      id: 'ship-usps-ground',
      name: 'Standard shipping',
      carrier: 'USPS',
      service: 'Ground Advantage',
      priority: 'Standard',
      price: 7.95,
      estimatedDays: '3-5 business days',
      sortOrder: 10,
    ),
    ShippingOption(
      id: 'ship-ups-ground',
      name: 'UPS ground',
      carrier: 'UPS',
      service: 'Ground',
      priority: 'Standard',
      price: 9.95,
      estimatedDays: '3-5 business days',
      sortOrder: 20,
    ),
    ShippingOption(
      id: 'ship-fedex-express',
      name: 'Express shipping',
      carrier: 'FedEx',
      service: '2 Day',
      priority: 'Express',
      price: 18.95,
      estimatedDays: '1-2 business days',
      sortOrder: 30,
    ),
  ];
}

List<FragranceNoteGuide> buildSeedNoteGuide() {
  return const [
    FragranceNoteGuide(
      name: 'Bergamot',
      tier: 'Top',
      family: 'Citrus',
      description:
          'Bright, sparkling citrus with a lightly floral bitterness. Often used to make an opening feel clean and refined.',
      pairings: 'Neroli, lavender, black tea, vetiver, cedar.',
    ),
    FragranceNoteGuide(
      name: 'Mandarin',
      tier: 'Top',
      family: 'Citrus',
      description:
          'Sweet orange-citrus character that reads juicy, cheerful, and easy to wear.',
      pairings: 'Neroli, jasmine, musk, vanilla, amber.',
    ),
    FragranceNoteGuide(
      name: 'Lavender',
      tier: 'Top / Heart',
      family: 'Aromatic',
      description:
          'Fresh herbal floral note used in fougeres, clean colognes, and calming blends.',
      pairings: 'Bergamot, mint, tonka, oakmoss, woods.',
    ),
    FragranceNoteGuide(
      name: 'Rose',
      tier: 'Heart',
      family: 'Floral',
      description:
          'Classic floral note ranging from dewy petals to jammy, spicy, or velvety facets.',
      pairings: 'Lychee, patchouli, oud, musk, amber.',
    ),
    FragranceNoteGuide(
      name: 'Jasmine',
      tier: 'Heart',
      family: 'White floral',
      description:
          'Radiant floral note with creamy, fruity, and indolic depth. Adds diffusion and elegance.',
      pairings: 'Orange blossom, sandalwood, vanilla, musk.',
    ),
    FragranceNoteGuide(
      name: 'Iris',
      tier: 'Heart',
      family: 'Powdery floral',
      description:
          'Soft, cosmetic, powdery effect that can feel elegant, cool, woody, or suede-like.',
      pairings: 'Violet, cedar, musk, leather, vanilla.',
    ),
    FragranceNoteGuide(
      name: 'Sandalwood',
      tier: 'Heart / Base',
      family: 'Wood',
      description:
          'Creamy, smooth wood note used for warmth, comfort, and long-lasting texture.',
      pairings: 'Iris, rose, coconut, amber, musk.',
    ),
    FragranceNoteGuide(
      name: 'Vetiver',
      tier: 'Base',
      family: 'Earthy wood',
      description:
          'Dry grassy root note that can smell smoky, mineral, green, nutty, or elegant.',
      pairings: 'Citrus, pepper, cedar, grapefruit, cardamom.',
    ),
    FragranceNoteGuide(
      name: 'Amber',
      tier: 'Base',
      family: 'Amber / resin',
      description:
          'Warm, sweet resinous accord that gives depth, glow, and a lingering dry-down.',
      pairings: 'Vanilla, labdanum, benzoin, woods, spice.',
    ),
    FragranceNoteGuide(
      name: 'Musk',
      tier: 'Base',
      family: 'Soft / skin',
      description:
          'Clean, soft, skin-like foundation used to smooth a fragrance and extend wear.',
      pairings: 'White florals, citrus, amber, woods, cotton notes.',
    ),
    FragranceNoteGuide(
      name: 'Oud',
      tier: 'Base',
      family: 'Resinous wood',
      description:
          'Dense woody note that can feel smoky, leathery, medicinal, animalic, or luxurious.',
      pairings: 'Rose, saffron, amber, incense, sandalwood.',
    ),
    FragranceNoteGuide(
      name: 'Vanilla',
      tier: 'Base',
      family: 'Gourmand',
      description:
          'Sweet creamy note that brings comfort, warmth, and softness to florals, ambers, and woods.',
      pairings: 'Tonka, caramel, sandalwood, citrus, tobacco.',
    ),
    FragranceNoteGuide(
      name: 'Orange blossom',
      tier: 'Heart',
      family: 'White floral',
      description:
          'Clean white floral with honeyed citrus facets, often brighter and softer than jasmine.',
      pairings: 'Neroli, petitgrain, musk, vanilla, amber.',
    ),
    FragranceNoteGuide(
      name: 'Patchouli',
      tier: 'Base',
      family: 'Earthy wood',
      description:
          'Earthy, woody, camphoraceous note that can feel chocolatey, damp, dry, or polished.',
      pairings: 'Rose, amber, vanilla, incense, citrus.',
    ),
    FragranceNoteGuide(
      name: 'Cedarwood',
      tier: 'Base',
      family: 'Dry wood',
      description:
          'Pencil-dry woody note used for structure, clarity, and a clean tailored finish.',
      pairings: 'Iris, vetiver, grapefruit, leather, musk.',
    ),
    FragranceNoteGuide(
      name: 'Tonka bean',
      tier: 'Base',
      family: 'Gourmand',
      description:
          'Warm coumarin-rich note with almond, hay, tobacco, and vanilla-like facets.',
      pairings: 'Lavender, vanilla, tobacco, amber, woods.',
    ),
    FragranceNoteGuide(
      name: 'Leather',
      tier: 'Base',
      family: 'Animalic / smoky',
      description:
          'Textural accord that may read suede, smoky, tarry, polished, or quietly animalic.',
      pairings: 'Iris, saffron, oud, birch, musk.',
    ),
    FragranceNoteGuide(
      name: 'Fig',
      tier: 'Top / Heart',
      family: 'Green fruity',
      description:
          'Milky green fruit note with leafy, woody, coconut, and sun-warmed skin effects.',
      pairings: 'Coconut, cedar, sandalwood, iris, citrus.',
    ),
    FragranceNoteGuide(
      name: 'Saffron',
      tier: 'Top / Heart',
      family: 'Spice',
      description:
          'Dry leathery spice with airy warmth, often used to lift amber woods and oud.',
      pairings: 'Oud, rose, amber, leather, woods.',
    ),
    FragranceNoteGuide(
      name: 'Oakmoss',
      tier: 'Base',
      family: 'Chypre',
      description:
          'Forest-floor, mossy, slightly salty note that gives classic structure and shadow.',
      pairings: 'Bergamot, rose, patchouli, vetiver, labdanum.',
    ),
  ];
}

List<IngredientGuide> buildSeedIngredientGuide() {
  return const [
    IngredientGuide(
      name: 'Alcohol denat.',
      profile:
          'Common carrier for spray perfumes. It helps fragrance disperse quickly and dry cleanly on skin.',
      role: 'Solvent and diffusion carrier.',
      safety:
          'Flammable. Avoid heat/flame and avoid spraying near eyes or irritated skin.',
    ),
    IngredientGuide(
      name: 'Fragrance accord',
      profile:
          'A blended aromatic composition made from natural materials, aroma molecules, or both.',
      role: 'Defines the character of the finished scent.',
      safety:
          'Review supplier allergen and IFRA documentation before production.',
    ),
    IngredientGuide(
      name: 'Carrier oil',
      profile:
          'Skin-friendly base used for body oils and roll-ons, often chosen for glide and feel.',
      role: 'Dilutes aromatic concentrate and supports skin application.',
      safety: 'Patch testing is recommended, especially for sensitive skin.',
    ),
    IngredientGuide(
      name: 'Essential oil',
      profile:
          'Volatile aromatic material extracted from botanicals such as citrus peel, lavender, or woods.',
      role: 'Adds natural aromatic facets and complexity.',
      safety:
          'Some essential oils can be sensitizing or phototoxic depending on material and level.',
    ),
    IngredientGuide(
      name: 'Aroma molecule',
      profile:
          'Isolated or synthesized fragrance material used for precision, stability, and modern effects.',
      role:
          'Builds notes such as clean musk, amber woods, marine effects, or transparent florals.',
      safety: 'Use within approved supplier and regulatory limits.',
    ),
    IngredientGuide(
      name: 'Fixative',
      profile:
          'Material that slows evaporation and helps the dry-down last longer.',
      role: 'Improves longevity and anchors volatile top notes.',
      safety: 'Must be compatible with formula type and intended skin use.',
    ),
    IngredientGuide(
      name: 'Distilled water',
      profile:
          'Purified water used in some sprays, lotions, and rinse-off products to adjust texture.',
      role: 'Formula diluent and texture support.',
      safety: 'Use preserved systems and clean production practices.',
    ),
    IngredientGuide(
      name: 'Glycerin',
      profile:
          'Clear humectant that helps retain moisture and soften the feel of skin products.',
      role: 'Skin feel and humectancy.',
      safety: 'Generally well tolerated, but high levels can feel sticky.',
    ),
    IngredientGuide(
      name: 'Jojoba oil',
      profile:
          'Liquid wax ester with a light glide commonly used in roll-ons and body oils.',
      role: 'Carrier for oil-based fragrance formats.',
      safety: 'Patch testing is recommended for new formulas.',
    ),
    IngredientGuide(
      name: 'Solubilizer',
      profile:
          'Ingredient that helps fragrance oils disperse more evenly in water-based products.',
      role: 'Clarity and dispersion support.',
      safety: 'Use supplier guidance for level and skin compatibility.',
    ),
    IngredientGuide(
      name: 'Preservative system',
      profile:
          'Blend chosen to protect water-containing products from microbial growth.',
      role: 'Product safety and shelf stability.',
      safety: 'Match to pH, format, and regulatory market requirements.',
    ),
    IngredientGuide(
      name: 'Vitamin E',
      profile:
          'Antioxidant often used to support oils against oxidation and rancid odor shifts.',
      role: 'Oil stability support.',
      safety: 'Not a preservative for water-based contamination control.',
    ),
  ];
}

List<ReviewSummary> buildSeedProductReviews() {
  return [];
}

List<ReviewSummary> buildSeedCompanyReviews() {
  return [
    ReviewSummary(
      id: 9001,
      author: 'Verified buyer',
      rating: 5,
      title: 'Fast shipping and strong projection',
      body:
          'The order arrived quickly and the scent lasted through the evening.',
      scope: 'company',
      status: 'pending',
    ),
    ReviewSummary(
      id: 9002,
      author: 'Anonymous',
      rating: 4,
      title: 'Nice presentation',
      body: 'Packaging felt premium and the bottle looked gift-ready.',
      scope: 'company',
      status: 'pending',
    ),
    ReviewSummary(
      id: 9003,
      author: 'Marissa J.',
      rating: 5,
      title: 'Great customer experience',
      body: 'Checkout was clear and the confirmation email had what I needed.',
      scope: 'company',
      status: 'pending',
    ),
    ReviewSummary(
      id: 9004,
      author: 'Anonymous',
      rating: 4,
      title: 'Would order again',
      body:
          'The fragrance was richer than expected and the ordering flow was smooth.',
      scope: 'company',
      status: 'pending',
    ),
    ReviewSummary(
      id: 9005,
      author: 'D. Carter',
      rating: 5,
      title: 'Excellent oil concentration',
      body: 'The scent stayed noticeable without needing a lot of sprays.',
      scope: 'company',
      status: 'pending',
    ),
  ];
}

List<BrandProfile> buildSeedBrands() {
  return [
    BrandProfile(
      id: 1,
      name: 'EgbeAnom',
      description:
          'A single-house fragrance catalog of perfumes, colognes, and body oils.',
      country: 'US',
      history:
          'EgbeAnom is built around one fragrance house and one catalog experience. Each scent belongs to the same brand story, from everyday body oils to gift-ready perfumes and colognes.',
      foundedYear: 2026,
      sortOrder: 1,
    ),
  ];
}
