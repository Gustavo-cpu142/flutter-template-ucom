import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPagosDelMes(),
            // ... resto del código ...
          ],
        ),
      ),
    );
  }

  Widget _buildPagosDelMes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pagos del Mes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Icon(
                Icons.payment,
                color: Colors.blue[700],
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Text(
            "${controller.pagosRealizadosMes.value} pagos",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          )),
          const SizedBox(height: 8),
          Obx(() => Text(
            "Monto total: \$${controller.montoTotalMes.value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          )),
        ],
      ),
    );
  }
} 