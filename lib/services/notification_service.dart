import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/gestante.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings: settings);
  }

  /// Solicita permissões de notificação para Android 13+ e iOS
  Future<bool> solicitarPermissoes() async {
    final bool? androidGranted = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final bool? iosGranted = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  /// O "Cérebro" da notificação: decide se agenda ou cancela
  Future<void> atualizarLembrete(Gestante g) async {
    if (g.id == null) return;

    // Regra de Negócio: Se quitou ou não tem dia de vencimento, cancela notificação
    if (g.saldoDevedor <= 0 || g.diaVencimento == null) {
      // CORREÇÃO 2: Adicionado o nome do parâmetro 'id'
      await _notifications.cancel(id: g.id!);
      return;
    }

    // Caso contrário, agenda/atualiza
    final agora = tz.TZDateTime.now(tz.local);
    var dataAgendada = tz.TZDateTime(tz.local, agora.year, agora.month, g.diaVencimento!, 9, 0);

    if (dataAgendada.isBefore(agora)) {
      dataAgendada = tz.TZDateTime(tz.local, agora.year, agora.month + 1, g.diaVencimento!, 9, 0);
    }

    // CORREÇÃO 3: Todos os parâmetros abaixo agora são nomeados,
    // e o antigo 'uiLocalNotificationDateInterpretation' foi removido.
    await _notifications.zonedSchedule(
          id: g.id!,
          title: 'Vencimento de Contrato',
          body: 'Hoje vence a parcela de ${g.nome}',
          scheduledDate: dataAgendada,
          // AJUSTE AQUI: Mudou de 'details' para 'notificationDetails'
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'financeiro_channel',
              'Financeiro',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
  }
}