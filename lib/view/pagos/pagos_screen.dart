import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finpay/controller/pagos_controller.dart';
import 'package:finpay/utils/utiles.dart';
import 'package:finpay/config/textstyle.dart';

class PagosScreen extends StatelessWidget {
  final controller = Get.put(PagosController());

  PagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = HexColor(AppTheme.primaryColorString!);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pagos Pendientes"),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.reservasPendientes.isEmpty) {
          return const Center(
            child: Text(
              "No hay pagos pendientes",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.reservasPendientes.length,
          itemBuilder: (context, index) {
            final reserva = controller.reservasPendientes[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    Text(
                      "Reserva: ${reserva.codigoReserva}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Vehículo: ${reserva.marcaAuto} - ${reserva.chapaAuto}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Monto: ₲${UtilesApp.formatearGuaranies(reserva.monto)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final success = await controller.cancelarReserva(reserva);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Reserva cancelada y lugar liberado"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                await controller.cargarReservasPendientes();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "CANCELAR",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final success = await controller.procesarPago(reserva.codigoReserva);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Pago procesado y lugar liberado"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                await controller.cargarReservasPendientes();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "PAGAR",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
} 