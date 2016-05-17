trigger VTT_ActivityLogEntryTrigger on Work_Order_Activity_Log_Entry__c (after update, after insert, after delete)  {
    If (VTT_Utilities.executeTriggerCode)
    {
        System.debug('\n*****************************************\n'
            + 'METHOD: VTT_ActivityLogEntryTrigger()'
            + '\nTrigger: executed'
            + '\n************************************************\n');                  

        if (Trigger.isDelete)
        {
            VTT_Utilities.TriggerAfterDeleteWorkOrderActivityLogEntry(Trigger.old);
        }
        
        if (Trigger.isInsert)
        {            
            VTT_Utilities.TriggerAfterInsertWorkOrderActivityLogEntry(Trigger.new);        
        }
                            
        if (Trigger.isUpdate)
        {
            VTT_Utilities.TriggerAfterUpdateWorkOrderActivityLogEntry(Trigger.new, Trigger.oldMap);
        }
                        
    }
}