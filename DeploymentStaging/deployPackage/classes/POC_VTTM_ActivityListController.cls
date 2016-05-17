public without sharing class POC_VTTM_ActivityListController {

	public List<Work_Order_Activity__c> assignedActivities   {get; private set;}
	public List<Work_Order_Activity__c> allActivities   {get; private set;}
	private Set<Id> assignedActivityIds;

	public Contact Tradesman {get; private set;}
	public Boolean IsAdmin {get;private set;}
    public Boolean IsVendorSupervisor {get;private set;}

    //Browser Variables
    public Boolean isMobileDevice {get; private set;}
    public Boolean isGeolocationAvailable {get; private set;}
    private Decimal tradesmanLatitude;
    private Decimal tradesmanLongitude;

	public POC_VTTM_ActivityListController() {

		Tradesman = VTT_Utilities.LoadTradesmanInfo();
		IsAdmin = VTT_Utilities.IsAdminUser();   
        IsVendorSupervisor =  VTT_Utilities.IsVendorSupervisor();

        assignedActivities = [
				select Id, Name, Assigned_Vendor__c, Description__c, 
				Work_Center__c, Assigned_Text__c, Location_Name__c,
				Maintenance_Work_Order__r.User_Status_Code__c, 
				Maintenance_Work_Order__r.Work_Order_Priority_Number__c, 
				Maintenance_Work_Order__r.Order_Type__c, 
				Maintenance_Work_Order__r.Name, 
				Maintenance_Work_Order__r.Location__r.Name,
				Maintenance_Work_Order__r.Location__r.Route__r.Route_Number__c, 
				Maintenance_Work_Order__r.Plant_Section__c,
				Maintenance_Work_Order__r.Order_Description__c,
				Maintenance_Work_Order__r.Description_of_Equipment__c,
				Maintenance_Work_Order__r.Required_End_Date__c,
				Maintenance_Work_Order__r.Location__c,
				Scheduled_Start_Date__c,
				Scheduled_Finish_Date__c,
				Status__c, 
				Status_Reason__c 
				from Work_Order_Activity__c 
				where 
				id in (select Work_Order_Activity__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Tradesman__c =  :tradesman.ID)
				And Status__c != :VTT_Utilities.ACTIVITY_STATUS_COMPLETED
				order by Scheduled_Start_Date__c
				Limit 1000
			];

		assignedActivityIds = new Set<Id>();
		for(Work_Order_Activity__c activity : assignedActivities) {
			assignedActivityIds.add(activity.Id);
		}

        if(IsAdmin) {
        	allActivities = [select Id, Name, Assigned_Vendor__c, Description__c, 
				Work_Center__c, Assigned_Text__c, Location_Name__c, 
				Maintenance_Work_Order__r.User_Status_Code__c, 
				Maintenance_Work_Order__r.Work_Order_Priority_Number__c, 
				Maintenance_Work_Order__r.Order_Type__c, 
				Maintenance_Work_Order__r.Name, 
				Maintenance_Work_Order__r.Location__r.Name,
				Maintenance_Work_Order__r.Location__r.Route__r.Route_Number__c,
				Maintenance_Work_Order__r.Plant_Section__c,
				Maintenance_Work_Order__r.Order_Description__c,
				Maintenance_Work_Order__r.Description_of_Equipment__c,
				Maintenance_Work_Order__r.Required_End_Date__c,
				Maintenance_Work_Order__r.Location__c,
				Scheduled_Start_Date__c,
				Scheduled_Finish_Date__c,
				Status__c, 
				Status_Reason__c 
				from Work_Order_Activity__c
				Where Id Not In :assignedActivityIds
				order by Scheduled_Start_Date__c
				Limit 1000];
        } else if (IsVendorSupervisor) {
        	allActivities = [select Id, Name, Assigned_Vendor__c, Description__c, 
				Work_Center__c, Assigned_Text__c, Location_Name__c,
				Maintenance_Work_Order__r.User_Status_Code__c, 
				Maintenance_Work_Order__r.Work_Order_Priority_Number__c, 
				Maintenance_Work_Order__r.Order_Type__c, 
				Maintenance_Work_Order__r.Name, 
				Maintenance_Work_Order__r.Location__r.Name,
				Maintenance_Work_Order__r.Location__r.Route__r.Route_Number__c, 
				Maintenance_Work_Order__r.Plant_Section__c,
				Maintenance_Work_Order__r.Order_Description__c,
				Maintenance_Work_Order__r.Description_of_Equipment__c,
				Maintenance_Work_Order__r.Required_End_Date__c,
				Maintenance_Work_Order__r.Location__c,
				Scheduled_Start_Date__c,
				Scheduled_Finish_Date__c,
				Status__c, 
				Status_Reason__c 
				from Work_Order_Activity__c
				where Assigned_Vendor__c = :Tradesman.AccountId
				And Id Not In :assignedActivityIds
				order by Scheduled_Start_Date__c
				Limit 1000];
        }
	}

	public PageReference StartWork()
    {
        Tradesman.Tradesman_Status__c = VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK;
        Tradesman.Tradesman_Status_Date__c = Datetime.now();

        try {
            update Tradesman;
        } catch(DmlException ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot start work: ' + ex.getMessage()));
            return null;
        } finally {
            Tradesman = VTT_Utilities.LoadTradesmanInfo();
        }

        return null;
    }

    public Boolean GetCanStartWork()
    {
        return Tradesman.Current_Work_Order_Activity__c == null && 
        Tradesman.Tradesman_Status__c != VTT_Utilities.Tradesman_Status_StartedWork &&
        Tradesman.Tradesman_Still_Working__c == false;
    }

    //Functions for setting Browser variables
    public void SetIsMobileDevice() {
        String isMobileDeviceParam = ApexPages.currentPage().getParameters().get('isMobileDevice');
        isMobileDevice = (isMobileDeviceParam == 'true') ? true : false;
        System.debug('isMobileDevice: ' + isMobileDevice);
        System.debug('isGeolocationAvailable: ' + isGeolocationAvailable + ' latitude: ' + tradesmanLatitude + ' longitude: ' + tradesmanLongitude);
    }

    public void SetGeolocation() {
    	String lat = ApexPages.currentPage().getParameters().get('latitude');
    	String longt = ApexPages.currentPage().getParameters().get('longitude');
        tradesmanLatitude = (lat!= null) ? Decimal.valueOf(lat) : null;
        tradesmanLongitude = (longt != null) ? Decimal.valueOf(longt) : null;
        isGeolocationAvailable = true;
        System.debug('isMobileDevice: ' + isMobileDevice);
        System.debug('isGeolocationAvailable: ' + isGeolocationAvailable + ' latitude: ' + tradesmanLatitude + ' longitude: ' + tradesmanLongitude);
    }
}