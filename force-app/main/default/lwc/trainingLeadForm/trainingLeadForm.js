import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createLead from '@salesforce/apex/TrainingLeadController.createLead';
import lookupCep from '@salesforce/apex/TrainingLeadController.lookupCep';

const EMPTY = {
    firstName: '', lastName: '', email: '', telefone: '', tipoPessoa: 'CPF', documento: '',
    cep: '', logradouro: '', numero: '', bairro: '', cidade: '', uf: '', complemento: ''
};

/* ---------- utilitários (validação PRELIMINAR; a definitiva é no Apex) ---------- */
const onlyDigits = (v) => (v || '').replace(/\D/g, '');

const maskCpf = (d) =>
    d.slice(0, 11)
        .replace(/^(\d{3})(\d)/, '$1.$2')
        .replace(/^(\d{3})\.(\d{3})(\d)/, '$1.$2.$3')
        .replace(/\.(\d{3})(\d)/, '.$1-$2');

const maskCnpj = (d) =>
    d.slice(0, 14)
        .replace(/^(\d{2})(\d)/, '$1.$2')
        .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
        .replace(/\.(\d{3})(\d)/, '.$1/$2')
        .replace(/(\d{4})(\d)/, '$1-$2');

const maskCep = (d) => d.slice(0, 8).replace(/^(\d{5})(\d)/, '$1-$2');

const allSame = (d) => d.split('').every((c) => c === d[0]);

const isValidCpf = (raw) => {
    const d = onlyDigits(raw);
    if (d.length !== 11 || allSame(d)) return false;
    const calc = (len, peso) => {
        let sum = 0;
        for (let i = 0; i < len; i++) sum += Number(d[i]) * (peso - i);
        const r = (sum * 10) % 11;
        return r === 10 ? 0 : r;
    };
    return calc(9, 10) === Number(d[9]) && calc(10, 11) === Number(d[10]);
};

const isValidCnpj = (raw) => {
    const d = onlyDigits(raw);
    if (d.length !== 14 || allSame(d)) return false;
    const calc = (pesos) => {
        const sum = pesos.reduce((acc, p, i) => acc + Number(d[i]) * p, 0);
        const r = sum % 11;
        return r < 2 ? 0 : 11 - r;
    };
    return (
        calc([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) === Number(d[12]) &&
        calc([6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) === Number(d[13])
    );
};

const friendlyError = (error) =>
    (error && error.body && error.body.message) || 'Não foi possível concluir a operação. Tente novamente.';

export default class TrainingLeadForm extends NavigationMixin(LightningElement) {
    form = { ...EMPTY };
    isLoading = false;
    cepMessage = '';

    tipoOptions = [
        { label: 'CPF - Pessoa Física', value: 'CPF' },
        { label: 'CNPJ - Pessoa Jurídica', value: 'CNPJ' }
    ];

    get documentoLabel() {
        return this.form.tipoPessoa === 'CPF' ? 'CPF' : 'CNPJ';
    }
    get documentoMaxLength() {
        return this.form.tipoPessoa === 'CPF' ? 14 : 18;
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        let value = event.detail.value;
        if (field === 'documento') {
            const d = onlyDigits(value);
            value = this.form.tipoPessoa === 'CPF' ? maskCpf(d) : maskCnpj(d);
        } else if (field === 'cep') {
            value = maskCep(onlyDigits(value));
        } else if (field === 'uf') {
            value = (value || '').toUpperCase().slice(0, 2);
        }
        this.form = { ...this.form, [field]: value };
        if (field === 'tipoPessoa') {
            this.form = { ...this.form, documento: '' }; // troca de tipo => nova máscara/validação
        }
    }

    async handleCepBlur() {
        const digits = onlyDigits(this.form.cep);
        this.cepMessage = '';
        if (digits.length !== 8) return; // só consulta com exatamente 8 dígitos
        this.isLoading = true;
        try {
            const a = await lookupCep({ cep: digits });
            this.form = {
                ...this.form,
                logradouro: a.logradouro || '',
                bairro: a.bairro || '',
                cidade: a.cidade || '',
                uf: a.uf || ''
            };
        } catch (error) {
            this.cepMessage = friendlyError(error);
        } finally {
            this.isLoading = false;
        }
    }

    validateForm() {
        let ok = true;
        const fields = this.template.querySelectorAll('lightning-input, lightning-combobox');
        const values = {};
        fields.forEach((el) => {
            const field = el.dataset.field;
            if (field) {
                values[field] = el.value;
            }
        });
        this.form = { ...this.form, ...values };
        fields.forEach((el) => {
            if (el.dataset.field === 'documento') {
                const valid = this.form.tipoPessoa === 'CPF'
                    ? isValidCpf(this.form.documento)
                    : isValidCnpj(this.form.documento);
                el.setCustomValidity(this.form.documento && !valid ? `${this.documentoLabel} inválido` : '');
            }
            if (!el.reportValidity()) ok = false;
        });
        return ok;
    }

    async handleSave() {
        if (!this.validateForm()) return;
        this.isLoading = true;
        try {
            const leadId = await createLead({ leadJson: JSON.stringify(this.form) });
            this.dispatchEvent(new ShowToastEvent({ title: 'Sucesso', message: 'Lead criado com sucesso!', variant: 'success' }));
            this.form = { ...EMPTY };
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: leadId, objectApiName: 'Lead', actionName: 'view' }
            });
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Não foi possível salvar', message: friendlyError(error), variant: 'error' }));
        } finally {
            this.isLoading = false;
        }
    }
}
