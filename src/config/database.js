import Database from 'better-sqlite3';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const db = new Database(join(__dirname, '..', '..', 'darak.db'));

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'user' CHECK(role IN ('user','agent','admin')),
    avatar TEXT DEFAULT '',
    favorites TEXT DEFAULT '[]',
    refreshToken TEXT,
    isActive INTEGER DEFAULT 1,
    lastLogin TEXT,
    createdAt TEXT DEFAULT (datetime('now')),
    updatedAt TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS properties (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    streetWidth INTEGER,
    lat REAL,
    lng REAL,

    images TEXT DEFAULT '[]',
    panoramicImage TEXT,
    floorPlan TEXT,

    features TEXT DEFAULT '[]',
    trust TEXT DEFAULT 'direct' CHECK(trust IN ('verified','office','direct')),
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending','active','sold','expired')),
    isFeatured INTEGER DEFAULT 0,
    views INTEGER DEFAULT 0,
    favorites INTEGER DEFAULT 0,

    agentName TEXT,
    agentPhone TEXT,
    agentOffice TEXT,
    agentUserId INTEGER,
    agentOfficeId INTEGER,

    expectedPrice REAL,
    suitablePrice REAL,
    maximumPrice REAL,
    saleChance INTEGER,

    createdAt TEXT DEFAULT (datetime('now')),
    updatedAt TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId INTEGER UNIQUE,
    officeName TEXT NOT NULL,
    commercialReg TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT,
    address TEXT,
    description TEXT,
    logo TEXT,
    isVerified INTEGER DEFAULT 0,
    rating REAL DEFAULT 0,
    totalSales INTEGER DEFAULT 0,
    totalListings INTEGER DEFAULT 0,
    phone TEXT,
    email TEXT,
    whatsapp TEXT,
    createdAt TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (userId) REFERENCES users(id)
  );

  CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
  CREATE INDEX IF NOT EXISTS idx_properties_type ON properties(type);
  CREATE INDEX IF NOT EXISTS idx_properties_price ON properties(price);
  CREATE INDEX IF NOT EXISTS idx_properties_status ON properties(status);
  CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

  CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId INTEGER NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    isRead INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (userId) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS propertyRequests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId INTEGER NOT NULL,
    city TEXT,
    district TEXT,
    type TEXT,
    purpose TEXT,
    minPrice REAL,
    maxPrice REAL,
    minArea REAL,
    maxArea REAL,
    rooms INTEGER,
    notes TEXT,
    status TEXT DEFAULT 'pending',
    createdAt TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (userId) REFERENCES users(id)
  );
`);

// Add columns if they don't exist (SQLite doesn't support IF NOT EXISTS for ALTER TABLE)
try { db.exec("ALTER TABLE users ADD COLUMN package TEXT DEFAULT 'basic'"); } catch (e) {}
try { db.exec("ALTER TABLE users ADD COLUMN packageExpiry TEXT"); } catch (e) {}

db.exec(`
  CREATE TABLE IF NOT EXISTS invoices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId INTEGER NOT NULL,
    propertyId INTEGER,
    type TEXT NOT NULL CHECK(type IN ('بيع','إيجار','عمولة','صيانة','أخرى')),
    amount REAL NOT NULL,
    description TEXT,
    clientName TEXT,
    clientPhone TEXT,
    status TEXT DEFAULT 'معلقة' CHECK(status IN ('معلقة','مدفوعة','متأخرة','ملغاة')),
    dueDate TEXT,
    paidAt TEXT,
    createdAt TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (userId) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS vendors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId INTEGER NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK(category IN ('مقاول','سمسار','محامي','مهندس','مقايس','أخرى')),
    phone TEXT,
    email TEXT,
    city TEXT,
    rating REAL DEFAULT 0,
    totalDeals INTEGER DEFAULT 0,
    notes TEXT,
    createdAt TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (userId) REFERENCES users(id)
  );
`);

export default db;
