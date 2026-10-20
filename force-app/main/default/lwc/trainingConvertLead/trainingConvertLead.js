import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import convertLead from '@salesforce/apex/TrainingLeadConversionController.convertLead';

export default class TrainingConvertLead extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;
    errorMessage = '';

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleConvert() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const accountId = await convertLead({ leadId: this.recordId });
            this.dispatchEvent(new ShowToastEvent({ title: 'Sucesso', message: 'Lead convertido em Cliente.', variant: 'success' }));
            this.dispatchEvent(new CloseActionScreenEvent());
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: accountId, objectApiName: 'Account', actionName: 'view' }
            });
        } catch (error) {
            this.errorMessage = (error && error.body && error.body.message) || 'Não foi possível converter o Lead.';
        } finally {
            this.isLoading = false;
        }
    }
}
