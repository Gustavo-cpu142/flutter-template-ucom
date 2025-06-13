import 'package:finpay/model/sitema_reservas.dart';
import 'package:get/get.dart';
import 'package:finpay/api/local.db.service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:finpay/controller/home_controller.dart';

class ReservaController extends GetxController {
  RxList<Piso> pisos = <Piso>[].obs;
  Rx<Piso?> pisoSeleccionado = Rx<Piso?>(null);
  RxList<Lugar> lugaresDisponibles = <Lugar>[].obs;
  Rx<Lugar?> lugarSeleccionado = Rx<Lugar?>(null);
  Rx<DateTime?> horarioInicio = Rx<DateTime?>(null);
  Rx<DateTime?> horarioSalida = Rx<DateTime?>(null);
  RxInt duracionSeleccionada = 0.obs;
  final db = LocalDBService();
  RxList<Auto> autosCliente = <Auto>[].obs;
  Rx<Auto?> autoSeleccionado = Rx<Auto?>(null);
  String codigoClienteActual =
      'cliente_1'; // ← este puede venir de login o contexto
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    print("Inicializando ReservaController...");
    resetearCampos();
    cargarDatosIniciales();
  }

  Future<void> cargarDatosIniciales() async {
    try {
      print("Cargando datos iniciales...");
      await cargarAutosDelCliente();
      await cargarPisosYLugares();
      print("Datos iniciales cargados correctamente");
    } catch (e) {
      print("Error al cargar datos iniciales: $e");
    }
  }

  Future<void> cargarPisosYLugares() async {
    final rawPisos = await db.getAll("pisos.json");
    final rawLugares = await db.getAll("lugares.json");
    final rawReservas = await db.getAll("reservas.json");

    final reservas = rawReservas.map((e) => Reserva.fromJson(e)).toList();
    final lugaresReservados = reservas.map((r) => r.codigoReserva).toSet();

    final todosLugares = rawLugares.map((e) => Lugar.fromJson(e)).toList();

    // Unir pisos con sus lugares correspondientes
    pisos.value = rawPisos.map((pJson) {
      final codigoPiso = pJson['codigo'];
      final lugaresDelPiso =
          todosLugares.where((l) => l.codigoPiso == codigoPiso).toList();

      return Piso(
        codigo: codigoPiso,
        descripcion: pJson['descripcion'],
        lugares: lugaresDelPiso,
      );
    }).toList();

    // Inicializar lugares disponibles (solo los no reservados)
    lugaresDisponibles.value = todosLugares.where((l) {
      return !lugaresReservados.contains(l.codigoLugar);
    }).toList();
  }

  Future<void> seleccionarPiso(Piso piso) {
    pisoSeleccionado.value = piso;
    lugarSeleccionado.value = null;

    // filtrar lugares de este piso
    lugaresDisponibles.refresh();
    return Future.value();
  }

  Future<bool> registrarReserva(Reserva nuevaReserva) async {
    try {
      isLoading.value = true;
      print("Iniciando registro de reserva: ${nuevaReserva.codigoReserva}");

      // Verificar si el auto ya existe
      final autos = await db.getAll("autos.json");
      
      bool autoExiste = false;
      for (var auto in autos) {
        if (auto['chapa'] == nuevaReserva.chapaAuto) {
          autoExiste = true;
          break;
        }
      }

      // Si el auto no existe, agregarlo
      if (!autoExiste) {
        print("Auto no encontrado, agregando nuevo auto");
        final nuevoAuto = {
          'chapa': nuevaReserva.chapaAuto,
          'marca': nuevaReserva.marcaAuto,
          'modelo': nuevaReserva.marcaAuto, // Usamos marcaAuto como modelo por ahora
          'clienteId': codigoClienteActual
        };
        autos.add(nuevoAuto);
        await db.saveAll("autos.json", autos);
        print("Nuevo auto agregado correctamente");

        // Actualizar el contador de autos
        final homeController = Get.find<HomeController>();
        homeController.totalAutos.value = homeController.totalAutos.value + 1;
        homeController.update();
        print("Contador de autos actualizado: ${homeController.totalAutos.value}");
      }

      // Guardar la reserva
      final reservas = await db.getAll("reservas.json");
      reservas.add(nuevaReserva.toJson());
      await db.saveAll("reservas.json", reservas);
      print("Reserva guardada correctamente");

      // Actualizar estadísticas
      final homeController = Get.find<HomeController>();
      homeController.pagosPendientes.value = homeController.pagosPendientes.value + 1;
      homeController.update();
      print("Estadísticas actualizadas después del registro");

      Get.snackbar(
        "Éxito",
        "Reserva registrada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );

      return true;
    } catch (e) {
      print("Error al registrar reserva: $e");
      Get.snackbar(
        "Error",
        "Ocurrió un error al registrar la reserva",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> confirmarReserva() async {
    if (pisoSeleccionado.value == null ||
        lugarSeleccionado.value == null ||
        horarioInicio.value == null ||
        horarioSalida.value == null ||
        autoSeleccionado.value == null) {
      Get.snackbar(
        "Error",
        "Por favor complete todos los campos",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    final duracionEnHoras = horarioSalida.value!.difference(horarioInicio.value!).inMinutes / 60;
    if (duracionEnHoras <= 0) {
      Get.snackbar(
        "Error",
        "La duración debe ser mayor a 0",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }

    final montoCalculado = (duracionEnHoras * 10000).roundToDouble();

    final nuevaReserva = Reserva(
      codigoReserva: "RES-${DateTime.now().millisecondsSinceEpoch}",
      horarioInicio: horarioInicio.value!,
      horarioSalida: horarioSalida.value!,
      monto: montoCalculado,
      estadoReserva: "PENDIENTE",
      chapaAuto: autoSeleccionado.value!.chapa,
      marcaAuto: autoSeleccionado.value!.marca,
    );

    try {
      isLoading.value = true;
      print("Iniciando registro de reserva: ${nuevaReserva.codigoReserva}");

      // Verificar si el auto ya existe
      final autos = await db.getAll("autos.json");
      
      bool autoExiste = false;
      for (var auto in autos) {
        if (auto['chapa'] == nuevaReserva.chapaAuto) {
          autoExiste = true;
          break;
        }
      }

      // Si el auto no existe, agregarlo
      if (!autoExiste) {
        print("Auto no encontrado, agregando nuevo auto");
        final nuevoAuto = {
          'chapa': nuevaReserva.chapaAuto,
          'marca': nuevaReserva.marcaAuto,
        };
        autos.add(nuevoAuto);
        await db.saveAll("autos.json", autos);
        print("Nuevo auto agregado correctamente");

        // Actualizar el contador de autos
        final homeController = Get.find<HomeController>();
        await homeController.actualizarTotalAutos();
      }

      // Guardar la reserva
      final reservas = await db.getAll("reservas.json");
      reservas.add(nuevaReserva.toJson());
      await db.saveAll("reservas.json", reservas);
      print("Reserva guardada correctamente");

      // Actualizar estadísticas
      final homeController = Get.find<HomeController>();
      await homeController.actualizarEstadisticas();
      print("Estadísticas actualizadas después del registro");

      Get.snackbar(
        "Éxito",
        "Reserva registrada correctamente",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );

      resetearCampos();
      return true;
    } catch (e) {
      print("Error al registrar reserva: $e");
      Get.snackbar(
        "Error",
        "Ocurrió un error al registrar la reserva",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void resetearCampos() {
    pisoSeleccionado.value = null;
    lugarSeleccionado.value = null;
    horarioInicio.value = null;
    horarioSalida.value = null;
    duracionSeleccionada.value = 0;
  }

  Future<void> cargarAutosDelCliente() async {
    try {
      print("Iniciando carga de autos del cliente...");
      final rawAutos = await db.getAll("autos.json");
      print("Autos encontrados en la base de datos: ${rawAutos.length}");
      
      // Actualizar el contador de total de autos primero
      final homeController = Get.find<HomeController>();
      final autosUnicos = <String>{};
      
      for (var auto in rawAutos) {
        try {
          final chapa = auto['chapa'] as String;
          autosUnicos.add(chapa);
          print("Auto procesado: $chapa");
        } catch (e) {
          print("Error al procesar auto: $e");
        }
      }

      homeController.totalAutos.value = autosUnicos.length;
      print("Total de autos actualizado: ${homeController.totalAutos.value}");
      homeController.update();

      // Luego cargar los autos del cliente
      final autos = rawAutos.map((e) => Auto.fromJson(e)).toList();
      autosCliente.value = autos.where((a) => a.clienteId == codigoClienteActual).toList();
      print("Autos del cliente cargados: ${autosCliente.length}");
      
      // Forzar actualización de la UI
      update();
    } catch (e) {
      print("Error al cargar autos del cliente: $e");
    }
  }

  Future<void> crearReserva() async {
    try {
      if (lugarSeleccionado.value == null ||
          horarioInicio.value == null ||
          horarioSalida.value == null ||
          autoSeleccionado.value == null) {
        Get.snackbar(
          'Error',
          'Por favor complete todos los campos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final monto = calcularMonto();
      final nuevaReserva = {
        'codigoReserva': 'RES-${DateTime.now().millisecondsSinceEpoch}',
        'chapa': autoSeleccionado.value!.chapa,
        'horaInicio': horarioInicio.value!.toIso8601String(),
        'horaFin': horarioSalida.value!.toIso8601String(),
        'monto': monto,
        'estadoReserva': 'PENDIENTE',
        'fechaCreacion': DateTime.now().toIso8601String(),
      };

      print("Creando nueva reserva: ${nuevaReserva['codigoReserva']}");

      // Verificar si el auto ya existe
      final autos = await db.getAll("autos.json");
      bool autoExiste = false;
      
      for (var auto in autos) {
        if (auto['chapa'] == autoSeleccionado.value!.chapa) {
          autoExiste = true;
          break;
        }
      }

      // Si el auto no existe, agregarlo
      if (!autoExiste) {
        print("Auto no encontrado, agregando nuevo auto");
        final nuevoAuto = {
          'chapa': autoSeleccionado.value!.chapa,
          'marca': autoSeleccionado.value!.marca,
          'modelo': autoSeleccionado.value!.modelo,
          'clienteId': codigoClienteActual
        };
        autos.add(nuevoAuto);
        await db.saveAll("autos.json", autos);
        print("Nuevo auto agregado correctamente");
      }

      // Guardar la reserva
      final reservas = await db.getAll("reservas.json");
      reservas.add(nuevaReserva);
      await db.saveAll("reservas.json", reservas);
      print("Reserva guardada correctamente");

      // Obtener el HomeController y actualizar contadores
      final homeController = Get.find<HomeController>();
      
      // Actualizar todos los contadores
      await homeController.actualizarEstadisticas();
      print("Estadísticas actualizadas después de crear reserva");
      
      // Forzar actualización de la UI
      homeController.update();

      Get.snackbar(
        'Éxito',
        'Reserva creada correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Limpiar campos
      resetearCampos();
      update();
    } catch (e) {
      print('Error al crear reserva: $e');
      Get.snackbar(
        'Error',
        'No se pudo crear la reserva',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  double calcularMonto() {
    if (horarioInicio.value == null || horarioSalida.value == null) {
      return 0.0;
    }
    
    final duracion = horarioSalida.value!.difference(horarioInicio.value!);
    final horas = duracion.inHours;
    final tarifaPorHora = 10000.0; // Tarifa base por hora
    
    return horas * tarifaPorHora;
  }

  @override
  void onClose() {
    resetearCampos();
    super.onClose();
  }
}
