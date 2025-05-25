import 'package:finpay/config/textstyle.dart';
import 'package:finpay/controller/reserva_controller.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/utils/utiles.dart';
import 'package:finpay/view/reservas/mis_reservas_screen.dart';
import 'package:finpay/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReservaScreen extends StatelessWidget {
  final controller = Get.put(ReservaController());

  ReservaScreen({super.key});

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
          "Nueva Reserva",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.to(
                () => const MisReservasScreen(),
                transition: Transition.rightToLeft,
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Seleccionar Auto"),
                const SizedBox(height: 8),
                _buildAutoSelector(),
                const SizedBox(height: 24),
                _buildSectionTitle("Seleccionar Ubicación"),
                const SizedBox(height: 8),
                _buildPisoSelector(),
                const SizedBox(height: 16),
                if (controller.pisoSeleccionado.value != null) ...[
                  _buildSectionTitle("Seleccionar Lugar"),
                  const SizedBox(height: 8),
                  _buildLugaresGrid(),
                ],
                const SizedBox(height: 24),
                _buildSectionTitle("Seleccionar Horario"),
                const SizedBox(height: 8),
                _buildHorarioSelector(context),
                const SizedBox(height: 16),
                _buildDuracionRapida(),
                const SizedBox(height: 24),
                if (controller.horarioInicio.value != null &&
                    controller.horarioSalida.value != null)
                  _buildResumenReserva(),
                const SizedBox(height: 32),
                CustomButton(
                  title: "Confirmar Reserva",
                  onTap: () async {
                    final confirmada = await controller.confirmarReserva();

                    if (confirmada) {
                      Get.snackbar(
                        "Éxito",
                        "Reserva realizada correctamente",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade900,
                      );

                      await Future.delayed(const Duration(milliseconds: 2000));
                      Get.off(() => const MisReservasScreen());
                    } else {
                      Get.snackbar(
                        "Error",
                        "Verificá que todos los campos estén completos",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade900,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAutoSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme == false
            ? const Color(0xff211F32)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
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
          items: controller.autosCliente.map((auto) {
            return DropdownMenuItem(
              value: auto,
              child: Text("${auto.marca} ${auto.modelo} - ${auto.chapa}"),
            );
                    }).toList(),
                  );
                }),
    );
  }

  Widget _buildPisoSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme == false
            ? const Color(0xff211F32)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() {
        return DropdownButton<Piso>(
                  isExpanded: true,
                  value: controller.pisoSeleccionado.value,
                  hint: const Text("Seleccionar piso"),
          underline: const SizedBox(),
          onChanged: (piso) {
            if (piso != null) controller.seleccionarPiso(piso);
          },
          items: controller.pisos.map((piso) {
            return DropdownMenuItem(
              value: piso,
              child: Text(piso.descripcion),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildLugaresGrid() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme == false
            ? const Color(0xff211F32)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() {
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
          children: controller.lugaresDisponibles.map((lugar) {
            final seleccionado = lugar == controller.lugarSeleccionado.value;
            final color = seleccionado
                ? Theme.of(Get.context!).primaryColor
                              : Colors.grey.shade300;

                      return GestureDetector(
              onTap: () => controller.lugarSeleccionado.value = lugar,
                        child: Container(
                          decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                            border: Border.all(
                                color: seleccionado
                        ? Theme.of(Get.context!).primaryColor
                        : Colors.grey.shade400,
                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                child: Center(
                          child: Text(
                            lugar.codigoLugar,
                            style: TextStyle(
                      color: seleccionado
                          ? Theme.of(Get.context!).primaryColor
                          : Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                    ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
        );
      }),
    );
  }

  Widget _buildHorarioSelector(BuildContext context) {
    return Row(
                  children: [
                    Expanded(
          child: _buildHorarioButton(
            context,
            "Inicio",
            controller.horarioInicio,
            Icons.access_time,
            (date, time) {
                          controller.horarioInicio.value = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
              controller.actualizarLugaresDisponibles();
            },
          ),
        ),
        const SizedBox(width: 16),
                    Expanded(
          child: _buildHorarioButton(
            context,
            "Fin",
            controller.horarioSalida,
            Icons.timer_off,
            (date, time) {
                          controller.horarioSalida.value = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
              controller.actualizarLugaresDisponibles();
            },
                      ),
                    ),
                  ],
    );
  }

  Widget _buildHorarioButton(
    BuildContext context,
    String label,
    Rx<DateTime?> horario,
    IconData icon,
    Function(DateTime, TimeOfDay) onSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme == false
            ? const Color(0xff211F32)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: horario.value ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date == null) return;

            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time == null) return;

            onSelected(date, time);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() {
                    if (horario.value == null) {
                      return Text(label);
                    }
                    return Text(
                      "${UtilesApp.formatearFechaDdMMAaaa(horario.value!)} ${TimeOfDay.fromDateTime(horario.value!).format(context)}",
                      style: const TextStyle(fontSize: 12),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuracionRapida() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Duración rápida",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 4, 6, 8].map((horas) {
            final seleccionada = controller.duracionSeleccionada.value == horas;
                    return ChoiceChip(
                      label: Text("$horas h"),
                      selected: seleccionada,
              selectedColor: Theme.of(Get.context!).primaryColor,
                      onSelected: (_) {
                        controller.duracionSeleccionada.value = horas;
                final inicio = controller.horarioInicio.value ?? DateTime.now();
                        controller.horarioInicio.value = inicio;
                        controller.horarioSalida.value =
                            inicio.add(Duration(hours: horas));
                controller.actualizarLugaresDisponibles();
                      },
                    );
                  }).toList(),
                ),
      ],
    );
  }

  Widget _buildResumenReserva() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme == false
            ? const Color(0xff211F32)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumen de la Reserva",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
                Obx(() {
            final inicio = controller.horarioInicio.value!;
            final salida = controller.horarioSalida.value!;
                  final minutos = salida.difference(inicio).inMinutes;
                  final horas = minutos / 60;
                  final monto = (horas * 10000).round();

            return Column(
              children: [
                _buildResumenRow(
                  "Duración",
                  "${horas.toStringAsFixed(1)} horas",
                ),
                const SizedBox(height: 8),
                _buildResumenRow(
                  "Monto estimado",
                  "₲${UtilesApp.formatearGuaranies(monto)}",
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
