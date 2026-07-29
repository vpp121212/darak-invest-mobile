import sql from '../src/config/database.js';

const [{ count }] = await sql`SELECT COUNT(*)::int as count FROM properties`;
if (count > 0) {
  console.log(`✅ DB already seeded (${count} properties) — appending new districts only`);
}

const properties = [{"title": "فيلا فاخرة في حي النرجس", "type": "فيلا", "purpose": "بيع", "price": 2500000, "area": 450, "rooms": 6, "baths": 5, "cars": 3, "facing": "شرقي", "year": 2023, "age": 1, "description": "فيلا فاخرة بتصميم عصري مع حديقة خاصة ومسبح", "city": "الرياض", "district": "حي النرجس", "street": "Prince Turki Rd", "streetWidth": 20, "lat": 24.7935, "lng": 46.6898, "images": "[\"/uploads/properties/villa1.jpg\",\"/uploads/properties/villa2.jpg\",\"/uploads/properties/villa3.jpg\"]", "panoramicImage": "/api/panorama/living_room.jpg", "features": "[\"حديقة خاصة\",\"مسبح خارجي\",\"موقف سيارات\",\"نادي صحي\"]", "trust": "verified", "status": "active", "isFeatured": 0, "agentName": "مكتب الديار العقارية", "agentPhone": "+966501234567", "agentOffice": null}, {"title": "شقة مفروشة في حي الملقا", "type": "شقة", "purpose": "إيجار", "price": 2500, "area": 180, "rooms": 3, "baths": 2, "cars": 1, "facing": "شمالي", "year": 2022, "age": 2, "description": "شقة مفروشة بإطلالة على برج المملكة", "city": "الرياض", "district": "حي الملقا", "street": "King Fahd Rd", "streetWidth": 15, "lat": 24.7115, "lng": 46.6748, "images": "[\"/uploads/properties/interior1.jpg\",\"/uploads/properties/interior2.jpg\",\"/uploads/properties/interior3.jpg\"]", "panoramicImage": "/api/panorama/bedroom.jpg", "features": "[\"مفروشة بالكامل\",\"إطلالة بانورامية\",\"Security 24/7\"]", "trust": "office", "status": "active", "isFeatured": 0, "agentName": "مكتب الديار العقارية", "agentPhone": "+966501234567", "agentOffice": null}, {"title": "بنتهاوس فاخر في حي الشفا", "type": "بنتهاوس", "purpose": "بيع", "price": 3800000, "area": 320, "rooms": 5, "baths": 4, "cars": 2, "facing": "غربي", "year": 2023, "age": 1, "description": "بنتهاوس بتصميم فريد مع تراس مفتوح", "city": "الرياض", "district": "حي الشفا", "street": "Olaya Street", "streetWidth": 25, "lat": 24.72, "lng": 46.68, "images": "[\"/uploads/properties/villa1.jpg\",\"/uploads/properties/villa2.jpg\"]", "panoramicImage": "/api/panorama/living_room.jpg", "features": "[\"تراس مفتوح\",\"إطلالة على المدينة\",\"نادي صحي فاخر\"]", "trust": "verified", "status": "active", "isFeatured": 1, "agentName": "مكتب الديار العقارية", "agentPhone": "+966501234567", "agentOffice": null}];

for (const p of properties) {
  await sql.unsafe(`
    INSERT INTO properties (title, type, purpose, price, area, rooms, baths, cars, facing, year, age, description, city, district, street, "streetWidth", lat, lng, images, "panoramicImage", features, trust, status, "isFeatured", "agentName", "agentPhone", "agentOffice")
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27)
    ON CONFLICT DO NOTHING
  `, [
    p.title, p.type, p.purpose, p.price, p.area, p.rooms, p.baths, p.cars, p.facing,
    p.year, p.age, p.description, p.city, p.district, p.street, p.streetWidth,
    p.lat, p.lng, p.images, p.panoramicImage, p.features, p.trust, p.status,
    p.isFeatured, p.agentName, p.agentPhone, p.agentOffice
  ]);
}

console.log(`✅ Seeded ${properties.length} properties`);
