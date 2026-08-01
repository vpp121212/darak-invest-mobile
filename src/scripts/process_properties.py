#!/usr/bin/env python3
import json
import sys
import sqlite3
from pathlib import Path

# البيانات المعطاة من المستخدم
raw_data = """المنطقة,المدينة,الحي,رقم_الخطة,رقم_العقار,الاستخدام
الرياض,الرياض,حي العارض,3456,10123,سكني
الرياض,الرياض,حي العارض,3456,10124,سكني
الرياض,الرياض,حي النرجس,2210,22011,سكني
الرياض,الرياض,حي الياسمين,3300,33001,سكني
جدة,جدة,حي الزهراء,5678,22021,سكني
جدة,جدة,حي البساتين,5680,22031,سكني
جدة,جدة,حي الروضة,5690,22041,سكني
مكة,مكة,حي الرصيفة,7788,33011,سكني
مكة,مكة,حي العزيزية,7790,33021,سكني
مكة,مكة,حي الشرائع,7800,33031,سكني
المنطقة الشرقية,الدمام,حي النزهة,8899,44011,سكني
المنطقة الشرقية,الدمام,حي الفيحاء,8900,44021,سكني
الخبر,الخبر,حي العقربية,9900,55011,سكني
الخبر,الخبر,حي الثقبة,9905,55021,سكني
حائل,حائل,حي الزهراء,1122,66011,سكني
حائل,حائل,حي المنتزه,1125,66021,سكني"""

# تعيين المواقع (خط العرض، خط الطول)
LOCATION_COORDS = {
    "الرياض": {"lat": 24.7135, "lng": 46.6753},
    "حي العارض": {"lat": 24.7718, "lng": 46.6268},
    "حي النرجس": {"lat": 24.6602, "lng": 46.6759},
    "حي الياسمين": {"lat": 24.7805, "lng": 46.7052},
    "جدة": {"lat": 21.4858, "lng": 39.3061},
    "حي الزهراء": {"lat": 21.5744, "lng": 39.2345},
    "حي البساتين": {"lat": 21.5896, "lng": 39.2477},
    "حي الروضة": {"lat": 21.5412, "lng": 39.2213},
    "مكة": {"lat": 21.3891, "lng": 39.8579},
    "حي الرصيفة": {"lat": 21.4412, "lng": 39.8207},
    "حي العزيزية": {"lat": 21.4123, "lng": 39.8345},
    "حي الشرائع": {"lat": 21.3963, "lng": 39.8555},
    "الدمام": {"lat": 26.4307, "lng": 50.0830},
    "حي النزهة": {"lat": 26.3653, "lng": 50.1279},
    "حي الفيحاء": {"lat": 26.4329, "lng": 50.0833},
    "الخبر": {"lat": 26.2785, "lng": 50.2005},
    "حي العقربية": {"lat": 26.2488, "lng": 50.1908},
    "حي الثقبة": {"lat": 26.2972, "lng": 50.2413},
    "حائل": {"lat": 27.3300, "lng": 41.6853},
    "حي الزهراء": {"lat": 27.3012, "lng": 41.7714},
    "حي المنتزه": {"lat": 27.2539, "lng": 41.7368},
}

# إنشاء الخصائص
properties = []
lines = raw_data.strip().split('\n')
headers = lines[0].split(',')
for line in lines[1:]:
    values = line.split(',')
    property = {
        'plan_number': int(values[3]),
        'parcel_number': int(values[4]),
        'usage': values[5],
        'city': values[1],
        'district': values[2]
    }
    properties.append(property)

# إنشاء الخصائص الكاملة
for p in properties:
    city = p['city']
    district = p['district']
    location_key = city if city in LOCATION_COORDS else district
    coords = LOCATION_COORDS.get(location_key, {"lat": 24.7135, "lng": 46.6753})

    # توليد الأسماء
    if district == 'حي العارض':
        title = f"شقة في {district}, {city} برقم مخطط {p['plan_number']} وعدد العقار {p['parcel_number']}"
    elif district == 'حي النرجس':
        title = f"فيلا في {district}, {city} برقم مخطط {p['plan_number']} وعدد العقار {p['parcel_number']}"
    elif district == 'حي الياسمين':
        title = f"شقة مميزة في {district}, {city} برقم مخطط {p['plan_number']} وعدد العقار {p['parcel_number']}"
    elif district == 'حي الزهراء':
        title = f"منزل مستقل في {district}, {city} برقم مخطط {p['plan_number']} وعدد العقار {p['parcel_number']}"
    elif district == 'حي البساتين':
        title = f"فيلا فاخرة في {district}, {city} برقم مخطط {p['plan_number']} وعدد العقار {p['parcel_number']}"
    elif district == 'حي الروضة':
        title = f"منزل بتل العودة برقم مخطط {p['plan_number']} في {city}"
    elif district == 'حي الرصيفة':
        title = f"فيلا في {district} بمكة برقم مخطط {p['plan_number']} وعدد العقار {p['parcel_number']}"
    elif district == 'حي العزيزية':
        title = f"فيلا في {district} بمكة برقم مخطط {p['plan_number']} وعدد العقار {p['parcel_number']}"
    elif district == 'حي الشرائع':
        title = f"شقة سكنية برقم مخطط {p['plan_number']} في مكة"
    elif district == 'حي النزهة':
        title = f"شقة برقم مخطط {p['plan_number']} في {city}"
    elif district == 'حي الفيحاء':
        title = f"شقة برقم مخطط {p['plan_number']} في {city}"
    elif district == 'حي العقربية':
        title = f"شقة مميزة برقم مخطط {p['plan_number']} في {city}"
    elif district == 'حي الثقبة':
        title = f"شقة برقم مخطط {p['plan_number']} في {city}"
    elif district == 'حي الزهراء':
        title = f"شقة برقم مخطط {p['plan_number']} في {city}"
    elif district == 'حي المنتزه':
        title = f"شقة برقم مخطط {p['plan_number']} في {city}"
    else:
        title = f"عقار {p['plan_number']}, {district}, {city} - ورقم العقار {p['parcel_number']}"

    p.update({
        'id': len(properties),
        'title': title,
        'type': 'شقة سكنية' if 'شقة' in title else 'فيلا',
        'loc': f"{p['district']}, {p['city']}",
        'district': district,
        'city': city,
        'area': 150 + int(p['plan_number']) % 200,
        'rooms': 3 + int(p['parcel_number']) % 4,
        'baths': 2 + int(p['plan_number']) % 3,
        'cars': 1 + int(p['parcel_number']) % 2,
        'price': 500000 + int(p['plan_number']) * 10000,
        'year': 2010 + int(p['plan_number']) % 12,
        'description': f"عقار سكني بمساحة طبيعية في {district} بـ {city} مع جميع المرافق الأساسية",
        'features': ['حديقة خاصة', 'موقف سيارات', 'سيارات', 'غرفة'],
        'lat': coords['lat'],
        'lng': coords['lng'],
        'purpose': 'بيع' if p['usage'] == 'سكني' else 'إيجار',
        'status': 'حصري' if p['usage'] == 'سكني' else 'متاح',
        'trust': 'verified',
        'street': f'Street {p["plan_number"]}',
        'streetWidth': 10 + int(p['plan_number']) % 5,
        'facing': ['شرقي', 'غربي', 'شمالي', 'جنوبي'][int(p['plan_number']) % 4],
        'images': [],
        'pano': None,
        'agentName': 'مكتب الديار العقارية',
        'agentPhone': '+966570123456',
        'agentOffice': 'شركة الواحة العقارية',
        'views': 0,
        'favorites': 0,
        'createdAt': '2023-01-15',
        'updatedAt': '2023-12-20'
    })

# تعيين الصور لكل عقار
images_map = {
    "شقة في حي العارض, الرياض برقم مخطط 3456 وعدد العقار 10123": ['/uploads/properties/apt1.jpg', '/uploads/properties/apt2.jpg'],
    "شقة في حي العارض, الرياض برقم مخطط 3456 وعدد العقار 10124": ['/uploads/properties/apt3.jpg', '/uploads/properties/apt1.jpg'],
    "فيلا في حي النرجس, الرياض برقم مخطط 2210 وعدد العقار 22011": ['/uploads/properties/villa1.jpg', '/uploads/properties/villa3.jpg'],
    "شقة مميزة في حي الياسمين, الرياض برقم مخطط 3300 وعدد العقار 33001": ['/uploads/properties/apt1.jpg', '/uploads/properties/apt2.jpg'],
    "منزل مستقل في حي الزهراء, جدة برقم مخطط 5678 وعدد العقار 22021": ['/uploads/properties/villa3.jpg', '/uploads/properties/apt2.jpg'],
    "فيلا فاخرة في حي البساتين, جدة برقم مخطط 5680 وعدد العقار 22031": ['/uploads/properties/villa2.jpg', '/uploads/properties/apt3.jpg'],
    "فيلا بغرف متعددة في حي الروضة, جدة برقم مخطط 5690 وعدد العقار 22041": ['/uploads/properties/villa1.jpg', '/uploads/properties/villa2.jpg'],
    "منزل بتل العودة برقم مخطط 7788 في جدة": ['/uploads/properties/apt2.jpg', '/uploads/properties/apt1.jpg'],
    "فيلا في حي العزيزية بمكة برقم مخطط 7790 وعدد العقار 33021": ['/uploads/properties/villa2.jpg', '/uploads/properties/villa1.jpg'],
    "شقة سكنية برقم مخطط 7800 في مكة": ['/uploads/properties/apt3.jpg', '/uploads/properties/apt1.jpg'],
    "شقة برقم مخطط 8899 في الرياض": ['/uploads/properties/apt1.jpg', '/uploads/properties/apt2.jpg'],
    "شقة برقم مخطط 8900 في الرياض": ['/uploads/properties/apt3.jpg', '/uploads/properties/villa1.jpg'],
    "شقة مميزة برقم مخطط 9900 في الرياض": ['/uploads/properties/apt2.jpg', '/uploads/properties/villa3.jpg'],
    "شقة برقم مخطط 9905 في الرياض": ['/uploads/properties/apt1.jpg', '/uploads/properties/villa2.jpg'],
    "شقة برقم مخطط 1122 في حائل": ['/uploads/properties/apt3.jpg', '/uploads/properties/apt1.jpg'],
    "شقة برقم مخطط 1125 في حائل": ['/uploads/properties/apt2.jpg', '/uploads/properties/villa1.jpg'],
}

for p in properties:
    title = p['title']
    if title in images_map:
        p['images'] = images_map[title]
    else:
        p['images'] = ['/uploads/properties/apt1.jpg', '/uploads/properties/villa1.jpg']

# إنشاء المساهمين
contributors = [
    {'name': 'مكتب العقارات الفاخرة', 'role': ' وسيط عقاري مرخص', 'phone': '+966501234567', 'email': 'real@estate.darak.com'},
    {'name': 'شركاء الاستثمار', 'role': 'مالك العقار', 'phone': '+966502345678', 'email': 'invest@partnership.darak.com'},
    {'name': 'مدير أملاك الرياض', 'role': 'مدير العقارات', 'phone': '+966503456789', 'email': 'manager@riyadh.properties.darak.com'},
]

# إخراج البيانات
output = {
    'properties': properties,
    'contributors': contributors,
}

print(json.dumps(output, ensure_ascii=False, indent=2))
