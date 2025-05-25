import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finpay/controller/Alumno/reserva_alumno_controller.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/utils/utiles.dart';
import 'package:finpay/config/textstyle.dart';

class ReservaAlumnoScreen extends StatelessWidget {
  final controller = Get.put(ReservaAlumnoController());

  ReservaAlumnoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = HexColor(AppTheme.primaryColorString!);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservar Estacionamiento"),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(primaryColor),
                  const SizedBox(height: 24),
                  _buildTicketPreview(primaryColor),
                  const SizedBox(height: 24),
                  _buildSelectionSection(
                    "Seleccionar Auto",
                    Icons.directions_car,
                    _buildAutoSelector(),
                  ),
                  const SizedBox(height: 24),
                  _buildSelectionSection(
                    "Seleccionar Piso",
                    Icons.layers,
                    _buildPisoSelector(),
                  ),
                  const SizedBox(height: 24),
                  _buildSelectionSection(
                    "Seleccionar Lugar",
                    Icons.local_parking,
                    _buildLugaresGrid(primaryColor),
                  ),
                  const SizedBox(height: 24),
                  _buildSelectionSection(
                    "Seleccionar Horarios",
                    Icons.access_time,
                    _buildHorariosSelector(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSelectionSection(
                    "Duración Rápida",
                    Icons.timer,
                    _buildDuracionRapida(context, primaryColor),
                  ),
                  const SizedBox(height: 24),
                  _buildConfirmarButton(context, primaryColor),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(Color primaryColor) {
    final steps = [
      "Auto",
      "Piso",
      "Lugar",
      "Horario",
    ];

    final currentStep = controller.autoSeleccionado.value != null
        ? (controller.pisoSeleccionado.value != null
            ? (controller.lugarSeleccionado.value != null
                ? (controller.horarioInicio.value != null ? 3 : 2)
                : 1)
            : 0)
        : -1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentStep;
          final isCurrent = index == currentStep + 1;

          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? primaryColor : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? primaryColor : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: TextStyle(
                    color: isCurrent ? primaryColor : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 2,
                    color: isCompleted ? primaryColor : Colors.grey.shade200,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectionSection(String title, IconData icon, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketPreview(Color primaryColor) {
    final hasAllSelections = controller.autoSeleccionado.value != null &&
        controller.lugarSeleccionado.value != null &&
        controller.horarioInicio.value != null &&
        controller.horarioSalida.value != null;

    if (!hasAllSelections) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Complete todas las selecciones para ver el ticket",
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  "Ticket de Reserva",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Pendiente",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTicketInfo(
                  "Auto",
                  "${controller.autoSeleccionado.value!.marca} ${controller.autoSeleccionado.value!.modelo}",
                  Icons.directions_car,
                  subtitle: controller.autoSeleccionado.value!.chapa,
                ),
                const Divider(),
                _buildTicketInfo(
                  "Lugar",
                  controller.lugarSeleccionado.value!.codigoLugar,
                  Icons.local_parking,
                  subtitle: controller.pisoSeleccionado.value?.descripcion ?? '',
                ),
                const Divider(),
                _buildTicketInfo(
                  "Horario",
                  "${UtilesApp.formatearFechaDdMMAaaa(controller.horarioInicio.value!)}",
                  Icons.access_time,
                  subtitle:
                      "${TimeOfDay.fromDateTime(controller.horarioInicio.value!).format(Get.context!)} - ${TimeOfDay.fromDateTime(controller.horarioSalida.value!).format(Get.context!)}",
                ),
                const Divider(),
                Obx(() {
                  final minutos = controller.horarioSalida.value!
                      .difference(controller.horarioInicio.value!)
                      .inMinutes;
                  final horas = minutos / 60;
                  final monto = (horas * 10000).round();

                  return _buildTicketInfo(
                    "Monto estimado",
                    "₲${UtilesApp.formatearGuaranies(monto)}",
                    Icons.payments,
                    isAmount: true,
                    subtitle: "Duración: ${horas.toStringAsFixed(1)} horas",
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(
    String label,
    String value,
    IconData icon, {
    bool isAmount = false,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: isAmount ? 18 : 16,
                    fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Obx(() {
        return DropdownButton<Auto>(
          isExpanded: true,
          value: controller.autoSeleccionado.value,
          hint: const Text("Seleccionar auto"),
          underline: const SizedBox(),
          onChanged: (auto) {
            controller.autoSeleccionado.value = auto;
          },
          items: controller.autosCliente.map((a) {
            final nombre = "${a.chapa} - ${a.marca} ${a.modelo}";
            return DropdownMenuItem(value: a, child: Text(nombre));
          }).toList(),
        );
      }),
    );
  }

  Widget _buildPisoSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<Piso>(
        isExpanded: true,
        value: controller.pisoSeleccionado.value,
        hint: const Text("Seleccionar piso"),
        underline: const SizedBox(),
        onChanged: (p) => controller.seleccionarPiso(p!),
        items: controller.pisos
            .map((p) => DropdownMenuItem(value: p, child: Text(p.descripcion)))
            .toList(),
      ),
    );
  }

  Widget _buildLugaresGrid(Color primaryColor) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: controller.lugaresDisponibles
            .where((l) => l.codigoPiso == controller.pisoSeleccionado.value?.codigo)
            .map((lugar) {
          final seleccionado = lugar == controller.lugarSeleccionado.value;
          final color = lugar.estado == "RESERVADO"
              ? Colors.red.shade300
              : seleccionado
                  ? primaryColor
                  : Colors.grey.shade200;

          return GestureDetector(
            onTap: lugar.estado == "DISPONIBLE"
                ? () => controller.lugarSeleccionado.value = lugar
                : null,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(
                  color: seleccionado ? primaryColor : Colors.black12,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: seleccionado
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lugar.codigoLugar,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: lugar.estado == "RESERVADO"
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  if (lugar.estado == "RESERVADO")
                    const Text(
                      "Ocupado",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHorariosSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildHorarioButton(
            context,
            "Inicio",
            Icons.access_time,
            controller.horarioInicio,
            () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date == null) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time == null) return;
              controller.horarioInicio.value = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHorarioButton(
            context,
            "Salida",
            Icons.timer_off,
            controller.horarioSalida,
            () async {
              final date = await showDatePicker(
                context: context,
                initialDate: controller.horarioInicio.value ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date == null) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time == null) return;
              controller.horarioSalida.value = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorarioButton(
    BuildContext context,
    String label,
    IconData icon,
    Rx<DateTime?> horario,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Obx(() => Text(
              horario.value == null
                  ? label
                  : "${UtilesApp.formatearFechaDdMMAaaa(horario.value!)} ${TimeOfDay.fromDateTime(horario.value!).format(context)}",
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDuracionRapida(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [1, 2, 4, 6, 8].map((horas) {
          final seleccionada = controller.duracionSeleccionada.value == horas;
          return ChoiceChip(
            label: Text("$horas h"),
            selected: seleccionada,
            selectedColor: primaryColor,
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: seleccionada ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            onSelected: (_) {
              controller.duracionSeleccionada.value = horas;
              final inicio = controller.horarioInicio.value ?? DateTime.now();
              controller.horarioInicio.value = inicio;
              controller.horarioSalida.value = inicio.add(Duration(hours: horas));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConfirmarButton(BuildContext context, Color primaryColor) {
    final hasAllSelections = controller.autoSeleccionado.value != null &&
        controller.lugarSeleccionado.value != null &&
        controller.horarioInicio.value != null &&
        controller.horarioSalida.value != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasAllSelections ? primaryColor : Colors.grey.shade300,
          foregroundColor: hasAllSelections ? Colors.white : Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: hasAllSelections
            ? () async {
                final confirmada = await controller.confirmarReserva();

                if (confirmada) {
                  Get.snackbar(
                    "Reserva",
                    "Reserva realizada con éxito",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.shade100,
                    colorText: Colors.green.shade900,
                    duration: const Duration(seconds: 2),
                  );

                  await Future.delayed(const Duration(milliseconds: 2000));
                  Get.back();
                } else {
                  Get.snackbar(
                    "Error",
                    "Verificá que todos los campos estén completos",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red.shade100,
                    colorText: Colors.red.shade900,
                    duration: const Duration(seconds: 3),
                  );
                }
              }
            : null,
        child: const Text(
          "Confirmar Reserva",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
