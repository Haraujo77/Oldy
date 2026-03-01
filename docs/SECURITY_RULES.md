# Regras de Segurança — Firestore & Storage

## Visão Geral

O Oldy implementa um modelo de controle de acesso baseado em papéis (**RBAC — Role-Based Access Control**) para proteger os dados dos pacientes. Cada membro associado a um paciente possui um papel (`admin`, `editor` ou `viewer`) que determina suas permissões.

---

## Modelo RBAC

### Papéis e Permissões

| Ação | Admin | Editor | Viewer |
|---|:---:|:---:|:---:|
| **Ler** dados do paciente | ✅ | ✅ | ✅ |
| **Criar** registros (saúde, doses, atividades) | ✅ | ✅ | ❌ |
| **Editar** registros existentes | ✅ | ✅ | ❌ |
| **Excluir** registros | ✅ | ❌ | ❌ |
| **Gerenciar** planos (saúde, medicamentos) | ✅ | ❌ | ❌ |
| **Gerenciar** membros e convites | ✅ | ❌ | ❌ |
| **Editar** dados do paciente | ✅ | ❌ | ❌ |
| **Excluir** paciente | ✅ | ❌ | ❌ |
| **Comentar** em posts | ✅ | ✅ | ✅ |
| **Excluir** próprios comentários | ✅ | ✅ | ✅ |
| **Excluir** comentários de outros | ✅ | ❌ | ❌ |

### Como o papel é determinado

O papel de cada usuário é armazenado na subcoleção `members` do paciente:

```
patients/{patientId}/members/{userId} → { role: "admin" | "editor" | "viewer" }
```

Quem cria o paciente é automaticamente adicionado como `admin`.

---

## Firestore Rules

### Funções Auxiliares

```javascript
function isAuthenticated() {
  return request.auth != null;
}
```
Verifica se o usuário está autenticado no Firebase Auth.

```javascript
function isOwner(userId) {
  return request.auth.uid == userId;
}
```
Verifica se o UID do requisitante é igual ao `userId` passado.

```javascript
function memberRole(patientId) {
  return get(/databases/$(database)/documents/patients/$(patientId)/members/$(request.auth.uid)).data.role;
}
```
Busca o papel do usuário autenticado na subcoleção `members` do paciente. Essa função faz uma leitura de documento (conta no limite de 10 leituras por regra).

```javascript
function isMember(patientId) {
  return isAuthenticated() &&
    exists(/databases/$(database)/documents/patients/$(patientId)/members/$(request.auth.uid));
}
```
Verifica se o usuário autenticado é membro do paciente (existe um documento na subcoleção `members`).

```javascript
function isAdmin(patientId) {
  return isMember(patientId) && memberRole(patientId) == 'admin';
}
```
Verifica se o usuário é membro **e** tem papel `admin`.

```javascript
function isEditor(patientId) {
  return isMember(patientId) && memberRole(patientId) in ['admin', 'editor'];
}
```
Verifica se o usuário é membro **e** tem papel `admin` ou `editor`. Note que `admin` é incluído — admins herdam todas as permissões de editor.

---

### Regras por Coleção

#### `users/{userId}` — Perfil do Usuário

```
allow read:   if isAuthenticated();          // Qualquer usuário logado pode ler perfis
allow create: if isOwner(userId);            // Só o próprio usuário pode criar seu perfil
allow update: if isOwner(userId);            // Só o próprio usuário pode editar seu perfil
allow delete: if false;                      // Exclusão de perfil não é permitida
```

**Justificativa:** Perfis são públicos para leitura entre usuários autenticados (necessário para exibir nomes em listas de membros), mas apenas o dono pode modificar seus dados.

#### `patients/{patientId}` — Paciente

```
allow read:   if isMember(patientId);        // Apenas membros podem ver dados do paciente
allow create: if isAuthenticated();           // Qualquer usuário logado pode criar um paciente
allow update: if isAdmin(patientId);          // Apenas admins podem editar
allow delete: if isAdmin(patientId);          // Apenas admins podem excluir
```

#### `patients/{patientId}/members/{memberId}` — Membros

```
allow read:  if isMember(patientId);          // Todos os membros veem a lista de membros
allow write: if isAdmin(patientId);           // Apenas admins gerenciam membros
```

#### `patients/{patientId}/plans/health/metrics/{metricType}` — Plano de Saúde

```
allow read:  if isMember(patientId);          // Todos os membros veem o plano
allow write: if isAdmin(patientId);           // Apenas admins configuram métricas
```

#### `patients/{patientId}/plans/meds/{medPlanId}` — Plano de Medicamentos

```
allow read:  if isMember(patientId);          // Todos os membros veem os medicamentos
allow write: if isAdmin(patientId);           // Apenas admins gerenciam planos
```

#### `patients/{patientId}/logs/health/{logId}` — Registros de Saúde

```
allow read:   if isMember(patientId);         // Todos os membros podem ler
allow create: if isEditor(patientId);         // Admins e editors podem criar
allow update: if isEditor(patientId);         // Admins e editors podem editar
allow delete: if isAdmin(patientId);          // Apenas admins podem excluir
```

#### `patients/{patientId}/logs/meds/{doseEventId}` — Eventos de Dose

```
allow read:   if isMember(patientId);         // Todos os membros podem ler
allow create: if isEditor(patientId);         // Admins e editors podem registrar doses
allow update: if isEditor(patientId);         // Admins e editors podem atualizar status
allow delete: if isAdmin(patientId);          // Apenas admins podem excluir
```

#### `patients/{patientId}/logs/activities/{postId}` — Posts de Atividade

```
allow read:   if isMember(patientId);         // Todos os membros podem ler
allow create: if isEditor(patientId);         // Admins e editors podem criar posts
allow update: if isEditor(patientId);         // Admins e editors podem editar posts
allow delete: if isAdmin(patientId);          // Apenas admins podem excluir posts
```

#### `patients/{patientId}/logs/activities/{postId}/comments/{commentId}` — Comentários

```
allow read:   if isMember(patientId);         // Todos os membros podem ler
allow create: if isMember(patientId);         // Qualquer membro pode comentar (inclusive viewer)
allow update: if isAuthenticated() &&
              request.auth.uid == resource.data.createdBy;  // Apenas o autor pode editar
allow delete: if isAdmin(patientId) ||
              (isAuthenticated() && request.auth.uid == resource.data.createdBy);
                                               // Admin ou o próprio autor pode excluir
```

**Nota:** Comentários são a exceção — `viewer` pode criar e excluir seus próprios comentários, diferente das outras operações de escrita.

#### `patients/{patientId}/invites/{inviteId}` — Convites

```
allow read:   if isMember(patientId) ||
              resource.data.email == request.auth.token.email;
                                               // Membros OU o convidado podem ler
allow create: if isAdmin(patientId);           // Apenas admins criam convites
allow update: if isAdmin(patientId) ||
              resource.data.email == request.auth.token.email;
                                               // Admin ou o convidado podem atualizar (aceitar)
allow delete: if isAdmin(patientId);           // Apenas admins podem cancelar convites
```

**Justificativa:** O convidado precisa ler o convite (para verificar o código) e atualizá-lo (para aceitar), mesmo sem ser membro ainda do paciente.

#### `medCatalog/{medicationId}` — Catálogo Global

```
allow read:  if isAuthenticated();            // Qualquer usuário logado pode buscar
allow write: if false;                         // Nenhum cliente pode escrever (seed via admin/script)
```

---

## Storage Rules

### `patients/{patientId}/{allPaths=**}` — Arquivos do Paciente

```
allow read:  if request.auth != null &&
             firestore.exists(.../patients/{patientId}/members/{auth.uid});
```
**Leitura:** Apenas membros autenticados do paciente podem acessar arquivos (fotos, áudios).

```
allow write: if request.auth != null &&
             firestore.get(.../patients/{patientId}/members/{auth.uid}).data.role in ['admin', 'editor'] &&
             request.resource.size < 10 * 1024 * 1024;
```
**Escrita:** Apenas admins e editors podem fazer upload. Limite de **10 MB** por arquivo.

### `users/{userId}/{allPaths=**}` — Arquivos do Usuário

```
allow read:  if request.auth != null;
```
**Leitura:** Qualquer usuário autenticado pode ver fotos de perfil de outros usuários.

```
allow write: if request.auth != null &&
             request.auth.uid == userId &&
             request.resource.size < 5 * 1024 * 1024;
```
**Escrita:** Apenas o próprio usuário pode fazer upload para sua pasta. Limite de **5 MB** por arquivo.

---

## Limites de Tamanho de Arquivo

| Caminho | Limite |
|---|---|
| `patients/{patientId}/**` | 10 MB |
| `users/{userId}/**` | 5 MB |

---

## Considerações de Segurança

1. **Nenhuma exclusão de perfil:** Contas de usuário não podem ser excluídas via client-side para evitar documentos órfãos
2. **Leituras cross-document:** As funções `isMember`, `isAdmin` e `isEditor` fazem leituras adicionais (contam no limite de 10 `get()` por regra)
3. **Dados desnormalizados:** Nomes de usuário são replicados em posts e comentários; uma atualização de nome não atualiza retroativamente esses campos
4. **Convites:** O e-mail do convite é verificado contra `request.auth.token.email`, garantindo que apenas o destinatário pode aceitar
5. **Catálogo somente leitura:** O catálogo de medicamentos é protegido contra escrita no client-side — deve ser populado via Firebase Console, Cloud Functions ou scripts de seed
