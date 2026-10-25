/// Where each recipe photo comes from. Unsplash and Pexels photos don't
/// require credit, but we give it anyway; the Wikimedia Commons photos are
/// CC BY-SA, which does require it (and the resized copies in
/// assets/images/recipes are shared under the same licence).
library;

enum PhotoLicense {
  unsplash('Unsplash License', 'https://unsplash.com/license'),
  pexels('Pexels License', 'https://www.pexels.com/license/'),
  ccBySa20('CC BY-SA 2.0', 'https://creativecommons.org/licenses/by-sa/2.0/'),
  ccBySa40('CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0/');

  const PhotoLicense(this.label, this.url);

  final String label;
  final String url;
}

class PhotoCredit {
  const PhotoCredit(this.author, this.license, this.source);

  final String author;
  final PhotoLicense license;

  /// The photo's page on its source site.
  final String source;
}

/// Credits by recipe id.
const Map<String, PhotoCredit> photoCredits = {
  'paneer_bhurji': PhotoCredit(
    'Maskaravivek',
    PhotoLicense.ccBySa40,
    'https://commons.wikimedia.org/wiki/File:Homemade_Paneer_Bhurji.jpg',
  ),
  'tomato_paneer_masala': PhotoCredit(
    'Dhiraj Jain',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/12737805/',
  ),
  'quick_paneer_wrap': PhotoCredit(
    'Kunal Lakhotia',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/29173104/',
  ),
  'jeera_aloo': PhotoCredit(
    'Surabhi Siddaiah',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/1051399/',
  ),
  'aloo_gobi': PhotoCredit(
    'やましこ',
    PhotoLicense.ccBySa20,
    'https://commons.wikimedia.org/wiki/File:Aloo_Gobi_Matar_(49653225183).jpg',
  ),
  'bhindi_masala': PhotoCredit(
    'Zoshua Colah',
    PhotoLicense.unsplash,
    'https://unsplash.com/photos/sauteed-okra-with-chili-and-onion-ZCCKQn0F81Q',
  ),
  'dal_tadka': PhotoCredit(
    'Nosh Caterers',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/30203314/',
  ),
  'chana_masala': PhotoCredit(
    'Zoshua Colah',
    PhotoLicense.unsplash,
    'https://unsplash.com/photos/chana-masala-with-fried-bhatura-bread-Idh9dnG2v8w',
  ),
  'rajma': PhotoCredit(
    'Dhiraj Jain',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/12737912/',
  ),
  'veg_pulao': PhotoCredit(
    'dhruvrchauhan',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/12669168/',
  ),
  'lemon_rice': PhotoCredit(
    'Shiva Kumar',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/4595316/',
  ),
  'veg_fried_rice': PhotoCredit(
    'I Own My Food Art',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/8992927/',
  ),
  'masala_omelette': PhotoCredit(
    'saveurssecretes',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/5769256/',
  ),
  'egg_curry': PhotoCredit(
    'drmkhawarnazir',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/40247278/',
  ),
  'chicken_curry': PhotoCredit(
    'Kalindu Waranga',
    PhotoLicense.unsplash,
    'https://unsplash.com/photos/chicken-curry-in-a-white-bowl-with-sauce-VtNLbOAeO68',
  ),
  'poha': PhotoCredit(
    'Zoshua Colah',
    PhotoLicense.unsplash,
    'https://unsplash.com/photos/poha-breakfast-with-peanuts-and-lime-_yxndM0wO8c',
  ),
  'upma': PhotoCredit(
    'Jack Baghel',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/20408458/',
  ),
  'besan_chilla': PhotoCredit(
    'Mdsmds0',
    PhotoLicense.ccBySa40,
    'https://commons.wikimedia.org/wiki/File:Gram_flour_Chilla_(Besan_ka_Cheela).JPG',
  ),
  'masala_maggi': PhotoCredit(
    'Deep Dasgupta',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/31109619/',
  ),
  'grilled_sandwich': PhotoCredit(
    'Kunal Lakhotia',
    PhotoLicense.pexels,
    'https://www.pexels.com/photo/29699515/',
  ),
};
