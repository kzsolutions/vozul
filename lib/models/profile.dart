class Profile {
  final String id;
  final String role;
  final String? nomeCompleto;
  final String? numeroEstudante;
  final String? celular;
  final String? email;
  final String? faculdade;
  final String? curso;
  final String? avatarUrl;
  final DateTime? createdAt;

  /// Dados da validação académica, escrita apenas pelo servidor.
  final String? numeroValidadoOrigem;
  final String? numeroValidadoEstado;
  final DateTime? numeroValidadoEm;
  final String? instituicaoId;
  final String? poloId;

  Profile({
    required this.id,
    required this.role,
    this.nomeCompleto,
    this.numeroEstudante,
    this.celular,
    this.email,
    this.faculdade,
    this.curso,
    this.avatarUrl,
    this.createdAt,
    this.numeroValidadoOrigem,
    this.numeroValidadoEstado,
    this.numeroValidadoEm,
    this.instituicaoId,
    this.poloId,
  });

  /// `true` quando o servidor já validou o número de estudante desta conta.
  bool get temValidacao => numeroValidadoOrigem != null;

  /// `true` quando há número registado mas ainda sem validação (por exemplo,
  /// a conta foi criada enquanto a fonte da universidade estava em baixo).
  bool get validacaoPendente =>
      !temValidacao &&
      numeroEstudante != null &&
      numeroEstudante!.isNotEmpty;

  bool get isEstudante => role == 'estudante';
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdminOuSuper => isAdmin || isSuperAdmin;

  String get displayName {
    if (nomeCompleto != null && nomeCompleto!.isNotEmpty) return nomeCompleto!;
    if (email != null) return email!;
    return 'Utilizador';
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'estudante',
      nomeCompleto: json['nome_completo'] as String?,
      numeroEstudante: json['numero_estudante'] as String?,
      celular: json['celular'] as String?,
      email: json['email'] as String?,
      faculdade: json['faculdade'] as String?,
      curso: json['curso'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      numeroValidadoOrigem: json['numero_validado_origem'] as String?,
      numeroValidadoEstado: json['numero_validado_estado'] as String?,
      numeroValidadoEm: json['numero_validado_em'] != null
          ? DateTime.tryParse(json['numero_validado_em'] as String)
          : null,
      instituicaoId: json['instituicao_id'] as String?,
      poloId: json['polo_id'] as String?,
    );
  }

  Profile copyWith({String? role}) {
    return Profile(
      id: id,
      role: role ?? this.role,
      nomeCompleto: nomeCompleto,
      numeroEstudante: numeroEstudante,
      celular: celular,
      email: email,
      faculdade: faculdade,
      curso: curso,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      numeroValidadoOrigem: numeroValidadoOrigem,
      numeroValidadoEstado: numeroValidadoEstado,
      numeroValidadoEm: numeroValidadoEm,
      instituicaoId: instituicaoId,
      poloId: poloId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'nome_completo': nomeCompleto,
      'numero_estudante': numeroEstudante,
      'celular': celular,
      'email': email,
      'faculdade': faculdade,
      'curso': curso,
      'avatar_url': avatarUrl,
    };
  }
}