trigger VTT_ActivityAssignmentTrigger on Work_Order_Activity_Assignment__c (before update, before insert,after update, after insert, before delete, after delete) {
    If (VTT_Utilities.executeTriggerCode)
    {
        System.debug('\n*****************************************\n'
            + 'METHOD: VTT_ActivityAssignmentTrigger()'
            + '\nTrigger: executed'
            + '\n************************************************\n');                  

        if (Trigger.isDelete)
        {

            if(Trigger.isBefore)
            {
                VTT_Utilities.ValidateActivityAssignmentBeforeDelete(Trigger.old);
            }
            else
            {
                VTT_Utilities.UpdateActivityAssigneeField(Trigger.old);
            }
        }
        
        if (Trigger.isInsert)
        {            
            if (Trigger.isBefore) 
            {               
                VTT_Utilities.UpdateActivityAssignmentTradesman(Trigger.new);         
            }    
            else                
            {
                VTT_Utilities.UpdateActivityAssigneeField(Trigger.new);    
                VTT_Utilities.NotifyAssignedTradesman(Trigger.new);                    
            }
        }
                            
        if (Trigger.isUpdate)
        {
            if (Trigger.isBefore)  
            {
                VTT_Utilities.UpdateActivityAssignmentTradesman(Trigger.new);  
            }
            else
            {
                System.debug('VTT_ActivityAssignmentTrigger->AfterUpdate()');
                VTT_Utilities.UpdateActivityAssigneeField(Trigger.new);
                VTT_Utilities.NotifyVendorSupervisorRejectedActivity(Trigger.new);
            }
            
        }
                        
    }
}