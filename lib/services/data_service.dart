import 'dart:convert';
import 'package:flutter/services.dart';

class DataService {
  Future<String> leerArchivoJson(String nombreArchivo) async {
    try {
      return await rootBundle.loadString('assets/data/$nombreArchivo');
    } catch (e) {
      throw Exception('Error al leer el archivo $nombreArchivo: $e');
    }
  }

  Future<void> escribirArchivoJson(String nombreArchivo, String contenido) async {
    // En una aplicación real, aquí se implementaría la lógica para escribir en el archivo
    // Por ahora, solo simulamos la escritura exitosa
    await Future.delayed(const Duration(milliseconds: 500));
  }
} 