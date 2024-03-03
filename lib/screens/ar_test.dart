import 'package:ar_flutter_plugin_flutterflow/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_node.dart';
import 'package:eggciting/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_flutterflow/ar_flutter_plugin.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARTestApp extends StatelessWidget {
  const ARTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ARViewPage(),
    );
  }
}

class ARViewPage extends StatefulWidget {
  const ARViewPage({super.key});

  @override
  _ARViewPageState createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARNode? localObjectNode;
  String? messageToDisplay;

  int count = 0;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    // Request camera permission for AR functionality
    var status = await Permission.camera.request();
    if (status.isGranted) {
      debugPrint("Camera permission granted");
      // Camera permission is granted, you can initialize AR functionalities here if needed
    } else {
      debugPrint("Camera permission denied");
      // Handle the case where permission is not granted
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Test'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
          ),
          // if (messageToDisplay != null)
          //   Positioned(
          //     top: 100,
          //     left: 100,
          //     child: Material(
          //       color: Colors.transparent,
          //       child: Text(
          //         messageToDisplay!,
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 24,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onLocalObjectAtOriginButtonPressed,
        tooltip: 'Add Local Object',
        child: const Icon(Icons.add),
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
          showWorldOrigin: false,
          handleTaps: true,
        );
    this.arObjectManager!.onInitialize();

    this.arObjectManager!.onNodeTap = onARObjectTapped;
  }

  void onARObjectTapped(List<String> hits) {
    debugPrint("AR object tapped $hits");

    count += 1;

    debugPrint(count.toString());

    if (count >= 5) {
      count = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
    } else {
      int remainingTaps = 5 - count;
      Fluttertoast.showToast(
        msg:
            "Ouch, that hurts!, If you touch me $remainingTaps times, I'll get angry",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void onLocalObjectAtOriginButtonPressed() async {
    // Check if the ARObjectManager is initialized
    if (arObjectManager == null) {
      debugPrint("ARObjectManager is not initialized");
      return;
    }

    // If the local object node already exists, remove it
    if (localObjectNode != null) {
      arObjectManager!.removeNode(localObjectNode!);
      localObjectNode = null;
      debugPrint("Local object removed");
    } else {
      // Assuming you have a method to get the current camera position and orientation
      // This is a placeholder for such a method, which you might need to implement
      // based on the AR framework you're using.
      var cameraPosition = await getCurrentCameraPosition();
      var cameraOrientation = await getCurrentCameraOrientation();

      var newPosition = cameraPosition + cameraOrientation * 1.0;

      // Create a new ARNode for the virtual object
      var newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/3D/Chicken_01/Chicken_01.gltf",
        scale: vector.Vector3(0.2, 0.2, 0.2),
        position: newPosition, // Position at the camera's current position
        rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0), // No rotation
      );

      // Add the new node to the ARObjectManager
      bool? didAddLocalNode = await arObjectManager!.addNode(newNode);
      if (didAddLocalNode == true) {
        localObjectNode = newNode;
        debugPrint("Local object added");
      } else {
        debugPrint("Failed to add local node");
      }
    }
  }

// Placeholder methods for getting the current camera position and orientation
  Future<vector.Vector3> getCurrentCameraPosition() async {
    // Implement this method based on your AR framework
    // This should return the current position of the camera in the AR scene
    return vector.Vector3(0.0, 0.0, 0.0); // Placeholder return value
  }

  Future<vector.Vector3> getCurrentCameraOrientation() async {
    // Implement this method based on your AR framework
    // This should return the current orientation of the camera in the AR scene
    return vector.Vector3(0.0, 0.0, -1.0); // Placeholder return value
  }
}
