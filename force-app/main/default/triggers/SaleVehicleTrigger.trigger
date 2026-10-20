trigger SaleVehicleTrigger on Sale_Vehicle__c (before delete, after insert, after update, after delete) {
    if (Trigger.isBefore) { SaleVehicleHandler.blockClosed(Trigger.old); return; }
    if (Trigger.isDelete) SaleVehicleHandler.releaseCars(Trigger.old);
    SaleVehicleHandler.refreshSummaries(Trigger.isDelete ? Trigger.old : Trigger.new);
}
