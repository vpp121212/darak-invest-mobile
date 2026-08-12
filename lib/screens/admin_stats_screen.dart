import 'package:flutter/material.dart';
import '../services/api_service.dart';
class AdminStatsScreen extends StatefulWidget { const AdminStatsScreen({super.key}); @override State<AdminStatsScreen> createState() => _AdminStatsScreenState(); }
class _AdminStatsScreenState extends State<AdminStatsScreen> {
int propertiesCount = 0;
bool loading = true;
@override void initState() { super.initState(); loadStats(); }
Future<void> loadStats() async {
 try { final props = await ApiService.getProperties(); setState(() { propertiesCount = props.length; loading = false; }); }
 catch(e){ setState(()=> loading=false); }
}
@override Widget build(BuildContext context) {
 return Scaffold(
   appBar: AppBar(title: const Text('لوحة الإدارة')),
   body: loading ? const Center(child: CircularProgressIndicator()) : Padding(
     padding: const EdgeInsets.all(16),
     child: GridView.count(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, children: [
       _card('العقارات', propertiesCount.toString(), Icons.home, Colors.blue),
       _card('المستخدمين', '47', Icons.people, Colors.green),
       _card('الزوار اليوم', '124', Icons.visibility, Colors.orange),
       _card('الأكثر مشاهدة', 'الرياض', Icons.star, Colors.purple),
     ]),
   ),
 );
}
Widget _card(String t,String v,IconData i,Color c){
 return Card(elevation:4, child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i,size:40,color:c), const SizedBox(height:10), Text(v,style: const TextStyle(fontSize:28,fontWeight:FontWeight.bold)), Text(t,style: const TextStyle(color: Colors.grey))]))); 
}
}
