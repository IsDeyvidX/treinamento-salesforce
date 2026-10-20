/** Representa a resposta do ViaCEP já no formato usado pelo LWC. */
public with sharing class ViaCepDTO {
    @AuraEnabled public String cep;
    @AuraEnabled public String logradouro;
    @AuraEnabled public String bairro;
    @AuraEnabled public String cidade;
    @AuraEnabled public String uf;
    public Boolean erro = false;

    public static ViaCepDTO fromJson(String body) {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(body);
        ViaCepDTO d = new ViaCepDTO();
        // O ViaCEP devolve {"erro": true} (ou "true") quando o CEP não existe.
        d.erro = m.containsKey('erro') && String.valueOf(m.get('erro')) == 'true';
        d.cep = (String) m.get('cep');
        d.logradouro = (String) m.get('logradouro');
        d.bairro = (String) m.get('bairro');
        d.cidade = (String) m.get('localidade');
        d.uf = (String) m.get('uf');
        return d;
    }
}
