@IsTest
private class DocumentValidatorTest {
    @IsTest static void sanitizeKeepsOnlyDigits() {
        Assert.areEqual('52998224725', DocumentValidator.sanitize('529.982.247-25'));
        Assert.areEqual('', DocumentValidator.sanitize(null));
    }
    @IsTest static void validCpfWithAndWithoutMask() {
        Assert.isTrue(DocumentValidator.isValidCpf('529.982.247-25'));
        Assert.isTrue(DocumentValidator.isValidCpf('52998224725'));
    }
    @IsTest static void invalidCpf() {
        Assert.isFalse(DocumentValidator.isValidCpf('52998224726'), 'dígito verificador errado');
        Assert.isFalse(DocumentValidator.isValidCpf('11111111111'), 'sequência repetida');
        Assert.isFalse(DocumentValidator.isValidCpf('00000000000'), 'sequência repetida');
        Assert.isFalse(DocumentValidator.isValidCpf('123'), 'tamanho errado');
    }
    @IsTest static void validCnpjWithAndWithoutMask() {
        Assert.isTrue(DocumentValidator.isValidCnpj('11.222.333/0001-81'));
        Assert.isTrue(DocumentValidator.isValidCnpj('11222333000181'));
    }
    @IsTest static void invalidCnpj() {
        Assert.isFalse(DocumentValidator.isValidCnpj('11222333000182'), 'dígito verificador errado');
        Assert.isFalse(DocumentValidator.isValidCnpj('00000000000000'), 'sequência repetida');
        Assert.isFalse(DocumentValidator.isValidCnpj('1122233300018'), 'tamanho errado');
    }
    @IsTest static void isValidRespectsType() {
        Assert.isTrue(DocumentValidator.isValid('CPF', '52998224725'));
        Assert.isFalse(DocumentValidator.isValid('CNPJ', '52998224725'));
        Assert.isFalse(DocumentValidator.isValid('XYZ', '52998224725'));
    }
}
