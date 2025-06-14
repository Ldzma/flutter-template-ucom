// ignore_for_file: deprecated_member_use

import 'package:finpay/api/local.db.service.dart';
import 'package:finpay/config/images.dart';
import 'package:finpay/config/textstyle.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/model/transaction_model.dart';
import 'package:finpay/services/reserva_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  List<TransactionModel> transactionList = List<TransactionModel>.empty().obs;
  RxBool isWeek = true.obs;
  RxBool isMonth = false.obs;
  RxBool isYear = false.obs;
  RxBool isAdd = false.obs;
  RxList<Pago> pagosPrevios = <Pago>[].obs;
  RxInt pagosDelMes = 0.obs;
  RxInt pagosPendientes = 0.obs;
  RxInt vehiculosEstacionados = 0.obs;

  customInit() async {
    await cargarPagosPrevios();
    await cargarPagosDelMes();
    await cargarPagosPendientes();
    await cargarVehiculosEstacionados();
    isWeek.value = true;
    isMonth.value = false;
    isYear.value = false;
    transactionList = [
      TransactionModel(
        Theme.of(Get.context!).textTheme.titleLarge!.color,
        DefaultImages.transaction4,
        "Apple Store",
        "iPhone 12 Case",
        "- \$120,90",
        "09:39 AM",
      ),
      TransactionModel(
        HexColor(AppTheme.primaryColorString!).withOpacity(0.10),
        DefaultImages.transaction3,
        "Ilya Vasil",
        "Wise • 5318",
        "- \$50,90",
        "05:39 AM",
      ),
      TransactionModel(
        Theme.of(Get.context!).textTheme.titleLarge!.color,
        "",
        "Burger King",
        "Cheeseburger XL",
        "- \$5,90",
        "09:39 AM",
      ),
      TransactionModel(
        HexColor(AppTheme.primaryColorString!).withOpacity(0.10),
        DefaultImages.transaction1,
        "Claudia Sarah",
        "Finpay Card • 5318",
        "- \$50,90",
        "04:39 AM",
      ),
    ];
  }

  Future<void> cargarPagosPrevios() async {
    final db = LocalDBService();
    final data = await db.getAll("pagos.json");
    pagosPrevios.value = data.map((json) => Pago.fromJson(json)).toList();
  }

  Future<void> cargarPagosDelMes() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 0);
    
    pagosDelMes.value = pagosPrevios.where((pago) => 
      pago.fechaPago.isAfter(inicioMes) && 
      pago.fechaPago.isBefore(finMes)
    ).length;
  }

  Future<void> cargarPagosPendientes() async {
    final reservaService = ReservaService();
    final reservasPendientes = await reservaService.obtenerReservasPendientesPorCliente('cliente_1');
    pagosPendientes.value = reservasPendientes.length;
  }

  Future<void> cargarVehiculosEstacionados() async {
    final reservaService = ReservaService();
    final reservas = await reservaService.obtenerReservasActivas('cliente_1');
    // Filtra solo las reservas CONFIRMADAS y cuenta las chapas únicas
    final chapas = reservas
        .where((r) => r.estadoReserva == "CONFIRMADA")
        .map((r) => r.chapaAuto)
        .toSet();
    vehiculosEstacionados.value = chapas.length;
  }
}
