# Treinamento Salesforce — Jornada Comercial

Projeto de treinamento Salesforce (SFDX) que implementa a jornada comercial das histórias US-01 a US-05:

Formulário LWC → validação de CPF/CNPJ → consulta ViaCEP → Lead → qualificação → conversão (Account/Contact) → Opportunity → Order.

## Estrutura

- `force-app/main/default/lwc` — componentes `trainingLeadForm`, `trainingConvertLead` e `trainingCreateOpportunity`
- `force-app/main/default/classes` e `triggers` — lógica Apex e testes
- `force-app/main/default/objects` — campos customizados (Lead, Account, Opportunity)
- `force-app/main/default/namedCredentials` — integração com o ViaCEP
- `force-app/main/default/permissionsets` — permission set `Treinamento_Salesforce`
- `docs/LEIA-ME.md` — guia completo de preparação da org, ligação das telas e roteiro de demonstração

## Início rápido

Pré-requisitos: org Salesforce (Developer Edition), Salesforce CLI (`sf`) e VS Code com o Salesforce Extension Pack.

```
sf org login web --alias treino
sf project deploy start --target-org treino
sf org assign permset --name Treinamento_Salesforce --target-org treino
sf apex run test --test-level RunLocalTests --wait 10 --result-format human --target-org treino
```

Antes do deploy, configure na org (Order Settings, Named Credential `ViaCEP`, etc.) conforme o [guia completo](docs/LEIA-ME.md).

## Nível 2 - Produtos e Pricebook

O desafio opcional foi implementado sem quebrar as histórias US-01 a US-05:

- Modal **Criar Oportunidade** com várias linhas de produto (de 1 a 20) e total geral calculado.
- Criação de `OpportunityLineItem` e `OrderItem` a partir dos produtos negociados; o preço vem sempre da `PricebookEntry`, no servidor.
- Validação de Pricebook entre Opportunity e Order.
- Rollback total: se qualquer etapa falhar, nada é salvo.

Pré-requisitos na org:

- Standard Price Book **ativa** e produtos ativos com `PricebookEntry`.
- Para criar produtos de teste, rode:

```
sf apex run --file scripts/apex/seed-products.apex --target-org treino
```

Detalhes na seção "Nível 2" de [docs/LEIA-ME.md](docs/LEIA-ME.md).
