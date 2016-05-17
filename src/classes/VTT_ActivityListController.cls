public without sharing class VTT_ActivityListController extends DynamicListController {

    //public List<SelectOption> AssignedOptions {get; private set;}
    public List<SelectOption> AMUOptions {get; private set;}
    public List<SelectOption> VendorOptions {get; private set;}    
    public List<SelectOption> TradesmanOptions {get; private set;}
    public List<SelectOption> SearchFilterOptions {get; private set;}      

    public List<Work_Order_Activity__c> selectedActivities   {get; private set;}
    public List<ActivityWrapper> currentPageActivities {get; private set;}
    public Boolean AllRecordsSelected {get;set;}
    public Boolean ActivitiesSelected {get;set;}    
    public String selectedActivityIDs {get;set;}
    

    //public List<Work_Order_Activity__c> activitylist {get; set;}  

    private Map<ID, Location__c > locationMap;
    
    private List<Work_Order_Activity_Search_Criteria__c> activitySearchCriteriaFilters { get; set; }
    public FilterWrapper pageFilter {get; set;}
    public String PageFilterString {get; private set;}
    public Boolean showSearchCriteriaNamePopUp { get; private set; }
    public String searchFilterName { get; set; }
    public Boolean saveConfirm { get; set; }
    public String selectedFilterId { get; set; }

    public Contact Tradesman {get; private set;}
    public Boolean IsAdmin {get;private set;}
    public Boolean IsVendorSupervisor {get;private set;}

    public String idlist {get; private set;}

    public Boolean showStartWorkPopup {get; private set;}
    public Boolean startWorkConfirm {get; set;}

    //Browser Variables
    public Boolean isMobileDevice {get; set;}
    public Boolean isGeolocationAvailable {get; set;}
    public Decimal currentLatitude {get; set;}
    public Decimal currentLongitude {get; set;}

    public VTT_ActivityListController () {
        
        super('select id, name, Assigned_Vendor__c, description__c, Work_Center__c, Assigned_Text__c, Maintenance_Work_Order__r.User_Status_Code__c, Maintenance_Work_Order__r.Work_Order_Priority_Number__c, Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Name, Maintenance_Work_Order__r.Location__r.Name, Maintenance_Work_Order__r.Plant_Section__c,Scheduled_Start_Date__c  ,Status__c, Status_Reason__c, Functional_Location_Description_SAP__c, Location_Name__c from Work_Order_Activity__c ');
        //sortColumn = 'Maintenance_Work_Order__r.Name, name';
        //SM 02/12/2016
        sortColumn = 'Maintenance_Work_Order__r.Requested_Start_Time__c, Maintenance_Work_Order__r.Name, Scheduled_Start_Date__c, Operation_Number__c, Sub_Operation_Number__c, Description__c';
        sortAsc = true;
        pageSize = 20;


        Tradesman = VTT_Utilities.LoadTradesmanInfo();
        IsAdmin = VTT_Utilities.IsAdminUser();   
        IsVendorSupervisor =  VTT_Utilities.IsVendorSupervisor(); 

        pageFilter = new FilterWrapper();
        showSearchCriteriaNamePopUp = false;

        showStartWorkPopup = false;

        //PopulateAssignedOptions();
        PopulateAMUOptions();
        PopulateVendorOptions();
        PopulateFilterOptions();

        //Get Url Parameters
        idlist = System.currentPageReference().getParameters().get('idlist');
        PageFilterString = System.currentPageReference().getParameters().get('filter');

        //Check Last Selected Filter
        Work_Order_Activity_Search_Criteria__c lastSelectedFilter;
        if(activitySearchCriteriaFilters != null && !activitySearchCriteriaFilters.isEmpty()) 
        {
            lastSelectedFilter = GetLastSelectedFilter();
        }

        if(lastSelectedFilter != null)
        {
            ChangeSelectedFilter(lastSelectedFilter.Id);
        }
        else if(PageFilterString <> null)
        {
            try
            {
                pageFilter = (FilterWrapper)System.JSON.deserialize(PageFilterString, FilterWrapper.class);
                String TradesmanFiler = pageFilter.tradesmanFilter;
                PopulateTradesmanOptions();
                pageFilter.tradesmanFilter = TradesmanFiler;
                RefreshData();
            }
            catch(Exception ex)
            {
                ClearFilter(); 
            }
        }
        else if(idlist <> null & idlist <> '')
        {
            RefreshData();
        }
        else
        {
            pageFilter = new FilterWrapper();
            ClearFilter();
        }
    }

    public override void reloadpage() {

        selectedActivities = new List<Work_Order_Activity__c>();
        ActivitiesSelected =false;
        AllRecordsSelected  = false;
        currentPageActivities  = getWActivities();    
    }
    
    public override void first() {
        super.first();
        reloadpage();
    }

    public override void previous() {
        super.previous();
        reloadpage();
    }

    public override void next() {
        super.next();
        reloadpage();
    }

    public override void last() {
        super.last();
        reloadpage();
    }

    public PageReference getSelected()
    {
        ActivitiesSelected =false;
        selectedActivityIDs = '';
        selectedActivities.clear();
        for(ActivityWrapper wrapper : currentPageActivities) 
        {
            if(wrapper.selected == true)
            {
                selectedActivities.add(wrapper.ActivityObject);
                if(ActivitiesSelected)
                {
                    selectedActivityIDs += '-';
                }
                selectedActivityIDs += wrapper.ActivityObject.id;
                ActivitiesSelected = true;
            }
        }
        return null;
    }



    private List<ActivityWrapper> getWActivities() {
        List<ActivityWrapper> result = new List<ActivityWrapper>();   
        for(Work_Order_Activity__c activityRec: (List<Work_Order_Activity__c>) getRecords())
        {
              result.add(new ActivityWrapper(activityRec));
        }
        return result;
    }  

    public List<SelectOption> getActivityStatuses()
    {
      List<SelectOption> options = new List<SelectOption>();
            
       Schema.DescribeFieldResult fieldResult =
     Work_Order_Activity__c.Status__c.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
       for( Schema.PicklistEntry f : ple)
       {
          if(f.getValue() <> VTT_Utilities.ACTIVITY_STATUS_CANCELLED)  
          {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
          }
       }       
       return options;
    }

    private void PopulateVendorOptions()
    {
        VendorOptions  = new List<SelectOption>();
        List<Account> VendorList =  VTT_Utilities.GetVendorAccountList();

        if(IsAdmin)
        {
            VendorOptions.add(new SelectOption('','- Any -'));            
            VendorOptions.add(new SelectOption('1','- Unassigned -'));   
        }

        for(Account accRec: VendorList)
        {
            SelectOption accOption = new SelectOption(accRec.id, accRec.Name);
            VendorOptions.add(accOption);                               
        } 
    }

    public void PopulateTradesmanOptions()
    {
        System.debug('PopulateTradesmanOptions: ' + pageFilter.vendorFilter);
        TradesmanOptions  = new List<SelectOption>();

        List<Contact> contactList = new List<Contact>(); 
        if(pageFilter.vendorFilter != '')
        {
            contactList = [select id, name from Contact where AccountID = :pageFilter.vendorFilter and User__c <> null order by name LIMIT 5000];            
        }



        TradesmanOptions.add(new SelectOption('','- Any -')); 
        if(IsAdmin || IsVendorSupervisor)
        {
            TradesmanOptions.add(new SelectOption('1','- Unassigned -'));   
        }        

        for(Contact contactRec: contactList)
        {
            SelectOption accOption = new SelectOption(contactRec.id, contactRec.Name);
            TradesmanOptions.add(accOption);                               
        }
        
        pageFilter.tradesmanFilter = TradesmanOptions[0].getValue();
        System.debug('TradesmanOptions: ' + TradesmanOptions + ' pageFilter.tradesmanFilter: ' + pageFilter.tradesmanFilter);        
    }    

    private void PopulateAMUOptions()
    {
        List<Field__c> amuList = [select id, name from Field__c where Operating_District__r.Business_Unit__r.Name =:VTT_Utilities.BU_NAME_HOG order by name];
        AMUOptions = new List<SelectOption>();
        AMUOptions.add(new SelectOption('','- Any -')); 

        for(Field__c rec: amuList)
        {
            SelectOption accOption = new SelectOption(rec.id, rec.Name);
            AMUOptions.add(accOption);                               
        }          
    }

    private void PopulateFilterOptions()
    {
        activitySearchCriteriaFilters = VTT_Utilities.GetUserActivitySearchFilters(UserInfo.getUserId());
        SearchFilterOptions = new List<SelectOption>();
        SearchFilterOptions.add(new SelectOption('', '- None -'));

        for(Work_Order_Activity_Search_Criteria__c searchFilter : activitySearchCriteriaFilters) {
            SelectOption filterOption = new SelectOption(searchFilter.Id, searchFilter.Assigned_Name__c);
            SearchFilterOptions.add(filterOption);
        }
    }

    private void ChangeSelectedFilter(String filterId)
    {
        selectedFilterId = filterId;

        Work_Order_Activity_Search_Criteria__c selectedFilter;
        for(Work_Order_Activity_Search_Criteria__c filter : activitySearchCriteriaFilters) {
            if(filter.Id == selectedFilterId) {
                selectedFilter = filter;
            }
        }
        selectedFilter = (selectedFilter == null) ? activitySearchCriteriaFilters[0] : selectedFilter;

        pageFilter = (FilterWrapper) JSON.deserialize(selectedFilter.Filter_String__c, FilterWrapper.class);
        String TradesmanFiler = pageFilter.tradesmanFilter;
        PopulateTradesmanOptions();
        pageFilter.tradesmanFilter = TradesmanFiler;
        RefreshData();
    }

    private Work_Order_Activity_Search_Criteria__c GetLastSelectedFilter()
    {
        Work_Order_Activity_Search_Criteria__c lastSelectedFilter;
        for(Work_Order_Activity_Search_Criteria__c filter : activitySearchCriteriaFilters) {
            if(filter.Last_Search_Criteria_Selected__c) {
                lastSelectedFilter = filter;
            }
        }

        return lastSelectedFilter;
    }

    public PageReference ClearLastSelectedFilter() {
        selectedFilterId = '';
        for(Work_Order_Activity_Search_Criteria__c filter : activitySearchCriteriaFilters) {
            filter.Last_Search_Criteria_Selected__c = false;
        }

        try {
            update activitySearchCriteriaFilters;
        } catch (Exception e) {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }

        return ClearFilter();
    }   
    
    public PageReference ClearFilter() {

        pageFilter = new FilterWrapper();

        idlist = null;

        if(IsAdmin)
        {
            pageFilter.vendorFilter = '';  
        }
        else
        {
            pageFilter.vendorFilter = Tradesman.AccountId;
            
        }
        PopulateTradesmanOptions();

        if(IsAdmin  || IsVendorSupervisor )
        {
            pageFilter.tradesmanFilter = '';  
        }
        else
        {
            pageFilter.tradesmanFilter = Tradesman.Id;
        }

        RefreshData();

        return null;
    }    
    
    public PageReference RefreshData() {  

       

        String FilteredSOQL = ' Name!=null AND SAP_Deleted__c = false ';  // always true, ignore deleted activities
            
        try {

            if(idlist <> null && idlist <> '')
            {
                String idFilter = idlist.replace(',', '\',\'');
                filteredSOQL  = filteredSOQL + ' and id in (\'' + idFilter + '\')';
                this.WhereClause  = FilteredSOQL;
            }
            else
            {
                this.WhereClause  = pageFilter.CreateSQLFilter();
            }

            PageFilterString = JSON.serialize(pageFilter);
            query();
            reloadpage();

        } catch (Exception e) {
              System.debug('RefreshData->Exception: ' + e.getMessage());
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }

        return null;
    }

    public PageReference SaveFilter_Start() {
        searchFilterName = '';
        showSearchCriteriaNamePopUp = true;
        return null;
    }

    public PageReference SaveFilter_End() {
        if(activitySearchCriteriaFilters == null) {
            activitySearchCriteriaFilters = new List<Work_Order_Activity_Search_Criteria__c>();
        }

        if(saveConfirm) {
            //Create New Filter
            Work_Order_Activity_Search_Criteria__c newFilter = new Work_Order_Activity_Search_Criteria__c();
            newFilter.Assigned_Name__c = searchFilterName;
            newFilter.Filter_String__c = JSON.serialize(pageFilter);
            newFilter.User__c = UserInfo.getUserId();

            try {
                VTT_Utilities.AddUserActivitySearchFilter(activitySearchCriteriaFilters, newFilter);
            } catch(DmlException ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }

            PopulateFilterOptions();
            ChangeSelectedFilter(newFilter.Id);
            showSearchCriteriaNamePopUp = false;
        }

        return null;
    }

    public PageReference DeleteFilter() {
        try {
            VTT_Utilities.DeleteUserActivitySearchFilter(activitySearchCriteriaFilters, selectedFilterId);
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }

        PopulateFilterOptions();
        if(activitySearchCriteriaFilters != null && !activitySearchCriteriaFilters.isEmpty()) {
            ChangeSelectedFilter(activitySearchCriteriaFilters[0].Id);
        }
        return null;
    }

    public PageReference FilterChanged() {
        Work_Order_Activity_Search_Criteria__c selectedFilter;

        if(selectedFilterId == null) {
            return ClearLastSelectedFilter();
        }

        //Update as lastSelectedFilter
        try {
            selectedFilter = VTT_Utilities.UpdateLastSelectedUserActivitySearchFilter(activitySearchCriteriaFilters, selectedFilterId);
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,ex.getMessage()));
        }

        if(selectedFilter != null) {
            ChangeSelectedFilter(selectedFilter.Id);
        }

        return null;       
    }

    public List<Work_Order_Activity__c> getActivityRecords() {
        return (List<Work_Order_Activity__c>) getRecords();
    }

    public PageReference JobInProgress()   
    {
        PageReference pageRef = new PageReference('/apex/VTT_ActivityDetailTimeLog?id=' + Tradesman.Current_Work_Order_Activity__c + '&filter=' + PageFilterString);
        pageRef.setRedirect(true);
        return pageRef;      
    }

    public PageReference StartWork_Start()
    {
        showStartWorkPopup = true;
        return null;
    }

    public PageReference StartWork_End()
    {
        if(startWorkConfirm) {
            try {
                VTT_Utilities.UpdateTradesmanStartedWork(Tradesman, currentLatitude, currentLongitude);
            } catch(DmlException ex) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot start work: ' + ex.getMessage()));
                return null;
            } finally {
                Tradesman = VTT_Utilities.LoadTradesmanInfo();
            }
        }

        showStartWorkPopup = false;
        return null;
    }

    public Boolean GetCanStartWork()
    {
        return Tradesman.Current_Work_Order_Activity__c == null && 
        Tradesman.Tradesman_Status__c != VTT_Utilities.Tradesman_Status_StartedWork &&
        Tradesman.Tradesman_Still_Working__c == false;
    }

    public PageReference ManageAssignments()   
    {
        if(selectedActivities == null || selectedActivities.isEmpty())
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select at least one Activity.'));        
            return null;
        }   

        PageReference pageRef = new PageReference('/apex/VTT_ManageAssignments?idlist=' + selectedActivityIDs + '&filter=' + PageFilterString);
        pageRef.setRedirect(true);
        return pageRef;
    
    }

    public PageReference RunAutoAssignments() {
        if(selectedActivities.size()>0)
        {
            Set<ID> selectedIDSet = new Set<ID>();
            for(ActivityWrapper wrapper : currentPageActivities) 
            {
                if(wrapper.selected == true)
                {
                    selectedIDSet.add(wrapper.ActivityObject.id);
                }
            }


            //run autoassignments
            system.debug('Execute AutoAssignments for activities: ');
            system.debug(selectedActivities);
            
            VTT_Utilities.AutoAssignActivities(selectedActivities);
            //reload data
            query();
            currentPageActivities  = getWActivities();
            //and restore selected attribute
            for(ActivityWrapper wrapper : currentPageActivities) 
            {
                   wrapper.selected =  selectedIDSet.contains(wrapper.ActivityObject.id);
            }

            return null;
        }
        else
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select at least one Activity.'));        
            return null;
        }    
    }

    //Functions for setting Browser variables
    public void SetIsMobileDevice() {
        String isMobileDeviceParam = ApexPages.currentPage().getParameters().get('isMobileDevice');
        isMobileDevice = (isMobileDeviceParam == 'true') ? true : false;
        System.debug('isMobileDevice: ' + isMobileDevice);
        System.debug('isGeolocationAvailable: ' + isGeolocationAvailable + ' latitude: ' + currentLatitude + ' longitude: ' + currentLongitude);
    }

    public void SetGeolocation() {
        currentLatitude = Decimal.valueOf(ApexPages.currentPage().getParameters().get('latitude'));
        currentLongitude = Decimal.valueOf(ApexPages.currentPage().getParameters().get('longitude'));
        isGeolocationAvailable = true;
        System.debug('isMobileDevice: ' + isMobileDevice);
        System.debug('isGeolocationAvailable: ' + isGeolocationAvailable + ' latitude: ' + currentLatitude + ' longitude: ' + currentLongitude);
    }

    public PageReference SetBrowserVariables() {
        System.debug('isMobileDevice: ' + isMobileDevice);
        System.debug('isGeolocationAvailable: ' + isGeolocationAvailable + ' latitude: ' + currentLatitude + ' longitude: ' + currentLongitude);
        return null;
    }

   public class FilterWrapper
   {
    public String scheduledFilter{get;set;}
    public String assignedFilter{get;set;}
    public String routeFilter{get;set;}
    public String filterName{get;set;}    
    public String activityStatusFilter{get;set;}    
    public Boolean hideCompletedFilter{get;set;}  
    public String amuFilter{get;set;}  
    public String workCenterFilter{get;set;}      
    public String orderTypeFilter{get;set;}  
    public String vendorFilter{get;set;}      
    public String tradesmanFilter{get;set;}      
    public String priorityFilter{get;set;}     
    public String workOrderStatusFilter{get;set;}     
    public String plannerGroupFilter{get;set;} 

    public Boolean hideONHOLDFilter{get;set;}  



    public List<String> activityMultiStatusFilter{get;set;}     

    public FilterWrapper()
    {
        scheduledFilter='';
        //assignedFilter='1';
        plannerGroupFilter = '';
        routeFilter = '';
        filterName='';
        activityStatusFilter ='';
        hideCompletedFilter = true;
        hideONHOLDFilter = false; //ssd - 11.05.2016 change request release 1 - remove Hide On Hold Filter
        amuFilter = '';
        workCenterFilter= '';
        orderTypeFilter = '';

        priorityFilter = '';
        workOrderStatusFilter = '';
        
        vendorFilter = '';
        tradesmanFilter = '';  

        activityMultiStatusFilter = new List<String>();
    }

    public String CreateSQLFilter()
    {
        String FilteredSOQL = ' Name!=null AND SAP_Deleted__c = false and Status__c <> \'' + VTT_Utilities.ACTIVITY_STATUS_CANCELLED + '\' '; //always true

            if(workOrderStatusFilter !='' && workOrderStatusFilter!= null  )
            {
                    filteredSOQL  = filteredSOQL + ' and Maintenance_Work_Order__r.User_Status_Code__c like \'%' +  String.escapeSingleQuotes(workOrderStatusFilter) + '%\''; 
            }  
            if(plannerGroupFilter !='' && plannerGroupFilter!= null  )
            {
                    filteredSOQL  = filteredSOQL + ' and Maintenance_Work_Order__r.Planner_Group__c = \'' + String.escapeSingleQuotes(plannerGroupFilter) + '\''; 
            }  

            
            if(priorityFilter !='' && priorityFilter!= null  )
            {
                    filteredSOQL  = filteredSOQL + ' and Maintenance_Work_Order__r.Work_Order_Priority_Number__c = \'' + String.escapeSingleQuotes(priorityFilter) + '\''; 
            }  

            if(vendorFilter !='' && vendorFilter!= null && vendorFilter !='1' )
            {
                    filteredSOQL  = filteredSOQL + ' and Assigned_Vendor__c = \'' + vendorFilter + '\'';
            }  
            if(vendorFilter == '1' )
            {
                    filteredSOQL  = filteredSOQL + ' and Assigned_Vendor__c = null ';
            }  

            if(tradesmanFilter !='' && tradesmanFilter!= null && tradesmanFilter !='1')
            {
                    filteredSOQL  = filteredSOQL + ' and id in (select Work_Order_Activity__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Tradesman__c =\'' + tradesmanFilter+  '\')';
            }  
            if(tradesmanFilter == '1' )
            {
                    filteredSOQL  = filteredSOQL + ' and Number_of_assigned_people__c = 0 ';
            }              

            if(orderTypeFilter !='' && orderTypeFilter!= null )
            {
                filteredSOQL  = filteredSOQL + ' and Maintenance_Work_Order__r.Order_Type__c = \'' + String.escapeSingleQuotes(orderTypeFilter) + '\'';
            }  

            if(workCenterFilter !='' && workCenterFilter!= null )
            {
                filteredSOQL  = filteredSOQL + ' and Work_Center__c like \'%' +  String.escapeSingleQuotes(workCenterFilter) + '%\'';
            }  

            if(routeFilter !='' && routeFilter!= null )
            {
                filteredSOQL  = filteredSOQL + ' and Maintenance_Work_Order__r.Plant_Section__c = \'' + String.escapeSingleQuotes(routeFilter) + '\'';
            }  
            if(amuFilter !='' && amuFilter!= null )
            {
                filteredSOQL  = filteredSOQL + ' and Maintenance_Work_Order__r.Operating_Field_AMU_Lookup__c = \'' + String.escapeSingleQuotes(amuFilter) + '\'';
            }  


            if(scheduledFilter !='' && scheduledFilter!= null )
            {
                filteredSOQL  = filteredSOQL + ' and Scheduled_Start_Date__c = ' + scheduledFilter;
            }  

            if(filterName !='' && filterName!= null )
            {
                filteredSOQL  = filteredSOQL + ' and (Name like \'%' +  String.escapeSingleQuotes(filterName) + '%\'';
                filteredSOQL  = filteredSOQL + ' or Assigned_Text__c like \'%' +  String.escapeSingleQuotes(filterName) + '%\'';                    
                filteredSOQL  = filteredSOQL + ' or Functional_Location_Description_SAP__c like \'%' +  String.escapeSingleQuotes(filterName) + '%\'';
                filteredSOQL  = filteredSOQL + ' or Maintenance_Work_Order__r.Name like \'%' +  String.escapeSingleQuotes(filterName) + '%\''; 
                filteredSOQL  = filteredSOQL + ' or Location_Name__c like \'%' +  String.escapeSingleQuotes(filterName) + '%\')'; 

            } 
            //if(activityStatusFilter !='' && activityStatusFilter!= null )
            //{
            //    filteredSOQL  = filteredSOQL + ' and Status__c = \'' + activityStatusFilter + '\'';
            //} 

            if(hideCompletedFilter)
            {
                filteredSOQL  = filteredSOQL + ' and Status__c <> \'' + VTT_Utilities.ACTIVITY_STATUS_COMPLETED + '\'';
            }
            if(hideONHOLDFilter == true)
            {
                filteredSOQL  = filteredSOQL + ' and Maintenance_Work_Order__r.On_Hold__c = false';
            }            

            if(activityMultiStatusFilter !=null && activityMultiStatusFilter.size()> 0)
            {
                String inClause = String.format( '(\'\'{0}\'\')', 
                         new List<String> { String.join( activityMultiStatusFilter , '\',\'') });

                filteredSOQL  = filteredSOQL + ' and Status__c in ' + inClause;
            } 

            return FilteredSOQL;
        

    }


   }

/*Wrapper class*/   
    public class ActivityWrapper
    {
        public Boolean selected {get; set;}
        public Work_Order_Activity__c ActivityObject {get;set;}   

        ActivityWrapper(Work_Order_Activity__c pActivityRecord)
        {
            this.ActivityObject = pActivityRecord;
        }    
    }        
}