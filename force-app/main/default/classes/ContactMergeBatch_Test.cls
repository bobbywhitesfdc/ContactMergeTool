@IsTest
public class ContactMergeBatch_Test {

    @testsetup
    public static void setup() {
       // Create some contacts with duplicates for our scenarios
       List<Account> testAccounts = Test.loadData(Account.sobjectType,'TestAccounts');
       List<Contact> testContacts = Test.loadData(Contact.sobjectType,'TestContacts');
        
    }

    private static testmethod void testMatchMode() {
        Test.startTest();

        final Integer batchScope = 50; // Limit to 50 records per execution to avoid limits
        Database.executeBatch(new ContactMergeBatch('SELECT Id From Contact Where TDA_Contact_Type__c=\'Prospect\''
                              ,'Match'),batchScope);

        Test.stopTest();

        /**
         * When the Match operation completes, we should have 1 or more successful
         * matches saved 
         **/ 

         System.Assert(![SELECT Id 
                        From Contact 
                        Where TDA_Contact_Type__c='Prospect'
                          and MasterContact__c != null].isEmpty(),'Expected matches!');

    }

    private static testmethod void testMergeMode() {
        Test.startTest();

        // Prerun the match, save Matches 
        final List<Contact> prospects = [SELECT Id, Name, TDA_Contact_Type__c, Email, Phone, Title, TDA_ODS_Client_ID__c 
        FROM Contact 
        WHERE TDA_Contact_Type__c = 'Prospect' 
        LIMIT 1000];

        ContactMergeUtility merger = new ContactMergeUtility(prospects,'Client');
        merger.match();
        merger.saveMatches(merger.matchResults);


        // now execute the batch

        Database.executeBatch(new ContactMergeBatch('SELECT Id, TDA_Contact_Type__c, MergeApproved__c, MasterContact__c From Contact Where TDA_Contact_Type__c=\'Prospect\''
                              ,'Merge'));

        Test.stopTest();

        /**
         * When the Merge operation completes, we should no Prospects left needing
         * to be merged 
         **/ 
         System.Assert([SELECT Id 
                        From Contact 
                        Where TDA_Contact_Type__c='Prospect'
                          and MergeApproved__c=true].isEmpty(),'Expected no unmerged Prospects!');

    }
}
