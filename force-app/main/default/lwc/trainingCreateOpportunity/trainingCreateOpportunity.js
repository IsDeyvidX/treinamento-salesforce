import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import PRODUTO_FIELD from '@salesforce/schema/Opportunity.Produto__c';
import createOpportunity from '@salesforce/apex/TrainingOpportunityController.createOpportunity';

const pad = (n) => String(n).padStart(2, '0');

export default class TrainingCreateOpportunity extends NavigationMixin(LightningElement) {
    @api recordId; // Id da Account onde a Quick Action foi acionada
    form = { name: '', produto: '', valorEstimado: '', quantidade: '', closeDate: '', observacao: '' };
    isLoading = false;
    errorMessage = '';

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT }) objectInfo;
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: PRODUTO_FIELD })
    produtoValues;

    get produtoOptions() {
        return this.produtoValues && this.produtoValues.data ? this.produtoValues.data.values : [];
    }

    get today() {
        const d = new Date();
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    }

    handleChange(event) {
        this.form = { ...this.form, [event.target.dataset.field]: event.detail.value };
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    validate() {
        let ok = true;
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
                    produto: v.produto,
                    valorEstimado: Number(v.valorEstimado),
                    quantidade: parseInt(v.quantidade, 10),
                    closeDate: v.closeDate,
                    observacao: v.observacao
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
