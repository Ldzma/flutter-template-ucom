import 'package:finpay/config/textstyle.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/services/reserva_service.dart';
import 'package:finpay/utils/utiles.dart';
import 'package:finpay/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({Key? key}) : super(key: key);

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final ReservaService _reservaService = ReservaService();
  final String clienteId = 'cliente_1'; // Esto debería venir del login
  RxList<Reserva> reservasActivas = <Reserva>[].obs;
  RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    cargarReservas();
  }

  Future<void> cargarReservas() async {
    isLoading.value = true;
    try {
      final reservas = await _reservaService.obtenerReservasActivas(clienteId);
      reservasActivas.value = reservas;
    } catch (e) {
      print("Error al cargar reservas: $e");
      Get.snackbar(
        "Error",
        "No se pudieron cargar las reservas",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelarReserva(String codigoReserva) async {
    final confirmacion = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Cancelar Reserva"),
        content: const Text("¿Estás seguro que deseas cancelar esta reserva?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Sí, Cancelar"),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        final cancelada = await _reservaService.cancelarReserva(codigoReserva);
        if (cancelada) {
          await cargarReservas();
          Get.snackbar(
            "Éxito",
            "Reserva cancelada correctamente",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
          );
        }
      } catch (e) {
        print("Error al cancelar reserva: $e");
        Get.snackbar(
          "Error",
          "No se pudo cancelar la reserva",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.isLightTheme == false
            ? HexColor('#15141f')
            : Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mis Reservas",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reservasActivas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No tienes reservas activas",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  title: "Nueva Reserva",
                  onTap: () {
                    Get.back();
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservasActivas.length,
          itemBuilder: (context, index) {
            final reserva = reservasActivas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Reserva #${reserva.codigoReserva}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: reserva.colorEstado.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            reserva.estadoFormateado,
                            style: TextStyle(
                              color: reserva.colorEstado,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_on,
                      "Lugar: ${reserva.codigoLugar} (Piso ${reserva.codigoPiso})",
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.directions_car,
                      "Auto: ${reserva.chapaAuto}",
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.access_time,
                      "Inicio: ${UtilesApp.formatearFechaDdMMAaaa(reserva.horarioInicio)} ${TimeOfDay.fromDateTime(reserva.horarioInicio).format(context)}",
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.timer_off,
                      "Fin: ${UtilesApp.formatearFechaDdMMAaaa(reserva.horarioSalida)} ${TimeOfDay.fromDateTime(reserva.horarioSalida).format(context)}",
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Monto: ₲${UtilesApp.formatearGuaranies(reserva.monto)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (reserva.estadoReserva == "PENDIENTE")
                          TextButton(
                            onPressed: () => cancelarReserva(reserva.codigoReserva),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text("Cancelar"),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
} 