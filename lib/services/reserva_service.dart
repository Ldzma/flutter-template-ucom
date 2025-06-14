import 'package:finpay/api/local.db.service.dart';
import 'package:finpay/model/sitema_reservas.dart';

class ReservaService {
  final LocalDBService _db = LocalDBService();

  // Obtener todas las reservas
  Future<List<Reserva>> obtenerReservas() async {
    final data = await _db.getAll("reservas.json");
    return data.map((json) => Reserva.fromJson(json)).toList();
  }

  // Obtener reservas por cliente
  Future<List<Reserva>> obtenerReservasPorCliente(String clienteId) async {
    final reservas = await obtenerReservas();
    return reservas.where((r) => r.clienteId == clienteId).toList();
  }

  // Obtener reservas activas (no canceladas)
  Future<List<Reserva>> obtenerReservasActivas(String clienteId) async {
    final reservas = await obtenerReservasPorCliente(clienteId);
    return reservas.where((r) => r.estadoReserva != "CANCELADA").toList();
  }

  // Crear nueva reserva
  Future<bool> crearReserva(Reserva reserva) async {
    try {
      final reservas = await _db.getAll("reservas.json");
      reservas.add(reserva.toJson());
      await _db.saveAll("reservas.json", reservas);
      return true;
    } catch (e) {
      print("Error al crear reserva: $e");
      return false;
    }
  }

  // Actualizar estado de reserva
  Future<bool> actualizarEstadoReserva(String codigoReserva, String nuevoEstado) async {
    try {
      final reservas = await _db.getAll("reservas.json");
      final index = reservas.indexWhere((r) => r['codigoReserva'] == codigoReserva);
      
      if (index != -1) {
        reservas[index]['estadoReserva'] = nuevoEstado;
        await _db.saveAll("reservas.json", reservas);
        return true;
      }
      return false;
    } catch (e) {
      print("Error al actualizar estado de reserva: $e");
      return false;
    }
  }

  // Cancelar reserva
  Future<bool> cancelarReserva(String codigoReserva) async {
    return actualizarEstadoReserva(codigoReserva, "CANCELADA");
  }

  // Verificar disponibilidad de lugar
  Future<bool> verificarDisponibilidadLugar(String codigoLugar, DateTime inicio, DateTime fin) async {
    final reservas = await obtenerReservas();
    final reservasActivas = reservas.where((r) => 
      r.codigoLugar == codigoLugar && 
      r.estadoReserva != "CANCELADA" &&
      ((inicio.isAfter(r.horarioInicio) && inicio.isBefore(r.horarioSalida)) ||
       (fin.isAfter(r.horarioInicio) && fin.isBefore(r.horarioSalida)) ||
       (inicio.isBefore(r.horarioInicio) && fin.isAfter(r.horarioSalida)))
    ).toList();

    return reservasActivas.isEmpty;
  }

  // Calcular monto de reserva
  double calcularMontoReserva(DateTime inicio, DateTime fin) {
    final duracionEnHoras = fin.difference(inicio).inMinutes / 60;
    return (duracionEnHoras * 10000).roundToDouble();
  }

  // Crear nueva reserva pendiente
  Future<bool> crearReservaPendiente(Reserva reserva) async {
    try {
      final reservasPendientes = await _db.getAll("reservas_pendientes.json");
      reservasPendientes.add(reserva.toJson());
      await _db.saveAll("reservas_pendientes.json", reservasPendientes);
      return true;
    } catch (e) {
      print("Error al crear reserva pendiente: $e");
      return false;
    }
  }

  // Obtener reservas pendientes
  Future<List<Reserva>> obtenerReservasPendientes() async {
    final data = await _db.getAll("reservas_pendientes.json");
    return data.map((json) => Reserva.fromJson(json)).toList();
  }

  // Obtener reservas pendientes por cliente
  Future<List<Reserva>> obtenerReservasPendientesPorCliente(String clienteId) async {
    final reservas = await obtenerReservasPendientes();
    return reservas.where((r) => r.clienteId == clienteId).toList();
  }

  // Mover reserva pendiente a reservas confirmadas
  Future<bool> confirmarReservaPendiente(String codigoReserva) async {
    try {
      // Obtener todas las reservas pendientes
      final reservasPendientes = await _db.getAll("reservas_pendientes.json");
      final index = reservasPendientes.indexWhere((r) => r['codigoReserva'] == codigoReserva);
      
      if (index != -1) {
        // Obtener la reserva pendiente
        final reservaPendiente = reservasPendientes[index];
        
        // Actualizar el estado a CONFIRMADA
        reservaPendiente['estadoReserva'] = "CONFIRMADA";
        
        // Agregar a reservas confirmadas
        final reservasConfirmadas = await _db.getAll("reservas.json");
        reservasConfirmadas.add(reservaPendiente);
        await _db.saveAll("reservas.json", reservasConfirmadas);
        
        // Eliminar de reservas pendientes
        reservasPendientes.removeAt(index);
        await _db.saveAll("reservas_pendientes.json", reservasPendientes);
        
        return true;
      }
      return false;
    } catch (e) {
      print("Error al confirmar reserva pendiente: $e");
      return false;
    }
  }

  // Eliminar reserva pendiente
  Future<bool> eliminarReservaPendiente(String codigoReserva) async {
    try {
      final reservasPendientes = await _db.getAll("reservas_pendientes.json");
      final index = reservasPendientes.indexWhere((r) => r['codigoReserva'] == codigoReserva);
      
      if (index != -1) {
        reservasPendientes.removeAt(index);
        await _db.saveAll("reservas_pendientes.json", reservasPendientes);
        return true;
      }
      return false;
    } catch (e) {
      print("Error al eliminar reserva pendiente: $e");
      return false;
    }
  }

  // Cancelar reserva pendiente
  Future<bool> cancelarReservaPendiente(String codigoReserva) async {
    try {
      final reservasPendientes = await _db.getAll("reservas_pendientes.json");
      final index = reservasPendientes.indexWhere((r) => r['codigoReserva'] == codigoReserva);
      
      if (index != -1) {
        // Eliminar directamente de reservas pendientes
        reservasPendientes.removeAt(index);
        await _db.saveAll("reservas_pendientes.json", reservasPendientes);
        return true;
      }
      return false;
    } catch (e) {
      print("Error al cancelar reserva pendiente: $e");
      return false;
    }
  }
} 