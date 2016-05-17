@isTest
private class POC_VTTM_ActivityListControllerTest {

	//Test Configuration
	private static Integer NUMBER_OF_UNASSIGNED_ACTIVITIES= 5;
	private static Integer NUMBER_OF_ASSIGNED_ACTIVITIES_ADMIN = 2;
	private static Integer NUMBER_OF_ASSIGNED_ACTIVITIES_SUPERVISOR = 3;
	private static Integer NUMBER_OF_ASSIGNED_ACTIVITIES_TRADESMAN = 4;
	
	@isTest static void testAsAdmin() {
		User adminUser = VTT_TestData.createVTTAdminUser();

		System.runAs(adminUser) {
			Account vendor = VTT_TestData.createVendorAccount('Vendor1');
			Contact adminUserContact = VTT_TestData.createTradesmanContact('Test', 'AdminUser',  vendor.Id, adminUser.Id);

	      	//Setup Work Order
	      	MaintenanceServicingUtilities.executeTriggerCode = false;       
	        HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
	        HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
	        workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;

	        //Setup Unassigned Activities Vendor
	        List<Work_Order_Activity__c> unassignedActivities = new List<Work_Order_Activity__c>();
	        for(Integer i=0; i < NUMBER_OF_UNASSIGNED_ACTIVITIES; i++) {
	        	Work_Order_Activity__c activity = VTT_TestData.createWorkOrderActivity(workOrder.Id);
	        	activity.Assigned_Vendor__c = vendor.Id;
	        	unassignedActivities.add(activity);
	        }
	        update unassignedActivities;

	        //Setup Assigned Activities for Admin
	        List<Work_Order_Activity__c> assignedActivitiesAdmin = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.Id, adminUserContact.Id, NUMBER_OF_ASSIGNED_ACTIVITIES_ADMIN);

			POC_VTTM_ActivityListController controller = new POC_VTTM_ActivityListController();
			System.assertEquals(controller.allActivities.size(), NUMBER_OF_UNASSIGNED_ACTIVITIES);
			System.assertEquals(controller.assignedActivities.size(), NUMBER_OF_ASSIGNED_ACTIVITIES_ADMIN);
		}
	}

	@isTest static void testAsSupervisor() {
		User supervisorUser = VTT_TestData.createVendorSupervisorUser();
		User tradesmanUser = VTT_TestData.createVTTUser();

		System.runAs(supervisorUser) {
			Account vendor = VTT_TestData.createVendorAccount('Vendor1');
			Contact supervisorUserContact = VTT_TestData.createTradesmanContact('Test', 'SupervisorUser',  vendor.Id, supervisorUser.Id);
			Contact tradesmanUserContact = VTT_TestData.createTradesmanContact('Test', 'Tradesmand',  vendor.Id, tradesmanUser.Id);

	      	//Setup Work Order
	      	MaintenanceServicingUtilities.executeTriggerCode = false;       
	        HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
	        HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
	        workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;

	        //Setup Unassigned Activities Vendor
	        List<Work_Order_Activity__c> unassignedActivities = new List<Work_Order_Activity__c>();
	        for(Integer i=0; i < NUMBER_OF_UNASSIGNED_ACTIVITIES; i++) {
	        	Work_Order_Activity__c activity = VTT_TestData.createWorkOrderActivity(workOrder.Id);
	        	activity.Assigned_Vendor__c = vendor.Id;
	        	unassignedActivities.add(activity);
	        }
	        update unassignedActivities;

	        //Setup Assigned Activities for Supervisor
	        List<Work_Order_Activity__c> assignedActivitiesSupervisor = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.Id, supervisorUserContact.Id, NUMBER_OF_ASSIGNED_ACTIVITIES_SUPERVISOR);

	        //Setup Assigned Activities for Tradesman
	        List<Work_Order_Activity__c> assignedActivitiesTradesman = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.Id, tradesmanUserContact.Id, NUMBER_OF_ASSIGNED_ACTIVITIES_TRADESMAN);

			POC_VTTM_ActivityListController controller = new POC_VTTM_ActivityListController();
			System.assertEquals(controller.allActivities.size(), NUMBER_OF_UNASSIGNED_ACTIVITIES + NUMBER_OF_ASSIGNED_ACTIVITIES_TRADESMAN);
			System.assertEquals(controller.assignedActivities.size(), NUMBER_OF_ASSIGNED_ACTIVITIES_SUPERVISOR);
		}

	}

	@isTest static void testStartWork() {
		User tradesmanUser = VTT_TestData.createVTTUser();

		System.runAs(tradesmanUser) {
			Account vendor = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesmanUserContact = VTT_TestData.createTradesmanContact('Test', 'Tradesmand',  vendor.Id, tradesmanUser.Id);

			POC_VTTM_ActivityListController controller = new POC_VTTM_ActivityListController();
			System.assertEquals(controller.GetCanStartWork(), true);
			controller.StartWork();
			tradesmanUserContact = VTT_Utilities.LoadTradesmanInfo();
			System.assertEquals(tradesmanUserContact.Tradesman_Status__c, VTT_Utilities.TRADESMAN_STATUS_STARTEDWORK);
			System.assertEquals(controller.GetCanStartWork(), false);
		}
	}

	@isTest static void testMobileAndGeolocation() {
		PageReference pageRef = Page.POC_VTTM_ActivityList;
        Test.setCurrentPageReference(pageRef);
        POC_VTTM_ActivityListController controller = new POC_VTTM_ActivityListController();
        controller.SetIsMobileDevice();
        controller.SetGeolocation();
        System.assertEquals(controller.isMobileDevice, false);
        System.assertEquals(controller.isGeolocationAvailable, true);
	}
	
}