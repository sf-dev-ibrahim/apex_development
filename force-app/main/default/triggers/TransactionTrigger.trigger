trigger TransactionTrigger on Transaction__c (before insert) {
    new TransactionTriggerHandler().run();
}