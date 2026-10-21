# Treinamento Salesforce Júnior — Jornada Comercial (US-01 a US-05)

Fluxo: Formulário LWC → validação CPF/CNPJ → ViaCEP → Lead → qualificação → conversão (Account/Contact) → Opportunity → Order.

## 1. Preparação (uma vez só, no PC)
1. Crie uma org gratuita: https://developer.salesforce.com/signup
2. Instale: VS Code + extensão "Salesforce Extension Pack" + Salesforce CLI (`sf`).
3. Na org, em **Setup**, faça manualmente (o deploy não cobre isso):
   - **Lead Status** (`Novo`, `Qualificado` e `Convertido`, este último marcado como *Converted*) e **Lead Source** (`Treinamento LWC`) são entregues pelos metadados em `force-app`; confira esses valores se já existirem configurações personalizadas na org.
   - **Order Settings**: ative *Enable Orders* (e *Enable Reduction Orders* pode ficar desligado).
   - **State and Country/Territory Picklists**: pode ficar ligado ou desligado, pois o código detecta via `TrainingAddressSupport`; se ligado, confira se Brasil e os estados estão ativos.
   - **Named Credential `ViaCEP`**: Setup > Named Credentials. Nome/Label: `ViaCEP`, URL: `https://viacep.com.br/ws`, sem autenticação.
     - Interface nova: crie primeiro uma *External Credential* com protocolo **No Authentication**, depois a Named Credential apontando para ela.
     - Se aparecer "New Legacy", pode usar também (Authentication Protocol = No Authentication).
     - Importante: o nome tem de ser exatamente `ViaCEP`, pois o código usa `callout:ViaCEP/...`.

## 2. Deploy
```
sf org login web --alias treino
sf project deploy start --target-org treino
sf org assign permset --name Treinamento_Salesforce --target-org treino
sf apex run test --test-level RunLocalTests --wait 10 --result-format human --target-org treino
```

## 3. Ligar as telas (cliques, uma vez)
- **Formulário (US-01/02):** App Launcher > Lightning App Builder > New > App Page > arraste `Cadastro de Lead (Treinamento)` > Activate (crie uma aba/app).
- **Converter (US-03):** Object Manager > Lead > Page Layouts > *Mobile & Lightning Actions* > arraste **Converter em Cliente**.
- **Oportunidade (US-04/05):** Object Manager > Account > Page Layouts > *Mobile & Lightning Actions* > arraste **Criar Oportunidade**.
- (Opcional) Mapeamento padrão Lead→Account na UI: Lead > Fields & Relationships > *Map Lead Fields*. O código já copia os campos, então não é obrigatório.

## 4. Roteiro de demonstração
1. Abra o formulário, informe CPF 529.982.247-25, CEP 01001-000 → endereço preenche → salve.
2. O Lead nasce com Score 100, Apto = true e Status Qualificado.
3. No Lead, use **Converter em Cliente** → vai para a Account (com campos customizados).
4. Na Account, **Criar Oportunidade** → toast com link; veja o Order (Draft) relacionado.

## 5. O que cada peça faz
| Peça | Papel |
|---|---|
| `trainingLeadForm` | UX, máscaras, validação preliminar, chama o Apex |
| `TrainingLeadController` | Entrada `@AuraEnabled`; só delega e converte erros |
| `TrainingLeadService` | Obrigatórios, CPF/CNPJ, duplicidade, monta o Lead, DML |
| `DocumentValidator` | Sanitização + dígitos verificadores + sequências repetidas |
| `ViaCepService` / `ViaCepDTO` | Callout via Named Credential; mensagens distintas (não achou x fora do ar) |
| `TrainingLeadTrigger` → `Handler` → `Helper` | Trigger mínima; Helper calcula score (40/30/15/15) e flags |
| `trainingConvertLead` + `TrainingLeadConversionController/Service` | Revalida elegibilidade no servidor e usa `Database.convertLead` sem Opportunity |
| `trainingCreateOpportunity` + `TrainingOpportunityController/Service` | Modal, validação, cria Opportunity ligada à Account |
| `TrainingOrderService` | Cria o Order (Draft, hoje) ligado à Opportunity |
| `TrainingErrors` / `TrainingException` | Só mensagens de negócio chegam ao usuário; erro técnico vai para o log |

Decisões importantes:
- O servidor reconsulta o ViaCEP ao criar o Lead e só marca `EnderecoValidado__c` se cidade/UF baterem. Não confiamos em flag vinda do navegador. Se o ViaCEP estiver fora, o Lead é criado sem endereço validado (score 70).
- Com a trigger ativa, um Lead completo já nasce `Qualificado` (o service grava `Novo`, a trigger promove).
- A checagem de duplicidade roda em `without sharing` para enxergar duplicados que o usuário não tem permissão de ver.
- Opportunity + Order usam `Savepoint`/`Database.rollback`. O teste `orderFailureRollsBackOpportunity` prova o rollback.

## 6. Respostas para o Code Review
1. **Só JS não basta:** o JS roda no navegador do usuário e pode ser contornado/alterado. Só o servidor é confiável.
2. **Outro consumidor chamando o Apex direto:** pularia a validação do LWC; por isso as regras críticas estão no Service, que todos os caminhos usam.
3. **Endpoint hardcoded:** muda por ambiente (sandbox/produção), precisa de deploy para alterar e exige Remote Site. Named Credential centraliza e é configurável sem código.
4. **Teste com ViaCEP real:** o Apex nem permite callout real em teste; e seria instável (internet, limite de uso, dados mudam). Por isso `HttpCalloutMock`.
5. **Controller × Service × Helper:** Controller = porta de entrada (parâmetros, erros). Service = regra de negócio e transação. Helper = lógica pura/reutilizável (ex.: score) sem acesso a DML.
6. **Trigger enxuta:** facilita teste, evita lógica duplicada/ordem de execução confusa e permite reaproveitar a regra fora da trigger.
7/8. **Order falha depois da Opportunity:** sem controle, a Opportunity ficaria órfã. Com `Savepoint` + `rollback`, as duas viram uma operação só.
9. **Detalhes técnicos:** `TrainingErrors.wrap` devolve só mensagem de negócio ou uma genérica; stack trace vai para `System.debug`.
10. **Concorrência (mesmo CPF ao mesmo tempo):** a checagem por SELECT tem janela de corrida. Soluções: campo único/External Id no banco, ou bloquear um registro de "lock" com `FOR UPDATE` antes de checar e inserir. Neste treinamento ficou documentado como melhoria.

## 7. Limitações / melhorias
- Segurança: use `Security.stripInaccessible` ou `WITH USER_MODE` se quiser reforçar CRUD/FLS.
- Nível 2 opcional (Product2, Pricebook, itens) não foi implementado.
