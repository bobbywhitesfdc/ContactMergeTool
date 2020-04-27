global class ContactMergeBatch implements Database.Batchable<SObject>, Database.Stateful {

    public enum OperationType {  MATCH, MERGEOP }

    private final String query;
    private final OperationType op;
    private final String duplicateKind='Prospect';
    private final String matchWithType='Client'; 
    public Integer recordsProcessed {get;private set;}
    public Integer errorCount {get; private set;}
 
    global ContactMergeBatch(final String q, final String opName){
       this.query=q;
       this.op = opName != null && opName=='Merge' ? OperationType.MERGEOP : OperationType.MATCH;
       this.recordsProcessed=0;
       this.errorCount=0;
    }
 
    global Database.QueryLocator start(Database.BatchableContext BC){
       return Database.getQueryLocator(query);
    }
 
    /**
     * Run the Matching Logic
     **/
    global void execute(Database.BatchableContext BC, List<Contact> scope){

        final ContactMergeUtility util = new ContactMergeUtility(scope,matchWithType);
 
        if (this.op == OperationType.MATCH) {
            for (Database.saveResult current : util.saveMatches(util.match())) {
                this.recordsProcessed++;
                this.errorCount += (current.isSuccess() ? 0 : 1);
            }
        } else {
            // Merge the duplicates 
            for(Database.mergeResult current : util.processMerges((List<Contact>)scope,duplicateKind)) {
                this.recordsProcessed++;
                this.errorCount += (current.isSuccess() ? 0 : 1);               
            } 
        }
    }
 
    global void finish(Database.BatchableContext BC){
        System.debug('recordsProcessed: ' + this.recordsProcessed);
        System.debug('errorCount: ' + this.errorCount);
    }
 }
