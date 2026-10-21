/** Regras de negócio da US-01: validar, checar duplicidade e criar o Lead. */
public with sharing class TrainingLeadService {
    public static final String LEAD_SOURCE = 'Treinamento LWC';
    public static final String STATUS_NEW = 'Novo';

    public static Id createLead(TrainingLeadRequest r) {
        if (r == null) {
            throw new TrainingException('Preencha todos os campos obrigatórios.');
        }
        validateRequired(r);

        String doc = DocumentValidator.sanitize(r.documento);
        String cep = DocumentValidator.sanitize(r.cep);

        if (r.tipoPessoa != DocumentValidator.CPF && r.tipoPessoa != DocumentValidator.CNPJ) {
            throw new TrainingException('Tipo de pessoa inválido.');
        }
        if (!DocumentValidator.isValid(r.tipoPessoa, doc)) {
            throw new TrainingException(r.tipoPessoa + ' inválido.');
        }
        if (cep.length() != 8) {
            throw new TrainingException(ViaCepService.MSG_INVALID);
        }
        if (new DuplicateChecker().exists(doc)) {
            throw new TrainingException('Já existe um Lead ou Cliente cadastrado com este documento.');
        }

        Lead l = new Lead(
            FirstName = r.firstName.trim(),
            LastName = r.lastName.trim(),
            Company = (r.firstName.trim() + ' ' + r.lastName.trim()),
            Email = r.email.trim(),
            Phone = r.telefone.trim(),
            TipoDocumento__c = r.tipoPessoa,
            Documento__c = doc,
            PostalCode = cep,
            Street = r.logradouro.trim(),
            NumeroEndereco__c = r.numero.trim(),
            Bairro__c = r.bairro.trim(),
            City = r.cidade.trim(),
            Complemento__c = r.complemento,
            LeadSource = LEAD_SOURCE,
            Status = STATUS_NEW,
            EnderecoValidado__c = isAddressConfirmed(cep, r)
        );
        TrainingAddressSupport.applyLeadState(l, r.uf);

        try {
            insert l;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            throw new TrainingException('Não foi possível salvar o Lead. Verifique os dados informados (ex.: e-mail).');
        }
        return l.Id;
    }

    private static void validateRequired(TrainingLeadRequest r) {
        Map<String, String> required = new Map<String, String>{
            'Nome' => r.firstName,
            'Sobrenome' => r.lastName,
            'E-mail' => r.email,
            'Telefone' => r.telefone,
            'Tipo de pessoa' => r.tipoPessoa,
            'Documento' => r.documento,
            'CEP' => r.cep,
            'Logradouro' => r.logradouro,
            'Numero' => r.numero,
            'Bairro' => r.bairro,
            'Cidade' => r.cidade,
            'UF' => r.uf
        };
        List<String> missing = new List<String>();
        for (String label : required.keySet()) {
            if (String.isBlank(required.get(label))) {
                missing.add(label);
            }
        }
        if (!missing.isEmpty()) {
            throw new TrainingException('Preencha os campos obrigatorios: ' + String.join(missing, ', ') + '.');
        }
    }

    /** O servidor reconfirma o CEP no ViaCEP: não confiamos em flag vinda do navegador. */
    private static Boolean isAddressConfirmed(String cep, TrainingLeadRequest r) {
        try {
            ViaCepDTO d = ViaCepService.lookup(cep);
            return String.isNotBlank(d.cidade) && d.cidade.equalsIgnoreCase(r.cidade.trim())
                && String.isNotBlank(d.uf) && d.uf.equalsIgnoreCase(r.uf.trim());
        } catch (TrainingException e) {
            return false;
        }
    }

    /** without sharing: o duplicado deve ser detectado mesmo que o usuário não o enxergue. */
    private without sharing class DuplicateChecker {
        private Boolean exists(String doc) {
            return ![SELECT Id FROM Lead WHERE Documento__c = :doc AND IsConverted = false LIMIT 1].isEmpty()
                || ![SELECT Id FROM Account WHERE Documento__c = :doc LIMIT 1].isEmpty();
        }
    }
}
