import 'package:shared_preferences/shared_preferences.dart';

/// Persiste localmente os códigos das denúncias anónimas para que o estudante
/// os possa voltar a consultar sem os perder. Só o código é guardado — nunca a
/// descrição nem dados pessoais.
///
/// Os códigos são guardados por utilizador (chave `codigos_guardados_<user_id>`)
/// para que uma segunda conta que entre no mesmo dispositivo não veja as
/// denúncias anónimas de outra pessoa.
class CodigosGuardadosService {
  static const String _prefixo = 'codigos_guardados_';

  String _chave(String userId) => '$_prefixo$userId';

  Future<List<String>> carregar(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_chave(userId)) ?? [];
  }

  Future<List<String>> guardar(String userId, String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    final chave = _chave(userId);
    final normalizado = _normalizar(codigo);
    if (normalizado.isEmpty) return prefs.getStringList(chave) ?? [];

    final atuais = prefs.getStringList(chave) ?? [];
    if (!atuais.contains(normalizado)) {
      atuais.insert(0, normalizado);
      await prefs.setStringList(chave, atuais);
    }
    return atuais;
  }

  Future<List<String>> remover(String userId, String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    final chave = _chave(userId);
    final normalizado = _normalizar(codigo);
    final novos = prefs.getStringList(chave) ?? [];
    novos.removeWhere((c) => c == normalizado);
    await prefs.setStringList(chave, novos);
    return novos;
  }

  /// Apaga todos os códigos guardados no dispositivo. Usado ao terminar sessão
  /// para que nada do utilizador anterior fique acessível.
  Future<void> limparTodas() async {
    final prefs = await SharedPreferences.getInstance();
    final chaves = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefixo))
        .toList();
    for (final k in chaves) {
      await prefs.remove(k);
    }
  }

  String _normalizar(String codigo) => codigo.trim().toUpperCase();
}