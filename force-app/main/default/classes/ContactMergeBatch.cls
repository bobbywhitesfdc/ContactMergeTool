global class ContactMergeBatch implements Database.Batchable<sObject>{

    public enum OperationType {  MATCH, MERGEOP }

    private final String query;
    private final OperationType op;
    private final String duplicateKind='Prospect';
    private final String matchWithType='Client'; 

 
    global ContactMergeBatch(final String q, final String opName){
       this.query=q;
       this.op = opName != null && opName=='Merge' ? OperationType.MERGEOP : OperationType.MATCH;
    }
 
    global Database.QueryLocator start(Database.BatchableContext BC){
       return Database.getQueryLocator(query);
    }
 
    /**
     * Run the Matching Logic
     **/
    global void execute(Database.BatchableContext BC, List<SObject> scope){

        final ContactMergeUtility util = new ContactMergeUtility((List<Contact>) scope,matchWithType);
 
        if (this.op == OperationType.MATCH) {
            util.saveMatches(util.match());
        } else {
            // Merge the duplicates 
            util.processMerges((List<Contact>)scope,duplicateKind); 
        }
    }
 
    global void finish(Database.BatchableContext BC){
    }
 }
