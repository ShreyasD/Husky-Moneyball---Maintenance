/*-------------------------------------------------------------------------------------------------
Author     : Sergey Makarov
Company    : Husky Energy
Description: A Global Utility class for Vendor Time Tracking
Inputs     : N/A
Test Class : VTT_UtilitiesTest
History    :24.11.15 ssd removed unused method GetVendorSupervisorEmailMap
            09.01.15 rbo removed references to rollup fields referencing Well Site Construction
            10.15.15 ssd added system admin as an admin user in IsAdminUser
            10.21.15 ssd added GetVendorSupervisorEmailMap, GetVendorAdminEmails, 
                         GetNotificationPlannerGroupEmailPerActivity for use in VTT_EmailNotifications
            10.23.15 ssd added ability to get save filters for admin and supervisor users
            11.12.15 rbo modified UpdateNotification to accmoodate 2 parameters, equipment number and
                         malfunction start date
            01.21.16 sm  modified UpdateNotification to accmoodate 2 parameters, 
                         malfunction end date, equipment indicator
            02.17.16 sm  updated GetNotificationPlannerGroupEmailPerActivity to populate Map with multiple email adresses
                         and check for User.isActive
            02.16.16 ssd Decreased time for logentry when elapsed time less than 10 min and added filter
                         to not add time if working on the same activity.
            02.22.16 ssd sd 02.22.2016 - W-000401 - If the tradesman started work from home take 
                         that start time and change tradesman status
            04.27.16 ssd Added completion check to not allow users to change the status of an activity
                         to complete if tradesmen still working on the activity.
            05.06.16 ssd Changed decision logic for Thermal facility based on name or Planner group not ending with 
                         "00". Refer to userstories W-000383 and W-000401 in AA.         
---------------------------------------------------------------------------------------------------*/ 

global without sharing class VTT_Utilities {

    public final static String ACTIVITY_STATUS_SCHEDULED = 'Scheduled';
    public final static String ACTIVITY_STATUS_NEW = 'New';    
    public final static String ACTIVITY_STATUS_STARTED = 'Started';
    public final static  String ACTIVITY_STATUS_STARTEDATSITE = 'Started at Equipment';  
    public final static  String ACTIVITY_STATUS_FINISHEDATSITE = 'Finished at Equipment'; 
    public final static  String ACTIVITY_STATUS_FINISHEDFORTHEDAY = 'Finished for the day';     
          
    public final static  String ACTIVITY_STATUS_COMPLETED = 'Completed';        
    public final static  String ACTIVITY_STATUS_CANCELLED = 'Cancelled';    
    public final static  String ACTIVITY_STATUS_ONHOLD = 'On Hold';     





    public final static  String LOGENTRY_STARTJOB = 'Start Job';        
    public final static  String LOGENTRY_STARTATSITE = 'Start at Equipment';
    public final static  String LOGENTRY_FINISHEDATSITE = 'Finished at Equipment';       
    public final static  String LOGENTRY_FINISHEDFORTHEDAY = 'Finished for the Day';    
    public final static  String LOGENTRY_JOBCOMPLETE = 'Job Complete';
    public final static  String LOGENTRY_JOBONHOLD = 'Put Job On Hold'; 
    public final static  String LOGENTRY_CANCELJOB = 'Cancel Job';   
    public final static  String LOGENTRY_AUTOCOMPLETE = 'Auto Complete';


    public final static  String TRADESMAN_STATUS_NOTWORKING = 'Not Working';
    public final static  String TRADESMAN_STATUS_STARTEDWORK = 'Started Work';        
    public final static  String TRADESMAN_STATUS_WORKING = 'Working';
    public final static  String TRADESMAN_STATUS_PREWORK = 'Pre-Work';          
    public final static  String TRADESMAN_STATUS_POSTWORK = 'Post Work';

    public final static  String WORKORDER_STATUS_AWAITINGONVENDORS = 'Awaiting On Vendor(s)';    
    public final static  String WORKORDER_STATUS_VENDORSCOMPLETE = 'Vendor(s) Complete';      
    
    // rbo 08.17.15
    public final static  String WORKORDER_STATUS_FULL_COMPLETE = 'Complete';      
    public final static  String WORKORDER_STATUS_CANCELLED = 'Cancelled';
    // rbo 08.17.15

    public final static String WORKORDER_USERSTATUS_COMPLETE = '6FCA';
    public final static String WORKORDER_USERSTATUS_INPROGRESS= '5X';


    public final static String ADMIN_PERMISSIONSET_NAME = 'HOG_VTT_Admin';
    public final static String VENDORSUPERVISOR_PERMISSIONSET_NAME = 'HOG_VTT_Vendor_Supervisor';
    public final static String USER_PERMISSIONSET_NAME = 'HOG_VTT_User';


    public final static String BU_NAME_HOG ='HEAVY OIL AND GAS - LLOYDMINSTER';


    public final static String[] WORK_CNETER_TO_IGNORE = new String[] {'OPER'};

    public final static Map<String, String> SAPActivityUserStatusMap 
        = new Map<String, String>{'3BEX' => '3BEX', 'HOLD' => 'HOLD', '4COM' => '4COM'};
    //public final static Map<String, String> SAPActivityUserStatusMap 
    //    = new Map<String, String>{'3BEX' => 'E0004', 'HOLD' => 'E0009', '4COM' => 'E0005'};


    public static Boolean UpdateActivityLogEntryInProgress = false;
    public static Boolean UpdateActivityLogInProgress = false;
    public static Boolean UpdateActivityInProgress = false;


    public static Boolean executeTriggerCode = true;  



    /*Trigger Handlers*/
    // rbo 08.17.15
    public static void TriggerBeforeInsertWorkOrderActivity(final List<Work_Order_Activity__c> pActivityList)
    {
        System.debug('TriggerBeforeInsertWorkOrderActivity');
        if(executeTriggerCode) {
            UpdateWorkOrderActivityStatus(pActivityList);
        }
    }

    public static void TriggerAfterInsertWorkOrderActivity(List<Work_Order_Activity__c>  pActivityList)
    {
        system.debug('TriggerAfterInsertWorkOrderActivity');
        if(executeTriggerCode) {
            AutoAssignActivities(pActivityList);
        }
    }

    public static void TriggerBeforeUpdateWorkOrderActivity(List<Work_Order_Activity__c> pActivityList, Map<Id, Work_Order_Activity__c> oldMap)
    {
        System.debug('TriggerBeforeUpdateWorkOrderActivity');
        if(executeTriggerCode) {
            ValidateActivityStatus(pActivityList, oldMap);
            UpdateWorkOrderActivityStatus(pActivityList, oldMap);
        }
    } 

    public static void TriggerAfterUpdateWorkOrderActivity(List<Work_Order_Activity__c>  pActivityList, Map<Id, Work_Order_Activity__c> oldMap)
    {
        system.debug('TriggerAfterUpdateWorkOrderActivity');

        if(executeTriggerCode) {
            List<Work_Order_Activity__c>  pActivityListWithChangedStatus = new List<Work_Order_Activity__c>();
            for(Work_Order_Activity__c rec : pActivityList)
            {
                Work_Order_Activity__c oldRec = oldMap.get(rec.id);
                if(oldRec.Status__c <> rec.Status__c) //status changed
                {
                    pActivityListWithChangedStatus.add(rec);
                }
            }

            if(pActivityListWithChangedStatus.size()>0)
            {
                System.debug('Calling UpdateWorkOrderStatus'); 
                UpdateWorkOrderStatus(pActivityListWithChangedStatus);
            }
        }
    }

    /***************************************************
    * Validate change made to activity status from Out
    * of the box page
    ***************************************************/
    private static void ValidateActivityStatus(final List<Work_Order_Activity__c> pActivityList, Map<Id, Work_Order_Activity__c> oldMap) {
        Set<Id> activityIds = new Set<Id>();
        Map<Id, Work_Order_Activity__c> activitiesMap;
        List<Contact> tradesmenListToUpdate = new List<Contact>();
        Boolean isAdminUser = IsAdminUser();

        //Get all acivity Ids
        for(Work_Order_Activity__c activity : pActivityList) {
            activityIds.add(activity.Id);
        }

        activitiesMap = new Map<Id, Work_Order_Activity__c>([Select Id, Name, Status__c,
                                                             (select Id, Name, Tradesman_Status__c from Working_Tradesmen__r)
                                                             From Work_Order_Activity__c
                                                             Where Id In :activityIds]);

        //If the status was changed to completed
        //by a normal (not Sys Admin or VTT Admin)
        //Check if anybody working on the activity
        for(Work_Order_Activity__c activity : pActivityList) {
            if(activity.Status__c == 'Completed' && oldMap.get(activity.Id).Status__c != 'Completed') {
                for(Contact tradesman : activitiesMap.get(activity.Id).Working_Tradesmen__r) {
                    if(tradesman.Tradesman_Status__c !=  TRADESMAN_STATUS_NOTWORKING) {
                        //there is still working tradesman 
                        if(isAdminUser) {
                            //if admin user, allow change and update tradesman status
                            tradesman.Tradesman_Status__c = TRADESMAN_STATUS_NOTWORKING;
                            tradesman.Last_Work_Order_Activity__c = tradesman.Current_Work_Order_Activity__c;
                            tradesman.Current_Work_Order_Activity__c = null;
                            tradesman.Tradesman_Still_Working__c = false;
                            tradesmenListToUpdate.add(tradesman);
                        } else {
                            //if not admin user, don't allow change
                            activity.addError('Cannot mark this activity as completed, tradesmen still working.');
                        }
                    }
                }
            }
        }

        update tradesmenListToUpdate;
    }
        
    /***************************************************
     * Update activity status based on Work Order status
     ***************************************************/       
    private static void UpdateWorkOrderActivityStatus
    (
        final List<Work_Order_Activity__c> pActivityList
    )
    {
        MaintenanceServicingUtilities.executeTriggerCode = false;

        Set<Id> workOrderSet = new Set<Id>();  

        for(Work_Order_Activity__c rec : pActivityList) 
        {
            workOrderSet.add(rec.Maintenance_Work_Order__c);
        }                 

        final List<HOG_Maintenance_Servicing_Form__c> workOrderList = 
            [
                Select 
                    Id, 
                    TECO__c, 
                    DLFL__c, 
                    CLSD__c 
                From HOG_Maintenance_Servicing_Form__c 
                Where Id In :workOrderSet
            ];

        Map<Id, HOG_Maintenance_Servicing_Form__c> workOrderMap = new Map<Id, HOG_Maintenance_Servicing_Form__c>();

        for(HOG_Maintenance_Servicing_Form__c workOrder : workOrderList)
        {
            workOrderMap.put(workOrder.Id, workOrder);
        }

        for(Work_Order_Activity__c activityRec : pActivityList) 
        {
            if (workOrderMap.containskey(activityRec.Maintenance_Work_Order__c))
            {
                final HOG_Maintenance_Servicing_Form__c workOrderRecord = workOrderMap.get(activityRec.Maintenance_Work_Order__c);

                if (workOrderRecord.DLFL__c)
                    activityRec.Status__c = ACTIVITY_STATUS_CANCELLED;
                else
                {
                    if (workOrderRecord.TECO__c || workOrderRecord.CLSD__c)
                        activityRec.Status__c = ACTIVITY_STATUS_COMPLETED;
                }
            }
        }                               
    }

    public static void TriggerAfterUpdateWorkOrderActivityLogEntry(List<Work_Order_Activity_Log_Entry__c>  pLogEntryList,   Map<Id, Work_Order_Activity_Log_Entry__c> oldMap)
    {
        UpdateActivityLogEntry(pLogEntryList);
        UpdateActivityLog(pLogEntryList); 
    }    
    public static void TriggerAfterDeleteWorkOrderActivityLogEntry(List<Work_Order_Activity_Log_Entry__c>  pLogEntryList)
    {
        UpdateActivityLogEntry(pLogEntryList);
        UpdateActivityLog(pLogEntryList); 
    }      
    public static void TriggerAfterInsertWorkOrderActivityLogEntry(List<Work_Order_Activity_Log_Entry__c>  pLogEntryList)
    {
        UpdateActivityLogEntry(pLogEntryList);
        UpdateActivityLog(pLogEntryList); 
    }    

    /*********************************************************
     * Update activity status based on User Status on Activity
     *********************************************************/
    private static void UpdateWorkOrderActivityStatus(List<Work_Order_Activity__c> pActivityList, Map<Id, Work_Order_Activity__c> oldMap)
    {
        for(Work_Order_Activity__c rec : pActivityList)
        {
            Work_Order_Activity__c oldRec = oldMap.get(rec.id);
            if( (!String.isBlank(oldRec.User_Status__c) && !String.isBlank(rec.User_Status__c)) &&
                oldRec.User_Status__c <> rec.User_Status__c && 
                (oldRec.User_Status__c.contains('HOLD') && !rec.User_Status__c.contains('HOLD'))) //User Status changed from On-Hold
            {
                //We are not using UpdateActivityStatus, because the User Status change is triggered from SAP
                rec.Status__c = ACTIVITY_STATUS_SCHEDULED;
                rec.Status_Reason__c = null;
            }
        }
    }

    public static Boolean CanChangeActivityStatusFromTo(String pOldActivityStatus, String pNewActivityStatus)
    {
        if(
            (pOldActivityStatus== null && pNewActivityStatus == ACTIVITY_STATUS_STARTED)             
            || (pOldActivityStatus == ACTIVITY_STATUS_SCHEDULED && pNewActivityStatus == ACTIVITY_STATUS_STARTED)              
            || (pOldActivityStatus == ACTIVITY_STATUS_NEW && pNewActivityStatus == ACTIVITY_STATUS_STARTED)
            || (pOldActivityStatus == ACTIVITY_STATUS_ONHOLD && pNewActivityStatus == ACTIVITY_STATUS_STARTED)
            || (pOldActivityStatus == ACTIVITY_STATUS_STARTED && pNewActivityStatus == ACTIVITY_STATUS_STARTEDATSITE)
            || (pOldActivityStatus == ACTIVITY_STATUS_STARTEDATSITE && pNewActivityStatus == ACTIVITY_STATUS_FINISHEDATSITE)
            || (pOldActivityStatus == ACTIVITY_STATUS_FINISHEDATSITE && pNewActivityStatus == ACTIVITY_STATUS_STARTEDATSITE)
            || (pOldActivityStatus == ACTIVITY_STATUS_FINISHEDATSITE && pNewActivityStatus == ACTIVITY_STATUS_FINISHEDFORTHEDAY)              
            || (pOldActivityStatus == ACTIVITY_STATUS_FINISHEDATSITE && pNewActivityStatus == ACTIVITY_STATUS_COMPLETED)
            || (pOldActivityStatus == ACTIVITY_STATUS_FINISHEDFORTHEDAY && pNewActivityStatus == ACTIVITY_STATUS_STARTED)             
            || pNewActivityStatus == ACTIVITY_STATUS_COMPLETED
            || pNewActivityStatus == ACTIVITY_STATUS_ONHOLD
        )
        {
            return true;
        }
        system.debug('Activity Status Update from ' + pOldActivityStatus + ' to ' + pNewActivityStatus + ' is not allowed');
        return false;
    }

    public static void UpdateWorkOrderStatus(List<Work_Order_Activity__c>  pActivityList)
    {
        
        system.debug('UpdateWorkOrderStatus executing');
        
        //-- rbo 08.05.15
        Boolean otherActivityStatusIncomplete = false;
        Integer logWorkCount = 0; 
        Integer logWorkIncompleteCount = 0;

        //-- rbo 09.01.15
        /*      
        Integer wscCount = 0;
        Integer wscIncompleteCount = 0;
        */
        //-- rbo 09.01.15       
         
        Integer vttActivitiesCount = 0;
        Integer vttActivitiesNewCount = 0;
        Integer vttActivitiesCompletedCount = 0; 
        //-- rbo 08.05.15
        
        //-- rbo 08.05.15
        //prevent execution of Rey's awesome trigger
        MaintenanceServicingUtilities.executeTriggerCode = false;
        //-- rbo 08.05.15

        Set<ID> workOrderSet = new Set<Id>();  
        for(Work_Order_Activity__c rec : pActivityList) 
        {
            workOrderSet.add(rec.Maintenance_Work_Order__c);
        }                 

        //-- rbo 09.01.15        
        /*
        List<HOG_Maintenance_Servicing_Form__c> workOrderList = [select id, User_Status_Code__c,
        VTT_Activities_Count__c, VTT_Activities_Completed_Count__c, VTT_Activities_In_Progress_Count__c, VTT_Activities_On_Hold_Count__c,
        Incomplete_Activity_Status_Count__c, WSC_Incomplete_Service_Status_Count__c, 
        VTT_Activities_New_Count__c, Maintenance_Servicing_Vendors_Count__c, WSC_Count__c,
        TECO__c, CLSD__c, DLFL__c,
        (select id, Status__c from Work_Order_Activities__r WHERE SAP_Deleted__c = false and Work_Center__c not in :WORK_CNETER_TO_IGNORE)
        from HOG_Maintenance_Servicing_Form__c 
        where id in :workOrderSet]; 
        */
        
        List<HOG_Maintenance_Servicing_Form__c> workOrderList = [select id, User_Status_Code__c,
        VTT_Activities_Count__c, VTT_Activities_Completed_Count__c, VTT_Activities_In_Progress_Count__c, VTT_Activities_On_Hold_Count__c,
        Incomplete_Activity_Status_Count__c, 
        VTT_Activities_New_Count__c, Maintenance_Servicing_Vendors_Count__c,
        TECO__c, CLSD__c, DLFL__c,
        (select id, Status__c from Work_Order_Activities__r WHERE SAP_Deleted__c = false and Work_Center__c not in :WORK_CNETER_TO_IGNORE)
        from HOG_Maintenance_Servicing_Form__c 
        where id in :workOrderSet]; 
        //-- rbo 09.01.15

        system.debug(workOrderList);

        List<HOG_Maintenance_Servicing_Form__c> workOrderListToUpdate = new List<HOG_Maintenance_Servicing_Form__c>();

        for(HOG_Maintenance_Servicing_Form__c wo_rec : workOrderList) 
        {           
            system.debug(wo_rec.Work_Order_Activities__r);

            //for some reason I can't rely on the rollup formulas on the work order object 
            //when I update sttus of the activity, so I have to query child records and check status for each of them
            Boolean allActivitiesCompleted = true;
            Boolean someActivitiesOnHold = false;
            Boolean someActivitiesInProgress = false;

            //-- rbo 08.05.15            
            vttActivitiesCount = 0;
            vttActivitiesNewCount = 0;
            vttActivitiesCompletedCount = 0; 
            //-- rbo 08.05.15
            
            for(Work_Order_Activity__c activityRec: wo_rec.Work_Order_Activities__r)
            {
                if(activityRec.Status__c <> ACTIVITY_STATUS_COMPLETED)
                {
                  allActivitiesCompleted = false;
                }

                if(activityRec.Status__c == ACTIVITY_STATUS_ONHOLD)
                {
                  someActivitiesOnHold = true;
                }
                if(activityRec.Status__c == ACTIVITY_STATUS_STARTED
                   || activityRec.Status__c == ACTIVITY_STATUS_STARTEDATSITE
                   || activityRec.Status__c == ACTIVITY_STATUS_FINISHEDATSITE
                   || activityRec.Status__c == ACTIVITY_STATUS_FINISHEDFORTHEDAY)
                {
                  someActivitiesInProgress = true;
                }                

                // rbo 08.05.15
                vttActivitiesCount++;
                vttActivitiesNewCount = 
                    (activityRec.Status__c == ACTIVITY_STATUS_NEW || String.IsBlank(activityRec.Status__c)) 
                    ? vttActivitiesNewCount + 1 : vttActivitiesNewCount;
                vttActivitiesCompletedCount = 
                    (activityRec.Status__c == ACTIVITY_STATUS_COMPLETED) 
                    ? vttActivitiesCompletedCount + 1 : vttActivitiesCompletedCount;  
                // rbo 08.05.15
            }

            String newWorkOrderUserStatus = wo_rec.User_Status_Code__c;

            // All activities are completed?
            //wo_rec.VTT_Activities_Count__c == wo_rec.VTT_Activities_Completed_Count__c

            //-- rbo 08.05.15
            //if(allActivitiesCompleted && wo_rec.Incomplete_Activity_Status_Count__c == 0 && wo_rec.WSC_Incomplete_Service_Status_Count__c == 0) 
            logWorkCount = wo_rec.Maintenance_Servicing_Vendors_Count__c == null ? 0 : (Integer)wo_rec.Maintenance_Servicing_Vendors_Count__c;
            logWorkIncompleteCount = wo_rec.Incomplete_Activity_Status_Count__c == null ? 0 : (Integer)wo_rec.Incomplete_Activity_Status_Count__c;
            
            //-- rbo 09.01.15
            /*          
            wscCount = wo_rec.WSC_Count__c == null ? 0 : (Integer)wo_rec.WSC_Count__c;
            wscIncompleteCount = wo_rec.WSC_Incomplete_Service_Status_Count__c == null ? 0 : (Integer)wo_rec.WSC_Incomplete_Service_Status_Count__c;                            
            otherActivityStatusIncomplete = (logWorkIncompleteCount > 0 || wscIncompleteCount > 0
                || (vttActivitiesNewCount <= 0 ? vttActivitiesCount - vttActivitiesCompletedCount > 0 : (logWorkCount <= 0 && wscCount <= 0) 
                || (vttActivitiesNewCount <> vttActivitiesCount)));
            */
            
            otherActivityStatusIncomplete = (logWorkIncompleteCount > 0
                || (vttActivitiesNewCount <= 0 ? vttActivitiesCount - vttActivitiesCompletedCount > 0 : logWorkCount <= 0 
                || (vttActivitiesNewCount <> vttActivitiesCount)));
            //-- rbo 09.01.15
                                                            
            system.debug('otherActivityStatusIncomplete : ' + otherActivityStatusIncomplete);
            system.debug('allActivitiesCompleted : ' + allActivitiesCompleted);
            system.debug('someActivitiesInProgress : ' + someActivitiesInProgress);
            system.debug('VTT_Activities_Count__c : ' + wo_rec.VTT_Activities_Count__c);
            system.debug('VTT_Activities_Completed_Count__c : ' + wo_rec.VTT_Activities_Completed_Count__c);
            system.debug('VTT_Activities_New_Count__c : ' + wo_rec.VTT_Activities_New_Count__c);
                                    
            if(allActivitiesCompleted)
            //-- rbo 08.05.15            
            {

                //-- rbo 08.05.15            
                //wo_rec.Service_Status__c = WORKORDER_STATUS_VENDORSCOMPLETE;
                //-- rbo 08.17.15                
                //wo_rec.Service_Status__c = otherActivityStatusIncomplete ? WORKORDER_STATUS_AWAITINGONVENDORS : WORKORDER_STATUS_VENDORSCOMPLETE;
                if (wo_rec.DLFL__c)
                    wo_rec.Service_Status__c = WORKORDER_STATUS_CANCELLED;
                else
                {
                    if (wo_rec.TECO__c || wo_rec.CLSD__c)
                        wo_rec.Service_Status__c = WORKORDER_STATUS_FULL_COMPLETE;
                    else
                        wo_rec.Service_Status__c = otherActivityStatusIncomplete ? WORKORDER_STATUS_AWAITINGONVENDORS : WORKORDER_STATUS_VENDORSCOMPLETE;
                }                
                //-- rbo 08.17.15                
                //-- rbo 08.05.15            
                
                newWorkOrderUserStatus = WORKORDER_USERSTATUS_COMPLETE;
                workOrderListToUpdate.add(wo_rec);
            }
            // Is there any activity in progress?
            //wo_rec.VTT_Activities_In_Progress_Count__c > 0 
            else if(someActivitiesInProgress)
            {
               wo_rec.Service_Status__c = WORKORDER_STATUS_AWAITINGONVENDORS;
               newWorkOrderUserStatus = WORKORDER_USERSTATUS_INPROGRESS;
               workOrderListToUpdate.add(wo_rec);
            }
            //wo_rec.VTT_Activities_Count__c > wo_rec.VTT_Activities_Completed_Count__c
            else if(allActivitiesCompleted==false)
            {               
                
               //-- rbo 08.05.15            
               //wo_rec.Service_Status__c = WORKORDER_STATUS_AWAITINGONVENDORS;                               
               //-- rbo 08.17.15                
               //wo_rec.Service_Status__c = otherActivityStatusIncomplete ? WORKORDER_STATUS_AWAITINGONVENDORS : WORKORDER_STATUS_VENDORSCOMPLETE;
               if (wo_rec.DLFL__c)
                  wo_rec.Service_Status__c = WORKORDER_STATUS_CANCELLED;
               else
               {
                  if (wo_rec.TECO__c || wo_rec.CLSD__c)
                     wo_rec.Service_Status__c = WORKORDER_STATUS_FULL_COMPLETE;
                  else
                     wo_rec.Service_Status__c = otherActivityStatusIncomplete ? WORKORDER_STATUS_AWAITINGONVENDORS : WORKORDER_STATUS_VENDORSCOMPLETE;
               }                
               //-- rbo 08.17.15
               //-- rbo 08.05.15            

               workOrderListToUpdate.add(wo_rec);
            }            

            if(newWorkOrderUserStatus <> wo_rec.User_Status_Code__c)
            {
                SAP_UpdateWorkOrderStatus(wo_rec.ID, newWorkOrderUserStatus);
            }

        }  

        update workOrderListToUpdate;
    }

    public static void UpdateActivityStatus(Work_Order_Activity__c pWorkOrderActivity, String pNewActivityStatus, String pNewActivityStatusReason)
    {
        //-- rbo 08.05.15
        MaintenanceServicingUtilities.executeTriggerCode = false;
        //-- rbo 08.05.15
        
        //update Activity Status 
        system.debug('VTT_Utilities.UpdateActivityStatus executing...');
        system.debug('UpdateActivityStatus for Activity: ' + pWorkOrderActivity.Name);
        system.debug('Status before: ' + pWorkOrderActivity.Status__c);
        system.debug('Status after: ' + pNewActivityStatus);

        if(pWorkOrderActivity <> null && pNewActivityStatus <> null && pWorkOrderActivity.Status__c <> pNewActivityStatus &&
            CanChangeActivityStatusFromTo(pWorkOrderActivity.Status__c, pNewActivityStatus))
        {
            if(pNewActivityStatus == ACTIVITY_STATUS_FINISHEDFORTHEDAY)
            {
                Work_Order_Activity__c woActivity = [select id, name,
                 (select id, name, Tradesman_Status__c from Working_Tradesmen__r) 
                 from Work_Order_Activity__c 
                 where id = :pWorkOrderActivity.id limit 1];
                 for(Contact tradesman : woActivity.Working_Tradesmen__r)
                 {
                    if(tradesman.Tradesman_Status__c !=  TRADESMAN_STATUS_NOTWORKING)
                    {
                        return; //there is still working tradesman, we can't update activity status to FINISH FOR THE DAY
                    }
                 }
            }
            system.debug('Status updating:');
			         
            pWorkOrderActivity.Status__c = pNewActivityStatus == null ? pWorkOrderActivity.Status__c : pNewActivityStatus;
            pWorkOrderActivity.Status_Reason__c = pNewActivityStatusReason == null ? pWorkOrderActivity.Status_Reason__c : pNewActivityStatusReason;
            update pWorkOrderActivity;

            //Now lets call out Mule to update activity user status in SAP if we have to
            String newActivityUserStatus = pWorkOrderActivity.User_Status__c;                
            if( pNewActivityStatus == ACTIVITY_STATUS_STARTED
                ||pNewActivityStatus == ACTIVITY_STATUS_STARTEDATSITE                   
                ||pNewActivityStatus == ACTIVITY_STATUS_FINISHEDATSITE  
                ||pNewActivityStatus == ACTIVITY_STATUS_FINISHEDFORTHEDAY                      
                )
            {
               newActivityUserStatus = '3BEX'; //
            }
            if(pNewActivityStatus == ACTIVITY_STATUS_ONHOLD)
            {
               newActivityUserStatus = 'HOLD';
            }                  
            if(pNewActivityStatus == ACTIVITY_STATUS_COMPLETED)
            {
               newActivityUserStatus = '4COM';
            }                
            if(pWorkOrderActivity.User_Status__c <> newActivityUserStatus)
            {
                String newActivityUserStatusCode = SAPActivityUserStatusMap.get(newActivityUserStatus);
                SAP_UpdateWorkOrderActivityStatus(pWorkOrderActivity.Id, newActivityUserStatusCode);                    
            }
        }
    }
    @Future(callout=true)
    public static void SAP_UpdateWorkOrderActivityStatus(ID pWorkOrderActivityID, String pNewActivityUserStatus)
    {

        Work_Order_Activity__c pWorkOrderActivity = [select id, name, Operation_Number__c, Sub_Operation_Number__c,
        Maintenance_Work_Order__r.Work_Order_Number__c, Description__c, Work_Details__c from Work_Order_Activity__c where id=:pWorkOrderActivityID LIMIT 1][0];


        SAPHOGWorkOrderServices.WorkOrderPort  workOrderService = new SAPHOGWorkOrderServices.WorkOrderPort();
        SAPHOGWorkOrderServices.UpdateWorkOrderActivitiesResponse response;
        SAPHOGWorkOrderServices.UpdateWorkOrderActivityRequest[] requestList = new SAPHOGWorkOrderServices.UpdateWorkOrderActivityRequest[]{};

        SAPHOGWorkOrderServices.UpdateWorkOrderActivityRequest request = new SAPHOGWorkOrderServices.UpdateWorkOrderActivityRequest();
        request.ActivityNumber = pWorkOrderActivity.Operation_Number__c;
        request.ActivitySubNumber = pWorkOrderActivity.Sub_Operation_Number__c;                
        request.WorkOrderNumber = pWorkOrderActivity.Maintenance_Work_Order__r.Work_Order_Number__c;                                
        request.UserStatus = pNewActivityUserStatus; //pWorkOrderActivity.User_Status__c;                                
        request.MainDescription = pWorkOrderActivity.Description__c;
        //request.MainLongDescription = pWorkOrderActivity.Work_Details__c;               

        system.debug('Request:');
        system.debug(request);


        requestList.add(request);
        try
        {
            response = workOrderService.UpdateWorkOrderActivities(requestList);
            system.debug('UpdateWorkOrderActivities Callout...');
            system.debug('Response:');
            system.debug(response);
            //return true;
        }
        catch(Exception e)
        {
            response = null;                                
            System.debug('An unexpected error has occurred: ' + e.getMessage());
            //logError('Service is not available because of the following error: ' + e.getMessage());
            //return false;
        }       
    }
    @Future(callout=true)
    public static void SAP_UpdateWorkOrderStatus(ID pWorkOrderID, String pNewUserStatus)
    {
        SAPHOGWorkOrderServices.WorkOrderPort  workOrderService = new SAPHOGWorkOrderServices.WorkOrderPort();
        SAPHOGWorkOrderServices.UpdateWorkOrderResponse response;

        //SAPHOGWorkOrderServices.UpdateWorkOrderRequest[] requestList = new SAPHOGWorkOrderServices.UpdateWorkOrderRequest[]{};

        //SAPHOGWorkOrderServices.UpdateWorkOrderRequest request = new SAPHOGWorkOrderServices.UpdateWorkOrderRequest();
        //request.WorkOrderNumber = pWorkOrder.Work_Order_Number__c;                                
        //request.UserStatus = pNewUserStatus;                                
             

        //requestList.add(request);
        system.debug('UpdateWorkOrder Callout...');
        system.debug('Work Order ID:' + pWorkOrderID);
        system.debug('Work Order User Status:' + pNewUserStatus);
        HOG_Maintenance_Servicing_Form__c pWorkOrder = [select id, name, Work_Order_Number__c, 
                System_Status_Code__c,
                User_Status_Code__c,
                SAP_Changed_Date__c,
                SAP_Changed_By__c
        from HOG_Maintenance_Servicing_Form__c where id = :pWorkOrderID limit 1][0];
        try
        {
            response = workOrderService.UpdateWorkOrder(pWorkOrder.Work_Order_Number__c,null,null,null,null,null,null,pNewUserStatus,pWorkOrder.SAP_Changed_Date__c,pWorkOrder.SAP_Changed_By__c,null);
            
            system.debug('Response:');
            system.debug(response);
            //return true;
        }
        catch(Exception e)
        {
            response = null;                                
            System.debug('An unexpected error has occurred: ' + e.getMessage());
            //logError('Service is not available because of the following error: ' + e.getMessage());
            //return false;
        }       
    }
    @Future(callout=true)
    public static void SAP_UpdateNotification
    (
      //final HOG_Maintenance_Servicing_Form__c notificationFormRecord, 
      String pActivityRecordID
    )
    {

        system.debug('SAP_UpdateNotification executing...');

        //sm 01/22/16 pass mal fun starte and mal func end date

        Work_Order_Activity__c activityRecord = [select id, name, 
        Maintenance_Work_Order__c,
        Maintenance_Work_Order__r.On_Hold__c,
        Maintenance_Work_Order__r.Equipment__c,
        Maintenance_Work_Order__r.Equipment__r.Catalogue_Code__c,
        Maintenance_Work_Order__r.Notification_Number__c,
        Maintenance_Work_Order__r.Main_Work_Centre__c,
        Operation_Number__c,
        Part_Key__c,
        Cause__c,
        Cause__r.Cause_Code__c,
        Cause__r.Code_Group__c,
        Cause_Text__c,
        Work_Details__c,
        Part__r.Catalogue_Code__c,
        Part__r.Part_Code__c,
        Part__r.Part_Description__c,
        Damage__c,
        Damage__r.Damage_Code__c,
        Damage_Text__c,
        Assigned_Vendor__c, Status__c, Status_Reason__c, User_Status__c,
        Maintenance_Work_Order__r.HOG_Service_Request_Notification_Form__r.Malfunction_Start_Date__c ,
        Maintenance_Work_Order__r.VTT_Activities_Count__c,
        Maintenance_Work_Order__r.VTT_Activities_Completed_Count__c
        from Work_Order_Activity__c where id=:pActivityRecordID][0];

        system.debug(activityRecord);

        DateTime malfunctionStartDate = activityRecord.Maintenance_Work_Order__r.HOG_Service_Request_Notification_Form__r.Malfunction_Start_Date__c;

        //sm if all activities are complete pass today as mal fun end date        
        DateTime malfunctionEndDate = activityRecord.Maintenance_Work_Order__r.VTT_Activities_Count__c == activityRecord.Maintenance_Work_Order__r.VTT_Activities_Completed_Count__c ?
                            DateTime.Now() : null ;

        String returnPartKey = null;
        If (activityRecord != null 
            && activityRecord.Maintenance_Work_Order__r.Notification_Number__c !=null
            && integer.valueof(activityRecord.Maintenance_Work_Order__r.Notification_Number__c) !=0)
        {
            
            HOG_Cause__c causeRecord = 
                MaintenanceServicingGlobal.GetCauseCodeRecord(String.isBlank(activityRecord.Cause__c) 
                    ? MaintenanceServicingUtilities.settingsHOG.Maintenance_WO_Default_Cause_Code__c
                    : activityRecord.Cause__r.Cause_Code__c);
                                        
            String causeCode = causeRecord.Cause_Code__c;
            String causeCodeGroup = causeRecord.Code_Group__c;

            system.debug(causeRecord);


            String notificationNumber = activityRecord.Maintenance_Work_Order__r.Notification_Number__c;            
            String partCodeGroup = activityRecord.Part__r.Catalogue_Code__c;
            String partCode = activityRecord.Part__r.Part_Code__c;

            //SM 01.07.16
            //Today we found out that glorious MuleSof always create partKey = 0001 when we pass null as a partkey parameter
            //so we can't pass null or multiple activities as a part key
            //We decided to use Operation_Number__c instead
            String partKey = activityRecord.Operation_Number__c; //activityRecord.Operation_Number__c; //Part_Key__c;

            String damageCodeGroup = activityRecord.Part__r.Part_Code__c;
            String damageCode = activityRecord.Damage__r.Damage_Code__c;
            String damageDescription = activityRecord.Damage_Text__c;
            String newDamageLongDescription = null;
            //String causeCodeGroup = notificationFormRecord.Cause__r.Code_Group__c;
            //String causeCode = notificationFormRecord.Cause__r.Cause_Code__c;
            String causeDescription = activityRecord.Cause_Text__c;
            String newCauseLongDescription = activityRecord.Work_Details__c;
            String mainDescription = null; /*activityRecord.Work_Details__c;*/
            String mainLongDescription = null;

            System.debug('SAP_UpdateNotification->mainDescription: ' + mainDescription);
            
            // rbo 04.20.15 set to null values, no need to update these in SAP          
            //String coding = notificationFormRecord.MAT_Code__c;
            //String codingGroup = notificationFormRecord.HOG_Service_Request_Notification_Form__r.HOG_Work_Order_Type__r.HOG_Notification_Type__r.HOG_Service_Code_Group__r.Code_Group__c;
            String coding = null;
            String codingGroup = null;
            //
            
            String mainWorkCenter = activityRecord.Maintenance_Work_Order__r.Main_Work_Centre__c;
            DateTime lastChangedDate = null;
            String lastChangedBy = null;
            String priority = null;

            SAPHOGNotificationServices.NotificationPort notification = new SAPHOGNotificationServices.NotificationPort();

            system.debug('partKey:' + partKey);

            try
            {
                SAPHOGNotificationServices.UpdateNotificationResponse notificationResponse = notification.UpdateNotification
                    (
                        notificationNumber,
                        causeCodeGroup,
                        causeCode,
                        causeDescription,
                        newCauseLongDescription,
                        damageCodeGroup,
                        damageCode,
                        damageDescription,
                        newDamageLongDescription,
                        partCodeGroup,
                        partCode,
                        partKey,
                        mainDescription,
                        mainLongDescription,
                        coding,
                        codingGroup,
                        mainWorkCenter,
                        priority,
                        lastChangedDate,
                        lastChangedBy,
                        null, // equipment number, passing null value means retaining the current one
                        malfunctionStartDate, // malfunction start date, passing null value means retaining the current one
                        malfunctionEndDate,
                        null
                    );

                if (notificationResponse != null)
                {
                    //returnPartKey = notificationResponse.type_x ? notificationResponse.Notification.Items.NotificationItem[0].ItemKey : null;
                    //SM 1/27/16 we need last element of items
                    Integer itemIndex = notificationResponse.Notification.Items.NotificationItem.size() - 1 ; //get last element index
                    returnPartKey = notificationResponse.type_x ? notificationResponse.Notification.Items.NotificationItem[itemIndex].ItemKey : null;
                    activityRecord.Part_Key__c = returnPartKey;
                    update activityRecord; 
                }
  
            }
            catch(Exception e)
            {
                System.debug('An unexpected error has occurred: ' + e.getMessage());
                //logError('An unexpected error has occurred: ' + e.getMessage());
            }                                                                                                          
        }

        

        system.debug('PartKey: ' + returnPartKey);
        //return returnPartKey;
    }

    public static Work_Order_Activity_Log_Entry__c GetLastLogEntry(Contact pTradesman, 
        Work_Order_Activity__c pWoActivity)
    {
        List<Work_Order_Activity_Log_Entry__c> logEntryList = [select id, name, Status__c
        FROM Work_Order_Activity_Log_Entry__c
        WHERE Tradesman__c = :pTradesman.ID
        AND Work_Order_Activity__c = :pWoActivity.ID
        ORDER BY TimeStamp__c DESC
        LIMIT 1
        ];

        if(logEntryList.size()==1)
        {
            return logEntryList[0];
        }
        return null;
    } 

    public static void AutoCompleteActivities(
        Contact pTradesman, 
        List<Work_Order_Activity__c> pWoActivityListToComplete,
        Decimal pCurrentLatitude,
        Decimal pCurrentLongitude,
        String pComments)
    {

        system.debug('VTT_Utilities.AutoCompleteActivities  executing for activities:');
        system.debug(pWoActivityListToComplete);        

        List<Work_Order_Activity_Log_Entry__c> logEntryList = new List<Work_Order_Activity_Log_Entry__c>();

        for(Work_Order_Activity__c woActivityTocomplete : pWoActivityListToComplete)
        {
            logEntryList.add(
                CreateLogEntry(pTradesman, 
                woActivityTocomplete, 
                LOGENTRY_AUTOCOMPLETE,
                pCurrentLatitude,
                pCurrentLongitude,
                null,
                pComments)
                );

            UpdateActivityStatus(woActivityTocomplete, ACTIVITY_STATUS_COMPLETED, null);
        }
        insert logEntryList;
    }


    public static Work_Order_Activity_Log_Entry__c CreateLogEntry(Contact pTradesman, 
        Work_Order_Activity__c pWoActivity, 
        String pActionName,
        Decimal pCurrentLatitude,
        Decimal pCurrentLongitude,
        String pStatusReason,
        String pComments)
    {
        Work_Order_Activity_Log__c dailyLog;

        List<Work_Order_Activity_Log__c> logList = [select id 
                    from Work_Order_Activity_Log__c 
                    where Tradesman__c = : pTradesman.Id
                    AND Date__c = TODAY
                    AND Work_Order_Activity__c = :pWoActivity.ID LIMIT 1];
        if(logList.size() == 1)         
        {
            dailyLog = logList[0];
        }
        else
        {
            dailyLog = new Work_Order_Activity_Log__c();
            dailyLog.Date__c = Date.today();
            dailyLog.Tradesman__c =pTradesman.Id;
            dailyLog.Work_Order_Activity__c =pWoActivity.ID;
            insert dailyLog;
        }


        //if tradesman stopped working less than 10 min ago, use the time when he stopped working
        DateTime dt = Datetime.now();
        if(pTradesman.Tradesman_Status_Date__c <> null)
        {
            Decimal elapsedMinutes  =  ((dt.getTime())/1000/60) - ((pTradesman.Tradesman_Status_Date__c.getTime())/1000/60); 
            if(pTradesman.Current_Work_Order_Activity__c == null
                && pTradesman.Last_Work_Order_Activity__c != pWoActivity.Id //Not working on the same activity 
                && pTradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_NOTWORKING
                && elapsedMinutes < 10.0
                )
            {
                dt = pTradesman.Tradesman_Status_Date__c;
                dt = dt.addSeconds(5); //add additional seconds to enforce correct sorting of the log entries on Calendar page
            }            
        }

        //sd 02.22.2016 - W-000401 - If the tradesman started work from home take that start time and change tradesman status
        if(pTradesman.Tradesman_Status__c == VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK &&
            pTradesman.Tradesman_Status_Date__c != null) {
            dt = pTradesman.Tradesman_Status_Date__c;
        }

        Work_Order_Activity_Log_Entry__c logEntry = new Work_Order_Activity_Log_Entry__c();
        logEntry.Work_Order_Activity_Log_Lookup__c = dailyLog.id;
        logEntry.Work_Order_Activity__c = pWoActivity.Id;
        logEntry.Tradesman__c = pTradesman.Id;
        logEntry.TimeStamp__c = dt;
        logEntry.Coordinate__Longitude__s = pCurrentLongitude;
        logEntry.Coordinate__Latitude__s = pCurrentLatitude;
        logEntry.Status__c = pActionName;
        logEntry.Reason__c = pStatusReason;
        logEntry.Comments__c = pComments;
        return logEntry;
    }

    public static void UpdateTradesmanStartedWork(Contact pTradesman, Decimal pLatitude, Decimal pLongitude)
    {
        pTradesman.Tradesman_Status__c = VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK;
        pTradesman.Tradesman_Status_Date__c = Datetime.now();
        pTradesman.Tradesman_Status_Coordinate__Latitude__s = pLatitude;
        pTradesman.Tradesman_Status_Coordinate__Longitude__s = pLongitude;
        pTradesman.Tradesman_Still_Working__c = true;
        update pTradesman;
    }

    public static void UpdateTradesmanStatus(Contact pTradesman, String pNewTradesmanStatus, ID pWorkOrderActivityID)
    {
        if(pNewTradesmanStatus <> null)
        {
            pTradesman.Tradesman_Status__c = pNewTradesmanStatus;
            //sd 02.22.2016 - W-000401 - If the tradesman started work from home take 
            //         that start time and change tradesman status
            if(pTradesman.Tradesman_Status__c != VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK) {
                pTradesman.Tradesman_Status_Date__c = Datetime.now();
            }
            
            if(pNewTradesmanStatus == TRADESMAN_STATUS_NOTWORKING)
            {
                pTradesman.Last_Work_Order_Activity__c = pTradesman.Current_Work_Order_Activity__c;
                pTradesman.Current_Work_Order_Activity__c = null;
                pTradesman.Tradesman_Still_Working__c = false;
            }
            else
            {
                pTradesman.Current_Work_Order_Activity__c = pWorkOrderActivityID;               
            }
            update pTradesman;
        }       
    }
    
    public static void UpdateTradesmanStatus(List<Contact> pTradesmanList, String pNewTradesmanStatus, ID pWorkOrderActivityID)
    {
        if(pNewTradesmanStatus <> null)
        {
            for(Contact tradesmanRec : pTradesmanList)
            {
                tradesmanRec.Tradesman_Status__c = pNewTradesmanStatus;
                //sd 02.22.2016 - W-000401 - If the tradesman started work from home take 
                //         that start time and change tradesman status
                if(tradesmanRec.Tradesman_Status__c != VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK) {
                    tradesmanRec.Tradesman_Status_Date__c = Datetime.now();
                }

                if(pNewTradesmanStatus == TRADESMAN_STATUS_NOTWORKING)
                {
                    tradesmanRec.Last_Work_Order_Activity__c = tradesmanRec.Current_Work_Order_Activity__c;
                    tradesmanRec.Current_Work_Order_Activity__c = null;
                    tradesmanRec.Tradesman_Still_Working__c = false;
                }
                else
                {
                    tradesmanRec.Current_Work_Order_Activity__c = pWorkOrderActivityID;             
                }               
            }
            update pTradesmanList;
        }       
    }



    //Helper Methods
    public static ID GetVendorContactRecordTypeId()
    {
        return [Select Id, Name, SObjectType, DeveloperName
                From RecordType
                Where SObjectType = 'Contact'
                And DeveloperName = 'HOG_Vendor_Contact' Limit 1][0].Id;
    }

    public static ID GetVendorAccountRecordTypeID()
    {
        ID VendorAccountRecordTypeID;

        List<RecordType>  recTypes = [select id, name, sobjectType,developername from recordtype where sobjecttype = 'Account' and developername = 'HOG_Vendor_Account_Record' LIMIT 1];
        if(recTypes .size()>0)
        {
            VendorAccountRecordTypeID = recTypes[0].id; 
        }   
        return VendorAccountRecordTypeID;        
    }

    public static List<Account> GetVendorAccountList(String pSearchAccount)
    {
        ID VendorAccountRecordTypeID = GetVendorAccountRecordTypeID();       
        List<Account> accountList = Database.query('Select id, Name, (select id, name from Contacts where User__c <> null order by name limit 1000) from Account where (recordtypeID = \'' + VendorAccountRecordTypeID + '\' or Husky_AD_Companyname__c =\'0002\') and Name like \'%' + String.escapeSingleQuotes(pSearchAccount) + '%\'  order by Name ');
        return accountList;
    }

    public static List<Account> GetVendorAccountList()
    {
        ID VendorAccountRecordTypeID = GetVendorAccountRecordTypeID();
        List<Account> accountList = [select id, name,
         (select id, name from Contacts order by name limit 1000)
         from Account 
         where recordtypeID = :VendorAccountRecordTypeID 
         or Husky_AD_Companyname__c ='0002'
         order by name];        
        return accountList;
    }

    /******************************************************************************************************************
    /    * Utility function to get email address list of all Vendor Admins in the system
    *******************************************************************************************************************/
    public static List<String> GetVendorAdminEmails(List<Work_Order_Activity__c> pWorkOrderActivityList)
    {
        //Get All users with VTT_admin permission set
        PermissionSet ps = [Select Id, Name
                            From PermissionSet
                            Where Name =:VTT_Utilities.ADMIN_PERMISSIONSET_NAME];

        List<PermissionSetAssignment> psAssignments = [Select Id, Assignee.Email
                                                       From PermissionSetAssignment
                                                       Where PermissionSetId = :ps.Id];


        List<String> vendorAdminEmails = new List<String>();
        for(PermissionSetAssignment psa : psAssignments) {
            vendorAdminEmails.add(psa.Assignee.Email);
        }

        return vendorAdminEmails;
    }

    /*******************************************************************************************************************
    * Utility function to map of Lead Tradesman Email mapped to Activity
    *******************************************************************************************************************/
    public static Map<Id, List<String>> GetNotificationPlannerGroupEmailPerActivity(List<Work_Order_Activity__c> pWorkOrderActivityList, String roleType)
    {
        Set<String> plannerGroupNamesSet = new Set<String>();
        for(Work_Order_Activity__c activity : pWorkOrderActivityList) {
            plannerGroupNamesSet.add(activity.Maintenance_Work_Order__r.Planner_Group__c);
        }

        List<HOG_Planner_Group__c> plannerGroupList = [Select   Id, Name, 
                                                                (Select Id, Order_Type_Text__c, Contact__r.Email, Contact__r.User__c, Contact__r.User__r.Email, Contact__r.User__r.isActive, Work_Center__c  
                                                                 From HOG_Planner_Group_Notification_Types__r 
                                                                 WHERE Role_Type__c = :roleType) 
                                                       From HOG_Planner_Group__c
                                                       Where Name In :plannerGroupNamesSet];


        Map<Id, List<String>> tradesmanEmailPerActivty = new Map<Id, List<String>>();
        for(Work_Order_Activity__c activity : pWorkOrderActivityList) {
            for(HOG_Planner_Group__c plannerGroup : plannerGroupList) {
                if(activity.Maintenance_Work_Order__r.Planner_Group__c == plannerGroup.Name) {
                    for(HOG_Planner_Group_Notification_Type__c notificationTypeRecord : plannerGroup.HOG_Planner_Group_Notification_Types__r) {
                        if(
                            notificationTypeRecord.Order_Type_Text__c.Contains(activity.Maintenance_Work_Order__r.Order_Type__c)
                            &&
                            (
                                FieldValueMatchTheRule(activity.Work_Center__c, notificationTypeRecord.Work_Center__c)
                                || notificationTypeRecord.Work_Center__c == null
                            )
                        ) 
                        {
                            String email = null;    
                            email = notificationTypeRecord.Contact__r.User__c == null? 
                                notificationTypeRecord.Contact__r.Email : 
                                notificationTypeRecord.Contact__r.User__r.isActive?  
                                    notificationTypeRecord.Contact__r.User__r.Email : 
                                    null;

                            if(email != null)
                            {
                                if(tradesmanEmailPerActivty.containsKey(activity.Id))
                                {
                                    //add email to a email List
                                    List<String> emailList = tradesmanEmailPerActivty.get(activity.Id);
                                    emailList.add(email);
                                }
                                else
                                {
                                    List<String> emailList = new List<String>();
                                    emailList.add(email);
                                    tradesmanEmailPerActivty.put(activity.Id, emailList); 
                                }                               
                            }
  
                        }
                    }
                }
            }
        }

        return tradesmanEmailPerActivty;
    }

    /*******************************************************************************************************************
    * Utility function to get user search filters for activity tracking
    *******************************************************************************************************************/
    public static List<Work_Order_Activity_Search_Criteria__c> GetUserActivitySearchFilters(Id pUserId) 
    {
        return [Select Id, Name, Assigned_Name__c, Filter_String__c, User__c, Last_Search_Criteria_Selected__c
                From Work_Order_Activity_Search_Criteria__c
                Where User__c =: pUserId];
    }

    public static void AddUserActivitySearchFilter(List<Work_Order_Activity_Search_Criteria__c> pFilters,  
        Work_Order_Activity_Search_Criteria__c pNewFilter)
    {
        pNewFilter.Last_Search_Criteria_Selected__c = true;
                
        for(Work_Order_Activity_Search_Criteria__c filter : pFilters) {
            filter.Last_Search_Criteria_Selected__c = false;
        }
        pFilters.add(pNewFilter);
        upsert pFilters;
    }

    public static Work_Order_Activity_Search_Criteria__c UpdateLastSelectedUserActivitySearchFilter(List<Work_Order_Activity_Search_Criteria__c> pFilters,  
        Id pSelectedFilterId)
    {
        Work_Order_Activity_Search_Criteria__c selectedFilter;

        for(Work_Order_Activity_Search_Criteria__c filter : pFilters) {
            if(filter.Id == pSelectedFilterId) {
                selectedFilter = filter;
                filter.Last_Search_Criteria_Selected__c = true; //Set this as last selected so when come back to this page defaults to this filter
            } else {
                filter.Last_Search_Criteria_Selected__c = false;
            }
        }

        update pFilters;
        return selectedFilter;
    }

    public static void DeleteUserActivitySearchFilter(List<Work_Order_Activity_Search_Criteria__c> pFilters,  
        Id pSelectedFilterId)
    {
        for(Work_Order_Activity_Search_Criteria__c filter : pFilters) {
            if(filter.Id == pSelectedFilterId)
                delete filter;
        }
    }

    public static Contact LoadTradesmanInfo()
    {
        List<Contact> result = [select id, name, Tradesman_Status__c, AccountId, Tradesman_Status_Date__c, 
                                Current_Work_Order_Activity__c, Last_Work_Order_Activity__c, Tradesman_Still_Working__c,
                                Tradesman_Status_Coordinate__c, Tradesman_Start_Work_Enabled__c                         
                                from Contact where User__c = :UserInfo.getUserId()];

        Contact Tradesman;                                      
        if(result.size()==0)
        {
            //logError('User with ID:' + UserInfo.getUserId() + ' is not set up correctly. Please contact system Admin.');
            Tradesman = new Contact();
        }
        else
        {
            Tradesman = result[0];
        }
        System.debug('Tradesman');
        System.debug(Tradesman);

        return Tradesman;
    }

    public Static Boolean IsAdminUser()
    {    
    
        //lets check if user sysadmin
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String MyProflieName = PROFILE[0].Name;
        if(MyProflieName  == 'System Administrator')
        {
            return true;
        }

        //lets check if user has VTT Admin permissionset
        PermissionSet ps = [select id, name from PermissionSet where name = :ADMIN_PERMISSIONSET_NAME limit 1];
        List<PermissionSetAssignment> psalist = [select id from PermissionSetAssignment where AssigneeId =:userinfo.getUserId() and PermissionSetId =:ps.id LIMIT 1];
        if(psalist.size()>0)
        {
            return true;        
        }
        return false;
    }

    public Static Boolean IsVendorSupervisor()
    {    

        //lets check if user has VTT Supervisor permissionset
        PermissionSet ps = [select id, name from PermissionSet where name = :VENDORSUPERVISOR_PERMISSIONSET_NAME limit 1];
        List<PermissionSetAssignment> psalist = [select id from PermissionSetAssignment where AssigneeId =:userinfo.getUserId() and PermissionSetId =:ps.id LIMIT 1];
        if(psalist.size()>0)
        {
            return true;        
        }
        return false;
    }

    public Static Boolean IsThermalActivity(Id pActivityId) 
    {
        //Work_Order_Activity__c activity = [Select Id, Name, Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__r.Thermal_Facility__c
        //                                   From Work_Order_Activity__c
        //                                   Where Id =: pActivityId];
        //return activity.Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__r.Thermal_Facility__c;

        //ssd 05.05.2016 Decision logic change to decide Thermal facility
        Work_Order_Activity__c activity = [Select Id, Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__c, Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__r.Name,
                                                  Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__r.Planner_Group__c
                                           From Work_Order_Activity__c
                                           Where Id = :pActivityId];

        if(activity.Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__c == null)
            return false;

        Boolean isThermalInName = activity.Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__r.Name.containsIgnoreCase('THERMAL');
        String plannerGroup = activity.Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__r.Planner_Group__c;
        Boolean isPlannerGroupThermal = (String.isBlank(plannerGroup)) ? false : !plannerGroup.endsWithIgnoreCase('00');
        
        return (isThermalInName || isPlannerGroupThermal);
    } 


    //Auto-Assign Activities Logic
    public static void AutoAssignActivities(List<Work_Order_Activity__c>  pActivityList)
    {       

        //-- rbo 08.05.15
        MaintenanceServicingUtilities.executeTriggerCode = false;
        //-- rbo 08.05.15
        
        Set<ID> activitySet = new Set<Id>();    
        Set<String>  recipientSet = new Set<String>();
        Set<String>  unloadingPointSet = new Set<String>();        
        Set<String>  workCenterSet = new Set<String>();
        Set<String>  matCodeSet = new Set<String>();
        Set<String>  plantSectionSet = new Set<String>();
        Set<String>  plannerGroupSet = new Set<String>();       
        Set<String>  orderTypeSet = new Set<String>();      

        for(Work_Order_Activity__c rec : pActivityList) 
        {
            activitySet.add(rec.ID);
        }
        
        List<Work_Order_Activity__c> activityList = [select id, Name, 
        Recipient__c,  Work_Center__c,
        Maintenance_Work_Order__r.MAT_Code__c,
        Maintenance_Work_Order__r.Plant_Section__c,
        Maintenance_Work_Order__r.Planner_Group__c,
        Maintenance_Work_Order__r.Order_Type__c,
        Maintenance_Work_Order__r.Work_Order_Number__c, 
        Maintenance_Work_Order__r.Order_Description__c, 
        Maintenance_Work_Order__r.Description_of_Equipment__c,
        Maintenance_Work_Order__r.Functional_Location__c,
        Unloading_Point__c
        FROM Work_Order_Activity__c
        WHERE id in :activitySet
        and (SAP_Assigned__c = null or SAP_Assigned__c = 0 )];
        
        for(Work_Order_Activity__c rec : activityList)  
        {
            recipientSet.add(rec.Recipient__c);
            workCenterSet.add(rec.Work_Center__c);          
            matCodeSet.add(rec.Maintenance_Work_Order__r.MAT_Code__c);
            plantSectionSet.add(rec.Maintenance_Work_Order__r.Plant_Section__c);            
            plannerGroupSet.add(rec.Maintenance_Work_Order__r.Planner_Group__c);
            orderTypeSet.add(rec.Maintenance_Work_Order__r.Order_Type__c);
            unloadingPointSet.add(rec.Unloading_Point__c);          
        }

        List<Work_Order_Activity_Assignment_Rule__c> ruleList = [select id, Name,
        Assigned_To_Vendor__c,
        MAT_Code__c,
        Order_Type__c,
        Planner_Group__c,
        Plant_Section__c,
        Recipient__c,
        Work_Center__c,
        Unloading_Point__c,
        Supervisor__c,
        Supervisor__r.email,
        (select tradesman__c from Tradesmen__r)
        from Work_Order_Activity_Assignment_Rule__c
        where   Active__c = true
        and (Recipient__c = null or Recipient__c in :recipientSet)                                              
        and (Unloading_Point__c = null or Unloading_Point__c in :unloadingPointSet)          
        order by Priority__c ASC                                                    
        ];

        //and (Operating_District__c = null or Operating_District__c in :operatingDistrictSet)        
        //and (Operator_Route__c = null or Operator_Route__c in :routeSet)                
        //and (Planner_Group__c = null or Planner_Group__c in :plannerGroupSet)                             
        //and (MAT_Code__c = null or MAT_Code__c in :matCodeSet)
        //and (Plant_Section__c = null or Plant_Section__c in :plantSectionSet) 
        //and (Work_Center__c = null or Work_Center__c in :workCenterSet)       
        //and (Order_Type__c = null or Order_Type__c in :orderTypeSet)

        List<Work_Order_Activity_Assignment__c> assignmentList = new List<Work_Order_Activity_Assignment__c>();

        List<Work_Order_Activity__c> activityListToNotifyVendorSupervisors = new List<Work_Order_Activity__c>();

        activitySet.clear();

        for(Work_Order_Activity__c activityRec : activityList)  
        {
            for(Work_Order_Activity_Assignment_Rule__c rule : ruleList) 
            {
                if(IsActivityMatchTheRule(activityRec, rule) == true)
                {
                    //found the perfect match
                    //do assignment here

                    activitySet.add(activityRec.id);

                    activityRec.Auto_Assignment_Rule__c = rule.ID;
                    activityRec.Assigned_Vendor__c = rule.Assigned_To_Vendor__c;
                    activityRec.Vendor_Supervisor__c = rule.Supervisor__c;
                    for(Work_Order_Activity_Assignment_Rule_Item__c ruleItem : rule.Tradesmen__r)
                    {
                        Work_Order_Activity_Assignment__c assignmentRec = new Work_Order_Activity_Assignment__c();
                        assignmentRec.Work_Order_Activity__c = activityRec.id;
                        assignmentRec.Tradesman__c = ruleItem.Tradesman__c;
                        assignmentList.add(assignmentRec);
                    }

                    //if there is a vendor supervisor specified on the rule and there are no specified tradesmen
                    //we need to send email notification
                    if(rule.Supervisor__c <> null && rule.Tradesmen__r.size() == 0)    
                    {
                        activityListToNotifyVendorSupervisors.add(activityRec);
                    }

                    break;
                }
            }            
        }
        //remove any tradesmen assignments from activities matching rules
        List<Work_Order_Activity_Assignment__c> assignmentsToDelete = [select id, name 
        from Work_Order_Activity_Assignment__c 
        where Work_Order_Activity__c in :activitySet];

        final Savepoint savePoint = Database.setSavepoint();        
        try
        {                    
            delete assignmentsToDelete;        
            update activityList;
            insert assignmentList;

            VTT_EmailNotifications notificationService = new VTT_EmailNotifications();
            notificationService.NotifyVendorSupervisorsAutoAssignment(activityListToNotifyVendorSupervisors);       
        }
        catch (Exception e)
        {
            Database.rollback(savePoint);                        
            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));                                    
        }



    }    
    public static Boolean IsActivityMatchTheRule(Work_Order_Activity__c pActivity, Work_Order_Activity_Assignment_Rule__c pRule)
    {

        system.debug('IsActivityMatchTheRule  -  Activity: ' + pActivity.Name + ' Rule: ' + pRule.Name);
        if( (pActivity.Recipient__c == pRule.Recipient__c || pRule.Recipient__c == null)
            && (pActivity.Unloading_Point__c == pRule.Unloading_Point__c || pRule.Unloading_Point__c == null)
            && (FieldValueMatchTheRule(pActivity.Work_Center__c,pRule.Work_Center__c) || pRule.Work_Center__c == null)
            && (FieldValueMatchTheRule(pActivity.Maintenance_Work_Order__r.MAT_Code__c,pRule.MAT_Code__c) || pRule.MAT_Code__c == null)
            && (FieldValueMatchTheRule(pActivity.Maintenance_Work_Order__r.Order_Type__c, pRule.Order_Type__c) || pRule.Order_Type__c == null)          
            && (FieldValueMatchTheRule(pActivity.Maintenance_Work_Order__r.Plant_Section__c,pRule.Plant_Section__c) || pRule.Plant_Section__c == null)
            && (FieldValueMatchTheRule(pActivity.Maintenance_Work_Order__r.Planner_Group__c,pRule.Planner_Group__c) || pRule.Planner_Group__c == null)            
            )
        {
            system.debug('IsActivityMatchTheRule: Match');             
            return true;
        }
        system.debug('IsActivityMatchTheRule: No Match'); 
        return false;
    }

    public static Boolean FieldValueMatchTheRule(String pFieldValue, String pRuleFieldValue)
    {

        system.debug('FieldValueMatchTheRule  -  pFieldValue: ' + pFieldValue + ' pRuleFieldValue: ' + pRuleFieldValue);

        if(pRuleFieldValue == null || pFieldValue == null)
        {
            system.debug('FieldValueMatchTheRule: No Match');             
            return false;
        }

        //check direct match
        if(pFieldValue == pRuleFieldValue)
        {
            system.debug('FieldValueMatchTheRule: Match');             

            return true;
        }

        //check comma separated lists
        List<String>ValueList = pRuleFieldValue.Split(',',0);
        for(string RuleFiledValue : ValueList)
        {
            system.debug('FieldValueMatchTheRule  -  pFieldValue: ' + pFieldValue + ' RuleFiledValue: ' + RuleFiledValue);


            RuleFiledValue = RuleFiledValue.trim();
            if(RuleFiledValue == pFieldValue)
            {
                system.debug('FieldValueMatchTheRule: Match');             
                return true;
            }

            if(RuleFiledValue.contains('*'))
            {
                RuleFiledValue = RuleFiledValue.replace('*','.*');
                Boolean matchResult = Pattern.matches(RuleFiledValue, pFieldValue);
                system.debug('FieldValueMatchTheRule: Match ' + matchResult);             
                if(matchResult)
                {
                    return true;
                }
                //return matchResult;
            }
            //return Pattern.matches(RuleFiledValue, pFieldValue);

            //if(RuleFiledValue.endsWith('*'))
            //{
            //  return pFieldValue.startswith(RuleFiledValue.substringBefore('*'));
            //}
            //if(RuleFiledValue.StartsWith('*'))
            //{
            //  return pFieldValue.endsWith(RuleFiledValue.substringAfter('*'));
            //} 
            //if(RuleFiledValue.contains('*'))
            //{
            //  List<String> RuleFiledValueList = RuleFiledValue.Split('\\*',0);
            //  for(string WildCardValue : RuleFiledValueList)
            //  {
            //      if(pFieldValue.contains(WildCardValue))
            //      {
            //          return true;
            //      }
            //  }

            //}

        }
        ////check wild card
        //if(pRuleFieldValue.endsWith('*'))
        //{
        //  return pFieldValue.startswith(pRuleFieldValue.substringBefore('*'));
        //}
        system.debug('FieldValueMatchTheRule: Match - No'); 
        return false;
    }   
      
    public static void ValidateActivityAssignmentBeforeDelete(List<Work_Order_Activity_Assignment__c>  pAssignmentsList)
    {
        List<Work_Order_Activity_Assignment__c> assignmentsWithWorkingTradesmen = [
        SELECT id, Name, Work_Order_Activity__c,
        Work_Order_Activity__r.Name, Tradesman__c, 
        Tradesman__r.Name, 
        Tradesman__r.Current_Work_Order_Activity__c
        FROM Work_Order_Activity_Assignment__c 
        WHERE Tradesman__r.Current_Work_Order_Activity__c <> null
        and id in :pAssignmentsList];

        system.debug('assignmentsWithWorkingTradesmen:');
        system.debug(assignmentsWithWorkingTradesmen);

        Map<Id, Work_Order_Activity_Assignment__c> cannotDeleteAssignmentsMap = new Map<Id, Work_Order_Activity_Assignment__c>(); 
        for(Work_Order_Activity_Assignment__c oAssignmentToCheck :assignmentsWithWorkingTradesmen)
        {
            if(oAssignmentToCheck.Work_Order_Activity__c==oAssignmentToCheck.Tradesman__r.Current_Work_Order_Activity__c)
            {
                cannotDeleteAssignmentsMap.put(oAssignmentToCheck.id,oAssignmentToCheck);
            }
            
        }  
        system.debug('cannotDeleteAssignmentsMap:');
        system.debug(cannotDeleteAssignmentsMap);

        for(Work_Order_Activity_Assignment__c oAssignmentToDelete : pAssignmentsList){
                Work_Order_Activity_Assignment__c cannotDeleteAssignment = cannotDeleteAssignmentsMap.get(oAssignmentToDelete.id);
                if(cannotDeleteAssignment <> null){
                    system.debug(oAssignmentToDelete.id + ' was not deleted' );
                    //Throw an error that the Opp cannot be deleted
                    String errorMessage = cannotDeleteAssignment.Tradesman__r.Name + ' is currently working this activity and cannot be unassigned: ' + cannotDeleteAssignment.Work_Order_Activity__r.Name;
                    oAssignmentToDelete.addError(errorMessage);
                }else{         
                    system.debug('Activity Assignment Id ' + oAssignmentToDelete.id + ' was deleted');
                }
        }        
    }



    /*
    This method is called from VTT_ActivityAssignmentTrigger, 
    when Mulesoft inserts or updates Assignment records we want to check if contact has a duplicate contact created under Vendor account, 
    if so, we want to use that contact instead of the internal Husky contact created by AD sync
    */
    public static void  UpdateActivityAssignmentTradesman(List<Work_Order_Activity_Assignment__c>  pAssignmentsList)
    {
        //first lets get set of contact IDs
        Set<ID> contactSet = new Set<Id>();   
        Map<ID, String> huskyContactMap = new Map<ID, String>(); 
        for(Work_Order_Activity_Assignment__c rec : pAssignmentsList)   
        {
            contactSet.add(rec.Tradesman__c);
        }
        //now lets get list of contacts with Husky_AD_Username__c <> null, we only interested in those contacts
        List<Contact> huskyContactList = [select id, name, Husky_AD_Username__c from Contact where id in :contactSet and Husky_AD_Username__c<>null];
        Set<String> HuskyADSet = new Set<String>(); 
        for(Contact rec : huskyContactList)   
        {
            HuskyADSet.add(rec.Husky_AD_Username__c);
            huskyContactMap.put(rec.id, rec.Husky_AD_Username__c);
        }

        //now lets get list of vendors with Tradesman ID = Husky AD usernames
        List<Contact> vendorContactList = [select id, name, Tradesman_ID__c from Contact where Tradesman_ID__c in :HuskyADSet];
        Map<String, ID> vendorContactMap = new Map<String, ID>();
        for(Contact rec : vendorContactList)   
        {
            vendorContactMap.put(rec.Tradesman_ID__c, rec.ID);
        } 

        system.debug('vendorContactMap');
        system.debug(vendorContactMap);
        //and final step - loop thru assignment records and replace husky contacts with vendors contacts
        for(Work_Order_Activity_Assignment__c rec : pAssignmentsList)   
        {

            String husky_AD_UserName = huskyContactMap.get(rec.Tradesman__c);
            if(husky_AD_UserName <> null)
            {
                ID vendorContactID = vendorContactMap.get(husky_AD_UserName);
                if(vendorContactID <> null)
                {
                    rec.Tradesman__c = vendorContactID;
                }
            }

        } 

    }
    /*
    This method should generate emails for tradesman who are currently not working 
    in case if activity was assigned to him and it is scheduled for today or tomorrow
    */
    public static void  NotifyAssignedTradesman(List<Work_Order_Activity_Assignment__c>  pAssignmentsList)
    {
            system.debug('*******************NotifyAssignedTradesman********************');
            VTT_EmailNotifications notificationService = new VTT_EmailNotifications();
            notificationService.NotifyTradesmanAfterActivtyAssignment(pAssignmentsList);
    }

    /********************************************************************************************************
    * Notfy Vendor Supervisor if rejected activity
    ********************************************************************************************************/
    public static void NotifyVendorSupervisorRejectedActivity(List<Work_Order_Activity_Assignment__c>  pAssignmentsList)
    {
        System.debug('VTT_Utilities->NotifyVendorSupervisorRejectedActivity');
        //Filter the Work Order Activities based on Rejected Assignments
        List<Work_Order_Activity_Assignment__c> rejectedAssignmentsList = new List<Work_Order_Activity_Assignment__c>();
        for(Work_Order_Activity_Assignment__c assignmentRec : pAssignmentsList) {
            if(assignmentRec.Rejected__c == true)
            {
                System.debug('VTT_Utilities->NotifyVendorSupervisorRejectedActivity->rejectedAssignment: ' + assignmentRec);
                rejectedAssignmentsList.add(assignmentRec);
            }
        }

        VTT_EmailNotifications notificationService = new VTT_EmailNotifications();
        notificationService.NotifySupervisorsRejectedActivityAssignment(rejectedAssignmentsList);
    }

    public static void  UpdateActivityAssigneeField(List<Work_Order_Activity_Assignment__c>  pAssignmentsList)
    {
        Boolean executeTriggerCode_Maintenance = MaintenanceServicingUtilities.executeTriggerCode;
        Boolean executeTriggerCode_VTT = VTT_Utilities.executeTriggerCode;        

        MaintenanceServicingUtilities.executeTriggerCode = false;
        VTT_Utilities.executeTriggerCode = false;  

        Set<ID> activitySet = new Set<Id>();    
        for(Work_Order_Activity_Assignment__c rec : pAssignmentsList)   
        {
            activitySet.add(rec.Work_Order_Activity__c);
        }

        List<Work_Order_Activity__c> activityList = [SELECT Id, Name, Assigned_Text__c, Assigned_Vendor__c,
        (select id, name, tradesman__r.Name, tradesman__r.AccountID from Work_Order_Activity_Assignments__r where rejected__c <> true order by tradesman__r.Name ) 
        FROM Work_Order_Activity__c
        where id in :activitySet];

        for(Work_Order_Activity__c activityRec :activityList)
        {
            String assignedTo = '';
            Boolean first = true;

            for(Work_Order_Activity_Assignment__c assignedRec :activityRec.Work_Order_Activity_Assignments__r)
            {   
                if(first)
                {
                    assignedTo = assignedRec.tradesman__r.Name; 
                }
                else
                {
                    assignedTo = assignedTo + ', ' +  assignedRec.tradesman__r.Name;    
                }
                first = false;

                //take first Vendor Account Id and use it as Assigned Vendor
                if(assignedRec.tradesman__r.AccountID <> null && activityRec.Assigned_Vendor__c == null)
                {
                    activityRec.Assigned_Vendor__c = assignedRec.tradesman__r.AccountID;
                }
                
            }

            activityRec.Assigned_Text__c = assignedTo;
        }
        update activityList;

        MaintenanceServicingUtilities.executeTriggerCode = executeTriggerCode_Maintenance;
        VTT_Utilities.executeTriggerCode = executeTriggerCode_VTT;          

    }

    public static void  UpdateActivityLogEntry(List<Work_Order_Activity_Log_Entry__c>  logEntryList)
    {

        if(UpdateActivityLogEntryInProgress)
        {
            return;
        }

        UpdateActivityLogEntryInProgress = true;

        Set<ID> activityLogSet = new Set<Id>();    
        for(Work_Order_Activity_Log_Entry__c rec :logEntryList) 
        {
            activityLogSet.add(rec.Work_Order_Activity_Log_Lookup__c);
        }

        List<Work_Order_Activity_Log__c> activityLogList = [SELECT Id, Name, 
        (select id, name, TimeStamp__c, StatusEnd__c
            from Work_Order_Activity_Log_Entries2__r order by TimeStamp__c desc) 
        FROM Work_Order_Activity_Log__c
        where id in :activityLogSet];

        List<Work_Order_Activity_Log_Entry__c> logEntryListToUpdate = new List<Work_Order_Activity_Log_Entry__c>();

        for(Work_Order_Activity_Log__c activityLogRec :activityLogList)
        {
            DateTime statusEnd = null;
            
            // loop from the last to the first, update StatusEnd__c with TimeStamp__c of the previous record 
            for(Work_Order_Activity_Log_Entry__c LogEntryRec :activityLogRec.Work_Order_Activity_Log_Entries2__r)
            {   
                //Status End
                if(LogEntryRec.StatusEnd__c  <> statusEnd)
                {
                    LogEntryRec.StatusEnd__c  = statusEnd; 
                    logEntryListToUpdate.add(LogEntryRec);                    
                }
                statusEnd = LogEntryRec.TimeStamp__c;
            }
        }

        update logEntryListToUpdate;

        UpdateActivityLogEntryInProgress = false;
    }

    private static void UpdateActivityLog(List<Work_Order_Activity_Log_Entry__c>  logEntryList) {
        if(UpdateActivityLogInProgress)
        {
            return;
        }

        UpdateActivityLogInProgress = true;

        Set<ID> activityLogSet = new Set<Id>();    
        for(Work_Order_Activity_Log_Entry__c rec :logEntryList) 
        {
            activityLogSet.add(rec.Work_Order_Activity_Log_Lookup__c);
        }

        List<Work_Order_Activity_Log__c> activityLogList = [SELECT Id, Name, Started_New__c, Started_At_Equipment_New__c,
        Finished_New__c, Finished_At_Equipment_New__c, TravelTime_New__c, WorkTime_New__c,
        (select id, name, TimeStamp__c, Status__c, Duration_Hours__c 
            from Work_Order_Activity_Log_Entries2__r) 
        FROM Work_Order_Activity_Log__c
        where id in :activityLogSet];

        List<Work_Order_Activity_Log_Entry__c> logEntryListToUpdate = new List<Work_Order_Activity_Log_Entry__c>();

        DateTime started;
        DateTime startedAtEquipment;
        DateTime finished;
        DateTime finishedAtEquipment;
        Decimal travelTime;
        Decimal workTime;

        for(Work_Order_Activity_Log__c activityLogRec :activityLogList)
        {
            started = null;
            startedAtEquipment = null;
            finished = null;
            finishedAtEquipment = null;
            travelTime = 0.00;
            workTime = 0.00;
            
            // loop from the last to the first, update StatusEnd__c with TimeStamp__c of the previous record 
            for(Work_Order_Activity_Log_Entry__c LogEntryRec :activityLogRec.Work_Order_Activity_Log_Entries2__r)
            {   
                //Roll-up summary fields
                if(LogEntryRec.Status__c == 'Start Job' || LogEntryRec.Status__c == 'Auto Complete') {
                    started = (started == null) ? LogEntryRec.TimeStamp__c : 
                    (started <= LogEntryRec.TimeStamp__c) ? started : LogEntryRec.TimeStamp__c;
                }

                if(LogEntryRec.Status__c == 'Start at Equipment') {
                    startedAtEquipment = (startedAtEquipment == null) ? LogEntryRec.TimeStamp__c : 
                    (startedAtEquipment <= LogEntryRec.TimeStamp__c) ? startedAtEquipment : LogEntryRec.TimeStamp__c;
                }

                if(LogEntryRec.Status__c == 'Job Complete' || LogEntryRec.Status__c == 'Put Job On Hold' || LogEntryRec.Status__c == 'Cancel Job' ||
                    LogEntryRec.Status__c == 'Finished for the Day' || LogEntryRec.Status__c == 'Auto Complete') {
                    finished = (finished == null) ? LogEntryRec.TimeStamp__c : 
                    (finished >= LogEntryRec.TimeStamp__c) ? finished : LogEntryRec.TimeStamp__c;
                }

                if(LogEntryRec.Status__c == 'Finished at Equipment') {
                    finishedAtEquipment = (finishedAtEquipment == null) ? LogEntryRec.TimeStamp__c : 
                    (finishedAtEquipment > LogEntryRec.TimeStamp__c) ? finishedAtEquipment : LogEntryRec.TimeStamp__c;
                }

                if((LogEntryRec.Status__c == 'Start Job' || LogEntryRec.Status__c == 'Finished at Equipment') 
                    && LogEntryRec.Duration_Hours__c != null) {
                    travelTime += LogEntryRec.Duration_Hours__c;
                }

                if(LogEntryRec.Status__c == 'Start at Equipment' && LogEntryRec.Duration_Hours__c != null) {
                    workTime += LogEntryRec.Duration_Hours__c;
                }                 
            }

            //Set Rollup Summary Fields
            activityLogRec.Started_New__c = started;
            activityLogRec.Started_At_Equipment_New__c = startedAtEquipment;
            activityLogRec.Finished_New__c = finished;
            activityLogRec.Finished_At_Equipment_New__c = finishedAtEquipment;
            activityLogRec.TravelTime_New__c = travelTime;
            activityLogRec.WorkTime_New__c = workTime;
        }

        update activityLogList;

        UpdateActivityLogInProgress = false;
    }

    /*****************************************************************
    * Utility function to update activities with the latest log entries
    ******************************************************************/
    public static void RefreshActivityWorkDetails(Work_Order_Activity__c pWorkOrderActivity) {
        String newWorkDetailsField = ''; 
        for(Work_Order_Activity_Log_Entry__c logEntry : [Select Id, Name, TimeStamp__c, Status__c,
                                                         Tradesman__r.Name, Reason__c, Comments__c
                                                         From Work_Order_Activity_Log_Entry__c
                                                         Where Work_Order_Activity__c =: pWorkOrderActivity.Id
                                                         Order By TimeStamp__c]) {
            System.debug('RefreshActivityWorkDetails->logEntry: ' + logEntry);
            String comments = null;
            comments = logEntry.Comments__c;

            if(logEntry.Status__c == LOGENTRY_JOBONHOLD) {
                newWorkDetailsField += String.format('Date/Time: {0}\nStatus: {1}\nTradesman: {2}\nReason: {3}\nComments: {4}\n\n', new List<String>{String.valueof(logEntry.TimeStamp__c), logEntry.Status__c, 
                    logEntry.Tradesman__r.Name, logEntry.Reason__c, comments});
            } else {
                newWorkDetailsField += String.format('Date/Time: {0}\nStatus: {1}\nTradesman: {2}\nComments: {3}\n\n', new List<String>{String.valueof(logEntry.TimeStamp__c), logEntry.Status__c, 
                    logEntry.Tradesman__r.Name, comments});
            }
        }

        pWorkOrderActivity.Work_Details__c = newWorkDetailsField;
    }

    public static String HoursToString(Decimal hours)
    {
        String result = '';
        if(hours == null)
        {
            return '';
        }


        if(Math.FLOOR(hours) <> 0)
        {
            result = Math.FLOOR(hours)  + ' Hours ';
        } 

        Integer minutes = Integer.valueOf(hours * 60);
        if(Math.MOD(minutes,60) <>0)
        {
           result = result + Math.MOD(minutes,60)  + ' Minutes ';
        }

        return result;
    }


    public static void logError(Exception ex)
    {
    
        string message = ex.getMessage();
        logError('Unexpected error:' +message );
    }
    public static void logError(string errorMessage)
    {
        String message = errorMessage;
        system.debug(message);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, message));
    }  

}