/*-------------------------------------------------------------------------------------------------
Author     : Sergey Makarov
Company    : Husky Energy
Description: A Global Utility class for Vendor Time Tracking
Inputs     : N/A
Test Class : VTT_WorkFlowEngineTest
History    : 02.22.16 sd  sd 02.22.2016 - W-000401 - If the tradesman started work from home take 
                          that start time and change tradesman status          
---------------------------------------------------------------------------------------------------*/
public without sharing class VTT_WorkFlowEngine {

    String recordId;
    ID userID;
  
    public Boolean IsAdmin {get;private set;}

    public Boolean CanManageAssignments  {get;private set;}

    private final ApexPages.StandardController stdcontroller;
    private final Work_Order_Activity__c woActivity;

    private Work_Order_Activity__c currentActivityCopy;

    public Boolean ViewMode {get; private set;}
    public Boolean ActionMode_RejectActivity {get; private set;}    
    public Boolean ActionMode_Generic {get; private set;}
    public Boolean ActionMode_StartJobAtEquipment {get; private set;}        
    public Boolean ActionMode_PutOnHold {get; private set;}            
    public Boolean ActionMode_JobComplete {get; private set;}                
  
    
    //public String ConfirmMessage {get; private set;}
    public String SaveButtonLabel {get; private set;}

 	public String ViewScreenDescription {get; private set;}    


    public Boolean userHasEditAccess {get; private set;}

    public decimal CurrentLatitude{get;set;}    
    public decimal CurrentLongitude{get;set;}    

    public Contact Tradesman{get;set;}  
    public List<AssignedTradesman>  AssignedTradesmenList {get; set;}
    public List<AssignedTradesman>  AvailableCrewMembers {get; set;}
    public List<Contact> OtherTradesmenStillWorking {get; private set;}

    public List<AvailableActivity>  AvailableActivitiesToComplete {get; set;}

    public Boolean CanExecuteAction {get; private set;}
    public Boolean CanStartJobAtEquipment {get; private set;}
    public Boolean CanPutActivityOnHold {get; private set;}
    public Boolean CanCancelActivity {get; private set;}   
    public Boolean CanRejectActivity {get; private set;}   
    public Boolean CanCompleteJob {get; private set;}
    
    public Boolean PageReloadRequired {get; private set;}

    public Boolean CurrentUserIsAssignedTradesman {get; private set;} 

    public String ActionName{get;set;}  
    public String ActionComment{get;set;}      
    public String NewTradesmanStatus {get; private set;}    
    public String NewActivityStatus {get; private set;} 

    public String OnHoldStatusReason {get; set;} 

    public List<WorkFlowAction> WorkFlowActions {get; private set;} 

    public static Map<String, String[]> workFlowMap = new Map<String, String[]>{
            VTT_Utilities.LOGENTRY_STARTJOB => new String[]{VTT_Utilities.TRADESMAN_STATUS_PREWORK, 
                                                            VTT_Utilities.ACTIVITY_STATUS_STARTED},
            VTT_Utilities.LOGENTRY_STARTATSITE => new String[]{VTT_Utilities.TRADESMAN_STATUS_WORKING, 
                                                            VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE},
            VTT_Utilities.LOGENTRY_FINISHEDATSITE => new String[]{VTT_Utilities.TRADESMAN_STATUS_POSTWORK,
                                                            VTT_Utilities.ACTIVITY_STATUS_FINISHEDATSITE},
            VTT_Utilities.LOGENTRY_FINISHEDFORTHEDAY => new String[]{VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, 
                                                            VTT_Utilities.ACTIVITY_STATUS_FINISHEDFORTHEDAY}
    };

    public VTT_WorkFlowEngine(ApexPages.StandardController stdController) {
        recordId = stdController.getId();
        userID =   UserInfo.getUserid();

        this.stdcontroller = stdController;
        this.woActivity = (Work_Order_Activity__c)stdController.getRecord();  

        ResetButtons();



        LoadAssignedTradesmen();
        Tradesman = VTT_Utilities.LoadTradesmanInfo();

        IsAdmin = VTT_Utilities.IsAdminUser(); 
        CanManageAssignments =  (this.woActivity.Status__c <> VTT_Utilities.ACTIVITY_STATUS_COMPLETED)
                                &&
                                (
                                    IsAdmin || 
                                    (
                                    VTT_Utilities.IsVendorSupervisor() && Tradesman.accountid <> null & this.woActivity.Assigned_Vendor__c == Tradesman.accountid
                                    )
                                );

        SetActionButtons();

        this.userHasEditAccess = IsAdmin || CurrentUserIsAssignedTradesman;        

        AvailableActivitiesToComplete = new List<AvailableActivity>();  
	}

    private void SetActionButtons()
    {

        WorkFlowActions = new List<WorkFlowAction>();

        CanCompleteJob = false;
        CanExecuteAction = false;
        CanStartJobAtEquipment = false;
        CanPutActivityOnHold = false;               
        CanCancelActivity = false;
        CanRejectActivity = false;

        NewActivityStatus = null;
        NewTradesmanStatus = null;


        if( woActivity.Status__c <> VTT_Utilities.ACTIVITY_STATUS_COMPLETED
            && woActivity.Status__c <> VTT_Utilities.ACTIVITY_STATUS_CANCELLED)

        {
             if(CurrentUserIsAssignedTradesman == false) 
            {
                String message = 'You are not assigned Tradesman for this Activity.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message));            
            }
            else if(Tradesman.Current_Work_Order_Activity__c<> null 
            && Tradesman.Current_Work_Order_Activity__c <> woActivity.ID 
            && CurrentUserIsAssignedTradesman)
            {
                String message = 'You are currently working on a different Activity.' ;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message)); 
                //even when tradesman work on another activity he should be albe to reject this one
                CanRejectActivity = true;           
            } 
            else if(Tradesman.Current_Work_Order_Activity__c == null  
                 && woActivity.Maintenance_Work_Order__r.On_Hold__c 
                 && CurrentUserIsAssignedTradesman)
            {
                String message = 'This Work Order is currently ON HOLD' ;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message));            
            } 
    
        }




        //if user is not assigned tradesman or Activity completed or Activity cancelled
        //he can't do anything with this activity
        system.debug('Check 1');
        if(CurrentUserIsAssignedTradesman == false 
            || woActivity.Status__c == VTT_Utilities.ACTIVITY_STATUS_COMPLETED
            || woActivity.Status__c == VTT_Utilities.ACTIVITY_STATUS_CANCELLED)
        {
            system.debug('Pass');
            return;
        }


        //if current user is assigned tradesman and he is not working on anything else 
        //and activity is not complete - he can start this job
        //if(Tradesman.Current_Work_Order_Activity__c == null && CurrentUserIsAssignedTradesman)
        system.debug('Check 2');
        if((Tradesman.Tradesman_Status__c == null 
            || Tradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_NOTWORKING
            || Tradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK)
             && CurrentUserIsAssignedTradesman
             && woActivity.Maintenance_Work_Order__r.On_Hold__c == false)
        {
            system.debug('Pass');            
            CanExecuteAction = true;
            CanRejectActivity = true;
            //Can start directly at equipment if thermal facility and tradesman has started work
            //for the day
            CanStartJobAtEquipment = VTT_Utilities.IsThermalActivity(this.woActivity.Id);

            WorkFlowActions.add(new WorkFlowAction(VTT_Utilities.LOGENTRY_STARTJOB));

            return;
        }

        //if current user is currently working on this activity assigned tradesman 
        system.debug('Check 3');
        if(Tradesman.Current_Work_Order_Activity__c == woActivity.ID && CurrentUserIsAssignedTradesman)
        {
            system.debug('Pass');
        
            CanCancelActivity = true;

            if(woActivity.Status__c == VTT_Utilities.ACTIVITY_STATUS_ONHOLD)
            {
                CanPutActivityOnHold = false;
                return;
            }
            else
            {
                //if there are any other tradesman working on this activity, you can't put this activity on Hold
                CanPutActivityOnHold = true;
                for(Contact workintradesman : woActivity.Working_Tradesmen__r)
                 {
                    if(workintradesman.id !=  tradesman.ID)
                    {
                        CanPutActivityOnHold = false;
                    }
                 }
            }

            if(Tradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_PREWORK)
            {
                CanExecuteAction = true;

                WorkFlowActions.add(new WorkFlowAction(VTT_Utilities.LOGENTRY_STARTATSITE));                
            }

            if(Tradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_WORKING )
            {
                CanExecuteAction = true;   
                
                WorkFlowActions.add(new WorkFlowAction(VTT_Utilities.LOGENTRY_FINISHEDATSITE));

                //ssd New workflow to complete job while working
                CanCompleteJob = VTT_Utilities.IsThermalActivity(woActivity.Id); 
            }

            if(Tradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_POSTWORK)
            {
                CanExecuteAction = true;

                WorkFlowActions.add(new WorkFlowAction(VTT_Utilities.LOGENTRY_STARTATSITE));                 
                WorkFlowActions.add(new WorkFlowAction(VTT_Utilities.LOGENTRY_FINISHEDFORTHEDAY));                 

                CanCompleteJob = true;
                //if there are any other tradesman working on this activity, you can't put this activity on Hold
                CanPutActivityOnHold = true;
                for(Contact workingtradesman : woActivity.Working_Tradesmen__r)
                 {
                    if(workingtradesman.id !=  tradesman.ID)
                    {
                        //ssd always allow to complete job but if other people working simply finish for the day for the current
                        //tradesman
                        //CanCompleteJob = false;
                        CanPutActivityOnHold = false;
                    }
                 }
            }           

            system.debug('woActivity.Working_Tradesmen__r');
            system.debug(woActivity.Working_Tradesmen__r);

            return;
        }
    }

    private void PopulateAvailableActivitiesToComplete()
    {
        AvailableActivitiesToComplete = new List<AvailableActivity>();  
        //give me all activities (except current activity) for current work order which are assigned to me and still in status NEW 
        for(Work_Order_Activity__c woaRec : [
            select id, Name, Status__c, System_Condition__c, Work__c, 
            Scheduled_Start_Date__c, Scheduled_Finish_Date__c,
            Equipment__r.Description_of_Equipment__c,
            Location__c,
            (select id from Working_Tradesmen__r  where id <> :Tradesman.ID),
            (select id, Tradesman__c
            from Work_Order_Activity_Assignments__r 
            where Tradesman__c = :Tradesman.ID) 
            from Work_Order_Activity__c
            where id <> :woActivity.id
            and Maintenance_Work_Order__c = :woActivity.Maintenance_Work_Order__c
            and Status__c <> :VTT_Utilities.ACTIVITY_STATUS_COMPLETED
            order by Name
            ])
        {
            //if Activity assigned to me and there are no other tradesmen currently working on this activity, show it in the list
            if(woaRec.Work_Order_Activity_Assignments__r.size()>0 && woaRec.Working_Tradesmen__r.size() == 0)
            {
                AvailableActivitiesToComplete.add(new AvailableActivity(woaRec));
            }
        } 
    }

    private void LoadAssignedTradesmen()
    {
        AssignedTradesmenList = new List<AssignedTradesman>();
        Set<ID> contactSet = new Set<ID>();
        for(Work_Order_Activity_Assignment__c woaa : [select id, Tradesman__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Work_Order_Activity__c = :woActivity.id])
        {
            contactSet.add(woaa.Tradesman__c);
        }
        system.debug('contactSet');
        system.debug(contactSet);


        CurrentUserIsAssignedTradesman = false;

        for(Contact tradesmancontact : [select id, name, Phone, email, Tradesman_Status__c, Current_Work_Order_Activity__c, Tradesman_Status_Date__c, User__c 
                                        from Contact where id in :contactSet order by name])
        {
            if( tradesmancontact.User__c <> UserInfo.getUserId())
            {
                AssignedTradesmenList.add(new AssignedTradesman(tradesmancontact));             
            }
            else
            {
                CurrentUserIsAssignedTradesman = true;
            }
        }

        system.debug('CurrentUserIsAssignedTradesman');
        system.debug(CurrentUserIsAssignedTradesman);
    }

    private void LoadOtherTradesmenStillWorking()
    {
        OtherTradesmenStillWorking = new List<Contact>();
        for(Contact workingTradesman : woActivity.Working_Tradesmen__r) {
            if(workingTradesman.Id != Tradesman.Id) {
                OtherTradesmenStillWorking.add(workingTradesman);
            }
        }
    }

    public PageReference VTT_CancelEdit()
    {

        ResetButtons();
        return null;
    }  


    public PageReference RejectActivity_Start()
    {
        System.debug('RejectActivity_Start');
        this.ViewMode = false;
        this.ActionMode_RejectActivity = true;

        this.SaveButtonLabel = 'Confirm';
        this.ViewScreenDescription  = 'Work Order Activity - Reject Activity';
        return null;
    }
    public PageReference RejectActivity_End()
    {
        System.debug('RejectActivity_End');
         List<Work_Order_Activity_Assignment__c> result = [select id, Tradesman__c, Rejected__c, Reject_Reason__c 
         from Work_Order_Activity_Assignment__c 
         where Tradesman__c = :tradesman.id
         and Work_Order_Activity__c = :woActivity.id
         and Rejected__c <> true];

         System.debug('RejectActivity_End-> tradesman.id: ' + tradesman.id + ' woActivity.id' + woActivity.id);
         System.debug('RejectActivity_End->result: ' + result);
         if(result.size()>0)
         {
            Work_Order_Activity_Assignment__c rec = result[0];
            rec.Rejected__c = true;
            rec.Reject_Reason__c = ActionComment;
            system.debug('Update Assignned Tradesman record');
            system.debug(rec);
            update rec;
         }            
        //ResetButtons();
        return ReloadCurrentPage();  
    }  

    public PageReference StartJobAtEquipment_Start()
    {
        if(OptimisticLockCheck() == false)
        {
            return null;
        }

        WorkFlowAction startJobAction = new WorkFlowAction(VTT_Utilities.LOGENTRY_STARTJOB);
        this.ActionName = startJobAction.ActionName;
        this.NewTradesmanStatus = startJobAction.NewTradesmanStatus;
        this.NewActivityStatus = startJobAction.NewActivityStatus;

        this.ViewMode = false;
        this.ActionMode_StartJobAtEquipment = true;

        this.SaveButtonLabel = 'Confirm';
        this.ViewScreenDescription  = 'Work Order Activity - Start Job at Equipment';

        return null;
    }

    public PageReference JobComplete_Start()
    {
        if(OptimisticLockCheck() == false)
        {
            return null;
        }


        this.ViewMode = false;
        this.ActionMode_JobComplete = true;

        this.SaveButtonLabel = 'Job Complete';
        this.ViewScreenDescription  = 'Work Order Activity - Job Complete';

        LoadOtherTradesmenStillWorking();
        PopulateAvailableActivitiesToComplete();

        return null;
    }
    public PageReference JobComplete_End()
    {
        if(OtherTradesmenStillWorking == null || OtherTradesmenStillWorking.isEmpty()) {
            system.debug('Executing JobComplete_End');
            try
            {
                ActionName = VTT_Utilities.LOGENTRY_JOBCOMPLETE;
                NewTradesmanStatus = VTT_Utilities.TRADESMAN_STATUS_NOTWORKING;
                NewActivityStatus = VTT_Utilities.ACTIVITY_STATUS_COMPLETED;

                List<Contact> TradesmanListforUpdate = new List<Contact>();  
                for(AssignedTradesman tradesmenRec : AssignedTradesmenList)
                {
                    //update statuses for assigned tradesmen only if they currently working on the same activity
                    if(tradesmenRec.Tradesman.Current_Work_Order_Activity__c == woActivity.ID)
                    {
                        TradesmanListforUpdate.add(tradesmenRec.Tradesman);
                    }
                }

                if(Tradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_WORKING &&
                    VTT_Utilities.IsThermalActivity(woActivity.Id)) {
                    WorkFlowAction finishAtEquipmentAction = new WorkFlowAction(VTT_Utilities.LOGENTRY_FINISHEDATSITE);

                    LogEntryAction(
                            Tradesman,
                            WoActivity,
                            finishAtEquipmentAction.ActionName,
                            CurrentLatitude, 
                            CurrentLongitude, 
                            ActionComment,
                            finishAtEquipmentAction.NewTradesmanStatus,
                            finishAtEquipmentAction.NewActivityStatus,
                            null,
                            TradesmanListforUpdate
                            );
                }

                LogEntryAction(
                        Tradesman,
                        WoActivity,
                        ActionName,
                        CurrentLatitude, 
                        CurrentLongitude, 
                        ActionComment,
                        NewTradesmanStatus,
                        NewActivityStatus,
                        null,
                        TradesmanListforUpdate
                        );
                /*Complete selected activities*/
                List<Work_Order_Activity__c> activitiesToComplete = new List<Work_Order_Activity__c>();
                for(AvailableActivity obj :AvailableActivitiesToComplete)
                {
                    if(obj.MarkToComplete)
                    {
                        activitiesToComplete.add(obj.ActivityRecord);
                    }
                }

                VTT_Utilities.AutoCompleteActivities(
                        Tradesman, 
                        activitiesToComplete,
                        CurrentLatitude,
                        CurrentLongitude,
                        'Autocompleted with activity: ' + WoActivity.Name);


                //update activitiesToComplete;

                return ReloadCurrentPage();  
            }
            catch(Exception ex)
            {
                VTT_Utilities.logError(ex);
            }
        } else {
            try {
                if(Tradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_WORKING) {
                    WorkFlowAction finishAtEquipmentAction = new WorkFlowAction(VTT_Utilities.LOGENTRY_FINISHEDATSITE);

                    LogEntryAction(
                        Tradesman,
                        WoActivity,
                        finishAtEquipmentAction.ActionName,
                        CurrentLatitude, 
                        CurrentLongitude, 
                        ActionComment,
                        finishAtEquipmentAction.NewTradesmanStatus,
                        finishAtEquipmentAction.NewActivityStatus,
                        null,
                        new List<Contact>()
                        );
                }

                WorkFlowAction finishedForTheDayAction = new WorkFlowAction(VTT_Utilities.LOGENTRY_FINISHEDFORTHEDAY);

                LogEntryAction(
                    Tradesman,
                    WoActivity,
                    finishedForTheDayAction.ActionName,
                    CurrentLatitude, 
                    CurrentLongitude, 
                    ActionComment,
                    finishedForTheDayAction.NewTradesmanStatus,
                    finishedForTheDayAction.NewActivityStatus,
                    null,
                    new List<Contact>()
                    );

            } catch (Exception ex) {
                VTT_Utilities.logError(ex);
            }
        }

        return null;        
    }  

    public PageReference GenericActivity_Start1()
    {

        WorkFlowAction currentAction = WorkFlowActions[0];
        this.ActionName = currentAction.ActionName;
        this.NewTradesmanStatus = currentAction.NewTradesmanStatus;
        this.NewActivityStatus = currentAction.NewActivityStatus;

        return GenericActivity_Start();
    }
    public PageReference GenericActivity_Start2()
    {
        WorkFlowAction currentAction = WorkFlowActions[1];
        this.ActionName = currentAction.ActionName;
        this.NewTradesmanStatus = currentAction.NewTradesmanStatus;
        this.NewActivityStatus = currentAction.NewActivityStatus;

        return GenericActivity_Start();
    }


    public PageReference GenericActivity_Start()
    {
        if(OptimisticLockCheck() == false)
        {
            return null;
        }

        this.ViewMode = false;
        this.ActionMode_Generic = true;

        this.SaveButtonLabel = 'Confirm';
        this.ViewScreenDescription  = 'Work Order Activity - ' + this.ActionName;

        return null;
    }
    public PageReference GenericActivity_End()
    {
        if(OptimisticLockCheck() == false)
        {
            return null;
        }


        system.debug('ActionComment');
        system.debug(ActionComment);

        system.debug('AssignedTradesmenList');
        system.debug(AssignedTradesmenList);

        try
        {
            //Get Prior tradesman status 
            String priorTradesmanStatus = Tradesman.Tradesman_Status__c;

            //Do Default Action
            LogEntryAction(
                        Tradesman,
                        WoActivity,
                        ActionName,
                        CurrentLatitude, 
                        CurrentLongitude, 
                        ActionComment,
                        NewTradesmanStatus,
                        NewActivityStatus,
                        null,
                        new List<Contact>()
                        );

            //If 'Start Job' and tradesman Started Work (Thermal)
            System.debug('GenericActivity_End -> ' + 
                ' NewTradesmanStatus: ' + NewTradesmanStatus + ' priorTradesmanStatus: ' + priorTradesmanStatus);
            if((NewTradesmanStatus == VTT_Utilities.TRADESMAN_STATUS_PREWORK &&
                priorTradesmanStatus == VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK) ||
                this.ActionMode_StartJobAtEquipment) {
                WorkFlowAction startAtEquipmentAction = new WorkFlowAction(VTT_Utilities.LOGENTRY_STARTATSITE);

                LogEntryAction(
                        Tradesman,
                        WoActivity,
                        startAtEquipmentAction.ActionName,
                        CurrentLatitude, 
                        CurrentLongitude, 
                        ActionComment,
                        startAtEquipmentAction.NewTradesmanStatus,
                        startAtEquipmentAction.NewActivityStatus,
                        null,
                        new List<Contact>()
                        );
            }

            //ResetButtons();
            return ReloadCurrentPage();   
        }
        catch(Exception ex)
        {
            VTT_Utilities.logError(ex);
        }
        return null;
    }  

    public PageReference ActivityOnHold_Start()
    {
        if(OptimisticLockCheck() == false)
        {
            return null;
        }

        if(CanPutJobOnHoldCheck() == false)
        {
            return null;
        }

        this.ViewMode = false;
        this.ActionMode_PutOnHold = true;

        this.SaveButtonLabel = 'Confirm';
        this.ViewScreenDescription  = 'Work Order Activity - Put Activity On Hold';
        return null;
    }

    public PageReference ActivityOnHold_End()
    {
        if(OptimisticLockCheck() == false)
        {
            return null;
        }
        if(CanPutJobOnHoldCheck() == false)
        {
            return null;
        }

        system.debug('Executing PutOnHold');

        ActionName = VTT_Utilities.LOGENTRY_JOBONHOLD;
        NewTradesmanStatus = VTT_Utilities.TRADESMAN_STATUS_NOTWORKING;
        NewActivityStatus = VTT_Utilities.ACTIVITY_STATUS_ONHOLD;

        List<Contact> TradesmanListforUpdate = new List<Contact>();  
        for(AssignedTradesman tradesmenRec : AssignedTradesmenList)
        {
            //update statuses for assigned tradesmen only if they currently working on the same activity
            if(tradesmenRec.Tradesman.Current_Work_Order_Activity__c == woActivity.ID)
            {

                TradesmanListforUpdate.add(tradesmenRec.Tradesman);
            }
        }
        try
        {
            LogEntryAction(
                    Tradesman,
                    WoActivity,
                    ActionName,
                    CurrentLatitude, 
                    CurrentLongitude, 
                    ActionComment,
                    NewTradesmanStatus,
                    NewActivityStatus,
                    OnHoldStatusReason,
                    TradesmanListforUpdate
                    );
            return ReloadCurrentPage();  
        }
        catch(Exception ex)
        {
            VTT_Utilities.logError(ex);
        }
        return null;

    } 


    public PageReference ReloadCurrentPage()
    {
        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
        pageRef.getParameters().put('id', woActivity.Id);
        pageRef.setRedirect(true);
        return pageRef; 
    }


    private void LogEntryAction(
        Contact pTradesman,
        Work_Order_Activity__c pWoActivity,
        String pActionName,
        Decimal pCurrentLatitude, 
        Decimal pCurrentLongitude, 
        String pActionComment,
        String pNewTradesmanStatus,
        String pNewActivityStatus,
        String pNewActivityStatusReason,
        List<Contact> pTradesmanList
        )
    {
        system.debug('ActionComment');
        system.debug(pActionComment);

        system.debug('AssignedTradesmenList');
        system.debug(pTradesmanList);

        List<Work_Order_Activity_Log_Entry__c> logEntryList = new List<Work_Order_Activity_Log_Entry__c>();


        Work_Order_Activity_Log_Entry__c lastLogEntry = VTT_Utilities.GetLastLogEntry(pTradesman, pWoActivity);

        if(lastLogEntry <> null && lastLogEntry.Status__c == pActionName)
        {
            system.debug('VTTApplicationException');
            throw new VTTApplicationException('Action: ' + pActionName + ' already done.');
        }

        Work_Order_Activity_Log_Entry__c logEntry = VTT_Utilities.CreateLogEntry(pTradesman, 
            pWoActivity, pActionName, pCurrentLatitude, pCurrentLongitude, pNewActivityStatusReason, pActionComment);

        logEntryList.add(logEntry);    

        List<Contact> TradesmanListforUpdate = new List<Contact>();  
        TradesmanListforUpdate.add(pTradesman);

        for(Contact tradesmenRec : pTradesmanList)
        {
                logEntry = VTT_Utilities.CreateLogEntry(tradesmenRec, 
                        pWoActivity, 
                        pActionName,
                        pCurrentLatitude,
                        pCurrentLongitude,
                        pNewActivityStatusReason, 
                        null);
                logEntryList.add(logEntry);
                TradesmanListforUpdate.add(tradesmenRec);
        }
        insert logEntryList;
        VTT_Utilities.RefreshActivityWorkDetails(woActivity);
        VTT_Utilities.UpdateTradesmanStatus(TradesmanListforUpdate, pNewTradesmanStatus, pwoActivity.ID);  
        VTT_Utilities.UpdateActivityStatus(woActivity, pNewActivityStatus, pNewActivityStatusReason);              
    }    

    private void ResetButtons()
    {
        this.ViewMode = true;
        this.ActionMode_RejectActivity = false;
        this.ActionMode_Generic = false;
        this.ActionMode_StartJobAtEquipment = false;        
        this.ActionMode_PutOnHold = false;                
        this.ActionMode_JobComplete = false;  

        this.SaveButtonLabel = 'Save';
        this.ViewScreenDescription  = 'Work Order Activity';
    }

    public Boolean CanCompleteJobCheck()
    {
        for(Contact workintradesman : currentActivityCopy.Working_Tradesmen__r)
         {
            if(workintradesman.id !=  tradesman.ID)
            {
                String message = workintradesman.Name +' is currently working on this Activity. You can\'t complete this Activity.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message)); 
                return false;
            }
         } 
         return True;       
    }

    public Boolean CanPutJobOnHoldCheck()
    {
        for(Contact workintradesman : currentActivityCopy.Working_Tradesmen__r)
         {
            if(workintradesman.id !=  tradesman.ID)
            {
                String message = workintradesman.Name +' is currently working on this Activity. You can\'t put this Activity on hold.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message)); 
                return false;
            }
         } 
         return True;       
    }



    public Boolean OptimisticLockCheck()
    {
        currentActivityCopy = ReloadWorkOrderActivity();

        if(currentActivityCopy.LastModifiedById == woActivity.LastModifiedById && 
            currentActivityCopy.LastModifiedDate == woActivity.LastModifiedDate )
        {
            return true;
        }
        else
        {
            //String message = 'This Activity was recently modified. Please reload this page.';
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message)); 
            PageReloadRequired = true;
            return false;
        }
    }    

    private Work_Order_Activity__c ReloadWorkOrderActivity()
    {
       List<Work_Order_Activity__c> result =  [
            select id, LastModifiedById, LastModifiedDate,
            (select id, Name, Tradesman_Status__c, Account.Name,
                    Phone, Tradesman_Status_Date__c
             from Working_Tradesmen__r) 
            from Work_Order_Activity__c
            where id = :woActivity.id LIMIT 1];

       if(result.size()==1)
       {
        return result[0];
       }     
       else
       {
        return new Work_Order_Activity__c();
       }
    }

    public class AssignedTradesman
    {
        public Boolean CrewMember {get; set;}
        public Contact Tradesman {get; private set;}

        public AssignedTradesman(Contact pTradesman, Boolean pSelected)
        {
            this.Tradesman = pTradesman;
            this.CrewMember = pSelected;
        }  

        public AssignedTradesman(Contact pTradesman)
        {
            this(pTradesman, false);
        }              
    } 

    public class AvailableActivity
    {
        public Boolean MarkToComplete {get; set;}
        public Work_Order_Activity__c ActivityRecord {get; private set;}

        public AvailableActivity(Work_Order_Activity__c pActivity, Boolean pSelected)
        {
            this.ActivityRecord = pActivity;
            this.MarkToComplete = pSelected;
        }  

        public AvailableActivity(Work_Order_Activity__c pActivity)
        {
            this(pActivity, false);
        }              
    } 


    public class WorkFlowAction
    {

        public String ActionName{get;set;}  
        public String NewTradesmanStatus {get; private set;}    
        public String NewActivityStatus {get; private set;}         

        public WorkFlowAction(String pActionName)
        {
            this.ActionName = pActionName;
            String[] rec = workFlowMap.get(pActionName);
            if(rec<>null)
            {
                this.NewTradesmanStatus = rec[0]; //pNewTradesmanStatus;
                this.NewActivityStatus = rec[1]; //pNewActivityStatus;                 
            }
           
        }
    }  

    public class VTTApplicationException extends Exception {}    

}