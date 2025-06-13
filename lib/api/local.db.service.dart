import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class LocalDBService {
  Future<String> _getFilePath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$filename';
  }

  Future<File> _getFile(String filename, {bool forceUpdate = false}) async {
    final path = await _getFilePath(filename);
    print("Ruta del archivo: $path");
    final file = File(path);

    if (forceUpdate || !await file.exists()) {
      print("Archivo no existe o se fuerza actualización");
      final data = await rootBundle.loadString('assets/data/$filename');
      print("Datos cargados del bundle: $data");
      await file.writeAsString(data); // Sobreescribe si se fuerza
      print("Archivo creado/actualizado");
    }

    return file;
  }

  Future<List<Map<String, dynamic>>> getAll(String filename,
      {bool forceUpdate = false}) async {
    print("Obteniendo datos de $filename");
    final file = await _getFile(filename, forceUpdate: forceUpdate);
    final contents = await file.readAsString();
    print("Contenido del archivo: $contents");
    return List<Map<String, dynamic>>.from(jsonDecode(contents));
  }

  Future<void> saveAll(String filename, List<Map<String, dynamic>> data) async {
    print("Guardando datos en $filename");
    print("Datos a guardar: $data");
    final file = await _getFile(filename);
    await file.writeAsString(jsonEncode(data));
    print("Datos guardados exitosamente");
  }

  Future<void> add(String filename, Map<String, dynamic> newItem) async {
    final list = await getAll(filename);
    list.add(newItem);
    await saveAll(filename, list);
  }

  Future<void> update(String filename, String key, String value,
      Map<String, dynamic> updatedItem) async {
    final list = await getAll(filename);
    final index = list.indexWhere((e) => e[key] == value);
    if (index != -1) {
      list[index] = updatedItem;
      await saveAll(filename, list);
    }
  }

  Future<void> delete(String filename, String key, String value) async {
    final list = await getAll(filename);
    list.removeWhere((e) => e[key] == value);
    await saveAll(filename, list);
  }

  Future<void> procesarPago(Map<String, dynamic> reserva) async {
    final reservas = await getAll("reservas.json");
    final index = reservas.indexWhere((r) => r['codigoReserva'] == reserva['codigoReserva']);
    if (index != -1) {
      reservas[index]['estado'] = "PAGADA";
      await saveAll("reservas.json", reservas);
    }
  }
}
