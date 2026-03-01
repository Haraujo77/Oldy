# Checklist de Qualidade (QA)

Checklist para testes manuais e automatizados do Oldy. Cada seção cobre uma área crítica do app.

---

## 1. Permissões (RBAC)

### Admin

- [ ] Pode criar, editar e excluir paciente
- [ ] Pode adicionar/remover/alterar papel de membros
- [ ] Pode criar e cancelar convites
- [ ] Pode configurar plano de saúde (adicionar/remover métricas)
- [ ] Pode criar/editar/excluir planos de medicamento
- [ ] Pode criar/editar/excluir registros de saúde
- [ ] Pode registrar/atualizar eventos de dose
- [ ] Pode criar/editar/excluir posts de atividade
- [ ] Pode comentar em posts
- [ ] Pode excluir qualquer comentário
- [ ] Pode fazer upload de fotos e áudios

### Editor

- [ ] Pode ler todos os dados do paciente
- [ ] **Não pode** editar dados do paciente
- [ ] **Não pode** gerenciar membros ou convites
- [ ] **Não pode** configurar planos (saúde/medicamentos)
- [ ] Pode criar e editar registros de saúde
- [ ] **Não pode** excluir registros de saúde
- [ ] Pode registrar/atualizar eventos de dose
- [ ] **Não pode** excluir eventos de dose
- [ ] Pode criar e editar posts de atividade
- [ ] **Não pode** excluir posts de atividade
- [ ] Pode comentar em posts
- [ ] Pode excluir apenas seus próprios comentários
- [ ] Pode fazer upload de fotos e áudios

### Viewer

- [ ] Pode ler todos os dados do paciente
- [ ] **Não pode** criar/editar/excluir registros de saúde
- [ ] **Não pode** registrar eventos de dose
- [ ] **Não pode** criar/editar posts de atividade
- [ ] Pode comentar em posts
- [ ] Pode excluir apenas seus próprios comentários
- [ ] **Não pode** fazer upload de arquivos para o paciente
- [ ] **Não pode** acessar configurações de plano

### Sem Associação

- [ ] Usuário não membro **não pode** ver dados de nenhum paciente
- [ ] Tentativa de acesso retorna erro de permissão
- [ ] Convite é a única forma de entrar em um paciente existente

---

## 2. Comportamento Offline

### Leitura

- [ ] Com conexão, dados carregam em tempo real via stream
- [ ] Sem conexão, dados do cache Firestore são exibidos
- [ ] Indicação visual clara quando operando com dados em cache
- [ ] Navegação entre telas funciona normalmente offline

### Escrita

- [ ] Criar registro de saúde offline → aparece localmente → sincroniza ao reconectar
- [ ] Marcar dose offline → status atualiza localmente → sincroniza ao reconectar
- [ ] Criar post offline → aparece no feed local → sincroniza ao reconectar
- [ ] Comentar offline → aparece localmente → sincroniza ao reconectar

### Reconexão

- [ ] Ao reconectar, dados pendentes são enviados automaticamente
- [ ] Não há duplicação de registros após reconexão
- [ ] Streams reativam e trazem dados atualizados de outros dispositivos

### Edge Cases

- [ ] Conexão intermitente (liga/desliga rápido) não causa crash
- [ ] Upload de mídia falha graciosamente offline (mensagem informativa)
- [ ] Login requer conexão (mensagem clara se offline)

---

## 3. Sincronização de Saúde

### Integração com Health (Apple Health / Google Health Connect)

- [ ] Solicitação de permissão é apresentada ao usuário
- [ ] Após permissão, dados são importados corretamente
- [ ] Dados integrados são marcados com `source: integrated`
- [ ] Dados manuais e integrados coexistem no histórico
- [ ] Gráficos exibem ambas as fontes corretamente

### Tipos de Métricas

- [ ] Pressão arterial (sistólica/diastólica) importa corretamente
- [ ] Frequência cardíaca importa corretamente
- [ ] Saturação O₂ importa corretamente
- [ ] Passos importam corretamente
- [ ] Peso importa corretamente
- [ ] Sono importa corretamente

### Periodicidade

- [ ] Sync respeita intervalo configurado (`healthSyncIntervalHours = 24`)
- [ ] Sync manual disponível para forçar atualização
- [ ] Não duplica dados em syncs consecutivos

---

## 4. Notificações

### Push (Firebase Messaging)

- [ ] Permissão de notificação é solicitada no primeiro uso
- [ ] Token FCM é registrado corretamente
- [ ] Notificação recebida com app em foreground
- [ ] Notificação recebida com app em background
- [ ] Notificação recebida com app fechado
- [ ] Toque na notificação navega para a tela correta

### Locais (flutter_local_notifications)

- [ ] Lembretes de medicamento disparam no horário correto
- [ ] Lembretes de medição de saúde disparam no horário correto
- [ ] Notificação de dose atrasada aparece após timeout
- [ ] Ações na notificação (marcar como tomado) funcionam

### Configurações

- [ ] Usuário pode desativar lembretes por métrica de saúde
- [ ] Lembretes respeitam `remindersEnabled` do `HealthMetric`
- [ ] Desligar notificações no sistema cancela todos os lembretes locais

---

## 5. UI/UX

### Modo Claro e Escuro

- [ ] Tema claro renderiza corretamente em todas as telas
- [ ] Tema escuro renderiza corretamente em todas as telas
- [ ] Troca dinâmica de tema (sistema) funciona sem restart
- [ ] Contraste adequado em ambos os modos (textos legíveis)
- [ ] Ícones e ilustrações adaptam ao tema
- [ ] Bottom navigation bar estiliza corretamente em ambos

### Acessibilidade

- [ ] Tamanhos de fonte respeitam `textScaleFactor` do sistema
- [ ] Todos os botões e ações têm target mínimo de 48x48 dp
- [ ] Labels de acessibilidade em ícones e imagens
- [ ] Navegação por TalkBack/VoiceOver funcional
- [ ] Cores não são o único meio de transmitir informação (faixa alvo com ícone+cor)

### Empty States

- [ ] Nenhum paciente → mensagem + CTA "Criar Paciente"
- [ ] Nenhum membro além do admin → mensagem + CTA "Convidar"
- [ ] Nenhum registro de saúde → mensagem + CTA "Registrar"
- [ ] Nenhum medicamento → mensagem + CTA "Adicionar"
- [ ] Nenhum post de atividade → mensagem + CTA "Criar Post"
- [ ] Nenhum comentário → mensagem incentivando interação

### Loading States

- [ ] Shimmer/skeleton durante carregamento inicial
- [ ] Indicador de loading em ações assíncronas (botões)
- [ ] Pull-to-refresh onde aplicável
- [ ] Sem tela em branco durante transições

### Error States

- [ ] Erro de rede exibe mensagem amigável com retry
- [ ] Erro de permissão exibe mensagem explicativa
- [ ] Erro de validação marca campos em vermelho com mensagem
- [ ] Crash reportado ao Crashlytics automaticamente

### Navegação

- [ ] Bottom navigation mantém estado ao trocar tabs
- [ ] Back button volta para a tela anterior correta
- [ ] Deep links funcionam (rotas diretas)
- [ ] Transições suaves entre telas (NoTransitionPage no shell)

### Responsividade

- [ ] App funciona em telas pequenas (320dp de largura)
- [ ] App funciona em telas grandes (tablets)
- [ ] Orientação fixa em portrait (conforme `SystemChrome`)
- [ ] Safe areas respeitadas (notch, home indicator)

---

## 6. Integridade de Dados

### Consistência

- [ ] Criar paciente gera automaticamente membro admin
- [ ] Aceitar convite cria membro e atualiza status do convite atomicamente
- [ ] `commentCount` é incrementado/decrementado ao adicionar/remover comentários
- [ ] Nome desnormalizado em posts (`createdByName`) corresponde ao perfil
- [ ] Nome desnormalizado em doses (`medicationName`) corresponde ao plano

### Validação

- [ ] E-mail validado no formato correto (login/registro)
- [ ] Senha com requisitos mínimos (registro)
- [ ] Campos obrigatórios não podem ser vazios (formulários)
- [ ] Data de nascimento não pode ser no futuro
- [ ] Data de término do medicamento não pode ser antes do início
- [ ] Convite expira após 7 dias
- [ ] Convite não pode ser aceito por e-mail diferente

### Limites

- [ ] Máximo 5 fotos por post (`AppConstants.maxPhotosPerPost`)
- [ ] Máximo 120s de áudio por post (`AppConstants.maxAudioDurationSeconds`)
- [ ] Upload de arquivo do paciente ≤ 10 MB
- [ ] Upload de arquivo do usuário ≤ 5 MB
- [ ] Paginação de histórico funciona (`historyPageSize = 10`)

### Exclusão

- [ ] Excluir paciente remove acesso de todos os membros
- [ ] Excluir post não deixa comentários órfãos
- [ ] Remover membro revoga acesso imediatamente
- [ ] Perfil de usuário não pode ser excluído (conforme regra)

---

## 7. Performance

- [ ] Lista de pacientes carrega em < 2s
- [ ] Feed de atividades com 50+ posts não trava
- [ ] Gráficos de saúde renderizam fluidamente com 100+ pontos
- [ ] Scroll suave em todas as listas
- [ ] Imagens em cache (`cached_network_image`) não recarregam
- [ ] Não há memory leaks em navegação repetida entre telas
