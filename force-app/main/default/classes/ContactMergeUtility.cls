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
            matchResults.put(currentMaster,(Contact)bestMatch.getRecord());
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

    
}