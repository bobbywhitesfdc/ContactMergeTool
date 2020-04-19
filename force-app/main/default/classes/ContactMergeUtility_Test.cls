@isTest
public class ContactMergeUtility_Test {
    
    @testsetup
    public static void setup() {
       // Create some contacts with duplicates for our scenarios 
    }
    public static testmethod void positiveCase() {
        List<Contact> prospects = [SELECT Id, Name, RecordType.Name 
                                   From Contact 
                                   Where RecordType.Name='Prospect' LIMIT 1000];
        
        for(Contact currentProspect : prospects) {
            List<Contact> candidates = new List<Contact>();
            candidates.add(currentProspect);
            ContactMergeUtility merger = new ContactMergeUtility(candidates);
            merger.match();
            if (merger.matchResults == null) {
                System.Debug('Match Results empty');
            } else {
                Map<Contact,Set<Contact>> matchResults = merger.matchResults;
                for (Contact current : matchResults.keyset()) {
                    System.debug('Candidate: ' + current);
                    Set<Contact> matches = matchResults.get(current);
                    if (matches !=null) {
                        for(Contact currentMatch : matches) {
                            System.debug('Match: ' + currentMatch );
                        }
                    } else {
                        System.debug('No matches!');
                    }
                }
            }
        }
        System.Assert(false,'Not implemented');
    }
    
}