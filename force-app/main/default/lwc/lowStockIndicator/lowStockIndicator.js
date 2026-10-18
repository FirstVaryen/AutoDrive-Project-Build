import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import AVAILABLE_STOCK from '@salesforce/schema/Vehicle_Model__c.Available_Stock__c';
import LOW_STOCK_THRESHOLD from '@salesforce/schema/Vehicle_Model__c.Low_stock_Threshold__c';

// Matches the Vehicle_Model_Low_Stock_Alert flow: low stock means strictly below the threshold.
export default class LowStockIndicator extends NavigationMixin(LightningElement) {
    @api recordId;

    goToModelList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Vehicle_Model__c', actionName: 'list' },
            state: { filterName: 'All' }
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: [AVAILABLE_STOCK, LOW_STOCK_THRESHOLD] })
    vehicleModel;

    get available() {
        return getFieldValue(this.vehicleModel.data, AVAILABLE_STOCK) ?? 0;
    }

    get threshold() {
        return getFieldValue(this.vehicleModel.data, LOW_STOCK_THRESHOLD);
    }

    get hasData() {
        return !!this.vehicleModel.data;
    }

    get hasThreshold() {
        return this.threshold !== null && this.threshold !== undefined;
    }

    get isLow() {
        return this.hasThreshold && this.available < this.threshold;
    }

    get badgeClass() {
        return this.isLow ? 'indicator indicator_low' : 'indicator indicator_ok';
    }

    get message() {
        if (!this.hasThreshold) {
            return `${this.available} available. No low-stock threshold set.`;
        }
        return this.isLow
            ? `LOW STOCK: ${this.available} available (threshold ${this.threshold})`
            : `In stock: ${this.available} available (threshold ${this.threshold})`;
    }
}
