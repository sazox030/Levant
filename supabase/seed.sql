-- Mashriq Editions — seed data
-- Run after schema.sql. Idempotent via ON CONFLICT upserts.
--
-- Strings mirror the storefront (Mashriq-Editions.html) so the catalog the
-- frontend renders and the data in Postgres stay in sync.

-- ---------------------------------------------------------------------------
-- Material price options
-- ---------------------------------------------------------------------------
insert into public.material_prices (material, price_eur) values
  ('digital', 25),
  ('print',   75),
  ('framed', 145)
on conflict (material) do update set price_eur = excluded.price_eur;

-- ---------------------------------------------------------------------------
-- Collections (4)
-- ---------------------------------------------------------------------------
insert into public.collections (id, name_en, name_ar, name_fr, desc_en, desc_ar, desc_fr, plate_count) values
  ('damascus',  'Damascus',  'دمشق',   'Damas',
   'The walled city and the seven gates, 1860 to 1932.',
   'المدينة المُسوَّرة والأبواب السّبعة، من ١٨٦٠ إلى ١٩٣٢.',
   'La ville close et ses sept portes, de 1860 à 1932.',
   14),
  ('jerusalem', 'Jerusalem', 'القُدس', 'Jérusalem',
   'Inside the Old City, before the Mandate divided the quarters.',
   'داخل البلدة القديمة، قبل أن يقسّم الانتداب الحارات.',
   'Dans la Vieille Ville, avant que le Mandat ne divise les quartiers.',
   11),
  ('aleppo',    'Aleppo',    'حلب',    'Alep',
   'The citadel, the souks, and the lines that ran to Anatolia.',
   'القلعة، والأسواق، والسّكك الممتدّة نحو الأناضول.',
   'La citadelle, les souks et les voies qui filaient vers l’Anatolie.',
   17),
  ('jaffa',     'Jaffa',     'يافا',   'Jaffa',
   'Orchards, port, and railway before the road to Tel Aviv.',
   'البساتين والميناء والسّكك قبل طريق تل أبيب.',
   'Vergers, port et chemin de fer avant la route de Tel-Aviv.',
   8)
on conflict (id) do update set
  name_en     = excluded.name_en,
  name_ar     = excluded.name_ar,
  name_fr     = excluded.name_fr,
  desc_en     = excluded.desc_en,
  desc_ar     = excluded.desc_ar,
  desc_fr     = excluded.desc_fr,
  plate_count = excluded.plate_count;

-- ---------------------------------------------------------------------------
-- Plates (8)
-- ---------------------------------------------------------------------------
-- collection_id is set for plates whose city matches one of the four named
-- collections; the others (Beirut, Tripoli, Antakya, Haifa) stay NULL since
-- they belong to no seeded collection in v1. Common fields: cotton-rag paper,
-- 50 × 70 cm, edition of 200.
insert into public.plates
  (id, collection_id, city_en, city_ar, city_fr, year, kind, default_material,
   source_plate, paper, size, edition_size)
values
  ('dam1893', 'damascus',  'Damascus',  'دمشق',     'Damas',     1893, 'walled',    'framed',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200),
  ('jer1883', 'jerusalem', 'Jerusalem', 'القُدس',   'Jérusalem', 1883, 'oldcity',   'print',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200),
  ('alp1912', 'aleppo',    'Aleppo',    'حلب',      'Alep',      1912, 'citadel',   'print',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200),
  ('jaf1878', 'jaffa',     'Jaffa',     'يافا',     'Jaffa',     1878, 'coastgrid', 'digital',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200),
  ('bey1876', null,        'Beirut',    'بيروت',    'Beyrouth',  1876, 'peninsula', 'framed',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200),
  ('tri1898', null,        'Tripoli',   'طرابلس',   'Tripoli',   1898, 'twincity',  'print',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200),
  ('ant1906', null,        'Antakya',   'أنطاكية',  'Antakya',   1906, 'river',     'digital',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200),
  ('hai1925', null,        'Haifa',     'حيفا',     'Haïfa',     1925, 'bay',       'framed',
   null, '300gsm cotton rag, deckle edge', '50 × 70 cm', 200)
on conflict (id) do update set
  collection_id    = excluded.collection_id,
  city_en          = excluded.city_en,
  city_ar          = excluded.city_ar,
  city_fr          = excluded.city_fr,
  year             = excluded.year,
  kind             = excluded.kind,
  default_material = excluded.default_material,
  source_plate     = excluded.source_plate,
  paper            = excluded.paper,
  size             = excluded.size,
  edition_size     = excluded.edition_size;
