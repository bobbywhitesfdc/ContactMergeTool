@isTest
public class ContactMergeUtility_Test {
    
    @testsetup
    public static void setup() {
       // Create some contacts with duplicates for our scenarios
       List<Account> testAccounts = Test.loadData(Account.sobjectType,'TestAccounts');
       List<Contact> testContacts = Test.loadData(Contact.sobjectType,'TestContacts');
        
    }
    public static testmethod void positiveCase() {
        final List<Contact> prospects = [SELECT Id, Name, RecordTypeId,RecordType.Name, Email, Phone, Title 
                                         From Contact 
                                         Where RecordType.Name='Prospect' LIMIT 1000];
        
        ContactMergeUtility merger = new ContactMergeUtility(prospects);
        merger.match();
        
        final Map<Contact,Set<Contact>> matchResults = merger.matchResults;
        
        for(Contact current : prospects) {
            System.debug('Candidate: ' + current);
            Set<Contact> matches = matchResults.get(current);
            final String expectedKey = current.title;
            System.AssertNotEquals(null,matches,'Expected match collection Set<Contact>');
            final Set<String> matchKeys = new Set<String>();
            for(Contact currentMatch : matches) {
                System.debug('Match: ' + currentMatch );
                matchKeys.add(currentMatch.title); // For this test, we've parked the externalid in the Title field            
            }
            
            if (String.isNotBlank(expectedKey)) {
                System.Assert(matchKeys.contains(expectedKey),'Expected match not found!' + expectedKey);
            } else {
                System.Assert(matchKeys.isEmpty(),'No matches expected!' + String.join(new List<String>(matchKeys),','));
            }
        }
    }
    
}