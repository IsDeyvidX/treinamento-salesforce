/** Utilitário de sanitização e validação de CPF/CNPJ (dígitos verificadores). */
public with sharing class DocumentValidator {
    public static final String CPF = 'CPF';
    public static final String CNPJ = 'CNPJ';

    private static final List<Integer> CNPJ_W1 = new List<Integer>{ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };
    private static final List<Integer> CNPJ_W2 = new List<Integer>{ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };

    /** Mantém somente números. */
    public static String sanitize(String value) {
        return value == null ? '' : value.replaceAll('[^0-9]', '');
    }

    public static Boolean isValid(String tipo, String documento) {
        if (tipo == CPF) return isValidCpf(documento);
        if (tipo == CNPJ) return isValidCnpj(documento);
        return false;
    }

    public static Boolean isValidCpf(String raw) {
        String d = sanitize(raw);
        if (d.length() != 11 || allSame(d)) return false;
        return cpfDigit(d, 9, 10) == digit(d, 9) && cpfDigit(d, 10, 11) == digit(d, 10);
    }

    public static Boolean isValidCnpj(String raw) {
        String d = sanitize(raw);
        if (d.length() != 14 || allSame(d)) return false;
        return cnpjDigit(d, CNPJ_W1) == digit(d, 12) && cnpjDigit(d, CNPJ_W2) == digit(d, 13);
    }

    private static Integer cpfDigit(String d, Integer qtd, Integer pesoInicial) {
        Integer sum = 0;
        for (Integer i = 0; i < qtd; i++) {
            sum += digit(d, i) * (pesoInicial - i);
        }
        Integer r = Math.mod(sum * 10, 11);
        return r == 10 ? 0 : r;
    }

    private static Integer cnpjDigit(String d, List<Integer> pesos) {
        Integer sum = 0;
        for (Integer i = 0; i < pesos.size(); i++) {
            sum += digit(d, i) * pesos[i];
        }
        Integer r = Math.mod(sum, 11);
        return r < 2 ? 0 : 11 - r;
    }

    private static Integer digit(String d, Integer i) {
        return Integer.valueOf(d.substring(i, i + 1));
    }

    /** Rejeita sequências repetidas (000..., 111...). */
    private static Boolean allSame(String d) {
        return d.countMatches(d.substring(0, 1)) == d.length();
    }
}
