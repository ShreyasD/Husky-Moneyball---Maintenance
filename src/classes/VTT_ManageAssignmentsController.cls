/*-------------------------------------------------------------------------------------------------
Author     : Sergey Makarov
Company    : Husky Energy
Description: controller for VTT_ManageAssignments VF page
Inputs     : N/A
Test Class : VTT_ManageAssignmentsControllerTest
History    : 01.06.16 SM Added check for User__r.isActive = true in  PopulateTradesmanOptions()   
             02.17.16 SM added PopulateDefaultVendor                    
---------------------------------------------------------------------------------------------------*/ 
public without sharing class VTT_ManageAssignmentsController {
	
	public List<string> idlist {get; private set;}

    public SelectOption[] selectedTradesmen { get; set; }
    public SelectOption[] allTradesmen { get; set; }    
    //public SelectOption[] vendorAccounts { get; set; }

    //public ID assignedVendor {get; set;}
    //public Boolean assignedVendorDisabled {get; private set;}
    public Contact Tradesman {get; private set;}
    public Boolean IsAdmin {get;private set;}
    public Boolean IsVendorSupervisor {get;private set;}

    public Boolean AllRecordsSelected {get;set;}
    public Boolean ActivitiesSelected {get;set;}   
    public List<Work_Order_Activity__c> selectedActivities   {get; private set;}
    public Set<String> selectedActivitySet {get; private set;}


    public List<ActivityWrapper> ActivityWrapperList {get; private set;}    




    public String VendorAccount {get;  set;}
    public String VendorAccountId {get; set;}    
    //public String tradesmanFilter {get; set;}    

	public String filter {get; private set;}    

    //public List<SelectOption> TradesmanOptions {get; private set;}  

	public VTT_ManageAssignmentsController() {

        Tradesman = VTT_Utilities.LoadTradesmanInfo();
        IsAdmin = VTT_Utilities.IsAdminUser();   
        IsVendorSupervisor =  VTT_Utilities.IsVendorSupervisor(); 

		selectedActivitySet = new Set<String>();

		String idlistString  = System.currentPageReference().getParameters().get('idlist');
		if(idlistString <> null)
		{
			idlist = idlistString.split('-');
			selectedActivitySet.addAll(idlist);
		}


        filter = System.currentPageReference().getParameters().get('filter');

		AllRecordsSelected = true;
		ReloadData();

        ClearSelection();

        PopulateDefaultVendor();
	}

	private void ReloadData()
	{

		List<Work_Order_Activity__c> activityList = [select id, name, Assigned_Vendor__c, Assigned_Vendor__r.Name,
		description__c, Work_Center__c, Assigned_Text__c, Maintenance_Work_Order__r.User_Status_Code__c, 
		Maintenance_Work_Order__r.Work_Order_Priority_Number__c, Maintenance_Work_Order__r.Order_Type__c, 
		Maintenance_Work_Order__r.Name, Maintenance_Work_Order__r.Location__r.Name, 
		Maintenance_Work_Order__r.Plant_Section__c,Scheduled_Start_Date__c  ,Status__c, Status_Reason__c,
        Location_Name__c 
		from Work_Order_Activity__c where id in :idlist];

		ActivityWrapperList= new List<ActivityWrapper>();
		selectedActivities = new List<Work_Order_Activity__c>();

		for(Work_Order_Activity__c activityRec :activityList)
        {
              ActivityWrapperList.add(new ActivityWrapper(activityRec, (selectedActivitySet.contains(activityRec.id) || AllRecordsSelected) ));
              if(selectedActivitySet.contains(activityRec.id) || AllRecordsSelected)
              {
              	selectedActivities.add(activityRec);              	
              }

        }
	}

    public PageReference getSelected()
    {
        ActivitiesSelected =false;
        //selectedActivityIDs = '';
        selectedActivities.clear();

		selectedActivitySet = new Set<String>();        

        for(ActivityWrapper wrapper : ActivityWrapperList) 
        {
            if(wrapper.selected == true)
            {

            	selectedActivitySet.add(wrapper.ActivityObject.id);

                selectedActivities.add(wrapper.ActivityObject);
                if(ActivitiesSelected)
                {
                    //selectedActivityIDs += '-';
                }
                //selectedActivityIDs += wrapper.ActivityObject.id;
                ActivitiesSelected = true;
            }
        }
        return null;
    }	


 	@RemoteAction
    public static List<Account > searchAccount(String searchAccount) {
        System.debug('Account Name is: '+searchAccount);
        List<Account> result =  VTT_Utilities.GetVendorAccountList(searchAccount);
        System.debug(result);
        return result ;
    }   

    public void PopulateTradesmanOptions()
    {
		allTradesmen  = new List<SelectOption>();
		selectedTradesmen  = new List<SelectOption>();

        List<Contact> contactList = new List<Contact>(); 
        if(VendorAccountId != '')
        {
            contactList = [select id, name from Contact where AccountID = :VendorAccountId 
                and User__c <> null 
                and User__r.isActive = true
                order by name LIMIT 5000];            
        }
        for(Contact contactRec: contactList)
        {
            SelectOption accOption = new SelectOption(contactRec.id, contactRec.Name);
            allTradesmen.add(accOption); 
        }  
        system.debug(allTradesmen);
    }  

    public PageReference ClearSelection()
    {

    	allTradesmen  = new List<SelectOption>();
    	selectedTradesmen  = new List<SelectOption>();

    	if(isAdmin)
    	{
	    	VendorAccountId = null;
	    	VendorAccount = null;
    	}
    	if(IsVendorSupervisor)
    	{
    		VendorAccountId = Tradesman.AccountId;
    		PopulateTradesmanOptions();
    	}
    	return null;
    }

    public void PopulateDefaultVendor()
    {

            Set<ID> vendorIDSet = new Set<ID>();
            //loop thru the activity list
            for(Work_Order_Activity__c activityRecord : selectedActivities )
            {
                //if vendor is assigned, add vendor to the set
                if(activityRecord.Assigned_Vendor__c <> null)
                {
                    vendorIDSet.add(activityRecord.Assigned_Vendor__c);   
                }
                else //if vendor is not assigned, there is nothing to do
                {
                    return;
                }
            }

            //if all activities are assigned to the same vendor
            if(vendorIDSet.size()==1)
            {
                //get first activity record and use assigned vendor
                VendorAccountId = selectedActivities[0].Assigned_Vendor__c;
                VendorAccount = selectedActivities[0].Assigned_Vendor__r.Name;
                PopulateTradesmanOptions();                    
            }
    }


    public PageReference RemoveAssignment()
    {

        if(selectedActivities.size()==0)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select at least one Activity.'));        
            return null;
        }  
		if(VendorAccountId == null || VendorAccountId == '')
		{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select a Vendor.'));        
            return null;
		}

    	/*
    	if vendor account selected and no tradesmen - 
    	we should set Assigned Vendor to null for selected activities 
    	and remove any assigned tradesmen for those activities
		*/

		system.debug('VendorAccountId: ' + VendorAccountId);
		if(isAdmin && VendorAccountId <> null && VendorAccountId <> '' && selectedTradesmen.size() == 0)
		{
			Set<ID> activitySetToDeleteAssignments = new Set<ID>();
			for(Work_Order_Activity__c activityRecord : selectedActivities )
			{

				if(activityRecord.Assigned_Vendor__c <> null && activityRecord.Assigned_Vendor__c == VendorAccountId)
				{
					activitySetToDeleteAssignments.add(activityRecord.id);
					activityRecord.Assigned_Vendor__c = null;
					activityRecord.Assigned_Text__c = null;
				}
			}

        	List<Work_Order_Activity_Assignment__c> assignmentList =  [select id, Tradesman__c 
        				from Work_Order_Activity_Assignment__c 
        				where Work_Order_Activity__c in :activitySetToDeleteAssignments];

            final Savepoint savePoint = Database.setSavepoint();
            try
            {                    
                delete assignmentList;
                update selectedActivities;
            }
            catch (Exception e)
            {
                Database.rollback(savePoint);                        
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));                                    
            }


			ReloadData();

			return null;
		}

		/*
		if vendor account and tradesmen selected - 
		remove selected tradesmen from activity assignments
		if activity assigned vendor is different from selected vendor - don't do anything
		*/
		if(selectedTradesmen.size() > 0)
		{
			Set<ID> tradesmenSetToDeleteAssignments = new Set<ID>();

			for ( SelectOption so : selectedTradesmen ) {
			    tradesmenSetToDeleteAssignments.add(so.getValue());
			}
			
			List<Work_Order_Activity_Assignment__c> deleteAssignmentList = [ select id from Work_Order_Activity_Assignment__c
			where Work_Order_Activity__c in :selectedActivities and Tradesman__c in :tradesmenSetToDeleteAssignments];
       	

            final Savepoint savePoint = Database.setSavepoint();
            try
            {                    
                delete deleteAssignmentList;                     
            }
            catch (Exception e)
            {
                Database.rollback(savePoint);                        
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));                                    
                return null;
            }


			ReloadData();

			return null;
		}

		if(IsVendorSupervisor && selectedTradesmen.size() == 0)
		{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select at least one tradesman to remove.'));
            return null;			
		}

		return null;
	}	

    public PageReference AddAssignment()
    {

        if(selectedActivities.size()==0)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select at least one Activity.'));        
            return null;
        }  

		if(VendorAccountId == null || VendorAccountId == '')
		{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select a Vendor.'));        
            return null;
		}


    	/*
    	if only vendor account selected and no tradesmen - 
    	we should update Assigned Vendor for selected activities 
    	and remove any assigned tradesmen in case if old Assigned vendor is different
		*/

		if(VendorAccountId <> null && VendorAccountId <> '' && selectedTradesmen.size()==0)
		{
			Set<ID> activitySetToDeleteAssignments = new Set<ID>();
			for(Work_Order_Activity__c activityRecord : selectedActivities )
			{

				if(activityRecord.Assigned_Vendor__c <> null && activityRecord.Assigned_Vendor__c <> VendorAccountId)
				{
					activitySetToDeleteAssignments.add(activityRecord.id);
					activityRecord.Assigned_Text__c = null;
				}

				activityRecord.Assigned_Vendor__c = VendorAccountId;
			}

        	List<Work_Order_Activity_Assignment__c> assignmentList =  [select id, Tradesman__c 
        				from Work_Order_Activity_Assignment__c 
        				where Work_Order_Activity__c in :activitySetToDeleteAssignments];

            final Savepoint savePoint = Database.setSavepoint();
            try
            {                    
                delete assignmentList;
                update selectedActivities;
            }
            catch (Exception e)
            {
                Database.rollback(savePoint);                        
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));                                    
            }            

			ReloadData();

			return null;
		}


		/*
		if vendor account and tradesmen selected - 
		update assigned vendor for selected activities
		add selected tradesmen to activity assignments if they are not assigned yet
		remove any previous assignments if new assigned vendor is different from the old assigned vendor
		*/
		if(VendorAccountId <> null && selectedTradesmen.size() > 0)
		{
			Set<ID> activitySetToDeleteAssignments = new Set<ID>();
            Set<ID> tradesmenSetToDeleteAssignments = new Set<ID>();

            for ( SelectOption so : selectedTradesmen ) {
                tradesmenSetToDeleteAssignments.add(so.getValue());
            }

			
			List<Work_Order_Activity_Assignment__c> newAssignmentList = new List<Work_Order_Activity_Assignment__c>();

			for(Work_Order_Activity__c activityRecord : selectedActivities )
			{

				if(activityRecord.Assigned_Vendor__c <> null && activityRecord.Assigned_Vendor__c <> VendorAccountId)
				{
					activitySetToDeleteAssignments.add(activityRecord.id);
				}

				activityRecord.Assigned_Vendor__c = VendorAccountId;
				for ( SelectOption so : selectedTradesmen ) {
				    Work_Order_Activity_Assignment__c assinmentRecord = new Work_Order_Activity_Assignment__c();
				    assinmentRecord.Tradesman__c = so.getValue();
				    assinmentRecord.Work_Order_Activity__c = activityRecord.id;
				    newAssignmentList.add(assinmentRecord);
				}


			}

        	List<Work_Order_Activity_Assignment__c> assignmentList1 =  [select id, Tradesman__c 
        				from Work_Order_Activity_Assignment__c 
        				where Work_Order_Activity__c in :activitySetToDeleteAssignments];

            List<Work_Order_Activity_Assignment__c> assignmentList2 =  [select id, Tradesman__c 
                        from Work_Order_Activity_Assignment__c 
                        where Work_Order_Activity__c in :selectedActivities
                        and tradesman__c in :tradesmenSetToDeleteAssignments];

            final Savepoint savePoint = Database.setSavepoint();
            try
            {                    
                delete assignmentList1;                        
                delete assignmentList2;
                update selectedActivities;
                insert newAssignmentList;
            }
            catch (Exception e)
            {
                Database.rollback(savePoint);                        
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            }            



			ReloadData();

			return null;
		}

		return null;
    }

    public PageReference VTT_Exit()
    {

        PageReference pageRef = new PageReference('/apex/VTT_ActivityListView');
        if(filter <> null)
        {
            pageRef.getParameters().put('filter',filter);
        }
        pageRef.setRedirect(true);
        return pageRef;  

    }

	/*Wrapper class*/   
    public class ActivityWrapper
    {
        public Boolean selected {get; set;}
        public Work_Order_Activity__c ActivityObject {get;set;}   

        ActivityWrapper(Work_Order_Activity__c pActivityRecord, Boolean pSelected)
        {
            this.ActivityObject = pActivityRecord;
            this.selected = pSelected;
        }    
    }   	
}