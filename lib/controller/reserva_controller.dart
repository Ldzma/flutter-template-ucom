import 'package:flutter/material.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/services/reserva_service.dart';
import 'package:get/get.dart';
import 'package:finpay/api/local.db.service.dart';

class ReservaController extends GetxController {
  final ReservaService _reservaService = ReservaService();
  
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
  RxBool isLoading = false.obs;
  String codigoClienteActual =
      'cliente_1'; // ← este puede venir de login o contexto

  @override
  void onInit() {
    super.onInit();
    resetearCampos();
    cargarAutosDelCliente();
    cargarPisosYLugares();
  }

  Future<void> cargarPisosYLugares() async {
    isLoading.value = true;
    try {
      // Aquí deberías cargar los pisos y lugares desde tu servicio
      // Por ahora usamos datos de ejemplo
      pisos.value = [
        Piso(
          codigo: "P1",
          descripcion: "Piso 1",
          lugares: [
            Lugar(
              codigoPiso: "P1",
              codigoLugar: "P1-A1",
              descripcionLugar: "Lugar A1",
            ),
            Lugar(
              codigoPiso: "P1",
              codigoLugar: "P1-A2",
              descripcionLugar: "Lugar A2",
            ),
          ],
        ),
        Piso(
          codigo: "P2",
          descripcion: "Piso 2",
          lugares: [
            Lugar(
              codigoPiso: "P2",
              codigoLugar: "P2-B1",
              descripcionLugar: "Lugar B1",
            ),
            Lugar(
              codigoPiso: "P2",
              codigoLugar: "P2-B2",
              descripcionLugar: "Lugar B2",
            ),
          ],
        ),
      ];

      // Cargar lugares disponibles
      await actualizarLugaresDisponibles();
    } catch (e) {
      print("Error al cargar pisos y lugares: $e");
      Get.snackbar(
        "Error",
        "No se pudieron cargar los pisos y lugares",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> actualizarLugaresDisponibles() async {
    if (pisoSeleccionado.value == null) return;

    try {
      final lugaresDelPiso = pisos
          .firstWhere((p) => p.codigo == pisoSeleccionado.value!.codigo)
          .lugares;

      // Verificar disponibilidad de cada lugar
      final lugaresDisponiblesTemp = <Lugar>[];
      for (var lugar in lugaresDelPiso) {
        if (horarioInicio.value != null && horarioSalida.value != null) {
          final disponible = await _reservaService.verificarDisponibilidadLugar(
            lugar.codigoLugar,
            horarioInicio.value!,
            horarioSalida.value!,
          );
          if (disponible) {
            lugaresDisponiblesTemp.add(lugar);
          }
        } else {
          lugaresDisponiblesTemp.add(lugar);
        }
      }

      lugaresDisponibles.value = lugaresDisponiblesTemp;
      // Si el lugar seleccionado ya no está disponible, deseleccionarlo
      if (lugarSeleccionado.value != null &&
          !lugaresDisponiblesTemp.contains(lugarSeleccionado.value)) {
        lugarSeleccionado.value = null;
      }
    } catch (e) {
      print("Error al actualizar lugares disponibles: $e");
    }
  }

  Future<void> seleccionarPiso(Piso piso) async {
    pisoSeleccionado.value = piso;
    lugarSeleccionado.value = null;
    await actualizarLugaresDisponibles();
  }

  Future<bool> confirmarReserva() async {
    if (pisoSeleccionado.value == null ||
        lugarSeleccionado.value == null ||
        horarioInicio.value == null ||
        horarioSalida.value == null ||
        autoSeleccionado.value == null) {
      return false;
    }

    final duracionEnHoras =
        horarioSalida.value!.difference(horarioInicio.value!).inMinutes / 60;

    if (duracionEnHoras <= 0) return false;

    final montoCalculado = _reservaService.calcularMontoReserva(
      horarioInicio.value!,
      horarioSalida.value!,
    );

    final nuevaReserva = Reserva(
      codigoReserva: "RES-PEND-${DateTime.now().millisecondsSinceEpoch}",
      horarioInicio: horarioInicio.value!,
      horarioSalida: horarioSalida.value!,
      monto: montoCalculado,
      estadoReserva: "PENDIENTE",
      chapaAuto: autoSeleccionado.value!.chapa,
      codigoLugar: lugarSeleccionado.value!.codigoLugar,
      codigoPiso: pisoSeleccionado.value!.codigo,
      clienteId: codigoClienteActual,
    );

    try {
      // Crear la reserva en el archivo de reservas pendientes
      final creada = await _reservaService.crearReservaPendiente(nuevaReserva);
      if (creada) {
        await actualizarLugaresDisponibles();
        return true;
      }
      return false;
    } catch (e) {
      print("Error al crear reserva: $e");
      return false;
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
      // Aquí deberías cargar los autos desde tu servicio
      // Por ahora usamos datos de ejemplo
      autosCliente.value = [
        Auto(
          chapa: "ABC-123",
          marca: "Toyota",
          modelo: "Corolla",
          chasis: "CHS123456",
          clienteId: codigoClienteActual,
        ),
        Auto(
          chapa: "XYZ-789",
          marca: "Honda",
          modelo: "Civic",
          chasis: "CHS789012",
          clienteId: codigoClienteActual,
        ),
      ];
    } catch (e) {
      print("Error al cargar autos del cliente: $e");
      Get.snackbar(
        "Error",
        "No se pudieron cargar los autos",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  @override
  void onClose() {
    resetearCampos();
    super.onClose();
  }
}
