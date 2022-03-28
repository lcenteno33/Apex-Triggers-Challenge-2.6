public with sharing class QuoteTriggerHandler {
    public static void beforeInsert(List<SBQQ__Quote__c> newList){
        setQuoteDefaults(newList);
    }

    public static void afterInsert(List<SBQQ__Quote__c> newList){
        setShippingAddress(newList);
    }

    public static void beforeUpdate(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap){
        setQuoteWatermark(newList, oldMap);
    }

    public static void afterUpdate(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap){
        // Call additional methods to perform logic
    }

    /************************** Perform Business Logic **************************/
    private static void setQuoteDefaults (List<SBQQ__Quote__c> newList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();

        for (SBQQ__Quote__c quote : newList) { 
            accountIds.add(quote.SBQQ__Account__c);
            opportunityIds.add(quote.SBQQ__Opportunity2__c);
        }

        Map<Id, Account> relatedAccountMap = new Map<Id, Account>([
            SELECT Id, Ship_To__c
            FROM Account
            WHERE Id IN :accountIds
        ]);

        Map<Id, Opportunity> relatedOpportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Ship_To_Override__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);

        for (SBQQ__Quote__c quote : newList) {
            quote.SBQQ__WatermarkShown__c = quote.SBQQ__Status__c != 'Approved' ? true : false;
            Opportunity relatedOpp = relatedOpportunityMap.get(quote.SBQQ__Opportunity2__c);
            if(relatedOpp.Ship_To_Override__c != null) {
                quote.Ship_To__c = relatedOpp.Ship_To_Override__c;
                // Shipping Address don't exist in Quote object, should we creat it?
            } else {
                Account relatedAccount = relatedAccountMap.get(quote.SBQQ__Account__c);
                if (relatedAccount.Ship_To__c != null) {
                    quote.Ship_To__c = relatedAccount.Ship_To__c;
                } else {
                    quote.Ship_To_Approval_Required__c = true;
                }
            }
        }

    }

    private static void setShippingAddress (List<SBQQ__Quote__c> newList) {
        Set<Id> contactIds = new Set<Id>();
        List<SBQQ__Quote__c> quoteToSetShippingAddress = new List<SBQQ__Quote__c>();

        for (SBQQ__Quote__c quote : newList) {
            if(quote.Ship_To__c != null) {
                contactIds.add(quote.Ship_To__c);
            }
        }

        if (!contactIds.isEmpty()){
            

            Map<Id, Contact> relatedContactMap = new Map<Id, Contact>([
                SELECT Id, 	MailingAddress
                FROM Contact
                WHERE Id IN :contactIds
            ]);
            
            for (SBQQ__Quote__c quote : newList) {
                Contact relatedContact = relatedContactMap.get(quote.Ship_To__c);
                SBQQ__Quote__c myQuote = new SBQQ__Quote__c();
                myQuote.Id = quote.Id; 
                //myQuote.Shipping_Address__c = relatedContact.MailingAddress;
                //Can't not assign Address to Text
                myQuote.Shipping_Address__c = 'Hard coded Address';

                quoteToSetShippingAddress.add(myQuote);
            }

            update quoteToSetShippingAddress;
        }
    }

    private static void setQuoteWatermark (List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        
    }
    /************************** Helper Methods **************************/

}
