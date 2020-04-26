/**
 * Utility to find matching Contacts and to perform merges.
 **/ 
public class ContactMergeUtility {
    // Set a default minimum matching confidence threshold
    public Double minimumThreshold = 80.0;
    
    public final List<Contact> inputs {get; private set;}
    public final String matchWithType;
    public Map<Contact,Contact> matchResults {get; private set;}
    
    public ContactMergeUtility(final List<Contact> inputs, final String matchWithType ) {
        this.inputs=inputs;
        this.matchWithType=matchWithType;
    }
    
    /**
	* Given a input list of contacts, find their duplicates if any
    * @param masters - the accounts for which to find matches
    * @return map containing 1 row per input contact.  Payload is a Set of matches which may be empty.
	**/ 
    public Map<Contact,Contact> match() {
        // Keyed by the master Contact Id.  Contains set of matching Ids
        matchResults = new Map<Contact,Contact>();
        final Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(inputs);
        
        final Map<Id,Contact> enrichedMatches = enrichMatches(results);
        
        Integer i = 0;
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            final Contact currentMaster = inputs[i];
            final Map<Id,Datacloud.MatchRecord> curatedMatches = new Map<Id, Datacloud.MatchRecord>();
            //final Set<Contact> currentMatches = new Set<Contact>();
            Datacloud.MatchRecord bestMatch = null;
            
         	System.debug('Duplicate results.size:' + findDupeResult.getDuplicateResults().size());     
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
            	System.debug('Duplicate Rule:' + dupeResult.getDuplicateRule());
         		System.debug('Duplicate results-Match Results.size:' + dupeResult.getMatchResults().size());     

                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    System.debug('Match Rule:' + matchResult.getRule());
                    for (Datacloud.MatchRecord possibleMatchRecord : matchResult.getMatchRecords()) {
                        final Contact current = enrichedMatches.get(possibleMatchRecord.getRecord().Id);
                        if (current.TDA_Contact_Type__c == this.matchWithType) {
                            System.debug('Matching Record: ' + possibleMatchRecord.getRecord());
                            System.debug('Matching Confidence: ' + possibleMatchRecord.getMatchConfidence());
                            
                            // Replace the current match with a better match based on confidence
                            if(bestMatch != null){
                                if(possibleMatchRecord.getMatchConfidence() > bestMatch.getMatchConfidence()){
                                    bestMatch=possibleMatchRecord;
                                }
                            } 
                            else{
                                // Only add matches that equal or exceed the minimal threshold
                                if (possibleMatchRecord.getMatchConfidence() >= minimumThreshold) {
                                    bestMatch=possibleMatchRecord;                               
                                } else {
                                    System.debug('match below threshold:' + possibleMatchRecord.getMatchConfidence());
                                }
                            }
                        } else {
                            System.debug('Skipping wrong matchWith Contact-Type:' + current);
                        }
                  }
                }
            }

            // Put a single best match in the results
            final Contact bestMatchContact = (bestMatch == null) ? null : (Contact) bestMatch.getRecord();
            matchResults.put(currentMaster,bestMatchContact);
            i++;
        } 
        
        return matchResults;
    }
    
    /**
     * Iterate through the results and in a bulkified manner, requery the possible matches to 
     * get any additional fields that are required
     **/ 
    private Map<Id,Contact> enrichMatches(final Datacloud.FindDuplicatesResult[] results) {
        final Set<Id> matchIds = new Set<Id>();
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        matchIds.add(matchRecord.getRecord().Id);
                    }
                }
            } 
        }
                   
        return new Map<Id,Contact>([Select Id, TDA_Contact_Type__c, FirstName, LastName, Email, Phone, TDA_ODS_Client_Id__c 
                                    From Contact 
                                    Where Id IN :matchIds]); 
    }


    /**
     * Break the overall process down by saving the Matches as lookups on the Contact object
     * This allows a business process where end users can review the proposed matches and uncheck
     * the MergeApproved__c field if they don't like the proposed match.
     */
    public List<Database.SaveResult> saveMatches(final Map<Contact,Contact> matchResults) {
        final List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact duplicate : matchResults.keySet()) {
            final Contact master = matchResults.get(duplicate);
            final Id masterId = (master==null? null : master.Id);
            contactsToUpdate.add(new Contact(Id=duplicate.Id
                                ,MasterContact__c= masterId
                                ,MergeApproved__c= (masterId != null)));
        }

        List<Database.SaveResult> results = Database.update(contactsToUpdate,false);
        return results;
    }
    
    /**
     * Iterate through the Approved Prospect merges and execute the physical merges
     **/
    public List<Database.MergeResult> processMerges(final List<Contact> toBeMerged, final String duplicateType) {
        List<Database.MergeResult> results = new List<Database.MergeResult>(); 
        for (Contact duplicate : toBeMerged) {
            if (duplicate.TDA_Contact_Type__c == duplicateType
               && duplicate.MergeApproved__c == true
               && duplicate.MasterContact__c != null ) {
                   // Merge the duplicate into the Master
                   final Contact master = new Contact(Id=duplicate.MasterContact__c);
                   Database.MergeResult currentResult = Database.Merge(master,duplicate.id);
                   results.add(currentResult);
               }
        }
        return results;
    }
}