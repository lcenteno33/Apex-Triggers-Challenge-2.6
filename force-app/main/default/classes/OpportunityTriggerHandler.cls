public with sharing class OpportunityTriggerHandler {
    public static void beforeUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        
    }

    public static void afterUpdate(List<Opportunity> newList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap){
        updateShipToOverride(newList, newMap, oldMap);
        closeAndOrder(newList, newMap, oldMap);
    }

    /************************** Perform Business Logic **************************/
    private static void updateShipToOverride (List<Opportunity> newList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Set<Id> opportunityIds = new Set<Id>();

        for (Opportunity opportunity : newList) {
            if (opportunity.Ship_To_Override__c != oldMap.get(opportunity.Id).Ship_To_Override__c){
                opportunityIds.add(opportunity.Id);
            }
        }

        if (!opportunityIds.isEmpty()) {

            List<SBQQ__Quote__c> relatedQuoteList = new List<SBQQ__Quote__c> ([
                SELECT Id, Ship_To__c, SBQQ__Account__c, SBQQ__Account__r.Ship_To__c, SBQQ__Opportunity2__r.Ship_To_Override__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c IN :opportunityIds
                AND SBQQ__Status__c = 'Draft'
            ]);

            List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();

            
            for (SBQQ__Quote__c quote : relatedQuoteList) {
                //create myquote
                //get the quote id
                if (quote.SBQQ__Opportunity2__r.Ship_To_Override__c != null) {
                    SBQQ__Quote__c myQuote = new SBQQ__Quote__c();//
                    myQuote.Id = quote.Id;
                    myQuote.Ship_To__c = quote.SBQQ__Opportunity2__r.Ship_To_Override__c;
                    quotesToUpdate.add(myQuote); // >> change mailing address in the quote
                } else {
                    if (quote.SBQQ__Account__r.Ship_To__c != null) {
                        SBQQ__Quote__c myQuote = new SBQQ__Quote__c();//
                        myQuote.Id = quote.Id;
                        myQuote.Ship_To__c = quote.SBQQ__Account__r.Ship_To__c;
                        quotesToUpdate.add(myQuote);
                    } else {
                        SBQQ__Quote__c myQuote = new SBQQ__Quote__c();//
                        myQuote.Id = quote.Id;
                        myQuote.Ship_To__c = null;
                        quotesToUpdate.add(myQuote);
                    } 
                }
                // quotes to update
            }
   
            update quotesToUpdate; // run quote trigger again
            // when we need to update a related object records in different requirements 
            // is best practice to make the updates just once, inside of a single method
        }

    }

    public static void closeAndOrder (List<Opportunity> newList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Set<Id> opportunityIds = new Set<Id>();

        for (Opportunity opportunity : newList) {
            if (opportunity.StageName == 'Closed Won' && opportunity.StageName != oldMap.get(opportunity.Id).StageName){
                opportunityIds.add(opportunity.Id);
            }
        }

        if (!opportunityIds.isEmpty()) {
            // if there are no quote lines in the quote the opportunity can't not be updated to close won
            List<SBQQ__Quote__c> queriedQuotes = [
                SELECT Id, SBQQ__Primary__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c IN :opportunityIds
            ];
            // its also possible to add a condition for primary field to que soql query
            List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
            
            for (SBQQ__Quote__c quote : queriedQuotes) {
                if (quote.SBQQ__Primary__c == true) {
                    SBQQ__Quote__c myQuote = new SBQQ__Quote__c();
                    myQuote.Id = quote.Id;
                    myQuote.SBQQ__Ordered__c = true;
                    quotesToUpdate.add(myQuote);
                }
            }
            update quotesToUpdate;
            
        }
    }
    /************************** Helper Methods **************************/
}
