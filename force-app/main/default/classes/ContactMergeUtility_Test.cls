@isTest
public class ContactMergeUtility_Test {
    
    @testsetup
    public static void setup() {
       // Create some contacts with duplicates for our scenarios
       // Test data 
       List<Account> testAccounts = Test.loadData(Account.sobjectType,'TestAccounts');
       List<Contact> testContacts = Test.loadData(Contact.sobjectType,'TestContacts');
        
    }
    public static testmethod void testMatching() {
        final List<Contact> prospects = [SELECT Id, Name, TDA_Contact_Type__c, Email, Phone, Title, TDA_ODS_Client_ID__c 
                                         From Contact 
                                         Where TDA_Contact_Type__c = 'Prospect' 
                                         LIMIT 1000];
        Test.startTest();

        ContactMergeUtility merger = new ContactMergeUtility(prospects,'Client');
        merger.match();
        final Map<Contact,Contact> matchResults = merger.matchResults;

        Test.stopTest();

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

    private static testmethod void testSaveMatches() {
        final List<Contact> prospects = [SELECT Id, Name, TDA_Contact_Type__c, Email, Phone, Title, TDA_ODS_Client_ID__c 
                                         FROM Contact 
                                         WHERE TDA_Contact_Type__c = 'Prospect' 
                                         LIMIT 1000];
        final Set<Id> prospectIds = new Map<Id,Contact>(prospects).keySet();

        ContactMergeUtility merger = new ContactMergeUtility(prospects,'Client');
        merger.match();

        final Map<Contact,Contact> matchResults = merger.matchResults;

        Test.startTest();

        for(Database.SaveResult currentResult : merger.saveMatches(merger.matchResults)) {
            final String errorMsg = currentResult.getErrors().isEmpty() ? 'Unknown failure' : currentResult.getErrors()[0].getMessage();
            System.Assert(currentResult.isSuccess(),errorMsg);
        }

        Test.stopTest();

 
        for (Contact current : [Select Id, Name, Title, MasterContact__c
                                        , MasterContact__r.TDA_ODS_Client_Id__c, MergeApproved__c
                                FROM Contact 
                                WHERE Id IN :prospectIds]) {
            final String expectedMatchId = String.IsBlank(current.Title) ? null : current.Title;
            final String actualMatchId = current.MasterContact__c == null ? null : current.MasterContact__r.TDA_ODS_Client_Id__c;
            System.AssertEquals(expectedMatchId,actualMatchId,'Unexpected match');
            System.AssertEquals(!String.isBlank(expectedMatchId)
                                ,current.MergeApproved__c,'MergeApproved flag set incorrectly');
        }

    }

    private static testmethod void testMergeDuplicates() {
        final List<Contact> prospects = [SELECT Id, Name, TDA_Contact_Type__c, Email, Phone, Title, TDA_ODS_Client_ID__c 
                                         FROM Contact 
                                         WHERE TDA_Contact_Type__c = 'Prospect' 
                                         LIMIT 1000];

        final List<Contact> expectedMerges = [SELECT Id, TDA_Contact_Type__c, Title
                                               FROM Contact
                                               WHERE TDA_Contact_Type__c = 'Prospect'
                                                 and Title != null];                                
 
        ContactMergeUtility merger = new ContactMergeUtility(prospects,'Client');
        merger.match();

        final Map<Contact,Contact> matchResults = merger.matchResults;

 
        for(Database.SaveResult currentResult : merger.saveMatches(merger.matchResults)) {
            final String errorMsg = currentResult.getErrors().isEmpty() ? 'Unknown failure' : currentResult.getErrors()[0].getMessage();
            System.Assert(currentResult.isSuccess(),errorMsg);
        }

        Test.startTest();

        final List<Contact> duplicates = [SELECT Id, Name
                                            , TDA_Contact_Type__c, Email, Phone, Title
                                            , TDA_ODS_Client_ID__c, MergeApproved__c, MasterContact__c
                                          FROM Contact 
                                          WHERE TDA_Contact_Type__c = 'Prospect' 
                                            and MergeApproved__c=true
                                            and MasterContact__c != null 
                                         LIMIT 1000];

        final List<Database.MergeResult> results = merger.processMerges(duplicates,'Prospect');

        Test.stopTest();

        for (Database.MergeResult current : results ) {
             final String errorMessage = current.isSuccess() || current.getErrors().isEmpty() ? 'No error' : current.getErrors()[0].getMessage();
             System.Assert(current.isSuccess(),'Error:' + errorMessage);
        }

        final List<Contact> afterMerge = [SELECT Id, MergeApproved__c, Title, isDeleted 
                                          FROM Contact
                                          WHERE isDeleted=true
                                          ALL ROWS];

        System.AssertEquals(expectedMerges.size(),afterMerge.size(),'Actual merge count wrong');
 
    }
    
}