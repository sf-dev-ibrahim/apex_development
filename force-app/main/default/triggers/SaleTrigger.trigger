trigger SaleTrigger on Sale__c (before insert) {
    new SaleTriggerHandler().run();
}