@isTest
public class VTT_TestData {

    private static final String serviceCategoryCode = 'MNT';  // Maintenance service category code
    private static final String notificationTypeCode = 'WP';
    private static final String orderTypeCode = 'WP01';
    private static final String matCode = 'TXN';
    private static final List<String> WORKORDERRECORDTYPE = new List<String>{'Flushby - Production Flush', 'Coil Tubing Unit - Rod Side Entry'};
    private static final String notificationNumber = 'TEST_NOTI';
    private static final String catalogueCode = 'CATCODE';
    private static final String partCode = 'PARTCODE';
    private static Id recordTypeId;

    //Related Objects Interface
    public static HOG_Service_Code_MAT__c serviceCodeMAT;
    public static HOG_Work_Order_Type__c workOrderType;
    public static HOG_Notification_Type_Priority__c notificationTypePriority;
    public static HOG_Service_Category__c serviceCategory;
    public static HOG_Service_Code_Group__c serviceCodeGroup;
    public static HOG_Notification_Type__c notificationType;
    public static HOG_Service_Required__c serviceRequiredList;
    public static HOG_User_Status__c userStatus;
    public static HOG_Service_Priority__c servicePriorityList;
    public static Business_Unit__c businessUnit;
    public static Business_Department__c businessDepartment;
    public static Operating_District__c operatingDistrict;
    public static Field__c field;
    public static Route__c route;
    public static Location__c location;    
    public static Facility__c facility;    
    public static Equipment__c equipment;
    public static HOG_Part__c equipmentPart;
    public static HOG_Damage__c equipmentPartDamage;
    public static HOG_Cause__c equipmentPartDamageCause;      

    private static User createUser(){
        User user = new User();
        
        Profile p = [select id from profile where name='Standard User'];
        
		Double random = Math.Random();

        user.email = 'VTTUser' +  random + '@vtt.com';
        user.Alias = 'VTTUser' ;
        user.EmailEncodingKey = 'UTF-8';
        user.LastName = 'User';
        user.LanguageLocaleKey = 'en_US'; 
        user.LocaleSidKey = 'en_US'; 
        user.ProfileId = p.Id;
        user.TimeZoneSidKey = 'America/Los_Angeles'; 
        user.UserName = 'VTTUser' + random + '@VTT.com.unittest';
        
        insert user;
        
        return user;    
    }
    
    private static User assignPermissionSet(User user, String userPermissionSetName){
    
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name =: userPermissionSetName]; 
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
        
        permissionSetAssignment.PermissionSetId = permissionSet.Id;
        permissionSetAssignment.AssigneeId = user.Id; 
        
        insert permissionSetAssignment;
            
        return user;
    }

    public static User createVTTUser() {
        User user = createUser();
        user = assignPermissionSet(user,VTT_Utilities.USER_PERMISSIONSET_NAME);
        
        return user;
    }
    
    public static User createVendorSupervisorUser() {
        User user = createUser();
        user = assignPermissionSet(user,VTT_Utilities.VENDORSUPERVISOR_PERMISSIONSET_NAME);
        
        return user;
    }    
    
    public static User createVTTAdminUser() {
        User user = createUser();
        user = assignPermissionSet(user,VTT_Utilities.ADMIN_PERMISSIONSET_NAME);
        
        return user;
    }  

    public static Contact createTradesmanContact(String pFirstName, String pLastName, ID pAccountId) {
        User user = createVTTUser();
        Contact tradesman = createTradesmanContact(pFirstName, pLastName, pAccountId, user.ID);
        return tradesman;
    }  
    public static Contact createTradesmanContact(String pFirstName, String pLastName,  ID pAccountId, ID pUserID) {
        Double random = Math.Random();
        String emailString  = 'VTTUser' +  random + '@vtt.com';

        Contact tradesman =  new Contact(firstName=pFirstName, lastName=pLastName, email=emailString);
        tradesman.AccountID = pAccountId;
        tradesman.User__c = pUserID;
        tradesman.recordTypeID = VTT_Utilities.GetVendorContactRecordTypeId();
        insert tradesman;
        
        return tradesman;
    }  

    public static Account createVendorAccount(String pAccountName) {
        Account vendorAccount = new Account(NAme = pAccountName);
        vendorAccount.recordtypeID = VTT_Utilities.GetVendorAccountRecordTypeID();
        insert vendorAccount;
        return vendorAccount;
    }

	public static HOG_Maintenance_Servicing_Form__c createWorkOrder(Id serviceRequestId, Id notificationTypeId)
	{

		MaintenanceServicingUtilities.executeTriggerCode = false;   // do not to execute trigger	
        Double random = Math.Random();

        HOG_Maintenance_Servicing_Form__c record = new HOG_Maintenance_Servicing_Form__c
        (
            Name = 'Test Name' + random,
            Functional_Location__c = 'Test FLOC',
            Work_Order_Number__c = (''+random).left(15),
            Notification_Type__c = 'WP',
            HOG_Notification_Type__c = notificationTypeId,
            Order_Type__c = 'WP01',
            MAT_Code__c = 'TXN',
            ALT_Confirmed__c = true,
            HOG_Service_Request_Notification_Form__c = serviceRequestId           
        );
        insert record;
        return  record;
	}

	public static HOG_Maintenance_Servicing_Form__c reloadWorkOrder(ID pWorkOrderId)
	{
		HOG_Maintenance_Servicing_Form__c record = [select id, name, Functional_Location__c, Work_Order_Number__c, Notification_Type__c,
		Order_Type__c, MAT_Code__c, ALT_Confirmed__c, Service_Status__c, User_Status_Code__c,
		(select id, name, Status__c, User_Status__c from Work_Order_Activities__r)
		from HOG_Maintenance_Servicing_Form__c where id=:pWorkOrderId][0];
		return record;
	}


	public static Work_Order_Activity__c createWorkOrderActivity(ID pWorkOrderID)
	{
         Work_Order_Activity__c record = new Work_Order_Activity__c
        (
            Name = 'Test Name',
            Maintenance_Work_Order__c = pWorkOrderID,
            Status__c = 'New',
            SAP_Assigned__c = null
        );
        insert record;
        return  record;
	}
	public static Work_Order_Activity__c reloadWorkOrderActivity(ID pWorkOrderActivityID)
	{
		Work_Order_Activity__c record = [select id, name, 
		Maintenance_Work_Order__c,
		Maintenance_Work_Order__r.On_Hold__c,
		Maintenance_Work_Order__r.Equipment__c,
		Maintenance_Work_Order__r.Equipment__r.Catalogue_Code__c,
        Maintenance_Work_Order__r.Notification_Number__c,
        Maintenance_Work_Order__r.Main_Work_Centre__c,
        Maintenance_Work_Order__r.Location__c,
        Maintenance_Work_Order__r.Facility__c,
        Location__c,
        Facility__c,
        Cause__c,
        Part_Key__c,
        Cause_Text__c,
        Work_Details__c,
		Part__r.Part_Code__c,
		Part__r.Part_Description__c,
		Assigned_Vendor__c, Status__c, Status_Reason__c, User_Status__c ,
        LastModifiedById,
        LastModifiedDate,
        (select id, Name, Tradesman_Status__c, Account.Name,
                    Phone, Tradesman_Status_Date__c
             from Working_Tradesmen__r)
		from Work_Order_Activity__c where id=:pWorkOrderActivityID][0];
		return  record;
	}


	public static List<Work_Order_Activity__c> createWorkOrderActivitiesWithAssignments(ID pWorkOrderID, ID pTradesmanID, Integer numberOfActivities)
	{

		List<Work_Order_Activity__c> activityList = new List<Work_Order_Activity__c>();
		for(Integer num = 0; num < numberOfActivities; num++)
		{
	        Decimal random = Math.random();	
	        Work_Order_Activity__c record = new Work_Order_Activity__c
	        (
	            Name = 'Test Name ' + random,
	            Maintenance_Work_Order__c = pWorkOrderID,
	            Status__c = 'New',
	            SAP_Assigned__c = null
	        );
			activityList.add(record);
		}
        insert activityList;
        system.debug(activityList);
        
        if(pTradesmanID <> null)
        {
            List<Work_Order_Activity_Assignment__c> assignmentList = new List<Work_Order_Activity_Assignment__c>();
            for(Work_Order_Activity__c record :activityList)
            {
                 assignmentList.add(new Work_Order_Activity_Assignment__c
                                        (
                                            Work_Order_Activity__c = record.id,
                                            Tradesman__c = pTradesmanID
                                        )
                );
            }
            insert assignmentList;
            system.debug(assignmentList);
        }

        return  activityList;
	}


	public static Work_Order_Activity_Assignment__c createWorkOrderActivityAssignment(ID pWorkOrderActivityID, ID pTradesmanID)
	{
         Work_Order_Activity_Assignment__c record = new Work_Order_Activity_Assignment__c
        (
            Work_Order_Activity__c = pWorkOrderActivityID,
            Tradesman__c = pTradesmanID
        );
        insert record;
        return  record;
	}			

	public static Work_Order_Activity_Assignment_Rule__c createAutoassignmentRule(String pName, ID pAccountID,
		String pMATCode, String pOrderType, String pPlannerGroup, String pPlantSection, 
		String pRecipient, String pUnloadingPoint, String pWorkCenter)
	{
        Work_Order_Activity_Assignment_Rule__c record = new Work_Order_Activity_Assignment_Rule__c
        (
        	Name = pName,
        	Active__c = true,
        	MAT_Code__c = pMATCode,
        	Order_Type__c = pOrderType,
        	Planner_Group__c = pPlannerGroup,
        	Plant_Section__c = pPlantSection,
        	Recipient__c = pRecipient,
        	Unloading_Point__c = pUnloadingPoint,
        	Work_Center__c = pWorkCenter,
        	Assigned_To_Vendor__c = pAccountID
        );
        insert record;
        return  record;
	}			

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    public static HOG_Service_Request_Notification_Form__c createServiceRequest() {
        //-- Begin setup of data needed for Maintenance Servicing --//                
        //-- Setup Service Category
        if(serviceCategory == null) {
            serviceCategory = new HOG_Service_Category__c
                (
                    Name = 'Test Category 1',
                    Service_Category_Code__c = serviceCategoryCode                                
                );
            insert serviceCategory;
        }

        //-- Setup Notification Type
        if(notificationType == null) {
            notificationType = new HOG_Notification_Type__c
                (
                    HOG_Service_Category__c = serviceCategory.Id,
                    Notification_Type__c = notificationTypeCode,
                    Order_Type__c = orderTypeCode
                );
            insert notificationType;
        }
        //--
  
        //-- Setup Service Code MAT
        if(serviceCodeMAT == null) {        
            serviceCodeMAT = ServiceCodeMATTestData.createServiceCodeMAT('Test MAT1', matCode, 'Master');       
            insert serviceCodeMAT;
        }         
        //--

        //-- Setup Service Required
        if(serviceRequiredList == null) {
            serviceRequiredList = ServiceRequiredTestData.createServiceRequired('Test Service Required', true, true, true);
            insert serviceRequiredList;
        }
        //--

        //-- Setup Service User Status
        if(userStatus == null) {
            userStatus = UserStatusTestData.createUserStatus('Test User Status', 'Test Description');
            insert userStatus;
        }
        //--

        //-- Setup Work Order Type
        if(workOrderType == null) {
            workOrderType = WorkOrderTypeTestData.createWorkOrderType(notificationType.Id, serviceCodeMAT.Id, serviceRequiredList.Id, userStatus.Id, WORKORDERRECORDTYPE[0], true);
            insert workOrderType;
        }
        //--

        ServiceRequestNotificationUtilities.executeTriggerCode = false;
        HOG_Service_Request_Notification_Form__c testServiceRequest = ServiceRequestNotificationFormTestData.createServiceRequestNotificationForm
                (
                    null,
                    workOrderType.Id, 
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    'W87654321',
                    'W87654321',
                    'Test Detail',
                    null,
                    null        
                );      
        insert testServiceRequest;
        ServiceRequestNotificationUtilities.executeTriggerCode = true;
        return testServiceRequest;
    }

    //Specific createServiceRigRequest for VTT_ActivityDetailTimeLogControllerXTest
    public static HOG_Service_Request_Notification_Form__c createServiceRequest(
        HOG_Work_Order_Type__c pWorkOrderType
    ) {
        ServiceRequestNotificationUtilities.executeTriggerCode = false;
        HOG_Service_Request_Notification_Form__c testServiceRequest = ServiceRequestNotificationFormTestData.createServiceRequestNotificationForm
                (
                    null,
                    pWorkOrderType.Id, 
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    'W87654321',
                    'W87654321',
                    'Test Detail',
                    null,
                    null        
                );      
        insert testServiceRequest;
        ServiceRequestNotificationUtilities.executeTriggerCode = true;
        return testServiceRequest;
    }

    /************************************ Related Data Interface Setup ******************************************/
    public static void SetupRelatedTestData() {        
        //-- Begin setup of data needed for Maintenance Servicing --//                
        //-- Setup Service Category
        serviceCategory = new HOG_Service_Category__c
            (
                Name = 'Test Category',
                Service_Category_Code__c = serviceCategoryCode                                
            );
        insert serviceCategory;

        //-- Setup Service Code Group
        serviceCodeGroup = ServiceCodeGroupTestData.createServiceCodeGroup('Test Group', true);
        insert serviceCodeGroup;
        //--

        //-- Setup Notification Type
        notificationType = new HOG_Notification_Type__c
            (
                HOG_Service_Category__c = serviceCategory.Id,
                Notification_Type__c = notificationTypeCode,
                Order_Type__c = orderTypeCode
            );
        insert notificationType;
        //--
  
        //-- Setup Service Code MAT        
        serviceCodeMAT = ServiceCodeMATTestData.createServiceCodeMAT('Test MAT1', matCode, 'Master');       
        insert serviceCodeMAT;        
        //--

        //-- Setup Service Required
        serviceRequiredList = ServiceRequiredTestData.createServiceRequired('Test Service Required', true, true, true);
        insert serviceRequiredList;
        //--

        //-- Setup Service User Status
        userStatus = UserStatusTestData.createUserStatus('Test User Status', 'Test Description');
        insert userStatus;
        //--

        //-- Setup Service - Priority
        servicePriorityList = ServicePriorityTestData.createServicePriority('Service Priority 1', 1, '1');
        insert servicePriorityList;
        //--
                
        //-- Setup Notification Type - Priority Detail
        notificationTypePriority = NotificationTypePriorityTestData.createNotificationTypePriority(notificationType.Id, servicePriorityList.Id, false);
        insert notificationTypePriority;        
        //--

        //-- Setup Work Order Type
        workOrderType = WorkOrderTypeTestData.createWorkOrderType(notificationType.Id, serviceCodeMAT.Id, serviceRequiredList.Id, userStatus.Id, WORKORDERRECORDTYPE[0], true);
        insert workOrderType;
        //--

        //-- Setup objects for Maintenance Work Order                                 
        businessUnit = new Business_Unit__c(Name = 'Test Business Unit');
        insert businessUnit;

        businessDepartment = BusinessDepartmentTestData.createBusinessDepartment('Test Business Department');    
        insert businessDepartment;

        operatingDistrict = OperatingDistrictTestData.createOperatingDistrict('Test Field', businessDepartment.Id, businessUnit.Id);
        insert operatingDistrict;
            
        recordTypeId = [Select Id From RecordType Where SObjectType = 'Field__c' And Name = 'HOG - Control Room Centre Record'].Id;

        field = FieldTestData.createField('Test Field Control Centre', operatingDistrict.Id, recordTypeId);
        insert field;

        User operatorOnCallUser = VTT_TestData.createVTTUser();  

        route = RouteTestData.createRoute('999');
        route.Fluid_Management__c = true;
        insert route;    

        Operator_On_Call__c operatorOnCall = new Operator_On_Call__c
           (
            Operator__c = operatorOnCallUser.Id,
            Operator_Route__c = route.Id
           );
        insert operatorOnCall;  

        route.Operator_On_Call__c = operatorOnCall.Id;
        update route;          

        location = LocationTestData.createLocation('Test Location', route.Id, field.Id);    
        insert location;

        facility = FacilityTestData.createFacility('Test Facility', route.Id, field.Id);
        insert facility;        
            
        equipment = new Equipment__c
          (
            Name = 'Equipment Test',
            Location__c = location.Id,         
            Catalogue_Code__c = catalogueCode
            );                
        insert equipment;

        equipmentPart = HOGPartTestData.createHOGPart('Test Part', partCode, 'Test Part', catalogueCode, true);
        insert equipmentPart;    

        equipmentPartDamage = HOGDamageTestData.createHOGDamage('Test Damage', 'DMGECODE', 'Test Damage', partCode, true);
        insert equipmentPartDamage;    

        equipmentPartDamageCause = HOGCauseTestData.createHOGCause('Test Cause', 'DMGECODE', 'Test Cause', 'CDEGROUP', true);
        insert equipmentPartDamageCause;
    }
    /******************************************************************************************************/
}