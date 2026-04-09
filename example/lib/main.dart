import 'package:flutter/material.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() => runApp(const MaterialApp(home: ZeusTestBench()));

class ZeusTestBench extends StatefulWidget {
  const ZeusTestBench({super.key});

  @override
  State<ZeusTestBench> createState() => _ZeusTestBenchState();
}

class _ZeusTestBenchState extends State<ZeusTestBench> {
  bool _isEditing = false;

  // 1. Modules currently displayed on the grid
  List<ZeusModule> myModules = [
    ZeusModule(id: 'module_a', x: 0, y: 0, w: 40, h: 30, minW: 20, minH: 15),
  ];

  // 2. Modules waiting in the "Arsenal" side menu
  List<ZeusModule> myArsenal = [
    ZeusModule(id: 'module_b', x: 0, y: 0, w: 80, h: 30, minW: 40, minH: 20),
    ZeusModule(id: 'module_c', x: 0, y: 0, w: 30, h: 20, minW: 10, minH: 10),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "ZEUS // ENGINE_TEST",
          style: TextStyle(fontFamily: 'monospace'),
        ),
        backgroundColor: Colors.black,
        actions: [
          const Center(child: Text("EDIT", style: TextStyle(fontSize: 12))),
          Switch(
            value: _isEditing,
            onChanged: (v) => setState(() => _isEditing = v),
            activeColor: Colors.greenAccent,
          ),
        ],
      ),
      body: ZeusGrid(
        isEditing: _isEditing,
        modules: myModules,
        unplacedModules: myArsenal, // 🎯 Pass the arsenal list here
        onGenerateContent: (id) => Container(
          color: Colors.blueGrey.withOpacity(0.1),
          child: Center(
            child: Text(
              id.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),

        onModuleUpdate: (m) => setState(() {
          // Check if this module is coming from the Arsenal
          final fromArsenalIndex = myArsenal.indexWhere(
            (item) => item.id == m.id,
          );

          if (fromArsenalIndex != -1) {
            // 🎯 MOVE: Arsenal -> Grid
            myArsenal.removeAt(fromArsenalIndex);
            myModules.add(m);
          } else {
            // 🎯 UPDATE: Existing Grid Position/Size
            final i = myModules.indexWhere((item) => item.id == m.id);
            if (i != -1) myModules[i] = m;
          }
        }),

        onModuleRemove: (id) => setState(() {
          // 🎯 MOVE: Grid -> Arsenal
          final removedIndex = myModules.indexWhere((m) => m.id == id);
          if (removedIndex != -1) {
            final removedModule = myModules.removeAt(removedIndex);
            myArsenal.add(removedModule);
          }
        }),
      ),
    );
  }
}
