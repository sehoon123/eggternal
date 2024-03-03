import 'package:ar_flutter_plugin_flutterflow/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_flutterflow/ar_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;


class ARTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ARViewPage(),
    );
  }
}

class ARViewPage extends StatefulWidget {
  @override
  _ARViewPageState createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARNode? localObjectNode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Test'),
      ),
      body: ARView(
        onARViewCreated: onARViewCreated,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onLocalObjectAtOriginButtonPressed,
        tooltip: 'Add Local Object',
        child: Icon(Icons.add),
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "triangle.png",
      showWorldOrigin: true,
      handleTaps: false,
    );
    this.arObjectManager!.onInitialize();
  }

  void onLocalObjectAtOriginButtonPressed() async {
    if (localObjectNode != null) {
      arObjectManager!.removeNode(localObjectNode!);
      localObjectNode = null;
    } else {
      var newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/YourModel.gltf",
        scale: vector.Vector3(0.2, 0.2, 0.2),
        position: vector.Vector3(0.0, 0.0, 0.0),
        rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
      );
      bool? didAddLocalNode = await arObjectManager!.addNode(newNode);
      localObjectNode = didAddLocalNode! ? newNode : null;
    }
  }
}
