import postgres from 'postgres';

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is required');
}

const sql = postgres(process.env.DATABASE_URL, {
  ssl: 'require',
  max: 10,
  idle_timeout: 30,
  connect_timeout: 10,
});

await sql.unsafe(`SET client_min_messages = WARNING;

  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'user' CHECK(role IN ('user','agent','admin','owner')),
    avatar TEXT DEFAULT '',
    favorites TEXT DEFAULT '[]',
    "refreshToken" TEXT,
    "isActive" INTEGER DEFAULT 1,
    "lastLogin" TEXT,
    "createdAt" TEXT DEFAULT (NOW()),
    "updatedAt" TEXT DEFAULT (NOW()),
    package TEXT DEFAULT 'basic',
    "packageExpiry" TEXT
  );

  ALTER TABLE users ADD COLUMN IF NOT EXISTS "phoneVerified" INTEGER DEFAULT 0;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS "otpCode" TEXT;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS "otpExpires" TEXT;

  ALTER TABLE properties ADD COLUMN IF NOT EXISTS apartments INTEGER DEFAULT 0;

  CREATE TABLE IF NOT EXISTS properties (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    type TEXT NOT NULL,
    purpose TEXT NOT NULL CHECK(purpose IN ('بيع','إيجار')),
    price REAL NOT NULL,
    area REAL NOT NULL,
    rooms INTEGER NOT NULL,
    baths INTEGER NOT NULL,
    cars INTEGER DEFAULT 0,
    apartments INTEGER DEFAULT 0,
    facing TEXT DEFAULT 'شمالي',
    year INTEGER,
    age INTEGER DEFAULT 0,
    description TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT NOT NULL,
    area_name TEXT,
    street TEXT,
    "streetWidth" INTEGER,
    lat REAL,
    lng REAL,
    images TEXT DEFAULT '[]',
    "panoramicImage" TEXT,
    "floorPlan" TEXT,
    features TEXT DEFAULT '[]',
    trust TEXT DEFAULT 'direct' CHECK(trust IN ('verified','office','direct')),
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','active','sold','expired')),
    "isFeatured" INTEGER DEFAULT 0,
    views INTEGER DEFAULT 0,
    favorites INTEGER DEFAULT 0,
    "agentName" TEXT,
    "agentPhone" TEXT,
    "agentOffice" TEXT,
    "agentUserId" INTEGER,
    "agentOfficeId" INTEGER,
    "expectedPrice" REAL,
    "suitablePrice" REAL,
    "maximumPrice" REAL,
    "saleChance" INTEGER,
    "createdAt" TEXT DEFAULT (NOW()),
    "updatedAt" TEXT DEFAULT (NOW())
  );

  CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
  CREATE INDEX IF NOT EXISTS idx_properties_type ON properties(type);
  CREATE INDEX IF NOT EXISTS idx_properties_price ON properties(price);
  CREATE INDEX IF NOT EXISTS idx_properties_status ON properties(status);
  CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

  CREATE TABLE IF NOT EXISTS agents (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER UNIQUE,
    "officeName" TEXT NOT NULL,
    "commercialReg" TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT,
    address TEXT,
    description TEXT,
    logo TEXT,
    "isVerified" INTEGER DEFAULT 0,
    rating REAL DEFAULT 0,
    "totalSales" INTEGER DEFAULT 0,
    "totalListings" INTEGER DEFAULT 0,
    phone TEXT,
    email TEXT,
    whatsapp TEXT,
    "createdAt" TEXT DEFAULT (NOW()),
    FOREIGN KEY ("userId") REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    "isRead" INTEGER DEFAULT 0,
    "createdAt" TEXT DEFAULT (NOW()),
    FOREIGN KEY ("userId") REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS "propertyRequests" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL,
    city TEXT,
    district TEXT,
    type TEXT,
    purpose TEXT,
    "minPrice" REAL,
    "maxPrice" REAL,
    "minArea" REAL,
    "maxArea" REAL,
    rooms INTEGER,
    notes TEXT,
    status TEXT DEFAULT 'pending',
    "createdAt" TEXT DEFAULT (NOW()),
    FOREIGN KEY ("userId") REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS invoices (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL,
    "propertyId" INTEGER,
    type TEXT NOT NULL CHECK(type IN ('بيع','إيجار','عمولة','صيانة','أخرى')),
    amount REAL NOT NULL,
    description TEXT,
    "clientName" TEXT,
    "clientPhone" TEXT,
    status TEXT DEFAULT 'معلقة' CHECK(status IN ('معلقة','مدفوعة','متأخرة','ملغاة')),
    "dueDate" TEXT,
    "paidAt" TEXT,
    "createdAt" TEXT DEFAULT (NOW()),
    FOREIGN KEY ("userId") REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS vendors (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK(category IN ('مقاول','سمسار','محامي','مهندس','مقايس','أخرى')),
    phone TEXT,
    email TEXT,
    city TEXT,
    rating REAL DEFAULT 0,
    "totalDeals" INTEGER DEFAULT 0,
    notes TEXT,
    "createdAt" TEXT DEFAULT (NOW()),
    FOREIGN KEY ("userId") REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL REFERENCES users(id),
    amount REAL NOT NULL,
    currency TEXT DEFAULT 'SAR',
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','paid','failed','refunded')),
    "paymentMethod" TEXT,
    "packageId" TEXT NOT NULL,
    "moyasarId" TEXT,
    description TEXT,
    "paidAt" TEXT,
    "createdAt" TEXT DEFAULT (NOW())
  );

  CREATE TABLE IF NOT EXISTS neighbourhood_pulse (
    id SERIAL PRIMARY KEY,
    city TEXT NOT NULL,
    district TEXT NOT NULL,
    avg_rent REAL,
    avg_sale REAL,
    roi REAL,
    metro_stations TEXT DEFAULT '[]',
    nearby_projects TEXT DEFAULT '[]',
    sports_boulevard BOOLEAN DEFAULT false,
    walk_score INTEGER DEFAULT 0,
    green_spaces TEXT DEFAULT '[]',
    future_value_growth REAL,
    data_source TEXT,
    "updatedAt" TEXT DEFAULT (NOW())
  );
  ALTER TABLE neighbourhood_pulse DROP CONSTRAINT IF EXISTS neighbourhood_pulse_district_key;
  ALTER TABLE neighbourhood_pulse ADD UNIQUE (city, district);

  DELETE FROM neighbourhood_pulse WHERE city = 'الرياض';
  INSERT INTO neighbourhood_pulse (city, district, avg_rent, avg_sale, roi, metro_stations, nearby_projects, sports_boulevard, walk_score, green_spaces, future_value_growth, data_source) VALUES
    ('الرياض', 'الصحافة', 50000, 1700000, 6.8, '[{"name": "طريق خالد بن الوليد", "line": "الأحمر", "year": 2024, "distance": "8 دقائق"}, {"name": "النزهة", "line": "الأحمر", "year": 2024, "distance": "12 دقيقة"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "12 دقيقة"}]', false, 58, '[{"name": "حديقة الصحافة", "distance": "5 دقائق"}]', 12, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الربيع', 65000, 2800000, 6.0, '[{"name": "الربيع", "line": "الأصفر", "year": 2024, "distance": "5 دقائق"}, {"name": "طريق عثمان بن عفان", "line": "الأصفر", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المسار الرياضي", "type": "مشروع رياضي", "year": 2026, "distance": "5 دقائق"}]', true, 72, '[{"name": "حديقة الربيع", "distance": "5 دقائق"}]', 15, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العارض', 45000, 2200000, 5.2, '[]', '[]', false, 45, '[{"name": "وادي حنيفة", "distance": "15 دقيقة"}]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الندى', 48000, 2000000, 5.8, '[{"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 55, '[{"name": "حديقة الندى", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'النفل', 50000, 2100000, 6.0, '[{"name": "حي الملك فهد", "line": "الأزرق", "year": 2024, "distance": "10 دقائق"}, {"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "12 دقيقة"}]', '[]', false, 60, '[{"name": "حديقة النفل", "distance": "5 دقائق"}]', 11, 'تحليل السوق 2024-2026'),
    ('الرياض', 'النرجس', 55000, 2500000, 6.2, '[{"name": "حي الملك فهد", "line": "الأزرق", "year": 2024, "distance": "8 دقائق"}, {"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "12 دقيقة"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "12 دقيقة"}]', false, 65, '[{"name": "حديقة النرجس", "distance": "5 دقائق"}]', 12, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العقيق', 70000, 3200000, 5.8, '[{"name": "حي الملك فهد", "line": "الأزرق", "year": 2024, "distance": "5 دقائق"}, {"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المسار الرياضي", "type": "مشروع رياضي", "year": 2026, "distance": "1 دقيقة"}, {"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "15 دقيقة"}]', true, 85, '[{"name": "حديقة العقيق", "distance": "5 دقائق"}, {"name": "وادي حنيفة", "distance": "8 دقائق"}]', 22, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الوادي', 58000, 2400000, 6.5, '[{"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المسار الرياضي", "type": "مشروع رياضي", "year": 2026, "distance": "8 دقائق"}]', true, 68, '[{"name": "حديقة الوادي", "distance": "5 دقائق"}]', 14, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الغدير', 52000, 2300000, 5.8, '[{"name": "طريق عثمان بن عفان", "line": "الأصفر", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 55, '[{"name": "حديقة الغدير", "distance": "5 دقائق"}]', 11, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الياسمين', 48000, 1600000, 7.0, '[{"name": "حي الملك فهد", "line": "الأزرق", "year": 2024, "distance": "10 دقائق"}, {"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "15 دقيقة"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "15 دقيقة"}]', false, 55, '[{"name": "حديقة الياسمين", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الفلاح', 45000, 1800000, 6.5, '[]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "20 دقيقة"}]', false, 50, '[{"name": "حديقة الفلاح", "distance": "5 دقائق"}]', 12, 'تحليل السوق 2024-2026'),
    ('الرياض', 'بنيان', 42000, 1700000, 6.8, '[]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "15 دقيقة"}]', false, 45, '[]', 14, 'تحليل السوق 2024-2026'),
    ('الرياض', 'القيروان', 62000, 2200000, 6.8, '[{"name": "حي الملك فهد", "line": "الأزرق", "year": 2024, "distance": "12 دقيقة"}, {"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "15 دقيقة"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "5 دقائق"}]', false, 70, '[]', 20, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حطين', 72000, 3500000, 5.5, '[{"name": "المركز المالي", "line": "الأصفر", "year": 2024, "distance": "5 دقائق"}, {"name": "المركز المالي", "line": "البنفسجي", "year": 2024, "distance": "5 دقائق"}]', '[{"name": "المسار الرياضي", "type": "مشروع رياضي", "year": 2026, "distance": "2 دقائق"}, {"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "10 دقائق"}]', true, 88, '[{"name": "حديقة حطين", "distance": "5 دقائق"}, {"name": "وادي حنيفة", "distance": "10 دقائق"}]', 22, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الملقا', 60000, 1800000, 7.5, '[{"name": "المروج", "line": "الأزرق", "year": 2024, "distance": "8 دقائق"}, {"name": "حي الملك فهد", "line": "الأزرق", "year": 2024, "distance": "10 دقائق"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "8 دقائق"}, {"name": "المسار الرياضي", "type": "مشروع رياضي", "year": 2026, "distance": "3 دقائق"}]', true, 78, '[{"name": "حديقة الملقا", "distance": "5 دقائق"}, {"name": "وادي حنيفة", "distance": "10 دقائق"}]', 18, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الخير', 55000, 2600000, 5.8, '[{"name": "سابك", "line": "الأصفر", "year": 2024, "distance": "5 دقائق"}, {"name": "طريق عثمان بن عفان", "line": "الأصفر", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المسار الرياضي", "type": "مشروع رياضي", "year": 2026, "distance": "6 دقائق"}]', true, 70, '[{"name": "حديقة الخير", "distance": "5 دقائق"}]', 16, 'تحليل السوق 2024-2026'),
    ('الرياض', 'جامعة الامام محمد بن سعود', 40000, 1500000, 6.5, '[{"name": "سابك", "line": "الأصفر", "year": 2024, "distance": "8 دقائق"}, {"name": "جامعة الأميرة نورة", "line": "الأصفر", "year": 2024, "distance": "12 دقيقة"}]', '[]', false, 50, '[{"name": "حديقة الجامعة", "distance": "5 دقائق"}]', 15, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الشفاء', 40000, 3800000, 4.5, '[{"name": "طويق", "line": "البرتقالي", "year": 2024, "distance": "10 دقائق"}, {"name": "طريق جدة", "line": "البرتقالي", "year": 2024, "distance": "15 دقيقة"}]', '[]', false, 40, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'بدر', 22000, 850000, 5.5, '[{"name": "منفوحة", "line": "الأزرق", "year": 2024, "distance": "12 دقيقة"}]', '[]', false, 30, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المروة', 25000, 900000, 5.2, '[]', '[]', false, 35, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الفواز', 20000, 700000, 5.8, '[]', '[]', false, 25, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الحزم', 28000, 1000000, 5.0, '[]', '[]', false, 30, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العزيزية', 35000, 2800000, 3.8, '[{"name": "العزيزية", "line": "الأزرق", "year": 2024, "distance": "5 دقائق"}, {"name": "الدار البيضاء", "line": "الأزرق", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 35, '[]', 2, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الدار البيضاء', 32000, 2500000, 4.0, '[{"name": "الدار البيضاء", "line": "الأزرق", "year": 2024, "distance": "3 دقائق"}, {"name": "العزيزية", "line": "الأزرق", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 32, '[]', 2, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المنصورة', 26000, 950000, 5.0, '[{"name": "الدوح", "line": "البرتقالي", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 30, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'نمار', 18000, 650000, 5.5, '[]', '[]', false, 20, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الدريهمية', 22000, 750000, 5.0, '[]', '[]', false, 25, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'شبرا', 30000, 1200000, 5.2, '[{"name": "المرقب", "line": "البرتقالي", "year": 2024, "distance": "10 دقائق"}, {"name": "الصالحية", "line": "البرتقالي", "year": 2024, "distance": "12 دقيقة"}]', '[]', false, 40, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'اليمامة', 28000, 1100000, 5.0, '[]', '[]', false, 35, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المصانع', 20000, 700000, 5.5, '[]', '[]', false, 25, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'بن تركي', 25000, 900000, 5.2, '[]', '[]', false, 30, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الشميسي', 30000, 1200000, 5.0, '[]', '[]', false, 35, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الحاير', 18000, 600000, 5.8, '[]', '[]', false, 20, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الشعلان', 28000, 1000000, 5.2, '[]', '[]', false, 30, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'اليرموك', 42000, 1800000, 5.5, '[{"name": "اليرموك", "line": "البنفسجي", "year": 2024, "distance": "5 دقائق"}, {"name": "الحمراء", "line": "البنفسجي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 60, '[{"name": "حديقة اليرموك", "distance": "5 دقائق"}]', 8, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المغرزات', 38000, 1500000, 5.8, '[]', '[]', false, 50, '[]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'النظيم', 28000, 900000, 6.0, '[]', '[]', false, 40, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'النهضة', 28000, 750000, 6.0, '[{"name": "الملز", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}, {"name": "حي جرير", "line": "البرتقالي", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 50, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الرواد', 35000, 1300000, 6.2, '[]', '[]', false, 45, '[]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الشهداء', 32000, 1200000, 6.0, '[]', '[]', false, 45, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'النسيم الغربي', 30000, 1100000, 5.8, '[{"name": "النسيم", "line": "البرتقالي", "year": 2024, "distance": "10 دقائق"}, {"name": "النسيم", "line": "البنفسجي", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 45, '[{"name": "حديقة النسيم", "distance": "5 دقائق"}]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'النسيم الشرقي', 28000, 1000000, 6.0, '[{"name": "النسيم", "line": "البرتقالي", "year": 2024, "distance": "12 دقيقة"}, {"name": "النسيم", "line": "البنفسجي", "year": 2024, "distance": "12 دقيقة"}]', '[]', false, 40, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'غرناطة', 45000, 2000000, 5.2, '[{"name": "غرناطة", "line": "البنفسجي", "year": 2024, "distance": "5 دقائق"}]', '[]', false, 65, '[{"name": "حديقة غرناطة", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'السلي', 35000, 1400000, 5.5, '[]', '[]', false, 50, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'اشبيليا', 48000, 2200000, 5.0, '[{"name": "إشبيليا", "line": "الأحمر", "year": 2024, "distance": "5 دقائق"}]', '[]', false, 62, '[{"name": "حديقة اشبيليا", "distance": "5 دقائق"}]', 9, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الروضة', 38000, 1600000, 5.5, '[]', '[]', false, 55, '[{"name": "حديقة الروضة", "distance": "5 دقائق"}]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الريان', 40000, 1700000, 5.2, '[]', '[]', false, 52, '[]', 8, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الخليج', 55000, 2800000, 4.8, '[{"name": "الخليج", "line": "الأحمر", "year": 2024, "distance": "5 دقائق"}]', '[]', false, 70, '[{"name": "حديقة الخليج", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الحمراء', 50000, 2500000, 5.0, '[{"name": "الحمراء", "line": "الأحمر", "year": 2024, "distance": "5 دقائق"}, {"name": "الحمراء", "line": "البنفسجي", "year": 2024, "distance": "5 دقائق"}]', '[]', false, 68, '[{"name": "حديقة الحمراء", "distance": "5 دقائق"}]', 9, 'تحليل السوق 2024-2026'),
    ('الرياض', 'قرطبة', 42000, 1900000, 5.2, '[]', '[]', false, 58, '[{"name": "حديقة قرطبة", "distance": "5 دقائق"}]', 8, 'تحليل السوق 2024-2026'),
    ('الرياض', 'السلام', 35000, 1500000, 5.5, '[{"name": "السلام", "line": "البنفسجي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 55, '[]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الروابي', 32000, 1300000, 5.8, '[]', '[]', false, 48, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المونسية', 48000, 2100000, 5.5, '[]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "20 دقيقة"}]', false, 60, '[{"name": "حديقة المونسية", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الرمال', 40000, 1800000, 5.2, '[]', '[]', false, 50, '[]', 8, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الفيحاء', 35000, 1400000, 5.8, '[]', '[]', false, 48, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'السعادة', 30000, 1200000, 5.5, '[]', '[]', false, 45, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الجزيرة', 28000, 1100000, 5.8, '[]', '[]', false, 40, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الشعلة', 25000, 900000, 6.0, '[]', '[]', false, 35, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'السويدي', 35000, 1500000, 5.5, '[{"name": "طريق جدة", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}, {"name": "طويق", "line": "البرتقالي", "year": 2024, "distance": "12 دقيقة"}]', '[]', false, 45, '[{"name": "حديقة السويدي", "distance": "5 دقائق"}]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'ظهرة البديعة', 40000, 1800000, 5.2, '[{"name": "ظهرة البديعة", "line": "البرتقالي", "year": 2024, "distance": "5 دقائق"}]', '[]', false, 50, '[{"name": "حديقة ظهرة البديعة", "distance": "5 دقائق"}]', 8, 'تحليل السوق 2024-2026'),
    ('الرياض', 'سلطانة', 38000, 1700000, 5.0, '[{"name": "سلطانة", "line": "البرتقالي", "year": 2024, "distance": "5 دقائق"}]', '[]', false, 48, '[]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العريجاء', 30000, 1200000, 5.5, '[{"name": "المحطة الغربية", "line": "البرتقالي", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 40, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العريجاء الغربي', 28000, 1100000, 5.8, '[]', '[]', false, 35, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'لبن', 32000, 1300000, 5.5, '[]', '[]', false, 40, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الخزامى', 45000, 2000000, 5.2, '[{"name": "التخصصي", "line": "الأحمر", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 55, '[{"name": "حديقة الخزامى", "distance": "5 دقائق"}]', 9, 'تحليل السوق 2024-2026'),
    ('الرياض', 'السفارات', 55000, 3000000, 4.8, '[{"name": "وزارة الدفاع", "line": "الأخضر", "year": 2024, "distance": "5 دقائق"}, {"name": "وزارة المالية", "line": "الأخضر", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 75, '[{"name": "حديقة السفارات", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'وادي لبن', 28000, 1000000, 5.8, '[]', '[]', false, 30, '[{"name": "وادي لبن", "distance": "5 دقائق"}]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'ظهرة لبن', 30000, 1200000, 5.5, '[]', '[]', false, 35, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العوالي', 45000, 2000000, 5.2, '[{"name": "جامعة الملك سعود", "line": "الأحمر", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 55, '[]', 9, 'تحليل السوق 2024-2026'),
    ('الرياض', 'طويق', 35000, 1600000, 5.0, '[{"name": "طويق", "line": "البرتقالي", "year": 2024, "distance": "3 دقائق"}, {"name": "طريق جدة", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 45, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'ديراب', 18000, 600000, 6.0, '[]', '[]', false, 20, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'البديعة', 32000, 1400000, 5.2, '[{"name": "ظهرة البديعة", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 42, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الناصرية', 38000, 1600000, 5.5, '[]', '[]', false, 48, '[]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'عليشة', 30000, 1200000, 5.5, '[]', '[]', false, 38, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المعذر', 50000, 2400000, 5.0, '[{"name": "التخصصي", "line": "الأحمر", "year": 2024, "distance": "5 دقائق"}, {"name": "الاتصالات السعودية", "line": "الأحمر", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "15 دقيقة"}]', false, 65, '[{"name": "حديقة المعذر", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الشرفية', 35000, 1500000, 5.2, '[]', '[]', false, 45, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الهدا', 28000, 1100000, 5.5, '[]', '[]', false, 35, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الزهرة', 32000, 1300000, 5.2, '[]', '[]', false, 40, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'أم سليم', 25000, 900000, 5.8, '[]', '[]', false, 30, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الفاخرية', 38000, 1600000, 5.5, '[{"name": "الجرادية", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 45, '[]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الجرادية', 35000, 1500000, 5.0, '[{"name": "الجرادية", "line": "البرتقالي", "year": 2024, "distance": "5 دقائق"}, {"name": "سلطانة", "line": "البرتقالي", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 42, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العليا', 75000, 3500000, 5.5, '[{"name": "العروبة", "line": "الأزرق", "year": 2024, "distance": "5 دقائق"}, {"name": "مصرف الإنماء", "line": "الأزرق", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "10 دقائق"}]', false, 90, '[{"name": "حديقة العليا", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المربع', 55000, 3000000, 5.0, '[{"name": "المربع", "line": "الأزرق", "year": 2024, "distance": "3 دقائق"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "5 دقائق"}]', false, 85, '[{"name": "حديقة المربع", "distance": "5 دقائق"}]', 12, 'تحليل السوق 2024-2026'),
    ('الرياض', 'البطحاء', 30000, 1500000, 5.0, '[{"name": "البطحاء", "line": "الأزرق", "year": 2024, "distance": "3 دقائق"}]', '[]', false, 50, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الملز', 35000, 1800000, 5.0, '[{"name": "الملز", "line": "البرتقالي", "year": 2024, "distance": "5 دقائق"}, {"name": "سكة الحديد", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 55, '[{"name": "حديقة الملز", "distance": "5 دقائق"}]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المنفوحة', 28000, 1200000, 5.5, '[{"name": "منفوحة", "line": "الأزرق", "year": 2024, "distance": "5 دقائق"}, {"name": "مستشفى الإيمان", "line": "الأزرق", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 42, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الديرة', 35000, 1800000, 5.0, '[{"name": "قصر الحكم", "line": "الأزرق", "year": 2024, "distance": "5 دقائق"}, {"name": "قصر الحكم", "line": "البرتقالي", "year": 2024, "distance": "5 دقائق"}]', '[]', false, 60, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الصالحية', 25000, 1000000, 5.5, '[{"name": "الصالحية", "line": "البرتقالي", "year": 2024, "distance": "5 دقائق"}, {"name": "المرقب", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 40, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المرقب', 28000, 1100000, 5.2, '[{"name": "المرقب", "line": "البرتقالي", "year": 2024, "distance": "3 دقائق"}, {"name": "الصالحية", "line": "البرتقالي", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 45, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العود', 30000, 1300000, 5.0, '[{"name": "العود", "line": "الأزرق", "year": 2024, "distance": "3 دقائق"}]', '[]', false, 48, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'سكيرينة', 28000, 1200000, 5.2, '[{"name": "سكيرينة", "line": "الأزرق", "year": 2024, "distance": "3 دقائق"}]', '[]', false, 45, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'أم الحمام', 40000, 2000000, 5.0, '[{"name": "الضباب", "line": "الأخضر", "year": 2024, "distance": "8 دقائق"}, {"name": "ميدان أبو ظبي", "line": "الأخضر", "year": 2024, "distance": "10 دقائق"}]', '[]', false, 58, '[{"name": "حديقة أم الحمام", "distance": "5 دقائق"}]', 7, 'تحليل السوق 2024-2026'),
    ('الرياض', 'النزهة', 45000, 2200000, 5.2, '[{"name": "النزهة", "line": "الأحمر", "year": 2024, "distance": "5 دقائق"}, {"name": "مركز الرياض للمعارض", "line": "الأحمر", "year": 2024, "distance": "8 دقائق"}]', '[]', false, 65, '[{"name": "حديقة النزهة", "distance": "5 دقائق"}]', 8, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الورود', 50000, 2500000, 5.0, '[{"name": "الورود", "line": "الأحمر", "year": 2024, "distance": "5 دقائق"}, {"name": "الاتصالات السعودية", "line": "الأحمر", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المسار الرياضي", "type": "مشروع رياضي", "year": 2026, "distance": "10 دقائق"}]', false, 70, '[{"name": "حديقة الورود", "distance": "5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'المحمدية', 55000, 2800000, 5.2, '[{"name": "طريق الملك عبدالعزيز", "line": "الأحمر", "year": 2024, "distance": "5 دقائق"}, {"name": "وزارة التعليم", "line": "الأحمر", "year": 2024, "distance": "8 دقائق"}]', '[{"name": "المربع الجديد", "type": "مشروع ترفيهي", "year": 2030, "distance": "12 دقيقة"}]', false, 72, '[{"name": "حديقة المحمدية", "distance": "5 دقائق"}]', 11, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي الراكة', 35000, 1200000, 7.2, '[]', '[{"name":"مشروع البحر الأحمر","type":"سياحي","year":2028,"distance":"20 دقيقة"}]', false, 60, '[{"name":"كورنيش جدة","distance":"10 دقائق"}]', 8, 'تحليل السوق 2024-2026'),
    ('جدة', 'التحلية', 40000, 1500000, 6.5, '[]', '[{"name":"مشروع البحر الأحمر","type":"سياحي","year":2028,"distance":"15 دقيقة"}]', false, 75, '[{"name":"كورنيش جدة","distance":"5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي السلامة', 45000, 3500000, 4.5, '[]', '[]', false, 55, '[]', 5, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي الروضة', 38000, 1400000, 6.0, '[]', '[]', false, 50, '[]', 6, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي الصفا', 50000, 4500000, 4.0, '[]', '[]', false, 45, '[]', 8, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي النعيم', 28000, 1200000, 5.5, '[]', '[]', false, 40, '[]', 3, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي السعادة', 35000, 2800000, 4.2, '[]', '[]', false, 42, '[]', 4, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي الجزيرة', 30000, 1100000, 5.8, '[]', '[]', false, 48, '[]', 5, 'تحليل السوق 2024-2026'),
    ('جدة', 'حي الراكة الجنوبية', 32000, 1000000, 6.0, '[]', '[]', false, 45, '[]', 6, 'تحليل السوق 2024-2026'),
    ('مكة', 'الششة', 25000, 950000, 6.5, '[]', '[{"name":"توسعة الحرم","type":"ديني","year":2028,"distance":"10 دقائق"}]', false, 60, '[]', 10, 'تحليل السوق 2024-2026'),
    ('مكة', 'العزيزية', 35000, 3200000, 3.5, '[]', '[{"name":"توسعة الحرم","type":"ديني","year":2028,"distance":"5 دقائق"}]', false, 55, '[]', 8, 'تحليل السوق 2024-2026'),
    ('مكة', 'الرصيفة', 30000, 1500000, 5.0, '[]', '[]', false, 45, '[]', 5, 'تحليل السوق 2024-2026'),
    ('مكة', 'النزهة', 28000, 2500000, 3.2, '[]', '[]', false, 35, '[]', 4, 'تحليل السوق 2024-2026'),
    ('مكة', 'الشرائع', 20000, 800000, 5.5, '[]', '[]', false, 40, '[]', 6, 'تحليل السوق 2024-2026'),
    ('مكة', 'بحرة', 18000, 1800000, 3.0, '[]', '[]', false, 25, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الدمام', 'أحد', 40000, 2800000, 4.5, '[]', '[{"name":"مشروع الواجهة البحرية","type":"ترفيهي","year":2027,"distance":"10 دقائق"}]', false, 60, '[{"name":"واجهة الدمام","distance":"5 دقائق"}]', 7, 'تحليل السوق 2024-2026'),
    ('الدمام', 'النورس', 30000, 1500000, 5.5, '[]', '[{"name":"مشروع الواجهة البحرية","type":"ترفيهي","year":2027,"distance":"8 دقائق"}]', false, 55, '[{"name":"كورنيش الدمام","distance":"10 دقائق"}]', 8, 'تحليل السوق 2024-2026'),
    ('الدمام', 'الجلوية', 45000, 3200000, 4.2, '[]', '[]', false, 50, '[]', 6, 'تحليل السوق 2024-2026'),
    ('الدمام', 'الطبيشي', 28000, 850000, 6.0, '[]', '[]', false, 45, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الدمام', 'الفيصلية', 35000, 1500000, 5.0, '[]', '[]', false, 40, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الدمام', 'السالمية', 25000, 900000, 5.8, '[]', '[]', false, 35, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الخبر', 'العليا', 55000, 3500000, 5.0, '[]', '[{"name":"مشروع الخبر الجديدة","type":"سكني","year":2028,"distance":"10 دقائق"}]', false, 70, '[{"name":"كورنيش الخبر","distance":"5 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الخبر', 'الكورنيش', 60000, 1500000, 7.0, '[]', '[{"name":"مشروع الخبر الجديدة","type":"سكني","year":2028,"distance":"15 دقيقة"}]', false, 80, '[{"name":"كورنيش الخبر","distance":"1 دقيقة"}]', 12, 'تحليل السوق 2024-2026'),
    ('الخبر', 'العقربية', 50000, 4200000, 4.0, '[]', '[]', false, 65, '[]', 8, 'تحليل السوق 2024-2026'),
    ('الخبر', 'الحزام الأخضر', 35000, 1800000, 5.5, '[]', '[]', false, 55, '[{"name":"الحزام الأخضر","distance":"2 دقائق"}]', 6, 'تحليل السوق 2024-2026'),
    ('الخبر', 'الخبر الشمالية', 45000, 2000000, 5.8, '[]', '[]', false, 60, '[]', 9, 'تحليل السوق 2024-2026'),
    ('الباحة', 'القابل', 20000, 1200000, 4.5, '[]', '[]', false, 40, '[{"name":"غابة رغدان","distance":"15 دقيقة"}]', 5, 'تحليل السوق 2024-2026'),
    ('الباحة', 'الشفا', 15000, 600000, 5.0, '[]', '[]', false, 50, '[{"name":"مصيف الشفا","distance":"5 دقائق"}]', 6, 'تحليل السوق 2024-2026'),
    ('الباحة', 'بني كبير', 12000, 800000, 3.5, '[]', '[]', false, 20, '[{"name":"الغابات","distance":"20 دقيقة"}]', 3, 'تحليل السوق 2024-2026'),
    ('الباحة', 'جرب', 15000, 650000, 4.8, '[]', '[]', false, 30, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الباحة', 'قرن ظبي', 12000, 500000, 5.0, '[]', '[]', false, 25, '[]', 3, 'تحليل السوق 2024-2026')
  ON CONFLICT (city, district) DO NOTHING;

  CREATE TABLE IF NOT EXISTS realestate_licenses (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id),
    license_type TEXT NOT NULL CHECK(license_type IN ('فال','وسيط عقاري','مكتب هندسي','وساطة','إيجار')),
    license_number TEXT,
    holder_name TEXT NOT NULL,
    holder_id TEXT,
    city TEXT,
    status TEXT DEFAULT 'active' CHECK(status IN ('active','expired','suspended','pending')),
    issue_date TEXT,
    expiry_date TEXT,
    issuing_authority TEXT DEFAULT 'وزارة الشؤون البلدية والقروية والإسكان',
    notes TEXT,
    "createdAt" TEXT DEFAULT (NOW()),
    "updatedAt" TEXT DEFAULT (NOW())
  );

  CREATE TABLE IF NOT EXISTS realestate_contracts (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id),
    contract_type TEXT NOT NULL CHECK(contract_type IN ('بيع','إيجار','وساطة','مقاولة','صيانة')),
    contract_number TEXT UNIQUE,
    first_party TEXT NOT NULL,
    second_party TEXT NOT NULL,
    property_desc TEXT,
    property_city TEXT,
    property_district TEXT,
    amount REAL,
    payment_terms TEXT,
    duration TEXT,
    start_date TEXT,
    end_date TEXT,
    is_authenticated INTEGER DEFAULT 0,
    authenticated_at TEXT,
    document_url TEXT,
    notes TEXT,
    status TEXT DEFAULT 'draft' CHECK(status IN ('draft','active','completed','cancelled')),
    "createdAt" TEXT DEFAULT (NOW()),
    "updatedAt" TEXT DEFAULT (NOW())
  );

  CREATE TABLE IF NOT EXISTS realestate_delivery_forms (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id),
    property_id INTEGER REFERENCES properties(id),
    form_type TEXT NOT NULL CHECK(form_type IN ('استلام','تسليم')),
    unit_desc TEXT NOT NULL,
    unit_address TEXT,
    lessor_name TEXT NOT NULL,
    lessee_name TEXT NOT NULL,
    handover_date TEXT,
    condition_notes TEXT,
    meter_readings TEXT,
    keys_count INTEGER DEFAULT 0,
    attachments TEXT DEFAULT '[]',
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','signed','completed')),
    "createdAt" TEXT DEFAULT (NOW()),
    "updatedAt" TEXT DEFAULT (NOW())
  );

  CREATE TABLE IF NOT EXISTS realestate_rental_invoices (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id),
    invoice_number TEXT UNIQUE,
    property_id INTEGER REFERENCES properties(id),
    tenant_name TEXT NOT NULL,
    period_from TEXT,
    period_to TEXT,
    rent_amount REAL NOT NULL,
    services_fee REAL DEFAULT 0,
    tax_amount REAL DEFAULT 0,
    total_amount REAL NOT NULL,
    payment_method TEXT DEFAULT 'نقدي' CHECK(payment_method IN ('نقدي','تحويل بنكي','شيك','بطاقة ائتمان')),
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','paid','overdue','cancelled')),
    paid_at TEXT,
    notes TEXT,
    "createdAt" TEXT DEFAULT (NOW())
  );

  CREATE TABLE IF NOT EXISTS realestate_certificates (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id),
    certificate_type TEXT NOT NULL CHECK(certificate_type IN ('فرز','تجزئة','ضم','تعديل')),
    property_id INTEGER REFERENCES properties(id),
    property_desc TEXT,
    total_units INTEGER,
    unit_details TEXT DEFAULT '[]',
    certificate_number TEXT UNIQUE,
    issuing_authority TEXT DEFAULT 'أمانة المنطقة',
    issue_date TEXT,
    engineer_name TEXT,
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
    document_url TEXT,
    notes TEXT,
    "createdAt" TEXT DEFAULT (NOW())
  );

  CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id),
    "propertyId" INTEGER REFERENCES properties(id),
    reason TEXT NOT NULL,
    description TEXT DEFAULT '',
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','reviewed','dismissed')),
    "createdAt" TEXT DEFAULT (NOW())
  );

  CREATE TABLE IF NOT EXISTS ratings (
    id SERIAL PRIMARY KEY,
    "advertiserId" INTEGER REFERENCES users(id) NOT NULL,
    "userId" INTEGER REFERENCES users(id) NOT NULL,
    score INTEGER NOT NULL CHECK(score >= 1 AND score <= 5),
    comment TEXT DEFAULT '',
    "createdAt" TEXT DEFAULT (NOW()),
    UNIQUE("advertiserId", "userId")
  );

  CREATE TABLE IF NOT EXISTS official_indicators (
    id SERIAL PRIMARY KEY,
    indicator_type TEXT NOT NULL CHECK(indicator_type IN ('rent','sales')),
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    region TEXT NOT NULL,
    city TEXT,
    district TEXT,
    property_type TEXT,
    category TEXT,
    deals INTEGER DEFAULT 0,
    avg_value REAL,
    avg_per_m2 REAL,
    source TEXT DEFAULT 'الهيئة العامة للعقار',
    source_url TEXT,
    notes TEXT,
    "createdAt" TEXT DEFAULT (NOW()),
    UNIQUE(indicator_type, year, quarter, region, city, district, property_type)
  );
  CREATE INDEX IF NOT EXISTS idx_official_indicators_city ON official_indicators(city);
  CREATE INDEX IF NOT EXISTS idx_official_indicators_district ON official_indicators(district);
  CREATE INDEX IF NOT EXISTS idx_official_indicators_type ON official_indicators(indicator_type);

  CREATE TABLE IF NOT EXISTS realestate_deeds (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id),
    deed_number TEXT UNIQUE NOT NULL,
    property_desc TEXT NOT NULL,
    property_city TEXT,
    property_district TEXT,
    area REAL,
    boundaries TEXT,
    owner_name TEXT NOT NULL,
    deed_type TEXT DEFAULT 'صك ملكية' CHECK(deed_type IN ('صك ملكية','حجة إرث','وصية','وقف','إفراغ')),
    issuing_court TEXT DEFAULT 'المحكمة العامة',
    issue_date TEXT,
    is_verified INTEGER DEFAULT 0,
    document_url TEXT,
    notes TEXT,
    "createdAt" TEXT DEFAULT (NOW()),
    "updatedAt" TEXT DEFAULT (NOW())
  );
`);

export default sql;
