@IsTest
private class TrainingAddressSupportTest {
    @IsTest
    static void applyLeadStateNormalizaEAplicaEstado() {
        Lead l = new Lead();
        TrainingAddressSupport.applyLeadState(l, ' sp ');
        if (TrainingAddressSupport.usesStateCountryPicklists()) {
            System.assertEquals('SP', l.get('StateCode'));
            System.assertEquals('BR', l.get('CountryCode'));
            System.assert(TrainingAddressSupport.extraLeadFields().contains('StateCode'));
        } else {
            System.assertEquals('SP', l.State);
            System.assertEquals('', TrainingAddressSupport.extraLeadFields());
        }
    }
}
