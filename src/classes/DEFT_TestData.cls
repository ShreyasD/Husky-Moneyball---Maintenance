@isTest
public class DEFT_TestData {

    private static final String serviceCategoryCode = 'WSR';  // Well Servicing service category code
    private static final String notificationTypeCode = 'RG';
    private static final String orderTypeCode = 'REX1';
    private static final String matCode = 'TXN';
	
	private static User createUser(){
        User user = new User();
        
        Profile p = [Select Id from Profile where Name='Standard HOG - General User'];
        
		Double random = Math.Random();

        user.email = 'DEFTUser' +  random + '@deft.com';
        user.Alias = 'DEFTUser' ;
        user.EmailEncodingKey = 'UTF-8';
        user.LastName = 'User';
        user.LanguageLocaleKey = 'en_US'; 
        user.LocaleSidKey = 'en_US'; 
        user.ProfileId = p.Id;
        user.TimeZoneSidKey = 'America/Los_Angeles'; 
        user.UserName = 'DEFTUser' + random + '@DEFT.com.unittest';
        
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

    private static User assignRole(User user, String userDeveloperRoleName) {
        UserRole role = [Select Id From UserRole Where DeveloperName =: userDeveloperRoleName];
        user.UserRoleId = role.Id;
        update user;
        return user;
    }

    private static User assignProfile(User user, String profileName) {
        Profile profile = [Select Id From Profile Where Name =: profileName];
        user.ProfileId = profile.Id;
        update user;
        return user;
    }

    public static User createDeftUser() {
    	User user = createUser();
    	user = assignPermissionSet(user, DEFT_Utilities.SNR_PERMISSIONSET_NAME);
    	user = assignPermissionSet(user, DEFT_Utilities.SRP_PERMISSIONSET_NAME);
        update user;
    	return user;
    }

    public static User createProductionCoordinator() {
        User user = createUser();
        return assignRole(user, 'Production_Coordinators');
    }

    public static User createServiceRigCoordinator() {
        User user = createUser();
        return assignRole(user, 'Service_Rig_Coordinator');
    }

    public static User createServiceRigPlanner() {
        User user = createUser();
        return assignProfile(user, 'Standard HOG - Administrator');
    }

    public static HOG_Service_Request_Notification_Form__c createServiceRigRequest(User runningUser, 
        User productionCoordinator, User serviceRigCoordinator) {
        //-- Begin setup of data needed for Maintenance Servicing --//                
        //-- Setup Service Category
        HOG_Service_Category__c serviceCategory = new HOG_Service_Category__c
            (
                Name = 'Test Category 1',
                Service_Category_Code__c = serviceCategoryCode                                
            );
        insert serviceCategory;

        //-- Setup Notification Type
        HOG_Notification_Type__c notificationType = new HOG_Notification_Type__c
            (
                HOG_Service_Category__c = serviceCategory.Id,
                Notification_Type__c = notificationTypeCode,
                Order_Type__c = orderTypeCode
            );
        insert notificationType;
        //--
  
        //-- Setup Service Code MAT        
        HOG_Service_Code_MAT__c serviceCodeMAT = ServiceCodeMATTestData.createServiceCodeMAT('Test MAT1', matCode, 'Master');       
        insert serviceCodeMAT;        
        //--

        //-- Setup Service Required
        HOG_Service_Required__c serviceRequiredList = ServiceRequiredTestData.createServiceRequired('Test Service Required', true, true, true);
        insert serviceRequiredList;
        //--

        //-- Setup Service User Status
        HOG_User_Status__c userStatus = UserStatusTestData.createUserStatus('Test User Status', 'Test Description');
        insert userStatus;
        //--

        //-- Setup Work Order Type
        HOG_Work_Order_Type__c testWorkOrderType = WorkOrderTypeTestData.createWorkOrderType(notificationType.Id, serviceCodeMAT.Id, serviceRequiredList.Id, userStatus.Id, 'Flushby - Production Flush', true);
        insert testWorkOrderType;
        //--

        //-- Business Unit
        Business_Unit__c businessUnit = new Business_Unit__c(
                Name = 'Test Business Unit',
                Service_Rig_Planner__c = runningUser.Id
            );
        insert businessUnit;
        //--

        //-- Business Department
        Business_Department__c businessDepartment = BusinessDepartmentTestData.createBusinessDepartment('Test Business Department');    
        insert businessDepartment;
        //--

        //-- Operating District
        Operating_District__c operatingDistrict = OperatingDistrictTestData.createOperatingDistrict('Test Field', businessDepartment.Id, businessUnit.Id);
        operatingDistrict.Production_Coordinator_User__c = productionCoordinator.Id;
        operatingDistrict.Service_Rig_Coordinator__c = serviceRigCoordinator.Id;
        operatingDistrict.Operations_Coordinator_User__c = runningUser.Id;
        insert operatingDistrict;
        //--

        //-- Operating Field AMU
        Id recordTypeId = [Select Id From RecordType Where SObjectType = 'Field__c' And Name = 'HOG - Control Room Centre Record'].Id;
        Field__c field = FieldTestData.createField('Test Field Control Centre', operatingDistrict.Id, recordTypeId);
        field.Production_Engineer_User__c = runningUser.Id;
        insert field;
        //--

        //-- Create Route Test Data
        Route__c route = new Route__c(
                Name = '111',
                Route_Number__c = '111',
                Field_Senior__c = runningUser.Id,
                Operator_1_User__c = runningUser.Id,
                Operator_2_User__c = runningUser.Id,
                Operator_3_User__c = runningUser.Id,
                Operator_4_User__c = runningUser.Id
            );
        insert route;
        //--

        //-- Well Tracker
        Location__c location = LocationTestData.createLocation('Test Location', route.Id, field.Id);
        //location.DLFL__c = false;     
        insert location;

        Facility__c facility = FacilityTestData.createFacility('Test Facility', route.Id, field.Id);
        insert facility; 

        Well_Tracker__c wellTracker = WellTrackerTestData.createWellTracker(location.Id, null, field.Id, 1, Datetime.now(), 'Producing', 'Engineering');
        insert wellTracker;
        //--

        ServiceRequestNotificationUtilities.executeTriggerCode = false;
        HOG_Service_Request_Notification_Form__c testServiceRequest = ServiceRequestNotificationFormTestData.createServiceRequestNotificationForm
                (
                    wellTracker.Id,
                    testWorkOrderType.Id,
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
        testServiceRequest.Generated_Rig_Program_Record__c = true;
        testServiceRequest.Operator_Route_Lookup__c = route.Id;
        testServiceRequest.Operating_District_Lookup__c = operatingDistrict.Id;
        testServiceRequest.Operating_Field_AMU_Lookup__c = field.Id;
        testServiceRequest.Business_Unit_Lookup__c = businessUnit.Id;     
        insert testServiceRequest;
        ServiceRequestNotificationUtilities.executeTriggerCode = true;
        return testServiceRequest;
    }

    public static HOG_Service_Rig_Program__c createServiceRigProgram(User runningUser, User productionCoordinator, User serviceRigCoordinator) {
        HOG_Service_Request_Notification_Form__c serviceRigRequest = createServiceRigRequest(runningUser, productionCoordinator, serviceRigCoordinator);

        //Process Builder should have created a Service Rig Program
        HOG_Service_Rig_Program__c serviceRigProgram = [Select Id, Name
                                                        From HOG_Service_Rig_Program__c
                                                        Where HOG_Service_Request_Notification_Form__c =: serviceRigRequest.Id];
        return serviceRigProgram;
    }

    public static HOG_EOJ__c createEOJReport(HOG_Service_Rig_Program__c serviceRigProgram) {
        HOG_EOJ__c eoj = new HOG_EOJ__c (
                Service_Rig_Program__c = serviceRigProgram.Id,
                Service_Started__c = Date.today().addDays(-5), //service started 5 days ago
                Service_Completed__c = Date.today(),
                Final_Cost__c = 5000
            );
        insert eoj;
        return eoj;
    } 
}