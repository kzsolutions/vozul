import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voz_ul/services/codigos_guardados_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ana = 'user-ana';
  const bruno = 'user-bruno';

  final service = CodigosGuardadosService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('começa sem códigos guardados', () async {
    expect(await service.carregar(ana), isEmpty);
  });

  test('guarda códigos normalizando para maiúsculas', () async {
    await service.guardar(ana, 'uni-58392');
    final guardados = await service.carregar(ana);
    expect(guardados, ['UNI-58392']);
  });

  test('não duplica códigos', () async {
    await service.guardar(ana, 'UNI-58392');
    await service.guardar(ana, 'UNI-58392');
    expect(await service.carregar(ana), ['UNI-58392']);
  });

  test('os códigos persistem entre instâncias do serviço', () async {
    await service.guardar(ana, 'UNI-00001');
    await service.guardar(ana, 'UNI-00002');

    final novaInstancia = CodigosGuardadosService();
    final guardados = await novaInstancia.carregar(ana);
    expect(guardados, contains('UNI-00001'));
    expect(guardados, contains('UNI-00002'));
  });

  test('remove apenas o código pedido', () async {
    await service.guardar(ana, 'UNI-00001');
    await service.guardar(ana, 'UNI-00002');

    await service.remover(ana, 'uni-00002');
    final guardados = await service.carregar(ana);
    expect(guardados, ['UNI-00001']);
  });

  test('um utilizador não vê os códigos de outro no mesmo dispositivo', () async {
    await service.guardar(ana, 'UNI-11111');

    expect(await service.carregar(bruno), isEmpty);
  });

  test('limparTodas apaga os códigos de todos os utilizadores', () async {
    await service.guardar(ana, 'UNI-11111');
    await service.guardar(bruno, 'UNI-22222');

    await service.limparTodas();

    expect(await service.carregar(ana), isEmpty);
    expect(await service.carregar(bruno), isEmpty);
  });

  test('código vazio não é guardado', () async {
    await service.guardar(ana, '   ');
    expect(await service.carregar(ana), isEmpty);
  });
}