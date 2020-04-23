@isTest
public class ContactMergeUtility_Test {
    
    @testsetup
    public static void setup() {
       // Create some contacts with duplicates for our scenarios
       // Test data 
       List<Account> testAccounts = Test.loadData(Account.sobjectType,'TestAccounts');
       List<Contact> testContacts = Test.loadData(Contact.sobjectType,'TestContacts');
        
    }
    public static testmethod void positiveCase() {
        final List<Contact> prospects = [SELECT Id, Name, TDA_Contact_Type__c, Email, Phone, Title, TDA_ODS_Client_ID__c 
                                         From Contact 
                                         Where TDA_Contact_Type__c = 'Prospect' 
                                         LIMIT 1000];
        
        ContactMergeUtility merger = new ContactMergeUtility(prospects,'Client');
        merger.match();
        
        final Map<Contact,Contact> matchResults = merger.matchResults;
        
        for(Contact current : prospects) {
            System.debug('Candidate: ' + current);
            final Contact match = matchResults.get(current);
            final String expectedKey = current.title;
 
        
            Contact currentMatch = (match == null) ? null  : [Select Id, Name, TDA_ODS_Client_ID__c, TDA_Contact_Type__c 
                                                              From Contact 
                                                              Where Id = :match.Id];

            final String matchKey = currentMatch == null ? null : currentMatch.TDA_ODS_Client_ID__c;
            
            if (String.isNotBlank(expectedKey)) {
                System.AssertEquals(expectedKey, matchKey,'Expected match not found!');
            } else {
                System.AssertEquals(null,matchKey,'Did not expect match!');
            }
        }
    }
    
}