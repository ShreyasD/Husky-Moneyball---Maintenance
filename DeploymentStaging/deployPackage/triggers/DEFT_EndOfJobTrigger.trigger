trigger DEFT_EndOfJobTrigger on HOG_EOJ__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

		if (Trigger.isBefore) {
	    	if(Trigger.isInsert) {
	    		DEFT_Utilities.TriggerBeforeInsertEOJ(Trigger.new);
	    	}
		} else if (Trigger.isAfter) {
	    	//call handler.after method
	    
		}
}