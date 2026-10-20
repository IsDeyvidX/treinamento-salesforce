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
