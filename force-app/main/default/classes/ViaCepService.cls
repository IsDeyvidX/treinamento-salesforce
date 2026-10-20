/** Encapsula o callout ao ViaCEP. O endpoint vem da Named Credential "ViaCEP". */
public with sharing class ViaCepService {
    public static final String MSG_INVALID = 'Informe um CEP com 8 dígitos.';
    public static final String MSG_NOT_FOUND = 'CEP não encontrado.';
    public static final String MSG_UNAVAILABLE =
        'Serviço de consulta de CEP indisponível no momento. Tente novamente em instantes ou preencha o endereço manualmente.';

    public static ViaCepDTO lookup(String cepRaw) {
        String cep = DocumentValidator.sanitize(cepRaw);
        if (cep.length() != 8) {
            throw new TrainingException(MSG_INVALID);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ViaCEP/' + cep + '/json/');
        req.setMethod('GET');
        req.setTimeout(10000);

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (CalloutException e) {
            throw new TrainingException(MSG_UNAVAILABLE);
        }
        if (res.getStatusCode() != 200) {
            throw new TrainingException(MSG_UNAVAILABLE);
        }

        ViaCepDTO dto;
        try {
            dto = ViaCepDTO.fromJson(res.getBody());
        } catch (Exception e) {
            throw new TrainingException(MSG_UNAVAILABLE);
        }
        if (dto.erro) {
            throw new TrainingException(MSG_NOT_FOUND);
        }
        return dto;
    }
}
