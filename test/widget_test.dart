import 'package:flutter_test/flutter_test.dart';
import 'package:voz_ul/config/app_constants.dart';
import 'package:voz_ul/services/catalogo_service.dart';

void main() {
  group('Faculdades e cursos', () {
    // As listas de faculdades, cursos e locais de ocorrencia passaram para a
    // base de dados, por campus. O codigo deixou de ter uma lista propria:
    // uma segunda fonte de verdade era a origem das listas divergentes entre
    // a instituicao e a aplicacao. O que se verifica aqui e o comportamento
    // dos modelos que passam a sustentar essas listas.

    test('Faculdade guarda o campus a que pertence', () {
      // O mesmo nome de faculdade pode existir em dois campus: e o polo que
      // distingue a delegacao.
      const beira = Faculdade(
        id: 'f1',
        nome: 'Faculdade de Educação',
        poloId: 'licungo-beira',
      );
      const quelimane = Faculdade(
        id: 'f2',
        nome: 'Faculdade de Educação',
        poloId: 'licungo-quelimane',
      );

      expect(beira.nome, quelimane.nome);
      expect(beira.poloId, isNot(quelimane.poloId));
    });

    test('Campus sede aparece em primeiro lugar', () {
      const sede = Polo(
        id: 'licungo-quelimane',
        nome: 'Quelimane (sede)',
        cidade: 'Quelimane',
        principal: true,
      );
      const delegacao = Polo(
        id: 'licungo-beira',
        nome: 'Beira (delegação)',
        cidade: 'Beira',
      );

      expect(sede.principal, isTrue);
      expect(delegacao.principal, isFalse);
      expect(sede.rotulo, 'Quelimane (sede) — Quelimane');
    });
  });

  group('Leitura do catalogo', () {
    test('Lista vazia e erro sao coisas diferentes', () {
      // "Nao ha nada publicado" e a interface mostra a lista vazia;
      // "nao consegui ler" obriga a oferecer nova tentativa. Confundir as
      // duas faz o estudante acreditar que a universidade nao tem cursos.
      const vazio = LeituraCatalogo<String>([]);
      final erro = LeituraCatalogo<String>(const [], 'Sem ligacao.');

      expect(vazio.semDados, isTrue);
      expect(vazio.falhou, isFalse);

      expect(erro.semDados, isFalse);
      expect(erro.falhou, isTrue);
      expect(erro.erro, 'Sem ligacao.');
    });

    test('Lista com conteudo nao esta vazia nem em erro', () {
      final leitura = LeituraCatalogo<String>(const ['Medicina Geral']);

      expect(leitura.semDados, isFalse);
      expect(leitura.falhou, isFalse);
      expect(leitura.itens, hasLength(1));
    });
  });

  group('Categorias e status de denuncia', () {
    // Estas listas continuam a ser do cliente: sao constantes de interface
    // (o que se pode denunciar, em que estado esta), e nao dados da
    // universidade.
    test('Verificar categorias de denúncia', () {
      expect(AppConstants.categoriasDenuncia, contains('Outro'));
      expect(AppConstants.categoriasDenuncia, contains('Assédio sexual'));
    });

    test('Verificar status de denúncia', () {
      expect(AppConstants.statusDenuncia.length, 5);
      expect(AppConstants.statusDenuncia.first, 'Recebida');
      expect(AppConstants.statusDenuncia.last, 'Encerrada');
    });
  });
}