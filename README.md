# VozUL — Voz da Universidade Licungo

Sistema institucional de denúncias académicas anónimas e identificadas.

## Visão Geral

A VozUL é uma aplicação Android (Flutter) que permite aos estudantes da Universidade Licungo comunicar ocorrências de assédio, corrupção académica, abuso de poder, discriminação e outros comportamentos inadequados, com garantia de anonimato e segurança.

## Decisões Técnicas

### Backend: Supabase (não Firebase)
- **Motivo:** O projeto já tinha Supabase conectado. Supabase fornece PostgreSQL + Auth + Storage + Realtime, substituindo totalmente o Firebase Firestore proposto.
- **Vantagens:** SQL relacional (melhor para dados estruturados), RLS para segurança no nível da base de dados, subscrições em tempo real via PostgreSQL.

### Autenticação: Supabase Auth + tabela profiles
- Usuários do Supabase Auth são estendidos com uma tabela `profiles` que contém `role` (estudante/admin/super_admin) e dados adicionais.
- Login: email + senha para todos os utilizadores.

### Chat: Supabase Realtime (postgres changes)
- Mensagens em tempo real via subscrição `supabase.from('mensagens').stream()`.
- Substitui Firebase Firestore/WebSockets propostos.

### State Management: Provider
- Simples, oficial do Flutter, adequado para o porte do projeto.

### Navegação: Navigator com IndexedStack
- Shell page (BottomNavigationBar para estudante, Drawer para admin).
- IndexedStack preserva estado entre abas.

### Anonimato
- Denúncias anónimas: `estudante_id = NULL` no banco.
- Código único `UNI-XXXXX` gerado por trigger PostgreSQL (8 dígitos randomicos).
- Chat: estudante aparece como "Denunciante Anónimo", admin como "Comissão de Ética".

### Segurança
- RLS habilitado em todas as tabelas.
- Storage bucket privado com URLs assinadas (1h de validade).
- Senhas com hash bcrypt (via Supabase Auth).
- Sem rastreio de IP ou localização no app.

## Estrutura do Projeto

```
lib/
├── main.dart                          # Entry point
├── config/
│   ├── supabase_config.dart           # URL e API key do Supabase
│   ├── app_theme.dart                 # Paleta de cores VozUL
│   └── app_constants.dart             # Faculdades, cursos, categorias
├── models/
│   ├── profile.dart                   # Modelo de perfil
│   ├── denuncia.dart                  # Modelo de denúncia
│   ├── mensagem.dart                  # Modelo de mensagem
│   └── notificacao.dart              # Modelo de notificação
├── services/
│   ├── auth_service.dart              # Login, registo, sessão
│   ├── denuncia_service.dart          # CRUD de denúncias
│   ├── chat_service.dart              # Mensagens em tempo real
│   └── admin_service.dart             # Gestão de admins, histórico
├── providers/
│   ├── auth_provider.dart             # Estado de autenticação
│   ├── denuncia_provider.dart         # Estado das denúncias
│   ├── chat_provider.dart             # Estado do chat
│   └── admin_provider.dart            # Estado administrativo
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart         # Verificação de sessão
│   │   ├── login_screen.dart          # Login email+senha
│   │   └── register_screen.dart       # Registo de estudante
│   ├── student/
│   │   ├── student_shell.dart         # Shell com BottomNavigationBar
│   │   ├── home_screen.dart           # Home com categorias
│   │   ├── denuncia_form_screen.dart  # Formulário completo
│   │   ├── denuncia_sucesso_screen.dart # Código gerado
│   │   ├── acompanhar_screen.dart     # Busca por código + timeline
│   │   ├── denuncias_minhas_screen.dart # Lista do estudante
│   │   ├── chat_screen.dart           # Chat em tempo real
│   │   └── perfil_screen.dart         # Perfil do estudante
│   └── admin/
│       ├── admin_shell.dart           # Shell com Drawer
│       ├── dashboard_screen.dart      # Stats + gráficos
│       ├── denuncias_list_screen.dart # Lista + filtros
│       ├── denuncia_detail_screen.dart # Detalhe + status + chat
│       ├── relatorios_screen.dart     # PDF e CSV
│       ├── admins_screen.dart         # Gestão de admins
│       ├── historico_screen.dart      # Histórico de acessos
│       ├── chat_list_screen.dart      # Lista de conversas
│       └── profile_screen.dart        # Perfil + config global
├── widgets/
│   ├── app_logo.dart                  # Logo institucional
│   ├── status_chip.dart               # Badge de status
│   └── empty_state.dart               # Estado vazio
└── utils/
    ├── validators.dart                # Validação de campos
    └── formatters.dart                # Formatação de dados
```

## Base de Dados (Supabase PostgreSQL)

### Tabelas
| Tabela | Descrição |
|--------|-----------|
| `profiles` | Estendida de `auth.users` com role, dados pessoais |
| `denuncias` | Denúncias com código único, status, evidências |
| `denuncias_evidencias` | Metadados de ficheiros uploadados |
| `mensagens` | Chat em tempo real por denúncia |
| `notificacoes` | Alertas por faculdade |
| `historico_acessos` | Log de ações dos admins |
| `admin_config` | Configurações globais do sistema |

### Triggers
- `gerar_codigo_denuncia()` — Gera `UNI-XXXXX` automaticamente no INSERT.
- `atualizar_updated_at()` — Atualiza timestamp no UPDATE.

### RLS (Row-Level Security)
- **Estudante:** Vê apenas suas denúncias e mensagens.
- **Admin Nível 2:** Vê denúncias da sua faculdade.
- **Super Admin:** Acesso total a todas as faculdades.

## Faculdades e Cursos

1. **Faculdade de Engenharia e Planeamento Físico** (4 cursos)
2. **Faculdade de Letras e Humanidades** (3 cursos)
3. **Faculdade de Educação** (20 cursos)
4. **Faculdade de Economia e Gestão** (5 cursos)
5. **Faculdade de Ciências Agrárias** (4 cursos)
6. **Faculdade de Medicina** (1 curso)

## Funcionalidades Implementadas

- [x] Login e registo de estudante
- [x] Login de administrador (email + senha)
- [x] Formulário completo de denúncia (8 categorias + "Outro")
- [x] Upload de evidências (imagens, PDFs, áudios, vídeos)
- [x] Denúncia anónima ou identificada
- [x] Código único `UNI-XXXXX` para acompanhamento
- [x] Timeline de status (Recebida → Em análise → Investigação → Resolvida → Encerrada)
- [x] Chat em tempo real entre estudante e comissão
- [x] Dashboard com gráficos (categorias, evolução mensal, faculdades)
- [x] Filtros por categoria, faculdade, status, período
- [x] Relatórios em PDF e CSV
- [x] Gestão de administradores (apenas Super Admin)
- [x] Histórico de acessos (pessoal ou global)
- [x] Perfil com edição e alteração de senha
- [x] Configurações globais dentro do perfil do Super Admin
- [x] Faculdade substitui departamento, com busca livre
- [x] Cursos dinâmicos conforme faculdade
- [x] Local: Campus Coalane (Bloco I, II), Campus Murropue, Outro
- [x] Validação de ficheiros (tipo, tamanho)
- [x] Informação explícita quando não há provas anexadas
- [x] Notificações por faculdade

## Credenciais Super Admin (Seed)

| Campo | Valor |
|-------|-------|
| Email | `admin@vozul.ac.mz` |
| Senha | `<definir no Supabase Auth>` |
| Role | `super_admin` |

## Executar o Projeto

```bash
# Instalar dependências
flutter pub get

# Executar em debug
flutter run

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release

# Rodar testes
flutter test

# Análise de código
flutter analyze
```

## Instalar num Dispositivo Real (Android)

### Pré-requisitos
1. **Dispositivo Android** com modo de programador ativado:
   - Definições → Sobre o telefone → Tocar 7x em "Número de compilação"
   - Definições → Opções de programador → Ativar "Depuração USB"
2. **Instalar/Atualizar** o [Android Studio](https://developer.android.com/studio) com o SDK Platform é recomendado.
3. Ligar o telemóvel ao PC via cabo USB e aceitar o aviso de "Depuração USB".

### Instalar e executar no dispositivo

```bash
# Ver dispositivos conectados
flutter devices

# Executar diretamente no dispositivo conectado
flutter run -d <id_do_dispositivo>

# Ou instalar o APK previamente compilado
flutter install -d <id_do_dispositivo>
```

### Sem cabo USB (transferência manual)

```bash
# Compilar o APK (fica em build/app/outputs/flutter-apk/)
flutter build apk --release
```

Depois transfira `build\app\outputs\flutter-apk\app-release.apk` para o telemóvel
(Google Drive, WhatsApp, cabo, etc.) e instale manualmente
(na primeira instalação, será pedido para permitir "fontes desconhecidas").

### Primeiro login

| Perfil | Email | Senha |
|--------|-------|-------|
| Super Admin | `admin@vozul.ac.mz` | `<definir no Supabase Auth>` |
| Estudante | Registe-se na própria app | — |

> **Nota:** O modo release requer assinatura com keystore. Para testes use
> `flutter build apk --debug` ou configure a assinatura em
> `android/app/build.gradle.kts` conforme a [documentação oficial](https://docs.flutter.dev/deployment/android#signing-the-app).

## Funcionalidades Futuras (não implementadas)

- Inteligência artificial para deteção de denúncias falsas
- App iOS
- Chat de apoio psicológico para vítimas
- Mapa de ocorrências por campus/bloco
- Notificações push (FCM)
- Limitação de spam por utilizador/IP
- CAPTCHA anti-bots

# vozul
