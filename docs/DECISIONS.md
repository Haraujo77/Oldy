# Decisões Técnicas e Trade-offs

Documento que registra as decisões arquiteturais significativas do projeto Oldy, incluindo alternativas consideradas e justificativas.

---

## 1. Riverpod em vez de Bloc

**Decisão:** Usar `flutter_riverpod` como gerenciamento de estado e injeção de dependências.

**Alternativas consideradas:** Bloc/Cubit, Provider, GetX.

**Justificativas:**

- **Compile-safe DI:** Riverpod resolve dependências em tempo de compilação, sem dependência do `BuildContext` para acessar providers. Isso elimina erros comuns de "provider not found" em runtime
- **Reatividade declarativa:** `StreamProvider` e `FutureProvider` se integram naturalmente com Streams do Firestore, sem necessidade de gerenciar subscriptions manualmente
- **Family providers:** `StreamProvider.family` permite parametrizar providers (ex: `medPlanProvider(patientId)`) de forma elegante, algo que com Bloc exigiria factories manuais
- **Menos boilerplate:** Não há necessidade de classes Event/State separadas para cada feature. `StateNotifier` cobre casos complexos, enquanto `StateProvider` lida com estado simples
- **Testing:** Providers podem ser facilmente sobrescritos em testes via `ProviderScope.overrides`
- **Auto-dispose:** Providers podem liberar recursos automaticamente quando não há mais listeners

**Trade-off:** Curva de aprendizado diferente do padrão Bloc que é mais estabelecido na comunidade Flutter.

---

## 2. Firebase em vez de Supabase

**Decisão:** Usar Firebase (Auth, Firestore, Storage, Messaging, Crashlytics, Analytics) como backend.

**Alternativas consideradas:** Supabase, backend customizado (Node.js + PostgreSQL).

**Justificativas:**

- **Sync em tempo real:** Firestore oferece sincronização em tempo real nativa via `snapshots()`, essencial para o uso colaborativo (múltiplos cuidadores atualizando dados do mesmo paciente)
- **Offline-first:** Firestore possui cache offline embutido — o app funciona sem internet e sincroniza automaticamente quando reconecta
- **Security Rules:** Regras declarativas no server-side que validam acesso sem necessidade de backend intermediário
- **Ecossistema integrado:** Auth, Storage, Messaging, Crashlytics e Analytics compartilham o mesmo SDK, simplificando a integração
- **Escalabilidade automática:** Sem necessidade de gerenciar servidores ou infraestrutura
- **Flutter SDK maduro:** `cloud_firestore`, `firebase_auth` e demais pacotes têm excelente suporte para Flutter

**Trade-offs:**
- Vendor lock-in no ecossistema Google
- Custos podem escalar com leituras/escritas em produção
- Consultas menos flexíveis que SQL (sem JOINs, queries limitadas)
- Supabase ofereceria SQL completo e auto-hosting, mas sem a mesma maturidade offline-first

---

## 3. Estratégia Offline (Firestore Cache + Pending Writes)

**Decisão:** Utilizar o cache offline nativo do Firestore como estratégia principal de funcionamento offline.

**Implementação:**

- O Firestore habilita cache offline por padrão no Flutter
- Operações de leitura usam cache local quando offline
- Operações de escrita ficam em fila (`pending writes`) e são sincronizadas quando a conexão é restaurada
- Streams (`snapshots()`) incluem dados do cache com flag `metadata.isFromCache`

**Justificativas:**

- **Zero código adicional:** Não há necessidade de implementar camada de cache separada (SQLite, Hive, etc.)
- **Consistência automática:** O Firestore resolve conflitos de merge automaticamente
- **Adequado ao caso de uso:** Cuidadores de idosos frequentemente estão em locais com conexão instável (hospitais, áreas rurais)

**Trade-offs:**
- Sem controle granular sobre o que é cached (Firestore gerencia automaticamente)
- Queries complexas podem não funcionar 100% offline se os dados necessários não estiverem em cache
- Tamanho do cache pode crescer significativamente com muitos pacientes
- Não há indicação visual nativa de "dados pendentes" — precisa ser implementada manualmente

---

## 4. Eventos de Dose como Log Append-Only

**Decisão:** Modelar `DoseEvent` como um log append-only (somente inserção) em vez de atualizar o status em um documento fixo.

**Caminho:** `patients/{patientId}/logs/meds/{doseEventId}`

**Implementação:**

- Cada dose agendada gera um documento separado com `status: pendente`
- Ao marcar como tomado/pulado/adiado, o status é atualizado no mesmo documento
- Novos dias geram novos documentos via `generateTodayDoses()`
- Nome do medicamento é desnormalizado no evento para exibição sem leitura adicional

**Justificativas:**

- **Auditoria completa:** Histórico completo de cada dose, quando foi tomada, por quem, se foi pulada e por quê
- **Queries temporais:** Fácil buscar "todas as doses de hoje", "doses atrasadas da semana", etc.
- **Sem conflitos de escrita:** Múltiplos cuidadores podem registrar doses diferentes simultaneamente sem conflito
- **Analytics:** Dados prontos para análise de aderência ao tratamento

**Trade-offs:**
- Mais documentos no Firestore (mais leituras/escritas)
- Necessidade de gerar doses diárias (função `generateTodayDoses`)
- Desnormalização do nome do medicamento (pode ficar desatualizado se o nome mudar)

---

## 5. Integração de Saúde via Pacote `health` Unificado

**Decisão:** Usar o pacote `health` (v13.x) para integração com Apple Health / Google Health Connect.

**Alternativa considerada:** Pacotes específicos por plataforma (`health_kit_reporter`, `google_fit`).

**Justificativas:**

- **API unificada:** Um único pacote que abstrai as diferenças entre plataformas
- **Tipos padronizados:** Tipos de dados como `BLOOD_PRESSURE_SYSTOLIC`, `HEART_RATE`, `BLOOD_OXYGEN` mapeiam diretamente para nosso enum `HealthMetricType`
- **Manutenção simplificada:** Um pacote para manter em vez de dois
- **Flutter-native:** Pacote mantido ativamente com bom suporte para Flutter 3.x

**Implementação:**

- Dados integrados são salvos com `source: integrated` no `HealthLog`
- Sync periódico configurável (`AppConstants.healthSyncIntervalHours = 24`)
- Dados manuais e integrados coexistem na mesma coleção, diferenciados pelo campo `source`

**Trade-offs:**
- Dependência de um pacote terceiro que pode ter breaking changes
- Nem todas as métricas estão disponíveis em ambas as plataformas
- Requer permissões de saúde do sistema (UX de consentimento)

---

## 6. Comentários como Subcoleção (em vez de Array Embutido)

**Decisão:** Armazenar comentários como subcoleção `comments/{commentId}` dentro do post de atividade.

**Alternativa considerada:** Array de objetos embutido no documento do post.

**Justificativas:**

- **Escalabilidade:** Sem limite prático de comentários (documentos Firestore têm limite de 1 MB)
- **Queries independentes:** Possível buscar/paginar comentários sem carregar o post inteiro
- **Security rules granulares:** Regras diferentes para o post e para comentários (qualquer membro pode comentar, mas apenas editor+ pode criar posts)
- **Real-time listeners:** Stream separado para comentários — novos comentários aparecem sem recarregar o post

**Trade-offs:**
- Mais leituras no Firestore (uma leitura para o post + uma query para comentários)
- `commentCount` precisa ser mantido manualmente (counter desnormalizado no post)
- Exclusão do post não exclui automaticamente os comentários (precisa de batch delete ou Cloud Function)

---

## 7. Abordagem de Seed para Catálogo de Medicamentos

**Decisão:** Manter um catálogo global de medicamentos (`medCatalog`) populado via seed/script, somente leitura para clientes.

**Alternativa considerada:** Busca em API externa (ANVISA, OpenFDA), input livre do usuário.

**Justificativas:**

- **Disponibilidade offline:** Catálogo está no Firestore, funciona offline via cache
- **Dados controlados:** Garantia de qualidade e consistência dos dados (nomes, princípios ativos, apresentações)
- **Performance:** Busca rápida via query Firestore, sem latência de API externa
- **Simplicidade:** Não depende de serviço externo que pode estar indisponível ou mudar API

**Implementação:**

- Coleção `medCatalog/{medicationId}` com dados de medicamentos comuns para idosos
- Regra de segurança `allow write: if false` — nenhum cliente pode modificar
- Busca por nome via `catalogSearchProvider(query)` usando query Firestore
- Usuário pode sempre adicionar medicamento manualmente (input livre) caso não esteja no catálogo

**Trade-offs:**
- Catálogo precisa ser atualizado manualmente (novos medicamentos, correções)
- Não cobre 100% dos medicamentos existentes
- Sem informações dinâmicas (preço, disponibilidade, interações medicamentosas)

---

## 8. Outras Decisões Menores

### go_router com ShellRoute

- **Por quê:** Navegação declarativa com suporte nativo a bottom navigation via `ShellRoute`, deep linking e redirect guards integrados com Riverpod
- **Trade-off:** API mais verbosa que Navigator 2.0 imperativo

### Material 3 com ThemeMode.system

- **Por quê:** Design moderno, acessível, com dark mode automático baseado na preferência do sistema
- **Trade-off:** Componentes Material 3 podem ter comportamento visual diferente entre versões do Flutter

### Datas como ISO 8601 String

- **Por quê:** Serialização universal, legível, compatível com todos os SDKs. Evita problemas com Timestamp do Firestore em diferentes plataformas
- **Trade-off:** Não é possível usar `orderBy` nativo do Firestore em campos timestamp (precisa converter ou usar Timestamp)

### Internacionalização pt-BR/en-US

- **Por quê:** Mercado primário é Brasil, mas preparado para expansão
- **Trade-off:** Manutenção de dois arquivos de tradução
