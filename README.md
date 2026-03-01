# Oldy

Aplicativo Flutter para **gestão colaborativa da saúde de idosos**. O Oldy permite que familiares, cuidadores e profissionais de saúde acompanhem medicamentos, sinais vitais e atividades diárias de forma compartilhada e em tempo real.

---

## Screenshots

> _Em breve — capturas de tela serão adicionadas aqui._

| Tela | Claro | Escuro |
|---|---|---|
| Login | ![login-light] | ![login-dark] |
| Home | ![home-light] | ![home-dark] |
| Saúde | ![health-light] | ![health-dark] |
| Medicamentos | ![meds-light] | ![meds-dark] |
| Atividades | ![activities-light] | ![activities-dark] |

<!--
[login-light]: docs/screenshots/login_light.png
[login-dark]: docs/screenshots/login_dark.png
[home-light]: docs/screenshots/home_light.png
[home-dark]: docs/screenshots/home_dark.png
[health-light]: docs/screenshots/health_light.png
[health-dark]: docs/screenshots/health_dark.png
[meds-light]: docs/screenshots/meds_light.png
[meds-dark]: docs/screenshots/meds_dark.png
[activities-light]: docs/screenshots/activities_light.png
[activities-dark]: docs/screenshots/activities_dark.png
-->

---

## Funcionalidades

### Gestão de Pacientes
- Cadastro completo do idoso (dados pessoais, condições, alergias, contatos de emergência)
- Sistema de convite por código para adicionar cuidadores
- Controle de acesso por papéis: **Admin**, **Editor** e **Viewer**

### Monitoramento de Saúde
- 8 tipos de métricas: pressão arterial, frequência cardíaca, saturação O₂, temperatura, glicemia, peso, sono e passos
- Plano de saúde configurável (frequência, horários, faixa alvo, lembretes)
- Gráficos de tendência com histórico
- Integração com Apple Health / Google Health Connect

### Gestão de Medicamentos
- Plano de medicamentos com horários fixos ou por intervalo
- Catálogo de medicamentos com busca
- Registro de doses (tomado, pulado, adiado, atrasado)
- Histórico completo de aderência

### Feed de Atividades
- Posts com fotos (até 5) e áudio (até 120s)
- Categorias: Banho, Alimentação, Fisioterapia, Visita médica, Visita familiar, Exercício
- Reações com emojis e comentários
- Filtro por categoria

### Geral
- Modo claro e escuro (automático)
- Internacionalização (Português BR e Inglês)
- Funciona offline (cache Firestore)
- Notificações push e lembretes locais

---

## Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| **Framework** | Flutter 3.x (Dart 3.11+) |
| **Estado** | Riverpod (flutter_riverpod) |
| **Navegação** | go_router (ShellRoute para bottom nav) |
| **Backend** | Firebase (Auth, Firestore, Storage, Messaging, Crashlytics, Analytics) |
| **Saúde** | Pacote `health` (Apple Health / Google Health Connect) |
| **Gráficos** | fl_chart |
| **Mídia** | image_picker, record, audioplayers, cached_network_image |
| **Notificações** | firebase_messaging, flutter_local_notifications |
| **UI** | Material 3, shimmer, flutter_svg, timeago |
| **Testes** | flutter_test, mocktail |
| **Code Gen** | build_runner, freezed, json_serializable, riverpod_generator |

---

## Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.x (canal stable)
- Dart SDK >= 3.11.0
- [Firebase CLI](https://firebase.google.com/docs/cli) instalado e configurado
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) para configuração Firebase
- Conta Firebase com projeto criado
- (Opcional) Xcode para build iOS
- (Opcional) Android Studio para build Android

---

## Configuração

### 1. Clonar o repositório

```bash
git clone https://github.com/seu-usuario/oldy.git
cd oldy
```

### 2. Instalar dependências Flutter

```bash
flutter pub get
```

### 3. Configurar Firebase

```bash
# Instalar FlutterFire CLI (se ainda não instalado)
dart pub global activate flutterfire_cli

# Configurar Firebase (gera firebase_options.dart)
flutterfire configure
```

Isso criará/atualizará o arquivo `lib/firebase/firebase_options.dart` com as credenciais do seu projeto.

### 4. Deploy das regras de segurança

```bash
# Instalar Firebase CLI (se ainda não instalado)
npm install -g firebase-tools

# Login
firebase login

# Deploy das regras
firebase deploy --only firestore:rules,storage
```

Os arquivos de regras estão em:
- `firebase/firestore.rules`
- `firebase/storage.rules`

### 5. (Opcional) Seed do catálogo de medicamentos

Popule a coleção `medCatalog` no Firestore com medicamentos comuns. Pode ser feito via Firebase Console ou script customizado.

### 6. (Opcional) Gerar código

Se modificar modelos com `freezed` ou `riverpod_generator`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Executando o App

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

### Debug com hot reload

```bash
flutter run
```

### Build de release

```bash
# Android (APK)
flutter build apk --release

# Android (AAB para Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## Estrutura do Projeto

```
oldy/
├── lib/
│   ├── core/                       # Código compartilhado
│   │   ├── constants/              # Constantes globais
│   │   ├── errors/                 # Classes de falha
│   │   ├── extensions/             # Extensões de contexto
│   │   ├── router/                 # GoRouter + ShellScaffold
│   │   ├── theme/                  # Tema Material 3
│   │   ├── utils/                  # Formatadores, validadores
│   │   └── widgets/                # Widgets reutilizáveis
│   │
│   ├── features/                   # Features (Clean Architecture)
│   │   ├── auth/                   # Autenticação
│   │   ├── patient_selection/      # Seleção de paciente
│   │   ├── management/             # Gestão de pacientes e membros
│   │   ├── home/                   # Dashboard
│   │   ├── health/                 # Monitoramento de saúde
│   │   ├── medications/            # Gestão de medicamentos
│   │   ├── activities/             # Feed de atividades
│   │   └── settings/               # Configurações
│   │
│   ├── firebase/                   # Configuração Firebase
│   ├── l10n/                       # Internacionalização
│   ├── app.dart                    # Widget raiz
│   └── main.dart                   # Entry point
│
├── firebase/                       # Regras de segurança
│   ├── firestore.rules
│   └── storage.rules
│
├── assets/                         # Recursos estáticos
│   ├── images/
│   └── icons/
│
├── docs/                           # Documentação
│   ├── ARCHITECTURE.md
│   ├── DATA_MODEL.md
│   ├── SECURITY_RULES.md
│   ├── FLOWS.md
│   ├── DECISIONS.md
│   └── QA_CHECKLIST.md
│
├── test/                           # Testes
├── pubspec.yaml                    # Dependências
└── README.md                       # Este arquivo
```

Cada feature segue a estrutura **Clean Architecture**:

```
feature/
├── data/
│   ├── datasources/        # Fontes de dados (Firebase)
│   ├── dtos/               # Data Transfer Objects
│   └── repositories/       # Implementação concreta
├── domain/
│   ├── entities/           # Modelos de domínio
│   ├── repositories/       # Contratos abstratos
│   └── usecases/           # Lógica de negócios
└── presentation/
    ├── pages/              # Telas
    ├── providers/          # Riverpod providers
    └── widgets/            # Componentes da feature
```

---

## Documentação Adicional

| Documento | Descrição |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arquitetura, camadas e padrões |
| [DATA_MODEL.md](docs/DATA_MODEL.md) | Modelo de dados Firestore |
| [SECURITY_RULES.md](docs/SECURITY_RULES.md) | Regras de segurança e RBAC |
| [FLOWS.md](docs/FLOWS.md) | Fluxos principais do usuário |
| [DECISIONS.md](docs/DECISIONS.md) | Decisões técnicas e trade-offs |
| [QA_CHECKLIST.md](docs/QA_CHECKLIST.md) | Checklist de qualidade |

---

## Contribuindo

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/minha-feature`)
3. Faça commit das suas alterações (`git commit -m 'Adiciona minha feature'`)
4. Envie para a branch (`git push origin feature/minha-feature`)
5. Abra um Pull Request

### Convenções

- **Commits:** Use mensagens descritivas em português ou inglês
- **Branches:** `feature/`, `fix/`, `refactor/`, `docs/`
- **Código:** Siga as regras do `analysis_options.yaml` e `riverpod_lint`
- **Testes:** Adicione testes para novas features quando possível

---

## Licença

Este projeto está licenciado sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.

```
MIT License

Copyright (c) 2025 Helder Araújo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
