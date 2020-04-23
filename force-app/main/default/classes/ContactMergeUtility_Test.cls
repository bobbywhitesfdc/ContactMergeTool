@isTest
public class ContactMergeUtility_Test {
    
    @testsetup
    public static void setup() {
       // Create some contacts with duplicates for our scenarios
       List<Account> testAccounts = Test.loadData(Account.sobjectType,'TestAccounts');
       List<Contact> testContacts = Test.loadData(Contact.sobjectType,'TestContacts');
        
    }
    public static testmethod void positiveCase() {
        final List<Contact> prospects = [SELECT Id, Name, TDA_Contact_Type__c, Email, Phone, Title, TDA_ODS_Client_ID__c 
                                         From Contact 
                                         Where TDA_Contact_Type__c = 'Prospect' 
                                         LIMIT 1000];
        
        ContactMergeUtility merger = new ContactMergeUtility(prospects);
        merger.match();
        
        final Map<Contact,Set<Contact>> matchResults = merger.matchResults;
        
        for(Contact current : prospects) {
            System.debug('Candidate: ' + current);
            Set<Contact> matches = matchResults.get(current);
            final String expectedKey = current.title;
            System.AssertNotEquals(null,matches,'Expected match collection Set<Contact>');
            Map<Id,Contact> matchMap = new Map<Id,Contact>(new List<Contact>(matches));

            final Set<String> matchKeys = new Set<String>();
            for(Contact currentMatch : [Select Id, Name, TDA_ODS_Client_ID__c, TDA_Contact_Type__c 
                                        From Contact 
                                        Where Id IN :matchMap.keySet()]) {
                System.debug('Match: ' + currentMatch );
                matchKeys.add(currentMatch.TDA_ODS_Client_ID__c); // ODS mastered Client Id           
            }
            
            if (String.isNotBlank(expectedKey)) {
                System.Assert(matchKeys.contains(expectedKey),'Expected match not found!' + expectedKey);
            } else {
                System.Assert(matchKeys.isEmpty(),'No matches expected!' + String.join(new List<String>(matchKeys),','));
            }
        }
    }
    
}