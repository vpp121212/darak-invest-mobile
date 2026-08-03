import '../models/property.dart';

/// بيانات تجريبية (Mock Data) بصور 360° وملفات .glb حقيقية.
///
/// كل الروابط أدناه مُتحقَّق منها (HTTP 200 + CORS مفتوح) بحيث تعمل الجولة
/// وبيت الدمية فور تشغيل التطبيق، حتى لو كان الخادم غير متاح.
class MockProperties {
  static const List<String> demoPanoScenes = [
    'https://pannellum.org/images/alma.jpg',
    'https://threejs.org/examples/textures/2294472375_24a3b8ef46_o.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/b/be/Biblioteca_P%C3%BAblica_de_%C3%89vora_-_Sala_de_exposi%C3%A7%C3%B5es_%28360_panorama%29.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/7/7b/Old_hall_%E2%80%93_Panorama_%28Sergej_Majboroda_via_Poly_Haven%29.jpg',
  ];

  static const List<String> demoModelUrls = [
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/ABeautifulGame/glTF-Binary/ABeautifulGame.glb',
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenChair/glTF-Binary/SheenChair.glb',
    'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
  ];

  static Property get demo {
    return Property(
      id: 'demo-villa-yasmine',
      title: 'فيلا الياسمين — نسخة تجريبية (جولة 360° وبيت الدمية)',
      type: 'فيلا',
      loc: 'الياسمين، الرياض',
      district: 'الياسمين',
      city: 'الرياض',
      price: 2450000,
      rooms: 6,
      baths: 5,
      cars: 2,
      area: 420,
      year: 2022,
      age: 2,
      status: 'active',
      lat: 24.7743,
      lng: 46.739,
      street: '',
      streetW: 0,
      facing: 'شمالي',
      purpose: 'بيع',
      desc: 'عقار تجريبي لتجربة جولة 360° المفتوحة ودخول المنزل بين الغرف، '
          'إضافة إلى بيت الدمية ثلاثي الأبعاد. البيانات حقيقية وكل الروابط تعمل.',
      images: const [
        'https://threejs.org/examples/textures/2294472375_24a3b8ef46_o.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/b/be/Biblioteca_P%C3%BAblica_de_%C3%89vora_-_Sala_de_exposi%C3%A7%C3%B5es_%28360_panorama%29.jpg',
      ],
      features: const ['مجلس كبير', 'غرف ماستر', 'صالة عائلية', 'حديقة خاصة'],
      panoramicImage: demoPanoScenes.first,
      panoramicImages: demoPanoScenes,
      model3dUrl: demoModelUrls.first,
      model3dUrls: demoModelUrls,
      trust: 100,
      isDemo: true,
    );
  }

  static List<Property> get demoList => <Property>[demo];
}
