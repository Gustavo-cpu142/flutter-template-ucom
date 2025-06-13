import 'package:get/get.dart';
import 'package:finpay/api/local.db.service.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:flutter/material.dart';
import 'package:finpay/controller/home_controller.dart';

class TopUpController extends GetxController {
  final db = LocalDBService();
  RxList<Map<String, dynamic>> reservasPendientes = <Map<String, dynamic>>[].obs;
  Rx<Map<String, dynamic>?> reservaSeleccionada = Rx<Map<String, dynamic>?>(null);
  RxString metodoPagoSeleccionado = 'Tarjeta de Crédito'.obs;

  @override
  void onInit() {
    super.onInit();
    print("TopUpController inicializado");
    cargarReservasPendientes();
  }

  Future<void> cargarReservasPendientes() async {
    try {
      print("Cargando reservas pendientes...");
      final reservas = await db.getAll("reservas.json");
      print("Reservas encontradas: ${reservas.length}");
      print("Contenido de reservas: $reservas");
      
      // Filtrar solo las reservas activas o reservadas
      final reservasFiltradas = reservas.where((r) {
        final estado = r['estado'] as String;
        final esPendiente = estado == "ACTIVA" || estado == "RESERVADA";
        print("Reserva ${r['codigoReserva']} - Estado: $estado - Es pendiente: $esPendiente");
        return esPendiente;
      }).toList();
      
      print("Reservas filtradas: ${reservasFiltradas.length}");
      reservasPendientes.value = reservasFiltradas;
      
      // Forzar actualización de la UI
      reservasPendientes.refresh();
    } catch (e, stackTrace) {
      print("Error al cargar reservas: $e");
      print("Stack trace: $stackTrace");
      reservasPendientes.value = [];
    }
  }

  void seleccionarReserva(Map<String, dynamic> reserva) {
    print("Seleccionando reserva: ${reserva['codigoReserva']}");
    reservaSeleccionada.value = reserva;
  }

  void seleccionarMetodoPago(String metodo) {
    print("Seleccionando método de pago: $metodo");
    metodoPagoSeleccionado.value = metodo;
  }

  Future<bool> procesarPago() async {
    if (reservaSeleccionada.value == null) {
      print("Error: No hay reserva seleccionada");
      Get.snackbar(
        "Error",
        "Por favor selecciona una reserva para pagar",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (metodoPagoSeleccionado.value.isEmpty) {
      print("Error: No hay método de pago seleccionado");
      Get.snackbar(
        "Error",
        "Por favor selecciona un método de pago",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      print("Procesando pago para reserva: ${reservaSeleccionada.value!['codigoReserva']}");
      
      // Verificar si la reserva ya está pagada
      final reservas = await db.getAll("reservas.json");
      final index = reservas.indexWhere(
        (r) => r['codigoReserva'] == reservaSeleccionada.value!['codigoReserva']
      );

      if (index == -1) {
        print("Error: No se encontró la reserva");
        Get.snackbar(
          "Error",
          "No se encontró la reserva seleccionada",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (reservas[index]['estado'] == "PAGADA") {
        print("Error: La reserva ya está pagada");
        Get.snackbar(
          "Error",
          "Esta reserva ya ha sido pagada",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      // Actualizar estado de la reserva
      print("Actualizando estado de la reserva");
      reservas[index]['estado'] = "PAGADA";
      await db.saveAll("reservas.json", reservas);

      // Crear registro de pago
      final pagos = await db.getAll("pagos.json");
      final nuevoPago = {
        "codigoPago": "PAG-${DateTime.now().millisecondsSinceEpoch}",
        "codigoReservaAsociada": reservaSeleccionada.value!['codigoReserva'],
        "montoPagado": reservaSeleccionada.value!['monto'] ?? 10000, // Usar el monto de la reserva o un valor por defecto
        "fechaPago": DateTime.now().toIso8601String(),
        "estadoPago": "COMPLETADO", // Asegurarnos de que el estado sea COMPLETADO
        "metodoPago": metodoPagoSeleccionado.value
      };

      print("Creando nuevo pago: $nuevoPago");
      pagos.add(nuevoPago);
      await db.saveAll("pagos.json", pagos);

      // Actualizar estadísticas en el HomeController
      final homeController = Get.find<HomeController>();
      await homeController.actualizarEstadisticas();
      print("Estadísticas actualizadas");

      // Limpiar selección
      reservaSeleccionada.value = null;
      metodoPagoSeleccionado.value = 'Tarjeta de Crédito';

      return true;
    } catch (e, stackTrace) {
      print("Error al procesar pago: $e");
      print("Stack trace: $stackTrace");
      Get.snackbar(
        "Error",
        "Ocurrió un error al procesar el pago. Por favor intenta nuevamente.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }
} 