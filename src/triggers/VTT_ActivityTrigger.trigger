trigger VTT_ActivityTrigger on Work_Order_Activity__c (before insert, after insert, before update, after update) 
{
    If (VTT_Utilities.executeTriggerCode)
    {
        System.debug('\n*****************************************\n'
            + 'METHOD: VTT_ActivityTrigger()'
            + '\nTrigger: executed'
            + '\n************************************************\n');                  

        if (Trigger.isInsert)
        {                      
 			if (Trigger.isBefore)
                VTT_Utilities.TriggerBeforeInsertWorkOrderActivity(Trigger.new);
            else
            	VTT_Utilities.TriggerAfterInsertWorkOrderActivity(Trigger.new);                       
        } 
        if (Trigger.isUpdate)
        { 
        	if (Trigger.isBefore)
                VTT_Utilities.TriggerBeforeUpdateWorkOrderActivity(Trigger.new, Trigger.oldMap);
            else
                VTT_Utilities.TriggerAfterUpdateWorkOrderActivity(Trigger.new, Trigger.oldMap);  
        }
    }
}