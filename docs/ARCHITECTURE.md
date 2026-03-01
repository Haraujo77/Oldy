# Arquitetura do Oldy

## Visão Geral

O Oldy segue os princípios da **Clean Architecture**, organizando o código em camadas com separação clara de responsabilidades. A estrutura é **baseada em features**, onde cada funcionalidade do app é um módulo independente com suas próprias camadas.

---

## Camadas da Arquitetura

### 1. Presentation (Apresentação)

Responsável pela UI e pelo gerenciamento de estado local.

| Componente | Responsabilidade |
|---|---|
| `pages/` | Telas completas (widgets de nível superior) |
| `widgets/` | Componentes reutilizáveis dentro da feature |
| `providers/` | Providers Riverpod que expõem estado reativo para a UI |

Os providers da camada de apresentação consomem os repositórios da camada de domínio e expõem streams/futures tipados para os widgets.

### 2. Domain (Domínio)

Núcleo de negócios do app, **sem dependências de frameworks externos**.

| Componente | Responsabilidade |
|---|---|
| `entities/` | Modelos de dados puros (classes Dart simples) |
| `repositories/` | Contratos abstratos (interfaces) que definem operações de dados |
| `usecases/` | Lógica de negócios encapsulada (quando necessário) |

As entidades possuem métodos `toMap()` e `fromMap()` para serialização, mantendo a conversão próxima ao modelo.

### 3. Data (Dados)

Implementação concreta do acesso a dados.

| Componente | Responsabilidade |
|---|---|
| `repositories/` | Implementações concretas (ex: `FirebaseAuthRepository`) |
| `datasources/` | Fontes de dados (Firestore, Storage, APIs) |
| `dtos/` | Objetos de transferência para conversão entre camadas |

---

## Estrutura de Pastas por Feature

```
lib/
├── core/                          # Código compartilhado
│   ├── constants/                 # Constantes globais (AppConstants)
│   ├── errors/                    # Classes de falha (Failure)
│   ├── extensions/                # Extensões de contexto
│   ├── router/                    # GoRouter + ShellScaffold
│   ├── theme/                     # Tema, cores, tipografia, espaçamento
│   ├── utils/                     # Formatadores, validadores
│   └── widgets/                   # Widgets compartilhados (AppBar, Loading, Empty, Error)
│
├── features/
│   ├── auth/                      # Autenticação
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── dtos/
│   │   │   └── repositories/      # FirebaseAuthRepository
│   │   ├── domain/
│   │   │   ├── entities/          # AppUser
│   │   │   ├── repositories/      # AuthRepository (abstrato)
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/             # Login, Register, Splash, ForgotPassword
│   │       ├── providers/         # authStateProvider, authNotifierProvider
│   │       └── widgets/
│   │
│   ├── patient_selection/         # Seleção de paciente
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── pages/             # MyPatientsPage
│   │
│   ├── management/                # Gestão de pacientes e membros
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── entities/          # Patient, PatientMember, Invite
│   │   └── presentation/
│   │       └── pages/             # CreatePatient, EditPatient, Members, Invite
│   │
│   ├── home/                      # Dashboard principal
│   │   └── presentation/
│   │
│   ├── health/                    # Monitoramento de saúde
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── entities/          # HealthMetric, HealthLog
│   │   └── presentation/
│   │       └── pages/             # Overview, MetricDetail, NewRecord, PlanConfig
│   │
│   ├── medications/               # Gestão de medicamentos
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── entities/          # MedPlanItem, DoseEvent, MedicationCatalogItem
│   │   └── presentation/
│   │       └── pages/             # MedicationsToday, Detail, Create, Search, History
│   │
│   ├── activities/                # Feed de atividades
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── entities/          # ActivityPost, ActivityComment
│   │   └── presentation/
│   │       └── pages/             # Feed, CreatePost, PostDetail
│   │
│   └── settings/                  # Configurações
│       └── presentation/
│
├── firebase/                      # Configuração Firebase
│   └── firebase_options.dart
│
├── l10n/                          # Internacionalização (pt-BR, en-US)
│
├── app.dart                       # Widget raiz (MaterialApp.router)
└── main.dart                      # Entry point (Firebase.initializeApp)
```

---

## Gerenciamento de Estado — Riverpod

O app utiliza **flutter_riverpod** como solução de gerenciamento de estado e injeção de dependências.

### Tipos de Providers utilizados

| Provider | Uso |
|---|---|
| `Provider` | Instâncias de repositórios (singleton) |
| `StateProvider` | Estado simples mutável (ex: `selectedPatientIdProvider`, `categoryFilterProvider`) |
| `StreamProvider` | Streams do Firestore em tempo real (ex: `myPatientsProvider`, `healthLogsProvider`) |
| `StreamProvider.family` | Streams parametrizados (ex: `medPlanProvider(patientId)`) |
| `FutureProvider` | Operações assíncronas pontuais (ex: `currentUserProvider`) |
| `FutureProvider.family` | Buscas parametrizadas (ex: `catalogSearchProvider(query)`) |
| `StateNotifierProvider` | Estado complexo com lógica (ex: `authNotifierProvider`) |

### Padrão de Injeção

```
Provider<Repository>  →  repositoryProvider (instância concreta)
     ↓
StreamProvider<T>     →  watch(repositoryProvider).watchXxx()
     ↓
ConsumerWidget        →  ref.watch(xxxProvider)
```

---

## Roteamento — go_router com ShellRoute

O roteamento é gerenciado pelo `go_router`, integrado com Riverpod via `routerProvider`.

### Estrutura de Rotas

```
/                        → SplashPage
/login                   → LoginPage
/register                → RegisterPage
/forgot-password         → ForgotPasswordPage
/my-patients             → MyPatientsPage
/create-patient          → CreatePatientPage (full screen)
/patient-profile         → PatientProfilePage (full screen)
/edit-patient            → EditPatientPage (full screen)
/members                 → MembersPage (full screen)
/invite                  → InviteMemberPage (full screen)
/settings                → SettingsPage (full screen)

ShellRoute (com bottom nav):
├── /home                → HomePage
├── /health              → HealthOverviewPage
│   ├── metric/:type     → HealthMetricDetailPage
│   ├── new-record       → NewHealthRecordPage
│   └── plan-config      → HealthPlanConfigPage
├── /medications         → MedicationsTodayPage
│   ├── detail/:id       → MedicationDetailPage
│   ├── create           → CreateEditMedPlanPage
│   ├── search           → MedicationSearchPage
│   └── history          → DoseHistoryPage
└── /activities          → ActivitiesFeedPage
    ├── create           → CreatePostPage
    └── :postId          → PostDetailPage
```

### ShellScaffold

O `ShellScaffold` envolve as 4 tabs principais (Início, Saúde, Remédios, Atividades) com um `NavigationBar` do Material 3. Sub-rotas que precisam de tela cheia usam `parentNavigatorKey: _rootNavigatorKey` para sair do shell.

### Redirect Guard

O `redirect` do GoRouter verifica o estado de autenticação via `authStateProvider`:
- Usuário **não autenticado** tentando acessar rota protegida → redireciona para `/login`
- Usuário **autenticado** tentando acessar rota de auth → redireciona para `/my-patients`

---

## Integração Firebase

### Serviços utilizados

| Serviço | Uso |
|---|---|
| **Firebase Auth** | Autenticação por e-mail/senha |
| **Cloud Firestore** | Banco de dados principal (tempo real, offline) |
| **Firebase Storage** | Upload de fotos, áudios e anexos |
| **Firebase Messaging** | Notificações push |
| **Firebase Crashlytics** | Relatórios de crash |
| **Firebase Analytics** | Eventos de uso |

### Padrão de Integração

1. `Firebase.initializeApp()` é chamado no `main()` antes de `runApp()`
2. O app é envolvido em `ProviderScope` (Riverpod)
3. Cada feature possui um `FirebaseXxxRepository` que implementa o contrato abstrato
4. Os repositórios acessam diretamente `FirebaseFirestore.instance` e `FirebaseStorage.instance`
5. Streams do Firestore (`snapshots()`) são expostos via `StreamProvider` para reatividade em tempo real
6. O Firestore opera com **cache offline habilitado** por padrão, permitindo leitura sem conexão

---

## Fluxo de Dependências entre Camadas

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                          │
│                                                          │
│   Pages ──► Providers (Riverpod)                         │
│                │                                         │
│                │ ref.watch(repositoryProvider)            │
│                ▼                                         │
├─────────────────────────────────────────────────────────┤
│                      DOMAIN                              │
│                                                          │
│   Entities       Repositories (abstract)     Use Cases   │
│       ▲                  ▲                               │
│       │                  │ implements                     │
│       │                  │                               │
├───────┼──────────────────┼──────────────────────────────┤
│       │            DATA  │                               │
│       │                  │                               │
│       └── DTOs    Repositories (Firebase)    DataSources │
│                          │                               │
│                          ▼                               │
│                  Firebase SDK (Firestore, Auth, Storage)  │
└─────────────────────────────────────────────────────────┘
```

### Regra de Dependência

- **Presentation** depende de **Domain** (via providers que referenciam interfaces)
- **Data** depende de **Domain** (implementa interfaces, usa entidades)
- **Domain** não depende de nenhuma outra camada (centro puro)
- **Core** é transversal — utilizado por todas as camadas (tema, rotas, widgets, constantes)

---

## Internacionalização

O app suporta dois idiomas via `flutter_localizations` + ARB files:

- `pt-BR` (padrão)
- `en-US`

Os arquivos de tradução ficam em `lib/l10n/`.

---

## Tema

O app utiliza **Material 3** com suporte a modo claro e escuro:

- `ThemeMode.system` — acompanha a preferência do sistema
- Cores, tipografia e espaçamento centralizados em `core/theme/`
- Componentes do Material 3 personalizados (Cards, Buttons, NavigationBar, Chips, etc.)
