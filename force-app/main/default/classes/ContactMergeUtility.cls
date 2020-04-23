/**
 * Utility to find matching Contacts and to perform merges.
 **/ 
public class ContactMergeUtility {
    // Set a default minimum matching confidence threshold
    public Double minimumThreshold = 80.0;
    
    public final List<Contact> inputs {get; private set;}
    public Map<Contact,Set<Contact>> matchResults {get; private set;}
    
    public ContactMergeUtility(List<Contact> inputs) {
        this.inputs=inputs;
    }
    
    /**
	* Given a input list of contacts, find their duplicates if any
    * @param masters - the accounts for which to find matches
    * @return map containing 1 row per input contact.  Payload is a Set of matches which may be empty.
	**/ 
    public Map<Contact,Set<Contact>> match() {
        // Keyed by the master Contact Id.  Contains set of matching Ids
        matchResults = new Map<Contact,Set<Contact>>();
        final Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(inputs);
        
        Integer i = 0;
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            final Contact currentMaster = inputs[i];
            final Map<Id,Datacloud.MatchRecord> curatedMatches = new Map<Id, Datacloud.MatchRecord>();
            final Set<Contact> currentMatches = new Set<Contact>();
            matchResults.put(currentMaster,currentMatches);
            
         	System.debug('Duplicate results.size:' + findDupeResult.getDuplicateResults().size());     
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
            	System.debug('Duplicate Rule:' + dupeResult.getDuplicateRule());
         		System.debug('Duplicate results-Match Results.size:' + dupeResult.getMatchResults().size());     

                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    System.debug('Match Rule:' + matchResult.getRule());
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        final Contact current = (Contact) matchRecord.getRecord();
                        System.debug('Matching Record: ' + matchRecord.getRecord());
                        System.debug('Matching Confidence: ' + matchRecord.getMatchConfidence());
                        
                        //Run the logic to get the highest confidence score record
                        if(curatedMatches.containsKey(current.Id)){
                            Datacloud.MatchRecord matchingRec = curatedMatches.get(current.Id);
                            if(matchRecord.getMatchConfidence() > matchingRec.getMatchConfidence()){
                                curatedMatches.put(current.Id,matchRecord);
                            }
                        } 
                        else{
                            // Only add matches that equal or exceed the minimal threshold
                            if (matchRecord.getMatchConfidence() >= minimumThreshold) {
                            	curatedMatches.put(current.Id,matchRecord);                                
                            } else {
                                System.debug('match below threshold:' + matchRecord.getMatchConfidence());
                            }
                        }
                    }
                }
            }
            
            for(Datacloud.MatchRecord mtch: curatedMatches.values()){
                currentMatches.add((Contact)mtch.getRecord());
            }
            i++;
        } 
        
        return matchResults;
    }
}