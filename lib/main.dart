import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'dart:developer' as dev;

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AIObjectDetector(),
    ));

class AIObjectDetector extends StatefulWidget {
  const AIObjectDetector({super.key});

  @override
  State<AIObjectDetector> createState() => _AIObjectDetectorState();
}

class _AIObjectDetectorState extends State<AIObjectDetector> {
  File? _image;
  List? _outputs;
  final _picker = ImagePicker();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  // 1. โหลดโมเดล (ปรับเป็น V2 ตามโจทย์ข้อ 5.2)
  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        // เปลี่ยนชื่อไฟล์เป็น mobilenetv2.tflite
        model: "assets/mobilenetv2.tflite", 
        labels: "assets/labels.txt",
      );
      dev.log("Model V2 Loaded: $res");
    } catch (e) {
      dev.log("Error loading model: $e");
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  // 2. เลือกรูปภาพ
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _loading = true;
        _image = File(image.path);
        _outputs = null; // เคลียร์ค่าเก่าก่อน
      });

      await classifyImage(_image!);
    } catch (e) {
      dev.log("Error picking image: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  // 3. ประมวลผลภาพ (ปรับให้แสดง 3 อันดับ)
  Future<void> classifyImage(File image) async {
    try {
      var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 3,    // <--- แก้เป็น 3 ตามโจทย์ข้อ 5.2
        threshold: 0.1,   // ลดเกณฑ์ลงเล็กน้อยเพื่อให้เห็นอันดับรองๆ ได้ง่ายขึ้น
        imageMean: 127.5, // คงค่านี้ไว้ตามโจทย์ (ห้ามเปลี่ยนเป็น 0 หรือ 1)
        imageStd: 127.5,
      );

      setState(() {
        _loading = false;
        _outputs = output;
      });
    } catch (e) {
      dev.log("Error running model: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  // 4. สร้าง UI แสดงผล (ปรับให้โชว์รายการ Top 3)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // เพิ่มไอคอนสายฟ้า ⚡ ตามชื่อโจทย์ Speed Demon
        title: const Text('AI Detector V2 (Top 3) ⚡'), 
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ส่วนแสดงรูปภาพ
                    _image == null
                        ? Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text('No image selected')),
                          )
                        : SizedBox(
                            height: 350,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            ),
                          ),
                    const SizedBox(height: 20),

                    // ส่วนแสดงผลลัพธ์ (Top 3 Results)
                    _outputs != null && _outputs!.isNotEmpty
                        ? Column(
                            children: _outputs!.map((result) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                color: Colors.teal.shade50,
                                child: ListTile(
                                  // แสดงชื่อ (Label)
                                  title: Text(
                                    "${result["label"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  // แสดงความมั่นใจ (Confidence %)
                                  trailing: Text(
                                    "${(result["confidence"] * 100).toStringAsFixed(1)}%",
                                    style: const TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : const Text("Waiting for result..."),

                    const SizedBox(height: 30),

                    // ปุ่มควบคุม
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: "cam",
                          onPressed: () => pickImage(ImageSource.camera),
                          tooltip: 'Camera',
                          backgroundColor: Colors.teal,
                          child: const Icon(Icons.camera_alt),
                        ),
                        const SizedBox(width: 20),
                        FloatingActionButton(
                          heroTag: "gal",
                          onPressed: () => pickImage(ImageSource.gallery),
                          tooltip: 'Gallery',
                          backgroundColor: Colors.teal,
                          child: const Icon(Icons.photo_library),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}