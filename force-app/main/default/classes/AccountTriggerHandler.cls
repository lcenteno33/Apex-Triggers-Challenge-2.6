public with sharing class AccountTriggerHandler {

    public static void beforeUpdate(List<Account> newList, Map<Id, Account> oldMap){
        
    }

    public static void afterUpdate(List<Account> newList, Map<Id, Account> newMap, Map<Id, Account> oldMap){
        updateShipTo(newList, newMap, oldMap);
    }

    /************************** Perform Business Logic **************************/
    private static void updateShipTo (List<Account> newList, Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        Set<Id> accountIds = new Set<Id>();

        for (Account account : newList) {
            if (account.Ship_To__c != oldMap.get(account.Id).Ship_To__c){
                accountIds.add(account.Id);
            }
        }

        if (!accountIds.isEmpty()) {

            List<SBQQ__Quote__c> relatedQuoteList = new List<SBQQ__Quote__c> ([
                SELECT Id, Ship_To__c, SBQQ__Account__c, SBQQ__Account__r.Ship_To__c, SBQQ__Opportunity2__r.Ship_To_Override__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Account__c IN :accountIds
                AND SBQQ__Status__c = 'Draft'
            ]);

            List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();

            
                for (SBQQ__Quote__c quote : relatedQuoteList) {
                    if (quote.SBQQ__Opportunity2__r.Ship_To_Override__c == null) {
                        if (newMap.get(quote.SBQQ__Account__c).Ship_To__c != null) {
                            SBQQ__Quote__c myQuote = new SBQQ__Quote__c();
                            myQuote.Id = quote.Id;
                            myQuote.Ship_To__c = quote.SBQQ__Account__r.Ship_To__c;
                            //newMap.get(quote.SBQQ__Account__c).Ship_To__c; Alternative Using newMap
                            //we can access the field from the new map in the triggered account
                            //update also the mailing address field here or in the quote trigger
                            //see edge cases
                            quotesToUpdate.add(myQuote); // >> change mailing address in the quote
                        } else {
                            SBQQ__Quote__c myQuote = new SBQQ__Quote__c();
                            myQuote.Id = quote.Id;
                            myQuote.Ship_To__c = null;
                            quotesToUpdate.add(myQuote);
                        }
                    }
                }
   
            update quotesToUpdate; // run quote trigger again
        }

    }
    /************************** Helper Methods **************************/
}
