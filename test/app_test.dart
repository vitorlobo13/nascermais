import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nascer_mais/models/gestante.dart';
import 'package:nascer_mais/services/database_helper.dart';
import 'package:nascer_mais/services/gestantes_provider.dart';
import 'package:nascer_mais/services/ficha_service.dart';

void main() {
  // Inicializa a factory FFI para rodar testes locais do SQLite em memória
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Testes de Regras de Negócio e Cálculos', () {
    test('Cálculo correto de semanas e dias de gestação', () {
      final hoje = DateTime.now();
      // Define DPP para exatamente 4 semanas (28 dias) no futuro
      final dppFutura = hoje.add(const Duration(days: 28));

      final gestante = Gestante(
        nome: 'Maria da Silva',
        dppFinal: dppFutura,
        maternidade: 'Maternidade Santa Joana',
        classificacaoRisco: 'Risco Habitual',
      );

      // Com 4 semanas para o parto, ela está com 36 semanas de gestação (40 - 4 = 36)
      expect(gestante.semanasHoje, equals('36 semanas e 0 dias'));
      expect(gestante.jaNasceu, isFalse);
    });

    test('Cálculo de status Pós-parto', () {
      final gestante = Gestante(
        nome: 'Joana Alencar',
        dppFinal: DateTime.now().subtract(const Duration(days: 10)),
        maternidade: 'Hospital São Luiz',
        classificacaoRisco: 'Alto Risco',
        jaNasceu: true,
      );

      expect(gestante.semanasHoje, equals('Pós-parto'));
    });

    test('Cálculos Financeiros de Contrato e Saldo Devedor', () {
      final gestante = Gestante(
        nome: 'Ana Souza',
        dppFinal: DateTime.now().add(const Duration(days: 120)),
        maternidade: 'Maternidade Pro Matre',
        classificacaoRisco: 'Risco Habitual',
        valorContrato: 5000.0,
      );

      expect(gestante.totalPago, equals(0.0));
      expect(gestante.saldoDevedor, equals(5000.0));

      // Adiciona parcelas
      gestante.pagamentos.add(Pagamento(valor: 1500.0, data: DateTime.now(), descricao: 'Primeira Parcela'));
      gestante.pagamentos.add(Pagamento(valor: 2000.0, data: DateTime.now(), descricao: 'Segunda Parcela'));

      expect(gestante.totalPago, equals(3500.0));
      expect(gestante.saldoDevedor, equals(1500.0));
    });
  });

  group('Testes de Banco de Dados e Provedor (Integração)', () {
    late DatabaseHelper dbHelper;
    late GestantesProvider provider;

    setUp(() async {
      DatabaseHelper.reset();
      DatabaseHelper.overrideFactory = databaseFactoryFfi;
      DatabaseHelper.overridePath = inMemoryDatabasePath;
      
      dbHelper = DatabaseHelper();
      provider = GestantesProvider();
    });

    test('Fluxo completo de Cadastro, Checklist e Financeiro', () async {
      // 1. Criar gestante de exemplo
      final gestante = Gestante(
        nome: 'Beatriz Santos',
        dppFinal: DateTime.now().add(const Duration(days: 100)),
        maternidade: 'Maternidade Municipal',
        classificacaoRisco: 'Risco Habitual',
        valorContrato: 4500.0,
        diaVencimento: 10,
        ficha: [
          CartaoFicha(
            titulo: 'Consultas Pré-Natal',
            subtopicos: [
              Subtopico(texto: '1ª Consulta', concluido: true),
              Subtopico(texto: '2ª Consulta', concluido: false),
            ],
          )
        ],
        pagamentos: [
          Pagamento(valor: 1500.0, data: DateTime.now(), descricao: 'Entrada')
        ]
      );

      // Salva no banco de dados normalizado
      final id = await dbHelper.insertGestante(gestante);
      gestante.id = id.toString();
      expect(id, isPositive);

      // 2. Carrega do banco e valida a normalização
      final gestantesDoBanco = await dbHelper.getGestantes();
      expect(gestantesDoBanco.length, equals(1));
      
      final gSalva = gestantesDoBanco.first;
      expect(gSalva.nome, equals('Beatriz Santos'));
      expect(gSalva.valorContrato, equals(4500.0));
      expect(gSalva.diaVencimento, equals(10));
      expect(gSalva.totalPago, equals(1500.0));
      expect(gSalva.saldoDevedor, equals(3000.0));
      
      // Valida o checklist
      expect(gSalva.ficha.length, equals(1));
      expect(gSalva.ficha.first.titulo, equals('Consultas Pré-Natal'));
      expect(gSalva.ficha.first.subtopicos.length, equals(2));
      expect(gSalva.ficha.first.subtopicos[0].texto, equals('1ª Consulta'));
      expect(gSalva.ficha.first.subtopicos[0].concluido, isTrue);

      // 3. Atualizar dados (Checklist concluído e novos pagamentos)
      final fichaService = FichaService();
      
      // Alterna o segundo subtópico para concluído
      await fichaService.alternarConclusaoSubtopico(gSalva, gSalva.ficha.first, gSalva.ficha.first.subtopicos[1], true);
      
      // Adiciona mais um pagamento
      gSalva.pagamentos.add(Pagamento(valor: 3000.0, data: DateTime.now(), descricao: 'Quitação'));
      
      // Persiste a atualização
      await dbHelper.updateGestante(gSalva);

      // Recarrega e valida os dados finais
      final gestantesAtualizadas = await dbHelper.getGestantes();
      final gFinal = gestantesAtualizadas.first;

      // Toda a ficha deve estar marcada como concluída de forma cascateada
      expect(gFinal.ficha.first.concluido, isTrue);
      expect(gFinal.ficha.first.subtopicos[1].concluido, isTrue);

      // Saldo devedor deve estar zerado (quitado)
      expect(gFinal.totalPago, equals(4500.0));
      expect(gFinal.saldoDevedor, equals(0.0));
    });
  });
}
