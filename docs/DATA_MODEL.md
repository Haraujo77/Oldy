# Modelo de Dados — Firestore

## Visão Geral

O Oldy utiliza o **Cloud Firestore** como banco de dados principal. Os dados são organizados em coleções e subcoleções aninhadas sob o documento do paciente, seguindo um modelo centrado no paciente.

---

## Diagrama de Coleções

```
firestore/
├── users/{userId}                                    # Perfil do usuário
├── patients/{patientId}                              # Dados do paciente
│   ├── members/{userId}                              # Membros com acesso
│   ├── invites/{inviteId}                            # Convites pendentes
│   ├── plans/
│   │   ├── health/metrics/{metricType}               # Plano de saúde
│   │   └── meds/{medPlanId}                          # Plano de medicamentos
│   └── logs/
│       ├── health/{logId}                            # Registros de saúde
│       ├── meds/{doseEventId}                        # Eventos de dose
│       └── activities/{postId}                       # Posts de atividade
│           └── comments/{commentId}                  # Comentários do post
└── medCatalog/{medicationId}                         # Catálogo de medicamentos (global, somente leitura)
```

---

## Coleções Detalhadas

### 1. `users/{userId}` — Perfil do Usuário

**Caminho Firestore:** `users/{userId}`
**Entidade Dart:** `AppUser`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `uid` | `string` | Sim | UID do Firebase Auth |
| `email` | `string` | Sim | E-mail do usuário |
| `displayName` | `string` | Sim | Nome de exibição |
| `photoUrl` | `string?` | Não | URL da foto de perfil |
| `phone` | `string?` | Não | Telefone |
| `relation` | `string?` | Não | Relação com o idoso (ex: Filho(a), Cuidador(a)) |
| `createdAt` | `string` (ISO 8601) | Sim | Data de criação da conta |

**Exemplo:**
```json
{
  "uid": "abc123",
  "email": "maria@email.com",
  "displayName": "Maria Silva",
  "photoUrl": "https://storage.googleapis.com/...",
  "phone": "+5511999999999",
  "relation": "Filho(a)",
  "createdAt": "2025-03-01T10:00:00.000Z"
}
```

---

### 2. `patients/{patientId}` — Paciente

**Caminho Firestore:** `patients/{patientId}`
**Entidade Dart:** `Patient`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do documento |
| `fullName` | `string` | Sim | Nome completo |
| `nickname` | `string?` | Não | Apelido |
| `photoUrl` | `string?` | Não | URL da foto |
| `dateOfBirth` | `string` (ISO 8601) | Sim | Data de nascimento |
| `sex` | `string` | Sim | Sexo (`M` / `F`) |
| `conditions` | `array<string>` | Não | Condições de saúde (ex: Diabetes, Hipertensão) |
| `allergies` | `array<string>` | Não | Alergias conhecidas |
| `emergencyContacts` | `array<map>` | Não | Contatos de emergência (cada mapa com `name`, `phone`, `relation`) |
| `responsibleDoctor` | `string?` | Não | Nome do médico responsável |
| `clinicalNotes` | `string?` | Não | Observações clínicas |
| `createdAt` | `string` (ISO 8601) | Sim | Data de criação |
| `createdBy` | `string` | Sim | UID de quem criou |

**Exemplo:**
```json
{
  "id": "pat_001",
  "fullName": "José da Silva",
  "nickname": "Seu Zé",
  "photoUrl": null,
  "dateOfBirth": "1940-05-15T00:00:00.000Z",
  "sex": "M",
  "conditions": ["Hipertensão", "Diabetes Tipo 2"],
  "allergies": ["Dipirona"],
  "emergencyContacts": [
    { "name": "Maria Silva", "phone": "+5511999999999", "relation": "Filha" }
  ],
  "responsibleDoctor": "Dr. Carlos Mendes",
  "clinicalNotes": "Acompanhamento cardiológico mensal.",
  "createdAt": "2025-03-01T10:00:00.000Z",
  "createdBy": "abc123"
}
```

---

### 3. `patients/{patientId}/members/{userId}` — Membro do Paciente

**Caminho Firestore:** `patients/{patientId}/members/{userId}`
**Entidade Dart:** `PatientMember`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `userId` | `string` | Sim | UID do membro |
| `displayName` | `string` | Sim | Nome de exibição |
| `email` | `string` | Sim | E-mail |
| `photoUrl` | `string?` | Não | URL da foto |
| `role` | `string` | Sim | Papel: `admin`, `editor` ou `viewer` |
| `status` | `string` | Sim | Status: `active` ou `pending` |
| `joinedAt` | `string` (ISO 8601) | Sim | Data de entrada |
| `invitedBy` | `string?` | Não | UID de quem convidou |

**Exemplo:**
```json
{
  "userId": "abc123",
  "displayName": "Maria Silva",
  "email": "maria@email.com",
  "photoUrl": null,
  "role": "admin",
  "status": "active",
  "joinedAt": "2025-03-01T10:00:00.000Z",
  "invitedBy": null
}
```

---

### 4. `patients/{patientId}/invites/{inviteId}` — Convite

**Caminho Firestore:** `patients/{patientId}/invites/{inviteId}`
**Entidade Dart:** `Invite`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do convite |
| `code` | `string` | Sim | Código único do convite |
| `patientId` | `string` | Sim | ID do paciente associado |
| `role` | `string` | Sim | Papel atribuído: `admin`, `editor` ou `viewer` |
| `email` | `string` | Sim | E-mail do convidado |
| `createdBy` | `string` | Sim | UID de quem criou o convite |
| `createdAt` | `string` (ISO 8601) | Sim | Data de criação |
| `expiresAt` | `string` (ISO 8601) | Sim | Data de expiração (padrão: 7 dias) |
| `status` | `string` | Sim | Status: `pending`, `accepted` ou `expired` |

**Exemplo:**
```json
{
  "id": "inv_001",
  "code": "ABC123XY",
  "patientId": "pat_001",
  "role": "editor",
  "email": "joao@email.com",
  "createdBy": "abc123",
  "createdAt": "2025-03-01T10:00:00.000Z",
  "expiresAt": "2025-03-08T10:00:00.000Z",
  "status": "pending"
}
```

---

### 5. `patients/{patientId}/plans/health/metrics/{metricType}` — Métrica de Saúde

**Caminho Firestore:** `patients/{patientId}/plans/health/metrics/{metricType}`
**Entidade Dart:** `HealthMetric`

O `{metricType}` é o nome do enum: `bloodPressure`, `heartRate`, `oxygenSaturation`, `temperature`, `glucose`, `weight`, `sleep`, `steps`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `metricType` | `string` | Sim | Tipo da métrica (enum name) |
| `frequency` | `string` | Sim | Frequência (ex: `Diário`, `Semanal`) |
| `scheduledTimes` | `array<string>` | Não | Horários agendados (ex: `["08:00", "20:00"]`) |
| `targetMin` | `number?` | Não | Valor mínimo alvo |
| `targetMax` | `number?` | Não | Valor máximo alvo |
| `remindersEnabled` | `boolean` | Sim | Se lembretes estão ativos |

**Tipos de métricas disponíveis:**

| Tipo | Label | Unidade | Faixa padrão |
|---|---|---|---|
| `bloodPressure` | Pressão Arterial | mmHg | 90–140 |
| `heartRate` | Frequência Cardíaca | bpm | 60–100 |
| `oxygenSaturation` | Saturação O₂ | % | 95–100 |
| `temperature` | Temperatura | °C | 36.0–37.5 |
| `glucose` | Glicemia | mg/dL | 70–140 |
| `weight` | Peso | kg | 40–120 |
| `sleep` | Sono | h | 6–9 |
| `steps` | Passos | — | 3000–10000 |

**Exemplo:**
```json
{
  "metricType": "bloodPressure",
  "frequency": "Diário",
  "scheduledTimes": ["08:00", "20:00"],
  "targetMin": 90,
  "targetMax": 140,
  "remindersEnabled": true
}
```

---

### 6. `patients/{patientId}/logs/health/{logId}` — Registro de Saúde

**Caminho Firestore:** `patients/{patientId}/logs/health/{logId}`
**Entidade Dart:** `HealthLog`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do registro |
| `metricType` | `string` | Sim | Tipo da métrica (enum name) |
| `values` | `map<string, dynamic>` | Sim | Valores medidos (varia por métrica) |
| `measuredAt` | `string` (ISO 8601) | Sim | Data/hora da medição |
| `source` | `string` | Sim | Origem: `manual` ou `integrated` |
| `notes` | `string?` | Não | Observações |
| `attachments` | `array<string>` | Não | URLs de anexos (fotos) |
| `createdBy` | `string` | Sim | UID de quem registrou |
| `createdAt` | `string` (ISO 8601) | Sim | Data de criação do registro |

**Formato do campo `values` por tipo:**

| Métrica | Campos em `values` |
|---|---|
| `bloodPressure` | `{ "systolic": 120, "diastolic": 80 }` |
| Todas as demais | `{ "value": 72 }` |

**Exemplo (pressão arterial):**
```json
{
  "id": "log_001",
  "metricType": "bloodPressure",
  "values": { "systolic": 125, "diastolic": 82 },
  "measuredAt": "2025-03-01T08:30:00.000Z",
  "source": "manual",
  "notes": "Medido em repouso",
  "attachments": [],
  "createdBy": "abc123",
  "createdAt": "2025-03-01T08:35:00.000Z"
}
```

**Exemplo (frequência cardíaca integrada):**
```json
{
  "id": "log_002",
  "metricType": "heartRate",
  "values": { "value": 72 },
  "measuredAt": "2025-03-01T09:00:00.000Z",
  "source": "integrated",
  "notes": null,
  "attachments": [],
  "createdBy": "abc123",
  "createdAt": "2025-03-01T09:00:00.000Z"
}
```

---

### 7. `patients/{patientId}/plans/meds/{medPlanId}` — Item do Plano de Medicamentos

**Caminho Firestore:** `patients/{patientId}/plans/meds/{medPlanId}`
**Entidade Dart:** `MedPlanItem`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do plano |
| `medicationName` | `string` | Sim | Nome do medicamento |
| `activeIngredient` | `string?` | Não | Princípio ativo |
| `form` | `string` | Sim | Forma farmacêutica (Comprimido, Cápsula, Gotas, etc.) |
| `dosage` | `string` | Sim | Dosagem (ex: `500mg`, `10ml`) |
| `frequencyType` | `string` | Sim | Tipo de frequência: `interval` ou `fixed` |
| `intervalHours` | `number?` | Não | Intervalo em horas (quando `frequencyType = interval`) |
| `scheduledTimes` | `array<string>` | Sim | Horários fixos (quando `frequencyType = fixed`) |
| `startDate` | `string` (ISO 8601) | Sim | Data de início |
| `endDate` | `string?` (ISO 8601) | Não | Data de término (null se contínuo) |
| `continuous` | `boolean` | Sim | Se o uso é contínuo |
| `instructions` | `string?` | Não | Instruções (ex: "Tomar em jejum") |
| `notes` | `string?` | Não | Observações adicionais |
| `photoUrl` | `string?` | Não | Foto do medicamento |
| `createdBy` | `string?` | Não | UID de quem criou |
| `createdAt` | `string` (ISO 8601) | Sim | Data de criação |

**Formas farmacêuticas disponíveis:** Comprimido, Cápsula, Gotas, Injeção, Pomada, Xarope, Adesivo, Inalação, Outro.

**Exemplo:**
```json
{
  "id": "med_001",
  "medicationName": "Losartana",
  "activeIngredient": "Losartana Potássica",
  "form": "Comprimido",
  "dosage": "50mg",
  "frequencyType": "fixed",
  "intervalHours": null,
  "scheduledTimes": ["08:00", "20:00"],
  "startDate": "2025-01-15T00:00:00.000Z",
  "endDate": null,
  "continuous": true,
  "instructions": "Tomar com água, longe das refeições",
  "notes": "Prescrito pelo Dr. Carlos",
  "photoUrl": null,
  "createdBy": "abc123",
  "createdAt": "2025-01-15T10:00:00.000Z"
}
```

---

### 8. `patients/{patientId}/logs/meds/{doseEventId}` — Evento de Dose

**Caminho Firestore:** `patients/{patientId}/logs/meds/{doseEventId}`
**Entidade Dart:** `DoseEvent`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do evento |
| `medPlanId` | `string` | Sim | ID do plano de medicamento associado |
| `medicationName` | `string` | Sim | Nome do medicamento (desnormalizado) |
| `status` | `string` | Sim | Status: `pendente`, `tomado`, `atrasado`, `pulado`, `adiado` |
| `scheduledAt` | `string` (ISO 8601) | Sim | Horário agendado |
| `actualAt` | `string?` (ISO 8601) | Não | Horário real de administração |
| `recordedBy` | `string?` | Não | UID de quem registrou |
| `skipReason` | `string?` | Não | Motivo de pular (quando `status = pulado`) |

**Statuses disponíveis:**

| Status | Descrição |
|---|---|
| `pendente` | Aguardando administração |
| `tomado` | Medicamento foi tomado |
| `atrasado` | Horário passou sem registro |
| `pulado` | Cuidador optou por pular |
| `adiado` | Adiado para outro momento |

**Exemplo:**
```json
{
  "id": "dose_001",
  "medPlanId": "med_001",
  "medicationName": "Losartana",
  "status": "tomado",
  "scheduledAt": "2025-03-01T08:00:00.000Z",
  "actualAt": "2025-03-01T08:15:00.000Z",
  "recordedBy": "abc123",
  "skipReason": null
}
```

---

### 9. `patients/{patientId}/logs/activities/{postId}` — Post de Atividade

**Caminho Firestore:** `patients/{patientId}/logs/activities/{postId}`
**Entidade Dart:** `ActivityPost`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do post |
| `category` | `string` | Sim | Categoria (Banho, Alimentação, Fisioterapia, etc.) |
| `text` | `string` | Sim | Texto descritivo |
| `photoUrls` | `array<string>` | Não | URLs de fotos (máx. 5) |
| `audioUrl` | `string?` | Não | URL de áudio (máx. 120s) |
| `eventAt` | `string` (ISO 8601) | Sim | Data/hora do evento |
| `tags` | `array<string>` | Não | Tags opcionais |
| `createdBy` | `string` | Sim | UID do autor |
| `createdByName` | `string` | Sim | Nome do autor (desnormalizado) |
| `createdAt` | `string` (ISO 8601) | Sim | Data de criação |
| `reactions` | `map<string, array<string>>` | Não | Reações (emoji → lista de UIDs) |
| `commentCount` | `number` | Sim | Contador de comentários |

**Categorias disponíveis:** Banho, Alimentação, Fisioterapia, Visita médica, Visita familiar, Exercício, Outro.

**Exemplo:**
```json
{
  "id": "post_001",
  "category": "Alimentação",
  "text": "Almoço bem aceito hoje! Comeu arroz, feijão e frango.",
  "photoUrls": ["https://storage.googleapis.com/.../photo1.jpg"],
  "audioUrl": null,
  "eventAt": "2025-03-01T12:30:00.000Z",
  "tags": ["boa aceitação"],
  "createdBy": "abc123",
  "createdByName": "Maria Silva",
  "createdAt": "2025-03-01T12:45:00.000Z",
  "reactions": {
    "❤️": ["def456", "ghi789"],
    "👍": ["abc123"]
  },
  "commentCount": 2
}
```

---

### 10. `patients/{patientId}/logs/activities/{postId}/comments/{commentId}` — Comentário

**Caminho Firestore:** `patients/{patientId}/logs/activities/{postId}/comments/{commentId}`
**Entidade Dart:** `ActivityComment`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do comentário |
| `postId` | `string` | Sim | ID do post pai |
| `text` | `string` | Sim | Texto do comentário |
| `createdBy` | `string` | Sim | UID do autor |
| `createdByName` | `string` | Sim | Nome do autor (desnormalizado) |
| `createdAt` | `string` (ISO 8601) | Sim | Data de criação |

**Exemplo:**
```json
{
  "id": "cmt_001",
  "postId": "post_001",
  "text": "Que ótimo! Ele está melhorando bastante.",
  "createdBy": "def456",
  "createdByName": "João Silva",
  "createdAt": "2025-03-01T13:00:00.000Z"
}
```

---

### 11. `medCatalog/{medicationId}` — Catálogo de Medicamentos (Global)

**Caminho Firestore:** `medCatalog/{medicationId}`
**Entidade Dart:** `MedicationCatalogItem`

Coleção de referência global, somente leitura para clientes. Preenchida via seed/admin.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `string` | Sim | ID do medicamento |
| `name` | `string` | Sim | Nome comercial |
| `activeIngredient` | `string?` | Não | Princípio ativo |
| `presentations` | `array<string>` | Não | Apresentações disponíveis (ex: `["50mg", "100mg"]`) |
| `isGeneric` | `boolean` | Sim | Se é genérico |

**Exemplo:**
```json
{
  "id": "cat_001",
  "name": "Losartana Potássica",
  "activeIngredient": "Losartana",
  "presentations": ["25mg", "50mg", "100mg"],
  "isGeneric": true
}
```

---

## Notas sobre Serialização

- Todas as datas são armazenadas como **strings ISO 8601** (`DateTime.toIso8601String()`)
- O Firestore armazena como string; a conversão de/para `DateTime` ocorre nos métodos `toMap()` / `fromMap()` das entidades
- Campos desnormalizados (como `medicationName` em `DoseEvent` e `createdByName` em `ActivityPost`) evitam leituras adicionais na exibição de listas
