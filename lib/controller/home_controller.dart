// ignore_for_file: deprecated_member_use

import 'package:finpay/api/local.db.service.dart';
import 'package:finpay/config/images.dart';
import 'package:finpay/config/textstyle.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final db = LocalDBService();
  RxList<TransactionModel> transactionList = <TransactionModel>[].obs;
  RxBool isWeek = true.obs;
  RxBool isMonth = false.obs;
  RxBool isYear = false.obs;
  RxBool isAdd = false.obs;
  RxList<Pago> pagosPrevios = <Pago>[].obs;
  RxList<Map<String, dynamic>> pagosRecientes = <Map<String, dynamic>>[].obs;

  RxInt pagosRealizadosMes = 0.obs;
  RxInt pagosPendientes = 0.obs;
  RxInt totalAutos = 0.obs;
  RxDouble montoTotalMes = 0.0.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    print("Inicializando HomeController...");
    // Inicializar contadores
    totalAutos.value = 0;
    pagosPendientes.value = 0;
    pagosRealizadosMes.value = 0;
    montoTotalMes.value = 0.0;
    
    // Cargar datos iniciales
    customInit();
  }

  customInit() async {
    print("Iniciando customInit...");
    try {
      isLoading.value = true;
      
      // Primero actualizamos el total de autos
      await actualizarTotalAutos();
      print("Total de autos actualizado: $totalAutos");

      // Luego cargamos los pagos y otras estadísticas
      await cargarPagosPrevios();
      await actualizarPagosPendientes();
      await actualizarPagosDelMes();
      
      isWeek.value = true;
      isMonth.value = false;
      isYear.value = false;
      
      // Forzar actualización de la UI
      update();
      print("customInit completado");
    } catch (e) {
      print("Error en customInit: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cargarPagosPrevios() async {
    try {
      print("Iniciando carga de pagos previos...");
      final data = await db.getAll("pagos.json");
      print("Pagos encontrados en el archivo: ${data.length}");

      final pagos = data.map((json) {
        try {
          final pago = Pago.fromJson(json);
          print("Pago cargado: ${pago.codigoReservaAsociada} - ${pago.fechaPago} - Estado: ${pago.estadoPago}");
          return pago;
        } catch (e) {
          print("Error al procesar pago: $e");
          return null;
        }
      }).whereType<Pago>().toList();

      pagosPrevios.value = pagos;
      print("Total de pagos procesados: ${pagos.length}");

      await actualizarPagosDelMes();
      await actualizarPagosPendientes();
    } catch (e) {
      print("Error al cargar pagos previos: $e");
    }
  }

  Future<void> cargarPagosRecientes() async {
    try {
      final pagosJson = await db.getAll("pagos.json");
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

      final pagosFiltrados = pagosJson.where((pago) {
        final fechaPago = DateTime.parse(pago['fechaPago']);
        final estadoPago = pago['estadoPago'] ?? "PENDIENTE";
        return (fechaPago.isAfter(inicioMes) || fechaPago.isAtSameMomentAs(inicioMes)) &&
               (fechaPago.isBefore(finMes) || fechaPago.isAtSameMomentAs(finMes)) &&
               estadoPago == "COMPLETADO";
      }).toList();

      // Ordenar por fecha más reciente
      pagosFiltrados.sort((a, b) {
        final fechaA = DateTime.parse(a['fechaPago']);
        final fechaB = DateTime.parse(b['fechaPago']);
        return fechaB.compareTo(fechaA);
      });

      pagosRecientes.value = pagosFiltrados;
    } catch (e) {
      print("Error al cargar pagos recientes: $e");
    }
  }

  Future<void> actualizarPagosDelMes() async {
    try {
      print("Iniciando actualización de pagos del mes...");
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
      
      // Obtener todos los pagos del archivo
      final pagosJson = await db.getAll("pagos.json");
      
      int pagosDelMes = 0;
      double montoTotal = 0;

      for (var pago in pagosJson) {
        try {
          final fechaPago = DateTime.parse(pago['fechaPago']);
          final estadoPago = pago['estadoPago'] ?? "PENDIENTE";
          final monto = double.tryParse(pago['montoPagado'].toString()) ?? 0;
          
          final esDelMes = (fechaPago.isAfter(inicioMes) || fechaPago.isAtSameMomentAs(inicioMes)) && 
                          (fechaPago.isBefore(finMes) || fechaPago.isAtSameMomentAs(finMes));
          final esCompletado = estadoPago == "COMPLETADO";
          
          if (esDelMes && esCompletado) {
            pagosDelMes++;
            montoTotal += monto;
          }
        } catch (e) {
          print("Error al procesar pago: $e");
        }
      }

      // Actualizar los contadores
      pagosRealizadosMes.value = pagosDelMes;
      montoTotalMes.value = montoTotal;
      
      // Forzar actualización de la UI
      update();
    } catch (e) {
      print("Error al actualizar pagos del mes: $e");
    }
  }

  void mostrarNotificacionPago(Map<String, dynamic> pago) {
    final monto = double.tryParse(pago['montoPagado'].toString()) ?? 0;
    final fechaPago = DateTime.parse(pago['fechaPago']);
    final codigoReserva = pago['codigoReservaAsociada'];

    Get.snackbar(
      'Pagos',
      'Reservas y home',
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nuevo pago registrado',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Reserva: $codigoReserva',
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            'Monto: ₲${monto.toStringAsFixed(0)}',
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            'Fecha: ${fechaPago.toString().split('.')[0]}',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 5),
      margin: EdgeInsets.all(10),
      borderRadius: 10,
      icon: Icon(Icons.payment, color: Colors.white),
    );
  }

  Future<void> actualizarPagosPendientes() async {
    try {
      print("Iniciando actualización de pagos pendientes...");
      final reservasJson = await db.getAll("reservas.json");
      print("Total de reservas encontradas: ${reservasJson.length}");

      int reservasPendientes = 0;
      for (var reserva in reservasJson) {
        try {
          final estado = reserva['estadoReserva'] as String;
          print("Procesando reserva con estado: $estado");
          
          if (estado == "PENDIENTE" || estado == "ACTIVA" || estado == "RESERVADA") {
            reservasPendientes++;
            print("Reserva pendiente encontrada. Total actual: $reservasPendientes");
          }
        } catch (e) {
          print("Error al procesar estado de reserva: $e");
        }
      }

      print("Total de reservas pendientes: $reservasPendientes");
      pagosPendientes.value = reservasPendientes;
      
      // Forzar actualización de la UI
      update();
      print("Contador de pagos pendientes actualizado: ${pagosPendientes.value}");
    } catch (e) {
      print("Error al actualizar pagos pendientes: $e");
    }
  }

  Future<void> actualizarTotalAutos() async {
    try {
      print("Iniciando actualización de total de autos...");
      final autosJson = await db.getAll("autos.json");
      print("Autos encontrados en el archivo: ${autosJson.length}");
      
      final autosUnicos = <String>{};
      for (var auto in autosJson) {
        try {
          final chapa = auto['chapa'] as String;
          if (chapa.isNotEmpty) {
            autosUnicos.add(chapa);
            print("Auto procesado: $chapa");
          } else {
            print("Advertencia: Se encontró un auto con chapa vacía");
          }
        } catch (e) {
          print("Error al procesar auto: $e");
          print("Contenido del auto: $auto");
        }
      }

      print("Total de autos únicos encontrados: ${autosUnicos.length}");
      print("Lista de chapas únicas: ${autosUnicos.toList()}");
      
      totalAutos.value = autosUnicos.length;
      print("Contador de total de autos actualizado a: ${totalAutos.value}");
      
      // Forzar actualización de la UI
      update();
    } catch (e) {
      print("Error al actualizar total de autos: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  Future<void> actualizarEstadisticas() async {
    print("Actualizando estadísticas...");
    try {
      isLoading.value = true;
      
      // Primero actualizamos el total de autos
      await actualizarTotalAutos();
      print("Total de autos actualizado: $totalAutos");
      
      // Luego actualizamos los pagos pendientes
      await actualizarPagosPendientes();
      print("Pagos pendientes actualizados: $pagosPendientes");
      
      // Finalmente actualizamos los pagos del mes
      await actualizarPagosDelMes();
      print("Pagos del mes actualizados: $pagosRealizadosMes");
      
    } catch (e) {
      print("Error al actualizar estadísticas: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
