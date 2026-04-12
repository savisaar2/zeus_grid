import 'package:flutter/material.dart';
import 'package:zeus_grid/zeus_grid.dart';

void main() => runApp(const MaterialApp(home: ZeusTestBench()));

class ZeusTestBench extends StatefulWidget {
  const ZeusTestBench({super.key});

  @override
  State<ZeusTestBench> createState() => _ZeusTestBenchState();
}

class _ZeusTestBenchState extends State<ZeusTestBench> {
  bool _isEditing = true;

  // 1. Modules currently displayed on the grid
  List<ZeusModule> myModules = [
    const ZeusModule(id: 'module_a', x: 10, y: 10, w: 40, h: 30, minW: 20, minH: 15),
  ];

  // 2. Modules waiting in the "Arsenal" side menu
  List<ZeusModule> myArsenal = [
    const ZeusModule(id: 'module_b', x: 0, y: 0, w: 80, h: 30, minW: 40, minH: 20),
    const ZeusModule(id: 'module_c', x: 0, y: 0, w: 30, h: 20, minW: 10, minH: 10),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "ZEUS // ENGINE_TEST",
          style: TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
        backgroundColor: Colors.black,
        actions: [
          Row(
            children: [
              const Text("EDIT", style: TextStyle(fontSize: 10, color: Colors.white70)),
              Switch(
                value: _isEditing,
                onChanged: (v) => setState(() => _isEditing = v),
                activeColor: Colors.greenAccent,
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ZeusGrid(
        isEditing: _isEditing,
        autoPack: true,
        cellSide: 10.0, // Fixed grid size
        modules: myModules,
        unplacedModules: myArsenal, 
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
          final fromArsenalIndex = myArsenal.indexWhere((item) => item.id == m.id);
          if (fromArsenalIndex != -1) {
            myArsenal.removeAt(fromArsenalIndex);
            myModules.add(m);
          } else {
            final i = myModules.indexWhere((item) => item.id == m.id);
            if (i != -1) myModules[i] = m;
          }
        }),

        onModuleRemove: (id) => setState(() {
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
