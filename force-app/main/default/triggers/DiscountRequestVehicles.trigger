trigger DiscountRequestVehicles on Discount_Request__c (before insert, before update) {
    DiscountRequestVehicles.fill(Trigger.new);
}
