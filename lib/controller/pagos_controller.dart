import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/services/data_service.dart';
import 'package:finpay/controller/home_controller.dart';

class PagosController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  
  final reservasPendientes = <Reserva>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    cargarReservasPendientes();
  }

  Future<void> cargarReservasPendientes() async {
    try {
      isLoading.value = true;
      
      // Cargar reservas
      final reservasJson = await _dataService.leerArchivoJson('reservas.json');
      final List<dynamic> reservasList = json.decode(reservasJson);
      print("Reservas cargadas del archivo: ${reservasList.length}");
      
      // Cargar autos para obtener información completa
      final autosJson = await _dataService.leerArchivoJson('autos.json');
      final List<dynamic> autosList = json.decode(autosJson);
      print("Autos cargados del archivo: ${autosList.length}");
      
      // Crear mapa de autos por chapa
      final mapaAutos = {
        for (var auto in autosList)
          auto['chapa']: auto
      };
      print("Mapa de autos creado con ${mapaAutos.length} entradas");
      
      // Procesar reservas y agregar información de autos
      final reservasProcesadas = reservasList.map((json) {
        final chapa = json['chapaAuto'];
        final autoInfo = mapaAutos[chapa];
        
        print("Procesando reserva con chapa: $chapa");
        print("Información del auto encontrada: ${autoInfo != null ? 'Sí' : 'No'}");
        
        // Agregar información del auto a la reserva
        json['marcaAuto'] = autoInfo?['marca'] ?? 'No especificada';
        print("Marca asignada: ${json['marcaAuto']}");
        
        return Reserva.fromJson(json);
      }).where((reserva) {
        final esValida = reserva.estadoReserva == "PENDIENTE" ||
            reserva.estadoReserva == "ACTIVA" ||
            reserva.estadoReserva == "RESERVADA";
        print("Reserva ${reserva.codigoReserva} - Estado: ${reserva.estadoReserva} - Válida: $esValida");
        return esValida;
      }).toList();
      
      print("Reservas procesadas: ${reservasProcesadas.length}");
      if (reservasProcesadas.isNotEmpty) {
        print("Primera reserva procesada: ${reservasProcesadas.first.toJson()}");
      }
      
      reservasPendientes.value = reservasProcesadas;
      
    } catch (e) {
      print("Error al cargar reservas: $e");
      Get.snackbar(
        "Error",
        "No se pudieron cargar las reservas pendientes",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> procesarPago(String codigoReserva) async {
    try {
      isLoading.value = true;
      
      // Obtener la reserva
      final reservasJson = await _dataService.leerArchivoJson('reservas.json');
      final List<dynamic> reservasList = json.decode(reservasJson);
      final reserva = reservasList.firstWhere(
        (r) => r['codigoReserva'] == codigoReserva,
        orElse: () => throw Exception('Reserva no encontrada'),
      );

      // Crear el registro de pago
      final pago = {
        'codigoPago': 'PAG-${DateTime.now().millisecondsSinceEpoch}',
        'codigoReservaAsociada': codigoReserva,
        'montoPagado': reserva['monto'],
        'fechaPago': DateTime.now().toIso8601String(),
        'estadoPago': 'COMPLETADO',
      };

      // Guardar el pago
      final pagosJson = await _dataService.leerArchivoJson('pagos.json');
      List<dynamic> pagosList = [];
      try {
        pagosList = json.decode(pagosJson);
      } catch (e) {
        print("No hay pagos previos, iniciando nueva lista");
      }
      
      pagosList.add(pago);
      await _dataService.escribirArchivoJson('pagos.json', json.encode(pagosList));

      // Actualizar estado de la reserva
      reserva['estadoReserva'] = 'PAGADA';
      await _dataService.escribirArchivoJson('reservas.json', json.encode(reservasList));

      // Obtener el HomeController y actualizar contadores
      final homeController = Get.find<HomeController>();
      
      // Actualizar contadores
      homeController.pagosPendientes.value = homeController.pagosPendientes.value - 1;
      homeController.pagosRealizadosMes.value = homeController.pagosRealizadosMes.value + 1;
      homeController.totalAutos.value = homeController.totalAutos.value + 1;
      
      print("Pagos Pendientes decrementado: ${homeController.pagosPendientes.value}");
      print("Pagos del Mes incrementado: ${homeController.pagosRealizadosMes.value}");
      print("Total Autos incrementado: ${homeController.totalAutos.value}");
      
      // Forzar actualización de la UI
      homeController.update();

      // Recargar las reservas pendientes
      await cargarReservasPendientes();

      Get.snackbar(
        'Éxito',
        'Pago procesado correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      return true;
    } catch (e) {
      print('Error al procesar pago: $e');
      Get.snackbar(
        'Error',
        'No se pudo procesar el pago',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelarReserva(Reserva reserva) async {
    try {
      isLoading.value = true;
      print("Iniciando cancelación de reserva: ${reserva.codigoReserva}");
      
      // Actualizar estado de la reserva
      final reservasJson = await _dataService.leerArchivoJson('reservas.json');
      final List<dynamic> reservasList = json.decode(reservasJson);
      
      final reservaIndex = reservasList.indexWhere(
        (r) => r['codigoReserva'] == reserva.codigoReserva
      );

      if (reservaIndex == -1) {
        print("Reserva no encontrada");
        return false;
      }

      // Actualizar el estado de la reserva a CANCELADA
      reservasList[reservaIndex]['estadoReserva'] = 'CANCELADA';
      await _dataService.escribirArchivoJson('reservas.json', json.encode(reservasList));

      // Obtener el HomeController y actualizar contadores
      final homeController = Get.find<HomeController>();
      homeController.pagosPendientes.value = homeController.pagosPendientes.value - 1;
      
      // Recargar las reservas pendientes
      await cargarReservasPendientes();

      print("Reserva cancelada exitosamente");
      return true;
    } catch (e) {
      print("Error al cancelar reserva: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
} 