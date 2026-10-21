import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';
import createOpportunity from '@salesforce/apex/TrainingOpportunityController.createOpportunity';
import getProductOptions from '@salesforce/apex/TrainingOpportunityController.getProductOptions';

const MAX_ROWS = 20;
const pad = (n) => String(n).padStart(2, '0');

export default class TrainingCreateOpportunity extends NavigationMixin(LightningElement) {
    @api recordId; // Id da Account onde a Quick Action foi acionada
    form = { name: '', closeDate: '', observacao: '' };
    rows = [{ key: 'row-0', pricebookEntryId: '', quantidade: '1' }];
    products = [];
    isLoading = false;
    errorMessage = '';
    rowCounter = 1;

    @wire(getProductOptions)
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data;
        } else if (error) {
            this.errorMessage = (error.body && error.body.message) || 'Não foi possível carregar os produtos.';
        }
    }

    get today() {
        const d = new Date();
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    }

    get currencyCode() {
        return CURRENCY;
    }

    get canAddRow() {
        return this.rows.length < MAX_ROWS && this.products.length > 0;
    }

    get canRemoveRow() {
        return this.rows.length > 1;
    }

    get isAddDisabled() {
        return !this.canAddRow || this.isLoading;
    }

    get isRemoveDisabled() {
        return !this.canRemoveRow || this.isLoading;
    }

    formatPrice(value) {
        return new Intl.NumberFormat(LOCALE, { style: 'currency', currency: CURRENCY }).format(value);
    }

    // Visão das linhas: opções sem os produtos já escolhidos em outras linhas, preço e subtotal.
    get rowViews() {
        return this.rows.map((row, index) => {
            const chosenElsewhere = new Set(
                this.rows.filter((r) => r.key !== row.key && r.pricebookEntryId).map((r) => r.pricebookEntryId)
            );
            const options = this.products
                .filter((p) => !chosenElsewhere.has(p.pricebookEntryId))
                .map((p) => ({
                    value: p.pricebookEntryId,
                    label: `${p.name}${p.productCode ? ` (${p.productCode})` : ''} - ${this.formatPrice(p.unitPrice)}`
                }));
            const product = this.products.find((p) => p.pricebookEntryId === row.pricebookEntryId);
            const unitPrice = product ? product.unitPrice : 0;
            const qty = parseInt(row.quantidade, 10);
            const cents = Number.isInteger(qty) && qty > 0 ? Math.round(unitPrice * 100) * qty : 0;
            return {
                ...row,
                options,
                unitPrice,
                subtotal: cents / 100,
                productLabel: `Produto da linha ${index + 1}`,
                quantityLabel: `Quantidade da linha ${index + 1}`,
                removeLabel: `Remover linha ${index + 1}`
            };
        });
    }

    // Total apenas visual; o servidor recalcula com o preço da PricebookEntry.
    get total() {
        return this.rowViews.reduce((sum, r) => sum + Math.round(r.subtotal * 100), 0) / 100;
    }

    handleChange(event) {
        this.form = { ...this.form, [event.target.dataset.field]: event.detail.value };
    }

    handleRowChange(event) {
        const { key, rowField } = event.target.dataset;
        const value = event.detail.value;
        this.rows = this.rows.map((r) => (r.key === key ? { ...r, [rowField]: value } : r));
    }

    handleAddRow() {
        if (!this.canAddRow) return;
        this.rows = [...this.rows, { key: `row-${this.rowCounter++}`, pricebookEntryId: '', quantidade: '1' }];
    }

    handleRemoveRow(event) {
        if (!this.canRemoveRow) return;
        const { key } = event.currentTarget.dataset;
        this.rows = this.rows.filter((r) => r.key !== key);
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    validate() {
        let ok = true;
        const seen = new Set();
        this.template.querySelectorAll('lightning-combobox[data-row-field="pricebookEntryId"]').forEach((el) => {
            const duplicated = el.value && seen.has(el.value);
            el.setCustomValidity(duplicated ? 'O mesmo produto não pode ser adicionado duas vezes.' : '');
            if (el.value) seen.add(el.value);
        });
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach((el) => {
            if (!el.reportValidity()) ok = false;
        });
        return ok;
    }

    // Lê os valores atuais direto dos campos, evitando depender só do estado do componente.
    readFields() {
        const v = { ...this.form };
        this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea').forEach((el) => {
            if (el.dataset.field) v[el.dataset.field] = el.value;
        });
        return v;
    }

    // Lê produto e quantidade de cada linha direto da tela; o preço nunca é enviado.
    readItems() {
        return this.rows.map((row) => {
            const item = { pricebookEntryId: row.pricebookEntryId, quantidade: row.quantidade };
            this.template.querySelectorAll(`[data-key="${row.key}"][data-row-field]`).forEach((el) => {
                item[el.dataset.rowField] = el.value;
            });
            return { pricebookEntryId: item.pricebookEntryId, quantidade: parseInt(item.quantidade, 10) };
        });
    }

    async handleSave() {
        this.errorMessage = '';
        if (!this.validate()) return;
        this.isLoading = true;
        try {
            const v = this.readFields();
            const oppId = await createOpportunity({
                requestJson: JSON.stringify({
                    accountId: this.recordId,
                    name: v.name,
                    closeDate: v.closeDate,
                    observacao: v.observacao,
                    itens: this.readItems()
                })
            });
            const url = await this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: { recordId: oppId, objectApiName: 'Opportunity', actionName: 'view' }
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Sucesso',
                    message: 'Oportunidade e pedido criados. {0}',
                    messageData: [{ url, label: 'Abrir oportunidade' }],
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.errorMessage = (error && error.body && error.body.message) || 'Não foi possível criar a oportunidade.';
        } finally {
            this.isLoading = false;
        }
    }
}
