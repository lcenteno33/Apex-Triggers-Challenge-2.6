trigger QuoteTrigger on SBQQ__Quote__c (before insert, after insert, before update, after update) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        QuoteTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        QuoteTriggerHandler.afterInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        QuoteTriggerHandler.beforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        QuoteTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    } 

}