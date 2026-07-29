import postgres from 'postgres';

const sql = postgres(process.env.DATABASE_URL || 'postgresql://postgres:lRduReiPwvPvfHrSoKrWDPFcsvPweKUd@sakura.proxy.rlwy.net:38495/railway', {
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
    role TEXT DEFAULT 'user' CHECK(role IN ('user','agent','admin')),
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

  CREATE TABLE IF NOT EXISTS neighbourhood_pulse (
    id SERIAL PRIMARY KEY,
    city TEXT NOT NULL,
    district TEXT NOT NULL UNIQUE,
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

  INSERT INTO neighbourhood_pulse (city, district, avg_rent, avg_sale, roi, metro_stations, nearby_projects, sports_boulevard, walk_score, green_spaces, future_value_growth, data_source) VALUES
    ('الرياض', 'حي الملقا', 60000, 1800000, 7.5, '[{"name":"محطة العقيق","line":"الأزرق","year":2025,"distance":"8 دقائق"},{"name":"محطة الربيع","line":"الأزرق","year":2025,"distance":"12 دقيقة"}]', '[{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"8 دقائق"},{"name":"المسار الرياضي","type":"مشروع رياضي","year":2026,"distance":"3 دقائق"}]', true, 78, '[{"name":"حديقة الملقا","distance":"2 دقائق"},{"name":"وادي حنيفة","distance":"10 دقائق"}]', 18, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي النرجس', 55000, 2500000, 6.2, '[{"name":"محطة الصحافة","line":"الأحمر","year":2025,"distance":"10 دقائق"}]', '[{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"12 دقيقة"}]', false, 65, '[{"name":"حديقة النرجس","distance":"5 دقائق"}]', 12, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي العقيق', 70000, 3200000, 5.8, '[{"name":"محطة العقيق","line":"الأزرق","year":2025,"distance":"3 دقائق"},{"name":"محطة الربيع","line":"الأزرق","year":2025,"distance":"8 دقائق"}]', '[{"name":"المسار الرياضي","type":"مشروع رياضي","year":2026,"distance":"1 دقيقة"},{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"15 دقيقة"}]', true, 85, '[{"name":"حديقة العقيق","distance":"1 دقيقة"},{"name":"وادي حنيفة","distance":"8 دقائق"}]', 22, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي الربيع', 65000, 2800000, 6.0, '[{"name":"محطة الربيع","line":"الأزرق","year":2025,"distance":"5 دقائق"}]', '[{"name":"المسار الرياضي","type":"مشروع رياضي","year":2026,"distance":"5 دقائق"}]', true, 72, '[{"name":"حديقة الربيع","distance":"3 دقائق"}]', 15, 'تحليل السوق 2024-2026'),
    ('الرياض', 'القيروان', 62000, 2200000, 6.8, '[{"name":"محطة الربيع","line":"الأزرق","year":2025,"distance":"10 دقائق"}]', '[{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"5 دقائق"}]', false, 70, '[]', 20, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي الياسمين', 48000, 1600000, 7.0, '[]', '[{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"15 دقيقة"}]', false, 55, '[{"name":"حديقة الياسمين","distance":"4 دقائق"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي الشفا', 40000, 3800000, 4.5, '[]', '[]', false, 40, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي النخيل', 52000, 1800000, 6.5, '[{"name":"محطة النخيل","line":"الأحمر","year":2025,"distance":"5 دقائق"}]', '[{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"10 دقائق"}]', false, 60, '[{"name":"حديقة النخيل","distance":"3 دقائق"}]', 14, 'تحليل السوق 2024-2026'),
    ('الرياض', 'العليا', 75000, 3500000, 5.5, '[{"name":"محطة العليا","line":"الأزرق","year":2025,"distance":"2 دقائق"},{"name":"محطة الملك فهد","line":"الأزرق","year":2025,"distance":"5 دقائق"}]', '[{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"10 دقائق"}]', false, 90, '[{"name":"حديقة العليا","distance":"1 دقيقة"}]', 10, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي البطحاء', 30000, 1500000, 5.0, '[{"name":"محطة البطحاء","line":"الأزرق","year":2025,"distance":"3 دقائق"}]', '[]', false, 50, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي العارض', 45000, 2200000, 5.2, '[]', '[]', false, 45, '[{"name":"وادي حنيفة","distance":"15 دقيقة"}]', 6, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي النهضة', 28000, 750000, 6.0, '[]', '[]', false, 50, '[]', 4, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي العزيزية', 35000, 2800000, 3.8, '[]', '[]', false, 35, '[]', 2, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي العنبة', 32000, 1300000, 5.5, '[]', '[]', false, 40, '[]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي الثقوب', 30000, 2100000, 4.2, '[]', '[]', false, 30, '[]', 3, 'تحليل السوق 2024-2026'),
    ('الرياض', 'حي الدحو', 28000, 1900000, 4.0, '[]', '[]', false, 35, '[]', 2, 'تحليل السوق 2024-2026'),
    ('الرياض', 'الصحافه', 50000, 1700000, 6.8, '[{"name":"محطة الصحافة","line":"الأحمر","year":2025,"distance":"5 دقائق"}]', '[{"name":"المربع الجديد","type":"مشروع ترفيهي","year":2030,"distance":"12 دقيقة"}]', false, 58, '[{"name":"حديقة الصحافة","distance":"5 دقائق"}]', 12, 'تحليل السوق 2024-2026'),
    ('الرياض', 'القويعية', 85000, 8500000, 3.0, '[]', '[]', false, 20, '[{"name":"وادي القويعية","distance":"10 دقائق"}]', 5, 'تحليل السوق 2024-2026'),
    ('الرياض', 'خيمة', 25000, 950000, 5.0, '[]', '[]', false, 25, '[]', 3, 'تحليل السوق 2024-2026'),
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
  ON CONFLICT (district) DO NOTHING;
`);

export default sql;
