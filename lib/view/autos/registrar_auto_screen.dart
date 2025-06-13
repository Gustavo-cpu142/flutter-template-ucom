import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finpay/api/local.db.service.dart';
import 'package:finpay/controller/home_controller.dart';
import 'package:finpay/config/textstyle.dart';

class RegistrarAutoScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _chapaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final db = LocalDBService();

  RegistrarAutoScreen({super.key});

  Future<void> _registrarAuto() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Verificar si el auto ya existe
        final autos = await db.getAll("autos.json");
        bool autoExiste = false;
        
        for (var auto in autos) {
          if (auto['chapa'] == _chapaController.text) {
            autoExiste = true;
            break;
          }
        }

        if (autoExiste) {
          Get.snackbar(
            'Error',
            'Ya existe un auto con esta chapa',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // Crear nuevo auto
        final nuevoAuto = {
          'chapa': _chapaController.text,
          'marca': _marcaController.text,
          'modelo': _modeloController.text,
          'clienteId': 'cliente_1' // Agregamos el ID del cliente
        };

        // Guardar auto
        autos.add(nuevoAuto);
        await db.saveAll("autos.json", autos);

        // Actualizar contador de autos usando actualizarEstadisticas
        final homeController = Get.find<HomeController>();
        await homeController.actualizarEstadisticas();
        print("Estadísticas actualizadas después de registrar auto");
        
        // Forzar actualización de la UI
        homeController.update();

        Get.snackbar(
          'Éxito',
          'Auto registrado correctamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Limpiar campos
        _chapaController.clear();
        _marcaController.clear();
        _modeloController.clear();

        // Volver a la pantalla anterior
        Get.back();
      } catch (e) {
        print('Error al registrar auto: $e');
        Get.snackbar(
          'Error',
          'No se pudo registrar el auto',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = HexColor(AppTheme.primaryColorString!);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Auto"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _chapaController,
                  decoration: const InputDecoration(
                    labelText: 'Chapa',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la chapa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _marcaController,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la marca';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el modelo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _registrarAuto,
                    child: const Text(
                      'Registrar Auto',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 