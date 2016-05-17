public without sharing class VTT_TradesmanScheduleController {

    public Contact Tradesman {get; set;}
    public ID TradesmanID {get; set;}    

    public List<SelectOption> VendorAccoountOptions {get; private set;}
    public List<SelectOption> TradesmenOptions {get; private set;}

    public String AccountID {get; set;}

    public String CurrentDate {get; set;}
    public List<Work_Order_Activity_Log_Entry__c> LogEntryList {get; set;}
    public Decimal TotalHours {get; set;}
    public String TotalHoursText {get; set;}    

    public Decimal TotalHoursOnEquipment {get; set;}
    public String TotalHoursOnEquipmentText {get; set;}    

    public Decimal TotalHoursOffEquipment {get; set;}
    public String TotalHoursOffEquipmentText {get; set;}    


    public Boolean IsVendorSupervisor {get;private set;}    
    public Boolean IsAdmin {get;private set;}    

    public List<calEvent> events {get;set;}
    public List<WorkOrderSummary> WorkOrderSummaryList {get;set;}    


    private Set<ID> workedActivitySet = new set<ID>(); 

    //The calendar plugin is expecting dates is a certain format. We can use this string to get it formated correctly
    //String dtFormat = 'EEE, d MMM yyyy HH:mm:ss z';
    //for IE9
    String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
    //String dtFormat = 'yyyy-mm-dd HH:mm:ss z';

    //constructor
    public VTT_TradesmanScheduleController() {

        system.debug('VTT_TradesmanScheduleController:');
        AccountID = null;
        TradesmanID = null;
        events = new list<calEvent>();

        IsAdmin = VTT_Utilities.IsAdminUser();
        IsVendorSupervisor = VTT_Utilities.IsVendorSupervisor();
        Tradesman = VTT_Utilities.LoadTradesmanInfo();

        String vendorIdString =  ApexPages.CurrentPage().getParameters().get('VendorID');
        String tradesmanIdString =  ApexPages.CurrentPage().getParameters().get('TradesmanID');  

        if(IsAdmin)
        {
            LoadVendorAccountList();
            if(vendorIdString!=null)
            {
                AccountID = vendorIdString;
            }
            else if(VendorAccoountOptions.size()>0)
            {
                AccountID = Tradesman.AccountID <> null? Tradesman.AccountID : VendorAccoountOptions[0].getValue();
            }
            LoadTradesmanList();
            if(tradesmanIdString!=null)
            {
                TradesmanID = tradesmanIdString;
            }
            else if(TradesmenOptions.size()>0)
            {
                TradesmanID =  Tradesman.id <> null?  Tradesman.id : TradesmenOptions[0].getValue();                
            }

        }
        else if(IsVendorSupervisor)
        {
            AccountID =  Tradesman.AccountID;
            LoadTradesmanList(); 
            if(tradesmanIdString!=null)
            {
                TradesmanID = tradesmanIdString;
            }
            else  if(TradesmenOptions.size()>0)
            {
                TradesmanID = Tradesman.id <> null?  Tradesman.id : TradesmenOptions[0].getValue();                
            }       
        }
        else
        {
            AccountID =  Tradesman.AccountID;
            TradesmanID = Tradesman.id; 
        }

        system.debug('AccountID:' + AccountID);
        system.debug('TradesmanID:' + TradesmanID); 

        ReloadEvents(); 

        Datetime currentDatetime = Datetime.now();
        CurrentDate = currentDatetime.format('yyyy-MM-dd'); 
        LogEntryList = new List<Work_Order_Activity_Log_Entry__c>();
        ReloadLogEntries();
    }

    public PageReference PageReload() {
        PageReference pageRef = ApexPages.currentPage();
        pageRef.setRedirect(true);
        pageRef.getParameters().put('VendorID', AccountID);
        pageRef.getParameters().put('TradesmanID', TradesmanID); 

        system.debug('AccountID:' + AccountID);
        system.debug('TradesmanID:' + TradesmanID); 

        return pageRef;  
    }

    public PageReference JobInProgress()   
    {
        PageReference pageRef = new PageReference('/apex/VTT_ActivityDetailTimeLog?id=' + Tradesman.Current_Work_Order_Activity__c);
        pageRef.setRedirect(true);
        return pageRef;      
    }

    public void LoadVendorAccountList()
    {
        events = new list<calEvent>();
        system.debug('LoadVendorAccountList:');
        if(IsAdmin)
        {
            VendorAccoountOptions = new List<SelectOption>();
            for(Account accountRec: VTT_Utilities.GetVendorAccountList())
            {
                //if(accountRec.id ==  Tradesman.AccountId)
                {
                    SelectOption accOption = new SelectOption(accountRec.id, accountRec.Name);
                    VendorAccoountOptions.add(accOption);

                    //if(AccountID == null)
                    //{
                    //    AccountID = accountRec.id;
                    //}
                }
            }  
        } 
        else
        {
            AccountID = Tradesman.AccountId;
        }
        system.debug('AccountID:' + AccountID);
        system.debug('TradesmanID:' + TradesmanID); 
    }

    public void LoadTradesmanList()
    {
        events = new list<calEvent>();
        system.debug('LoadTradesmanList:');
        TradesmenOptions = new List<SelectOption>();
        TradesmanID = null;

        if((IsVendorSupervisor || isAdmin) && AccountID <> null)
        {

            List<Contact> contactList = [select id, name from Contact where AccountID = :AccountID and User__c <> null order by name LIMIT 5000];

            for(Contact contactRec: contactList)
            {

                if(TradesmanID == null)
                {
                    TradesmanID = contactRec.id;
                }
                //if(contactRec.id <> Tradesman.ID)
                {
                    SelectOption accOption = new SelectOption(contactRec.id, contactRec.Name);
                    TradesmenOptions.add(accOption);                               
                }
            }  

            
        }  
        //ReloadEvents();
        system.debug('AccountID:' + AccountID);
        system.debug('TradesmanID:' + TradesmanID);      
    }

    public void ReloadEvents()
    {
        system.debug('Reload Events:');
        system.debug('AccountID:' + AccountID);
        system.debug('TradesmanID:' + TradesmanID);           
        LogEntryList = new List<Work_Order_Activity_Log_Entry__c>();        
        events  =  new list<calEvent>(); 

        LoadMyActivityWorkLogs();
        LoadMyScheduledActivities();
        LoadMyAvailability();   
        system.debug('events count:' + events.size());
    }


    private void LoadMyAvailability()
    {
        //TODO: load my availability information
    }
    private void LoadMyScheduledActivities()
    {


        //TODO: load scheduled information for assigned to me activities starting today
        List<Work_Order_Activity__c> activityList = [SELECT ID, Name, Scheduled_Start_Date__c, Scheduled_Finish_Date__c 
        FROM Work_Order_Activity__c 
        WHERE 
        id in (select Work_Order_Activity__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Tradesman__c =:TradesmanID)
        AND Scheduled_Start_Date__c >= LAST_N_DAYS:30
        AND id not in :workedActivitySet
        AND SAP_deleted__c = false
        AND Status__c <> :VTT_Utilities.ACTIVITY_STATUS_COMPLETED
        ORDER BY Scheduled_Start_Date__c
        LIMIT 1000];


        for(Work_Order_Activity__c activity : activityList)
        {
            DateTime startDT = activity.Scheduled_Start_Date__c;
            DateTime endDT = activity.Scheduled_Finish_Date__c;
            if(endDT==null)
            {
                endDT = DateTime.now();
            }
            if(startDT <> null && endDT <> null)
            {
                calEvent campEvent = new calEvent();
                campEvent.title = activity.Name;
                campEvent.allDay = false;
                campEvent.startString = startDT.format(dtFormat);
                campEvent.endString = endDT.format(dtFormat);
                campEvent.url = 'VTT_ActivityDetailTimeLog?id=' + activity.id + 
                    '&retUrl=' + EncodingUtil.urlEncode('/apex/VTT_TradesmanCalendar?VendorID=' + AccountID + '&TradesmanID=' + TradesmanID, 'UTF-8');
                campEvent.className = 'event-scheduled';
                campEvent.activityId = activity.Id;
                events.add(campEvent);
            }

            
        }


    }

    private void LoadMyActivityWorkLogs()
    {

        System.debug('LoadMyActivityWorkLogs->TradesmandId: ' + TradesmanID);
        workedActivitySet = new Set<ID>();

        List<Work_Order_Activity_Log__c> workLogList = [SELECT ID, Work_Order_Activity__c, 
        Work_Order_Activity__r.Name, Started_New__c, Finished_New__c, 
        Work_Order_Activity__r.Status__c,
        Work_Order_Activity__r.Finished__c
        FROM Work_Order_Activity_Log__c 
        WHERE Tradesman__c = :TradesmanID
        AND Date__c = LAST_90_DAYS
        AND Started_New__c <> null
        ORDER BY Date__c DESC
        LIMIT 1000];

        for(Work_Order_Activity_Log__c workLog : workLogList)
        {
            System.debug('ActivityLog: ' + workLog.Work_Order_Activity__r.Name + ' Started_New__c: ' + workLog.Started_New__c);
            //add activity ID to the set so we can use it later in 
            //LoadMyScheduledActivities in order to ignore scheduled activities if  Tradesman already working on it
            workedActivitySet.add(workLog.Work_Order_Activity__c);

            Boolean eventProblem = false;
            DateTime startDT = workLog.Started_New__c;
            DateTime endDT = workLog.Finished_New__c;
            if(endDT==null)
            {
                if(startDT.date() == Date.today())
                {
                    endDT = DateTime.now();                    
                }
                else
                {
                    endDT = startDT + 1/24; // add one hour
                    eventProblem = true;
                }

            }
            if(startDT <> null && endDT <> null)
            {
                calEvent campEvent = new calEvent();
                campEvent.title = workLog.Work_Order_Activity__r.Name;
                campEvent.allDay = false;
                campEvent.startString = startDT.format(dtFormat);
                campEvent.endString = endDT.format(dtFormat);
                campEvent.url = 'VTT_ActivityDetailTimeLog?id=' + workLog.Work_Order_Activity__c +
                    '&retUrl=' + EncodingUtil.urlEncode('/apex/VTT_TradesmanCalendar?VendorID=' + AccountID + '&TradesmanID=' + TradesmanID, 'UTF-8');
                if(eventProblem)
                {
                    campEvent.className = 'event-activitylog-err';
                }
                else if(workLog.Work_Order_Activity__r.Status__c == VTT_Utilities.ACTIVITY_STATUS_COMPLETED
                    /*&& workLog.Work_Order_Activity__r.Finished__c == workLog.Finished_New__c*/)
                {
                    campEvent.className = 'event-activitylog-complete';
                }
                else
                {
                    campEvent.className = 'event-activitylog';
                }
                campEvent.activityId = worklog.Work_Order_Activity__c;
                events.add(campEvent);
            }

            
        }
    }


    public PageReference ReloadLogEntries()
    {

        system.debug('ReloadLogEntries:');
        system.debug('CurrentDate:');
        system.debug(CurrentDate);        
        Date currDate = Date.valueOf(CurrentDate);
        system.debug('currDate:');
        system.debug(currDate);          

        //LogEntryList.clear();
        LogEntryList = [select id, Status__c, Work_Order_Activity__r.Name, TimeStamp__c, Duration_Hours__c, 
        Include_in_Calculation__c, OnEquipment__c, OffEquipment__c, Duration_Text__c,
        Work_Order_Activity__r.Maintenance_Work_Order__r.Name, Work_Order_Activity__r.Maintenance_Work_Order__r.Work_Order_Number__c,
        Work_Order_Activity__r.Maintenance_Work_Order__r.Location__r.Name
        from Work_Order_Activity_Log_Entry__c 
        where Work_Order_Activity_Log_Lookup__r.Tradesman__c = :TradesmanID 
        and Date__c = :currDate
        order by TimeStamp__c];
        system.debug(LogEntryList);

        TotalHours = 0;
        TotalHoursOffEquipment = 0;        
        TotalHoursOnEquipment = 0;        

        WorkOrderSummaryList = new List<WorkOrderSummary>();
        Map<String, WorkOrderSummary> workOrderSummaryMap = new Map<String, WorkOrderSummary>(); 

        for(Work_Order_Activity_Log_Entry__c rec :LogEntryList)
        {
            if(rec.Include_in_Calculation__c && rec.Duration_Hours__c <> null)
            {
                TotalHours = TotalHours + rec.Duration_Hours__c;

                if(rec.OffEquipment__c)
                {
                    TotalHoursOffEquipment = TotalHoursOffEquipment + rec.Duration_Hours__c;                    
                }
                if(rec.OnEquipment__c)
                {
                    TotalHoursOnEquipment = TotalHoursOnEquipment + rec.Duration_Hours__c;                    
                }

                WorkOrderSummary workOrderSummaryItem;
                if(workOrderSummaryMap.containsKey(rec.Work_Order_Activity__r.Maintenance_Work_Order__r.Work_Order_Number__c))
                {
                    workOrderSummaryItem = workOrderSummaryMap.get(rec.Work_Order_Activity__r.Maintenance_Work_Order__r.Work_Order_Number__c);
                    workOrderSummaryItem.Hours += rec.Duration_Hours__c;
                }
                else
                {
                    workOrderSummaryItem = new WorkOrderSummary();
                    workOrderSummaryItem.WorkOrderName = rec.Work_Order_Activity__r.Maintenance_Work_Order__r.Work_Order_Number__c;
                    workOrderSummaryItem.LocationName = rec.Work_Order_Activity__r.Maintenance_Work_Order__r.Location__r.Name;
                    workOrderSummaryItem.Hours = rec.Duration_Hours__c;

                    workOrderSummaryMap.put(workOrderSummaryItem.WorkOrderName, workOrderSummaryItem);
                    WorkOrderSummaryList.add(workOrderSummaryItem);
                }

            }

        }

        workOrderSummaryList.sort();

        TotalHoursText = VTT_Utilities.HoursToString(TotalHours);
        TotalHoursOnEquipmentText = VTT_Utilities.HoursToString(TotalHoursOnEquipment);        
        TotalHoursOffEquipmentText = VTT_Utilities.HoursToString(TotalHoursOffEquipment);                

        return null;
    }

    //Class to hold calendar event data

    public class calEvent{
        public String title {get;set;}
        public Boolean allDay {get;set;}
        public String startString {get;private set;}
        public String endString {get;private set;}
        public String url {get;set;}
        public String className {get;set;}
        public Id activityId {get; set;} //For Mobile Calendar
    }

    public class WorkOrderSummary implements Comparable{
        public String WorkOrderName {get;set;}
        public String LocationName {get;set;}        
        public Decimal Hours {get;set;}

        public Integer compareTo(Object compareTo) 
        {
            WorkOrderSummary WorkOrderSummaryItem = (WorkOrderSummary) compareTo;
            if (this.WorkOrderName == WorkOrderSummaryItem.WorkOrderName) return 0;
            if (this.WorkOrderName > WorkOrderSummaryItem.WorkOrderName) return 1;
            return -1;        
        }
    }

}