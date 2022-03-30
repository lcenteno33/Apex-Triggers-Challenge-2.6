public with sharing class QuoteTriggerHandler {
    public static void beforeInsert(List<SBQQ__Quote__c> newList){
        setDefaults(newList);
    }

    public static void afterInsert(List<SBQQ__Quote__c> newList){
        //setShippingAddress(newList);
    }

    public static void beforeUpdate(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> newMap, Map<Id, SBQQ__Quote__c> oldMap){
        setWatermarkAndMailingAddress(newList, oldMap);
        customRollUp(newList, newMap, oldMap);
    }
    
    public static void afterUpdate(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap){
        // Call additional methods to perform logic
    }

    /************************** Perform Business Logic **************************/
    private static void setDefaults (List<SBQQ__Quote__c> newList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();

        for (SBQQ__Quote__c quote : newList) { 
            accountIds.add(quote.SBQQ__Account__c);
            opportunityIds.add(quote.SBQQ__Opportunity2__c);
        }

        Map<Id, Account> relatedAccountMap = new Map<Id, Account>([
            SELECT Id, Ship_To__c, Ship_To__r.MailingCity, Ship_To__r.MailingCountry
            FROM Account
            WHERE Id IN :accountIds
        ]);

        Map<Id, Opportunity> relatedOpportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Ship_To_Override__c, Ship_To_Override__r.MailingCity, Ship_To_Override__r.MailingCountry
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);

        for (SBQQ__Quote__c quote : newList) {
            quote.SBQQ__WatermarkShown__c = quote.SBQQ__Status__c != 'Approved' ? true : false;
            Opportunity relatedOpp = relatedOpportunityMap.get(quote.SBQQ__Opportunity2__c);
            if(relatedOpp.Ship_To_Override__c != null) {
                quote.Ship_To__c = relatedOpp.Ship_To_Override__c;
                quote.SBQQ__ShippingCity__c = relatedOpp.Ship_To_Override__r.MailingCity;
                quote.SBQQ__ShippingCountry__c = relatedOpp.Ship_To_Override__r.MailingCountry;
                // take all the address fields
            } else {
                Account relatedAccount = relatedAccountMap.get(quote.SBQQ__Account__c);
                if (relatedAccount.Ship_To__c != null) {
                    quote.Ship_To__c = relatedAccount.Ship_To__c;
                    quote.SBQQ__ShippingCity__c = relatedAccount.Ship_To__r.MailingCity;
                    quote.SBQQ__ShippingCountry__c = relatedAccount.Ship_To__r.MailingCountry;
                    // take all the address fields
                } else {
                    quote.Ship_To_Approval_Required__c = true;
                }
            }
        }

    }
    
    private static void setWatermarkAndMailingAddress (List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for(SBQQ__Quote__c quote : newList){
            if (quote.SBQQ__Status__c != oldMap.get(quote.Id).SBQQ__Status__c) {
                quote.SBQQ__WatermarkShown__c = quote.SBQQ__Status__c != 'Approved' ? true : false;
            }

            if (quote.Ship_To__c!= null && quote.Ship_To__c != oldMap.get(quote.Id).Ship_To__c) {
                contactIds.add(quote.Ship_To__c);
            }
        }

         // Will be better to get the contact       
        if(!contactIds.isEmpty()){
            Map<Id, Contact> relatedContactMap = new Map<Id, Contact>([
                    SELECT Id, MailingCity, MailingState, MailingCountry
                    FROM Contact
                    WHERE Id IN :contactIds
                ]);
            //what happen if we dont check if the quote do not have a contact?
            //quote.Ship_To__c!= null will solve this issue?
            for (SBQQ__Quote__c quote : newList) {
                if(relatedContactMap.containsKey(quote.Ship_To__c)) {
                    Contact relatedContact = relatedContactMap.get(quote.Ship_To__c);
                    quote.SBQQ__ShippingCity__c = relatedContact.MailingCity;
                    quote.SBQQ__ShippingState__c = relatedContact.MailingState;
                    quote.SBQQ__ShippingCountry__c = relatedContact.MailingCountry;
                    quote.Ship_To_Approval_Required__c = false;
                } else {
                    quote.Ship_To_Approval_Required__c = true;
                    quote.SBQQ__ShippingState__c = null;
                    quote.SBQQ__ShippingCity__c = null;
                    quote.SBQQ__ShippingCountry__c = null;
                } 
            }
        } else {
            for (SBQQ__Quote__c quote : newList) {
                quote.Ship_To_Approval_Required__c = true;
                quote.SBQQ__ShippingState__c = null;
                quote.SBQQ__ShippingCity__c = null;
                quote.SBQQ__ShippingCountry__c = null; 
            }
            
        }
                
    }

    private static void customRollUp (List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> newMap, Map<Id, SBQQ__Quote__c> oldMap) {
        Set<Id> quoteIds = new Set<Id>();

        //Wich field can I use to check and only run the logic when that field is updated?
        for(SBQQ__Quote__c quote : newList){
            quoteIds.add(quote.Id);
        }

        if(!quoteIds.isEmpty()) {
            List<SBQQ__QuoteLine__c> relatedQuoteLines = new List<SBQQ__QuoteLine__c> ([
                SELECT Id, SBQQ__ProductFamily__c, SBQQ__Quote__c, SBQQ__TotalDiscountAmount__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIds
            ]);

            for (SBQQ__Quote__c quote : newList) {
                Decimal discountSoftware = 0.00;
                Decimal discountHardware = 0.00;
                Decimal discountService = 0.00;
                for (SBQQ__QuoteLine__c quoteLine :relatedQuoteLines ){
                    if(quoteLine.SBQQ__ProductFamily__c == 'Software'){
                        discountSoftware += quoteLine.SBQQ__TotalDiscountAmount__c;
                    } else if(quoteLine.SBQQ__ProductFamily__c == 'Hardware') {
                        discountHardware += quoteLine.SBQQ__TotalDiscountAmount__c;
                    } else if (quoteLine.SBQQ__ProductFamily__c == 'Service') {
                        discountService += quoteLine.SBQQ__TotalDiscountAmount__c;
                    }
                }
                quote.Software_Discount_Total__c = discountSoftware;
                quote.Hardware_Discount_Total__c = discountHardware;
                quote.Service_Discount_Total__c = discountService;
                
            }

        }
    }
    /************************** Helper Methods **************************/

}
