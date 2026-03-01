# Fluxos Principais do Usuário

## Índice

1. [Autenticação](#1-autenticação)
2. [Criação e Seleção de Paciente](#2-criação-e-seleção-de-paciente)
3. [Convite de Membro](#3-convite-de-membro)
4. [Monitoramento de Saúde](#4-monitoramento-de-saúde)
5. [Gestão de Medicamentos](#5-gestão-de-medicamentos)
6. [Feed de Atividades](#6-feed-de-atividades)

---

## 1. Autenticação

### 1.1 Registro de Nova Conta

```
RegisterPage → AuthNotifier.register() → FirebaseAuthRepository
```

1. Usuário acessa `/register` a partir da tela de login
2. Preenche **nome**, **e-mail** e **senha**
3. Validação local dos campos (e-mail válido, senha mínima)
4. `AuthNotifier.register()` é chamado
5. `FirebaseAuthRepository.registerWithEmail()` cria a conta no Firebase Auth
6. Documento do perfil é criado em `users/{uid}` com os dados iniciais
7. `authStateProvider` emite o novo `AppUser`
8. O redirect do GoRouter detecta login e redireciona para `/my-patients`

### 1.2 Login

```
LoginPage → AuthNotifier.signIn() → FirebaseAuthRepository
```

1. Usuário acessa `/login`
2. Preenche **e-mail** e **senha**
3. `AuthNotifier.signIn()` é chamado
4. `FirebaseAuthRepository.signInWithEmail()` autentica no Firebase Auth
5. Busca o documento do perfil em `users/{uid}`
6. `authStateProvider` emite o `AppUser`
7. Redirect para `/my-patients`

### 1.3 Recuperação de Senha

```
ForgotPasswordPage → AuthNotifier.sendPasswordReset() → Firebase Auth
```

1. Usuário acessa `/forgot-password` a partir da tela de login
2. Informa o **e-mail** cadastrado
3. `AuthNotifier.sendPasswordReset()` chama `Firebase Auth.sendPasswordResetEmail()`
4. Firebase envia e-mail de redefinição
5. Usuário é informado do envio e retorna para `/login`

### 1.4 Logout

1. Usuário acessa a tela de configurações (`/settings`)
2. Toca em "Sair"
3. `AuthNotifier.signOut()` é chamado
4. Firebase Auth faz sign out local
5. `authStateProvider` emite `null`
6. Redirect para `/login`

---

## 2. Criação e Seleção de Paciente

### 2.1 Primeiro Acesso — Criar Paciente

```
MyPatientsPage → CreatePatientPage → PatientRepository.createPatient()
```

1. Após login, o usuário chega em `/my-patients`
2. Se não há pacientes, é exibido um **empty state** incentivando a criação
3. Usuário toca em "Criar Paciente" e navega para `/create-patient`
4. Preenche os dados obrigatórios:
   - Nome completo
   - Data de nascimento
   - Sexo
5. Opcionalmente adiciona: apelido, foto, condições, alergias, contatos de emergência, médico, notas clínicas
6. `PatientRepository.createPatient()` cria o documento em `patients/{patientId}`
7. Automaticamente cria um documento em `patients/{patientId}/members/{userId}` com `role: admin`
8. Retorna para `/my-patients` onde o paciente aparece na lista

### 2.2 Selecionar Paciente

1. Na tela `/my-patients`, o usuário vê todos os pacientes em que é membro
2. A lista é alimentada por `myPatientsProvider` (stream em tempo real)
3. Ao tocar em um paciente:
   - `selectedPatientIdProvider` é atualizado com o ID
   - Navegação para `/home` (dentro do ShellRoute)
4. Todas as features (saúde, medicamentos, atividades) passam a operar no contexto do paciente selecionado

### 2.3 Editar Paciente

```
PatientProfilePage → EditPatientPage → PatientRepository.updatePatient()
```

1. Na tela do paciente (`/patient-profile`), admin toca em "Editar"
2. Navega para `/edit-patient`
3. Formulário pré-preenchido com dados atuais
4. Após edição, `PatientRepository.updatePatient()` atualiza o documento
5. Retorna para o perfil atualizado

---

## 3. Convite de Membro

### 3.1 Criar Convite (Admin)

```
MembersPage → InviteMemberPage → PatientRepository.createInvite()
```

1. Admin acessa `/members` a partir do perfil do paciente
2. Visualiza a lista de membros atuais com seus papéis
3. Toca em "Convidar Membro" e navega para `/invite`
4. Preenche:
   - **E-mail** do convidado
   - **Papel** a ser atribuído (admin, editor ou viewer)
5. `PatientRepository.createInvite()` cria documento em `patients/{patientId}/invites/{inviteId}` com:
   - Código único gerado
   - Status `pending`
   - Data de expiração (7 dias, conforme `AppConstants.inviteExpirationDays`)
6. Convite é enviado (o convidado recebe notificação ou verifica manualmente)

### 3.2 Aceitar Convite (Convidado)

```
Convidado loga → verifica código → PatientRepository.acceptInvite()
```

1. O convidado faz login (ou cria conta) no app
2. Informa o **código do convite**
3. O app busca o convite onde `email == auth.token.email` e valida:
   - Status é `pending`
   - Não expirou (`expiresAt > now`)
4. `PatientRepository.acceptInvite()`:
   - Cria documento em `patients/{patientId}/members/{userId}` com o papel definido
   - Atualiza o convite para `status: accepted`
5. O paciente aparece na lista `/my-patients` do convidado

### 3.3 Gerenciar Membros (Admin)

1. Na tela `/members`, admin pode:
   - **Alterar papel** de um membro (admin/editor/viewer)
   - **Remover** um membro do paciente
2. Operações via `PatientRepository.updateMemberRole()` e `removeMember()`

---

## 4. Monitoramento de Saúde

### 4.1 Configurar Plano de Saúde (Admin)

```
HealthOverviewPage → HealthPlanConfigPage → HealthRepository.updateHealthPlan()
```

1. Admin acessa `/health` e toca em "Configurar Plano" (navega para `/health/plan-config`)
2. Seleciona quais **métricas** acompanhar entre as disponíveis:
   - Pressão Arterial, Frequência Cardíaca, Saturação O₂, Temperatura, Glicemia, Peso, Sono, Passos
3. Para cada métrica configurada:
   - Define a **frequência** (Diário, Semanal, etc.)
   - Define **horários agendados** (ex: 08:00, 20:00)
   - Define **faixa alvo** (min/max)
   - Ativa/desativa **lembretes**
4. `HealthRepository.updateHealthPlan()` salva cada métrica em `patients/{patientId}/plans/health/metrics/{metricType}`

### 4.2 Registrar Sinal Vital (Admin/Editor)

```
HealthOverviewPage → NewHealthRecordPage → HealthRepository.addHealthLog()
```

1. Na tela `/health`, editor/admin toca em "Novo Registro" ou seleciona métrica específica
2. Navega para `/health/new-record` (opcionalmente com `?metric=heartRate`)
3. Preenche os valores:
   - Para pressão arterial: **sistólica** e **diastólica**
   - Para demais: **valor único**
4. Opcionalmente adiciona **data/hora** da medição, **observações** e **anexos** (fotos)
5. Seleciona a **origem**: manual ou integrada (via pacote `health`)
6. `HealthRepository.addHealthLog()` salva em `patients/{patientId}/logs/health/{logId}`
7. Retorna para a overview atualizada

### 4.3 Visualizar Histórico

```
HealthOverviewPage → HealthMetricDetailPage
```

1. Na tela `/health`, toca em uma métrica específica
2. Navega para `/health/metric/:type`
3. Exibe:
   - **Gráfico** de tendência (via `fl_chart`)
   - **Lista** de registros recentes
   - **Indicadores** de faixa alvo (verde/vermelho)
4. Dados alimentados por `healthLogsProvider(metricType)` em tempo real

---

## 5. Gestão de Medicamentos

### 5.1 Criar Plano de Medicamento (Admin)

```
MedicationsTodayPage → CreateEditMedPlanPage → MedicationRepository.addMedPlanItem()
```

1. Admin acessa `/medications` e toca em "Adicionar Medicamento"
2. Navega para `/medications/create`
3. Pode **buscar no catálogo** (`/medications/search`) para auto-preencher nome e princípio ativo
4. Preenche:
   - **Nome** do medicamento
   - **Princípio ativo** (opcional)
   - **Forma farmacêutica** (Comprimido, Cápsula, Gotas, etc.)
   - **Dosagem** (ex: 50mg)
   - **Tipo de frequência**: intervalo (a cada X horas) ou horários fixos
   - **Horários** agendados ou **intervalo** em horas
   - **Data de início** e **data de término** (ou marcar como contínuo)
   - **Instruções** (ex: "Tomar em jejum")
   - **Foto** do medicamento (opcional)
5. `MedicationRepository.addMedPlanItem()` salva em `patients/{patientId}/plans/meds/{medPlanId}`

### 5.2 Marcar Dose (Admin/Editor)

```
MedicationsTodayPage → recordDoseEvent()
```

1. Na tela `/medications`, editor/admin vê as **doses do dia**
2. Lista alimentada por `todayDosesProvider(patientId)` — doses geradas automaticamente via `generateTodayDoses()`
3. Cada dose mostra: medicamento, horário agendado, status atual
4. Ao interagir com uma dose:
   - **Confirmar** → status muda para `tomado`, `actualAt` é registrado
   - **Pular** → status muda para `pulado`, pode informar motivo (`skipReason`)
   - **Adiar** → status muda para `adiado`
5. `MedicationRepository.recordDoseEvent()` salva em `patients/{patientId}/logs/meds/{doseEventId}`
6. A lista atualiza em tempo real via stream

### 5.3 Visualizar Histórico de Doses

```
MedicationsTodayPage → DoseHistoryPage
```

1. Na tela `/medications`, toca em "Histórico" (navega para `/medications/history`)
2. Exibe lista cronológica de todos os eventos de dose
3. Filtro opcional por medicamento específico via `doseHistoryProvider`
4. Cada evento mostra: medicamento, horário agendado, horário real, status, quem registrou

### 5.4 Ver Detalhes do Medicamento

```
MedicationsTodayPage → MedicationDetailPage
```

1. Toca em um medicamento na lista para ver `/medications/detail/:medPlanId`
2. Exibe informações completas: nome, forma, dosagem, frequência, instruções, foto
3. Admin pode **editar** ou **excluir** o plano

---

## 6. Feed de Atividades

### 6.1 Criar Post (Admin/Editor)

```
ActivitiesFeedPage → CreatePostPage → ActivityRepository.createPost()
```

1. Na tela `/activities`, editor/admin toca em "+" (FAB)
2. Navega para `/activities/create`
3. Preenche:
   - **Categoria** (Banho, Alimentação, Fisioterapia, etc.)
   - **Texto** descritivo
   - **Data/hora** do evento
   - **Fotos** (até 5, via `image_picker`) — upload para Firebase Storage
   - **Áudio** (até 120s, via `record`) — upload para Firebase Storage
   - **Tags** opcionais
4. `ActivityRepository.createPost()` salva em `patients/{patientId}/logs/activities/{postId}`
5. Retorna ao feed onde o post aparece no topo

### 6.2 Comentar em Post (Qualquer Membro)

```
ActivitiesFeedPage → PostDetailPage → ActivityRepository.addComment()
```

1. No feed, toca em um post para ver `/activities/:postId`
2. Na tela de detalhe, vê o post completo com fotos/áudio e comentários
3. Digita um comentário no campo de texto
4. `ActivityRepository.addComment()` salva em `.../comments/{commentId}`
5. `commentCount` é incrementado no documento do post
6. Comentário aparece em tempo real via `activityCommentsProvider`

### 6.3 Reagir a Post (Qualquer Membro)

1. No feed ou na tela de detalhe, toca em um emoji de reação
2. `ActivityRepository.toggleReaction()` adiciona/remove o UID do usuário no mapa `reactions`
3. Reação é um toggle — tocar novamente remove

### 6.4 Filtrar por Categoria

1. No feed `/activities`, toca em chips de categoria no topo
2. `categoryFilterProvider` é atualizado
3. `activitiesProvider` re-executa a query com filtro de categoria
4. Feed exibe apenas posts da categoria selecionada

### 6.5 Excluir Post/Comentário

- **Post:** Apenas admin pode excluir (`ActivityRepository.deletePost()`)
- **Comentário:** Admin ou o autor do comentário pode excluir (`ActivityRepository.deleteComment()`)
