public without sharing class VTT_TradesmanAssignmentControllerX {

	private final Work_Order_Activity__c woActivity;
    public SelectOption[] selectedTradesmen { get; set; }
    public SelectOption[] allTradesmen { get; set; }    
    public SelectOption[] vendorAccounts { get; set; }
    public ID assignedVendor {get; set;}
    public Boolean assignedVendorDisabled {get; private set;}
    public Contact Tradesman {get; private set;}

	public VTT_TradesmanAssignmentControllerX(ApexPages.StandardController stdController) {
        this.woActivity = (Work_Order_Activity__c)stdController.getRecord();

        VendorAccountsSetup();
        assignedVendor = this.woActivity.Assigned_Vendor__c; 
        TradesmanAssignmentSetup();        		

		Tradesman = VTT_Utilities.LoadTradesmanInfo();
		assignedVendorDisabled = false;
		if(VTT_Utilities.IsVendorSupervisor() 
            && Tradesman.accountid <> null 
            && assignedVendor == Tradesman.accountid)
		{
			assignedVendorDisabled = true;
		} 

        if(this.woActivity.Status__c == VTT_Utilities.ACTIVITY_STATUS_COMPLETED) 
        {
            assignedVendorDisabled = true;  
            String message = 'You can not change assignment for completed activity.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message));              
        }      
	}

    public PageReference UpdateAssignment()
    {

        //first delete everything from assignment table

        List<Work_Order_Activity_Assignment__c> assignmentListToDelete =  [select id, Tradesman__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Work_Order_Activity__c = :woActivity.id];


        List<Work_Order_Activity_Assignment__c> assignmentListToCreate = new List<Work_Order_Activity_Assignment__c>();

        for ( SelectOption so : selectedTradesmen ) {
            Work_Order_Activity_Assignment__c assinmentRecord = new Work_Order_Activity_Assignment__c();
            assinmentRecord.Tradesman__c = so.getValue();
            assinmentRecord.Work_Order_Activity__c = this.woActivity.id;
            assignmentListToCreate.add(assinmentRecord);
        }

        this.woActivity.Assigned_Vendor__c = this.assignedVendor;
        

        final Savepoint savePoint = Database.setSavepoint();
        try
        {                    
            delete assignmentListToDelete;
            insert assignmentListToCreate; 
            upsert this.woActivity;                       
        }
        catch (Exception e)
        {
            Database.rollback(savePoint);                        
            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));                                    
            return null;
        }






        PageReference pageRef = new PageReference('/apex/VTT_ActivityDetailTimeLog?id=' + this.woActivity.id);
        pageRef.setRedirect(true);
        return pageRef;  
    }

    public PageReference ExitAssignment()
    {

        PageReference pageRef = new PageReference('/apex/VTT_ActivityDetailTimeLog?id=' + this.woActivity.id);
        pageRef.setRedirect(true);
        return pageRef;  
    }

    private void  VendorAccountsSetup()
    {

        List<Account> accountList =VTT_Utilities.GetVendorAccountList();

        vendorAccounts = new List<SelectOption>();
        for(Account acc: accountList)
        {
            SelectOption accOption = new SelectOption(acc.id, acc.Name);
            vendorAccounts.add(accOption);
        }
    }

    public void  TradesmanAssignmentSetup()
    {
        selectedTradesmen = new List<SelectOption>();
        allTradesmen  = new List<SelectOption>();

        //assignedVendor; 
		Set<ID> assignedContactSet = new Set<ID>();


        if(assignedVendor ==this.woActivity.Assigned_Vendor__c)
        {

	        for(Work_Order_Activity_Assignment__c woaa : [select id, Tradesman__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Work_Order_Activity__c = :woActivity.id])
	        {
	            assignedContactSet.add(woaa.Tradesman__c);
	        }

	        for(Contact tradesmancontact : [select id, name, Phone, email, Tradesman_Status__c, Current_Work_Order_Activity__c, Tradesman_Status_Date__c, User__c 
	                                        from Contact where id in :assignedContactSet order by name])
	        {
	            SelectOption accOption = new SelectOption(tradesmancontact.id, tradesmancontact.Name);
	            selectedTradesmen.add(accOption);
	        }        	
        }


        List<Contact> contactList = [select id, name from Contact 
        where AccountID = :assignedVendor 
        and user__c <> null
        order by name limit 1000];

        for(Contact contactRec: contactList)
        {

        	if(!assignedContactSet.contains(contactRec.id))
        	{
	            SelectOption accOption = new SelectOption(contactRec.id, contactRec.Name);
	            allTradesmen.add(accOption);        		
        	}

        }  




    }

}