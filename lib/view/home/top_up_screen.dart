// ignore_for_file: deprecated_member_use

import 'package:finpay/config/images.dart';
import 'package:finpay/config/textstyle.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/services/reserva_service.dart';
import 'package:finpay/utils/utiles.dart';
import 'package:finpay/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:finpay/controller/home_controller.dart';
import 'package:finpay/api/local.db.service.dart';

class TopUpSCreen extends StatefulWidget {
  const TopUpSCreen({Key? key}) : super(key: key);

  @override
  State<TopUpSCreen> createState() => _TopUpSCreenState();
}

class _TopUpSCreenState extends State<TopUpSCreen> {
  final ReservaService _reservaService = ReservaService();
  final String clienteId = 'cliente_1'; // Esto debería venir del login
  RxList<Reserva> reservasPendientes = <Reserva>[].obs;
  RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    cargarReservasPendientes();
  }

  Future<void> cargarReservasPendientes() async {
    isLoading.value = true;
    try {
      final reservas = await _reservaService.obtenerReservasPendientesPorCliente(clienteId);
      reservasPendientes.value = reservas;
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

  Future<void> cancelarReservaPendiente(String codigoReserva) async {
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Sí, Cancelar"),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        final cancelada = await _reservaService.cancelarReservaPendiente(codigoReserva);
        if (cancelada) {
          // Actualizar contadores en HomeController
          final homeController = Get.find<HomeController>();
          await homeController.cargarPagosPendientes();
          
          // Actualizar lista de reservas pendientes
          await cargarReservasPendientes();
          
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

  void mostrarDetallesReserva(Reserva reserva) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.isLightTheme == false
              ? const Color(0xff211F32)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Detalles de la Reserva",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetalleRow("Código", "#${reserva.codigoReserva}"),
            _buildDetalleRow("Lugar", "${reserva.codigoLugar} (Piso ${reserva.codigoPiso})"),
            _buildDetalleRow("Auto", reserva.chapaAuto),
            _buildDetalleRow(
              "Inicio",
              "${UtilesApp.formatearFechaDdMMAaaa(reserva.horarioInicio)} ${TimeOfDay.fromDateTime(reserva.horarioInicio).format(context)}",
            ),
            _buildDetalleRow(
              "Fin",
              "${UtilesApp.formatearFechaDdMMAaaa(reserva.horarioSalida)} ${TimeOfDay.fromDateTime(reserva.horarioSalida).format(context)}",
            ),
            const Divider(height: 30),
            _buildDetalleRow(
              "Monto a Pagar",
              "₲${UtilesApp.formatearGuaranies(reserva.monto)}",
              isBold: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    title: "Cancelar Reserva",
                    onTap: () {
                      Get.back(); // Cerrar el bottom sheet
                      cancelarReservaPendiente(reserva.codigoReserva);
                    },
                    backgroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    title: "Pagar Reserva",
                    onTap: () async {
                      Get.back(); // Cerrar el bottom sheet
                      // Lógica de pago existente...
                      final pago = Pago(
                        codigoPago: "PAG-${DateTime.now().millisecondsSinceEpoch}",
                        codigoReservaAsociada: reserva.codigoReserva,
                        montoPagado: reserva.monto,
                        fechaPago: DateTime.now(),
                        origen: "pago_modulo",
                      );
                      
                      // Guardar el pago en la base de datos
                      final db = LocalDBService();
                      final data = await db.getAll("pagos.json");
                      data.add(pago.toJson());
                      await db.saveAll("pagos.json", data);
                      
                      // Confirmar la reserva pendiente
                      await _reservaService.confirmarReservaPendiente(reserva.codigoReserva);
                      
                      // Actualizar contadores en HomeController
                      final homeController = Get.find<HomeController>();
                      await homeController.cargarPagosPrevios();
                      await homeController.cargarPagosDelMes();
                      await homeController.cargarPagosPendientes();
                      
                      // Actualizar lista de reservas pendientes
                      await cargarReservasPendientes();
                      
                      Get.snackbar(
                        "Éxito",
                        "Pago procesado correctamente",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade900,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isLightTheme == false
          ? HexColor('#15141f')
          : HexColor(AppTheme.primaryColorString!),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
                child: Row(
                  children: [
                    InkWell(
                      focusColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    Text(
                      "Pagar Reserva",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Expanded(child: SizedBox()),
                    const Icon(
                      Icons.arrow_back,
                      color: Colors.transparent,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Container(
                  height: Get.height - 107,
                  width: Get.width,
                  decoration: BoxDecoration(
                    color: AppTheme.isLightTheme == false
                        ? const Color(0xff211F32)
                        : Theme.of(context).appBarTheme.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Obx(() {
                    if (isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (reservasPendientes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No tienes reservas pendientes de pago",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reservasPendientes.length,
                      itemBuilder: (context, index) {
                        final reserva = reservasPendientes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => mostrarDetallesReserva(reserva),
                            borderRadius: BorderRadius.circular(16),
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
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          "Pendiente",
                                          style: TextStyle(
                                            color: Colors.orange,
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
                                    Icons.access_time,
                                    "Inicio: ${UtilesApp.formatearFechaDdMMAaaa(reserva.horarioInicio)} ${TimeOfDay.fromDateTime(reserva.horarioInicio).format(context)}",
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "Tocar para pagar",
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
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