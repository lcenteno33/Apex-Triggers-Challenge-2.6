trigger OpportunityTrigger on Opportunity (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
    } 
}