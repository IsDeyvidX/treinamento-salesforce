/** Isola o acesso a Estado/País para funcionar com os picklists ligados ou desligados. */
public with sharing class TrainingAddressSupport {
    private static Boolean cached;

    public static Boolean usesStateCountryPicklists() {
        if (cached == null) {
            Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();
            Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();
            cached = leadFields.containsKey('countrycode')
                && accountFields.containsKey('billingcountrycode')
                && !leadFields.get('countrycode').getDescribe().getPicklistValues().isEmpty();
        }
        return cached;
    }

    public static void applyLeadState(Lead l, String state) {
        String code = String.isBlank(state) ? null : state.trim().toUpperCase();
        if (usesStateCountryPicklists()) {
            l.put('CountryCode', 'BR');
            l.put('StateCode', code);
        } else {
            l.State = code;
        }
    }

    public static String extraLeadFields() {
        return usesStateCountryPicklists() ? ', StateCode, CountryCode' : '';
    }

    public static void applyBillingState(Account a, Lead l) {
        if (usesStateCountryPicklists()) {
            a.put('BillingCountryCode', l.get('CountryCode'));
            a.put('BillingStateCode', l.get('StateCode'));
        } else {
            a.BillingState = l.State;
        }
    }
}
