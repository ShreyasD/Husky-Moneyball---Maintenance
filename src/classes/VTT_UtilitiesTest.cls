/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class VTT_UtilitiesTest {
	
	@isTest static void TestUpdateWorkOrderStatus() {

		User runningUser = VTT_TestData.createVTTUser();

		System.runAs(runningUser) {			
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');			
			Contact tradesman = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);	

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
			MaintenanceServicingUtilities.executeTriggerCode = true; 

	         Work_Order_Activity__c woActivity1 = new Work_Order_Activity__c
	        (
	            Name = 'Test Name1',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity1;	

	         Work_Order_Activity__c woActivity2 = new Work_Order_Activity__c
	        (
	            Name = 'Test Name2',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity2;	

			workOrder = VTT_TestData.reloadWorkOrder(workOrder.id);
			System.assertEquals(VTT_Utilities.WORKORDER_STATUS_AWAITINGONVENDORS, workOrder.Service_Status__c);	

			//lets update work Order Activities
			woActivity1.Status__c = VTT_Utilities.ACTIVITY_STATUS_COMPLETED;
			update woActivity1;
			workOrder = VTT_TestData.reloadWorkOrder(workOrder.id);
			//SHOULD BE STILL WAITING FOR VENDORS
			System.assertEquals(VTT_Utilities.WORKORDER_STATUS_AWAITINGONVENDORS, workOrder.Service_Status__c);	

			woActivity2.Status__c = VTT_Utilities.ACTIVITY_STATUS_COMPLETED;
			update woActivity2;
			workOrder = VTT_TestData.reloadWorkOrder(workOrder.id);
			System.assertEquals(VTT_Utilities.WORKORDER_STATUS_VENDORSCOMPLETE, workOrder.Service_Status__c);	
		}

	}

	@isTest static void TestUpdateActivityStatus() {
		User runningUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {		
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);	

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

	         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
	        (
	            Name = 'Test Name',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity;	

			String newActivityStatus = null;
			String newActivityStatusReason = null;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			//when status and status reason are null, no updates
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_NEW, woActivity.Status__c);	

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_STARTED;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_STARTED, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_STARTED; 
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			//we already started, cant go back
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_ONHOLD;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_ONHOLD, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_STARTED;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_STARTED, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_FINISHEDATSITE;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_FINISHEDATSITE, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_FINISHEDFORTHEDAY;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_FINISHEDFORTHEDAY, woActivity.Status__c);

			newActivityStatus = VTT_Utilities.ACTIVITY_STATUS_COMPLETED;
			VTT_Utilities.UpdateActivityStatus(woActivity, newActivityStatus, newActivityStatusReason);
			System.assertEquals(VTT_Utilities.ACTIVITY_STATUS_COMPLETED, woActivity.Status__c);
		}
	}

	@isTest static void TestBeforeUpdateActivityStatus() {
		User runningUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {		
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);	

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

	         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
	        (
	            Name = 'Test Name',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = VTT_Utilities.ACTIVITY_STATUS_ONHOLD,
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1',
	            User_Status__c = '3BEX HOLD MSPT'
	        );
			insert woActivity;	

			woActivity.User_Status__c = '3BEX MSPT';
			update woActivity;

			//Set Status of woActivity to OnHold
			woActivity = [Select Id, Name, User_Status__c, Status__c
						  From Work_Order_Activity__c
						  Where Id =: woActivity.Id];
			System.assertEquals(woActivity.Status__c, VTT_Utilities.ACTIVITY_STATUS_SCHEDULED);
		}
	}

	@isTest static void TestUpdateActivityLogEntry() {
		User runningUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {		
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);	

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

	         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
	        (
	            Name = 'Test Name',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity;

			VTT_TestData.createWorkOrderActivityAssignment(woActivity.ID, tradesman.ID);

			Work_Order_Activity_Log_Entry__c logEntry1 = VTT_Utilities.CreateLogEntry(tradesman, 
			        woActivity, 
			        VTT_Utilities.LOGENTRY_STARTJOB,
			        null,
			        null,
			        null,
			        'Test Comments');
			insert logEntry1;

			System.assertNotEquals(null, logEntry1.ID);	

			Work_Order_Activity_Log_Entry__c logEntry2 = VTT_Utilities.CreateLogEntry(tradesman, 
			        woActivity, 
			        VTT_Utilities.LOGENTRY_STARTATSITE,
			        null,
			        null,
			        null,
			        'Test Comments');
			insert logEntry2;
			System.assertNotEquals(null, logEntry2.ID);	

			//lets update logentry2 with a new timestamp
			logentry2.TimeStamp__c = logentry2.TimeStamp__c.addMinutes(30);
			update logentry2;

			//lets reload logentry1 and check 	StatusEnd__c
			logEntry1 = [select id, name, TimeStamp__c, StatusEnd__c from Work_Order_Activity_Log_Entry__c where id = :logEntry1.id][0];
			System.assertEquals(logEntry2.TimeStamp__c, logEntry1.StatusEnd__c );

			//lets delete second log entry and reload first log entry
			delete logentry2;
			logEntry1 = [select id, name, TimeStamp__c, StatusEnd__c from Work_Order_Activity_Log_Entry__c where id = :logEntry1.id][0];
			System.assertEquals(null, logEntry1.StatusEnd__c);
		}

	}	

	@isTest static void TestCanChangeActivityStatusFromTo() {
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(null,VTT_Utilities.ACTIVITY_STATUS_STARTED));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_SCHEDULED,VTT_Utilities.ACTIVITY_STATUS_STARTED));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_NEW,VTT_Utilities.ACTIVITY_STATUS_STARTED));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_ONHOLD,VTT_Utilities.ACTIVITY_STATUS_STARTED));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_STARTED,VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE,VTT_Utilities.ACTIVITY_STATUS_FINISHEDATSITE));

		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_FINISHEDATSITE,VTT_Utilities.ACTIVITY_STATUS_STARTEDATSITE));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_FINISHEDATSITE,VTT_Utilities.ACTIVITY_STATUS_FINISHEDFORTHEDAY));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_FINISHEDATSITE,VTT_Utilities.ACTIVITY_STATUS_COMPLETED));

		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(VTT_Utilities.ACTIVITY_STATUS_FINISHEDFORTHEDAY,VTT_Utilities.ACTIVITY_STATUS_STARTED));

		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(null,VTT_Utilities.ACTIVITY_STATUS_COMPLETED));
		System.assert(VTT_Utilities.CanChangeActivityStatusFromTo(null,VTT_Utilities.ACTIVITY_STATUS_ONHOLD));

	}	

	@isTest static void TestSAP_UpdateWorkOrderActivityStatus() {
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new SAPHOGUpdateWorkOrderResponseMock());

		MaintenanceServicingUtilities.executeTriggerCode = false; 		
		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
        (
            Name = 'Test Name',
            Maintenance_Work_Order__c = workOrder.id,
            Status__c = 'New',
            SAP_Assigned__c = null,
            Work_Center__c = '500',
            Recipient__c = 'Recipient1',
            Unloading_Point__c = 'UnloadingPoint1'
        );
		insert woActivity;


		Test.startTest();
		VTT_Utilities.SAP_UpdateWorkOrderActivityStatus(woActivity.id, '3BX');
		Test.stopTest();
		System.assertNotEquals(null, woActivity.id);
	}	
	@isTest static void TestSAP_UpdateWorkOrderStatus() {
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new SAPHOGUpdateWorkOrderResponseMock());

		MaintenanceServicingUtilities.executeTriggerCode = false; 		
		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

		Test.startTest();
		VTT_Utilities.SAP_UpdateWorkOrderStatus(workOrder.id, '5X');
		Test.stopTest();
		System.assertNotEquals(null, workOrder.id);

	}	

	@isTest static void TestCreateLogEntry() {

		User runningUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);	

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

	         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
	        (
	            Name = 'Test Name',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity;

			VTT_TestData.createWorkOrderActivityAssignment(woActivity.ID, tradesman.ID);


			//lets pretend tradesman is not working since last 5 min, than new log entry should have stamp as 5 min ago
			tradesman.Current_Work_Order_Activity__c = null;
			tradesman.Tradesman_Status__c = VTT_Utilities.TRADESMAN_STATUS_NOTWORKING;
			DateTime lastTradesmanStatusTimeStamp = system.now().addMinutes(-5);
			tradesman.Tradesman_Status_Date__c = lastTradesmanStatusTimeStamp;


			Work_Order_Activity_Log_Entry__c logEntry = VTT_Utilities.CreateLogEntry(tradesman, 
			        woActivity, 
			        VTT_Utilities.LOGENTRY_STARTJOB,
			        null,
			        null,
			        null,
			        'Test Comments');
			insert logEntry;

			System.assertNotEquals(null, logEntry.ID);	
			//System.assertEquals(lastTradesmanStatusTimeStamp.addSeconds(10), logEntry.TimeStamp__c);			
			//Marek Kosar - fix - 4/21/2016
			System.assertEquals(lastTradesmanStatusTimeStamp.addSeconds(5), logEntry.TimeStamp__c);	
		}	
	}

	@isTest static void TestUpdateTradesmanStatus() {

		User runningUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);	
			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
			MaintenanceServicingUtilities.executeTriggerCode = true; 
			
	         Work_Order_Activity__c woActivity1 = new Work_Order_Activity__c
	        (
	            Name = 'Test Name1',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity1;	

			String newTradesmanStatus = VTT_Utilities.TRADESMAN_STATUS_PREWORK;
			VTT_Utilities.UpdateTradesmanStatus(tradesman, newTradesmanStatus, woActivity1.id);
			System.assertEquals(newTradesmanStatus, tradesman.Tradesman_Status__c);
			System.assertEquals(woActivity1.id, tradesman.Current_Work_Order_Activity__c);

			newTradesmanStatus = VTT_Utilities.TRADESMAN_STATUS_NOTWORKING;
			VTT_Utilities.UpdateTradesmanStatus(tradesman, newTradesmanStatus, woActivity1.id);
			System.assertEquals(newTradesmanStatus, tradesman.Tradesman_Status__c);
			System.assertEquals(null, tradesman.Current_Work_Order_Activity__c);
			
			newTradesmanStatus = VTT_Utilities.TRADESMAN_STATUS_PREWORK;
			List<Contact> tradesmanList = new List<Contact>(); 
			tradesmanList.add(tradesman);
			VTT_Utilities.UpdateTradesmanStatus(tradesmanList, newTradesmanStatus, woActivity1.id);
			System.assertEquals(newTradesmanStatus, tradesman.Tradesman_Status__c);
			System.assertEquals(woActivity1.id, tradesman.Current_Work_Order_Activity__c);
		}
	}

	@isTest static void TestGetVendorAccountList() {

		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');	
		Account vendor2 = VTT_TestData.createVendorAccount('Vendor2');	

	 	//////////////////
	    //* START TEST *//
	    //////////////////

	    Test.startTest();
		List<Account> accountList = VTT_Utilities.GetVendorAccountList();	    
	    /////////////////
	    //* STOP TEST *//
	    /////////////////
	    Test.stopTest();  		

		System.AssertNotEquals(vendor1.Id, Null);
		System.AssertNotEquals(vendor2.Id, Null);
		System.assertEquals(2, accountList.size());	
	}	
	@isTest static void TestLoadTradesmanInfo() {


		User runningUser = VTT_TestData.createVTTUser();

        System.runAs(runningUser) {
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);	

        	Contact currentTradesman = VTT_Utilities.LoadTradesmanInfo();
			System.AssertEquals(vendor1.id, currentTradesman.AccountId);
			System.AssertEquals('Tom Cruise', currentTradesman.Name);
        }
	}	

	@isTest static void TestIsAdminUser() {

        User runningUser = VTT_TestData.createVTTAdminUser();
        System.AssertNotEquals(runningUser.Id, Null);

	 	//////////////////
	    //* START TEST *//
	    //////////////////

	    Test.startTest();
	        
        System.runAs(runningUser) {
			System.Assert(VTT_Utilities.IsAdminUser());
        }
	    /////////////////
	    //* STOP TEST *//
	    /////////////////
	    Test.stopTest();        
	}		

	@isTest static void TestIsVendorSupervisor() {
        User runningUser = VTT_TestData.createVendorSupervisorUser();
        System.AssertNotEquals(runningUser.Id, Null);

	 	//////////////////
	    //* START TEST *//
	    //////////////////

	    Test.startTest();
	        
	        System.runAs(runningUser) {
				System.Assert(VTT_Utilities.IsVendorSupervisor());
	        }
	    /////////////////
	    //* STOP TEST *//
	    /////////////////
	    Test.stopTest();        

	}		
	@isTest static void TestAutoAssignActivities() {

		//Setup Data
		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
		Work_Order_Activity_Assignment_Rule__c assignmentRule = VTT_TestData.createAutoassignmentRule('Rule 1', vendor1.id,
		'TXN', 'WP01', null, null, 'Recipient1', 'UnloadingPoint1', '500');


		MaintenanceServicingUtilities.executeTriggerCode = false; 		
		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);


		workOrder.Order_Type__c = 'WP01';
        workOrder.MAT_Code__c = 'TXN';
        update workOrder;


         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
        (
            Name = 'Test Name',
            Maintenance_Work_Order__c = workOrder.id,
            Status__c = 'New',
            SAP_Assigned__c = null,
            Work_Center__c = '500',
            Recipient__c = 'Recipient1',
            Unloading_Point__c = 'UnloadingPoint1'
        );
		insert woActivity;

		//we need to reload activity
		Work_Order_Activity__c activityCopy = [select id, Assigned_Text__c, Assigned_Vendor__c
		FROM Work_Order_Activity__c
		WHERE id = :woActivity.id][0];

		//System.assertEquals('Tom Cruise', activityCopy.Assigned_Text__c, 'Tradesman name does not Match Assigned_Text__c');
		System.assertEquals(vendor1.id, activityCopy.Assigned_Vendor__c, 'Assigned_Vendor__c is not set');

	}
	@isTest static void TestUpdateActivityAssignmentTradesman() {

		User runningUser = VTT_TestData.createVTTUser();
		User vendorUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {	
			//Setup Data
			Account huskyAccount = VTT_TestData.createVendorAccount('Husky');
			Contact huskyTradesmanContact = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  huskyAccount.id, runningUser.id);	
			huskyTradesmanContact.Husky_AD_Username__c = 'HUSKYAD';
			update huskyTradesmanContact;

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact vendorTradesmanContact = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, vendorUser.id);
			vendorTradesmanContact.Tradesman_ID__c = 'HUSKYAD';
			update vendorTradesmanContact;

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

	         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
	        (
	            Name = 'Test Name',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity;
			
			Work_Order_Activity_Assignment__c assignmentRecord = VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, huskyTradesmanContact.id);

			//we will need to reload the record, otherwise changes made by before update trigger will not be reflected in the original record
			assignmentRecord = [select id, Tradesman__c from Work_Order_Activity_Assignment__c where id = :assignmentRecord.id][0];

			System.assertEquals(vendorTradesmanContact.id, assignmentRecord.Tradesman__c, 'Assigned Tradesman should be Vendor Tradesman, not Husky Tradesman');
		}
	}	

	@isTest static void TestValidateActivityAssignmentBeforeDelete() {

		User runningUser = VTT_TestData.createVTTUser();
		User vendorUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {	
			//Setup Data
			Account huskyAccount = VTT_TestData.createVendorAccount('Husky');
			Contact huskyTradesmanContact = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  huskyAccount.id, runningUser.id);	
			huskyTradesmanContact.Husky_AD_Username__c = 'HUSKYAD';
			update huskyTradesmanContact;

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact vendorTradesmanContact = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, vendorUser.id);
			vendorTradesmanContact.Tradesman_ID__c = 'HUSKYAD';
			update vendorTradesmanContact;

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

	         Work_Order_Activity__c woActivity = new Work_Order_Activity__c
	        (
	            Name = 'Test Name',
	            Maintenance_Work_Order__c = workOrder.id,
	            Status__c = 'New',
	            SAP_Assigned__c = null,
	            Work_Center__c = '500',
	            Recipient__c = 'Recipient1',
	            Unloading_Point__c = 'UnloadingPoint1'
	        );
			insert woActivity;

			Work_Order_Activity_Assignment__c assignmentRecord = VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, huskyTradesmanContact.id);

			//emulate tradesman currently working on this activity;
			vendorTradesmanContact.Current_Work_Order_Activity__c = woActivity.id;
			update vendorTradesmanContact;

			Test.startTest();

			//we will need to reload the record, otherwise changes made by before update trigger will not be reflected in the original record
			assignmentRecord = [select id, Tradesman__c from Work_Order_Activity_Assignment__c where id = :assignmentRecord.id][0];
			System.assertEquals(vendorTradesmanContact.id, assignmentRecord.Tradesman__c, 'Assigned Tradesman should be Vendor Tradesman, not Husky Tradesman');


			//now lets try to delete assignment
			try
			{
			  delete assignmentRecord;
			  // should throw an exception - the following assertion will cause an error if the code carries on
			  System.assert(false);
			}
			catch (DMLException e)
			{
			   // expected - could assert the message here
			}
			Test.stopTest();     

		}
	}

	@isTest static void TestIsActivityMatchTheRule() {
		//Setup Data
		MaintenanceServicingUtilities.executeTriggerCode = false; 		
		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');

		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
		Work_Order_Activity__c woActivity = VTT_TestData.createWorkOrderActivity(workOrder.id);

		workOrder.Order_Type__c = 'WP01';
        workOrder.MAT_Code__c = 'TXN';
        update workOrder;

		woActivity.Work_Center__c = '500';
		woActivity.Recipient__c = 'Recipient1';
		woActivity.Unloading_Point__c = 'UnloadingPoint1';
		update woActivity;

		//we need to reload activity
		Work_Order_Activity__c activityCopy = [select id, Name, Recipient__c,  Work_Center__c,
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
		WHERE id = :woActivity.id][0];


		system.debug('workOrder');
		system.debug(workOrder);

		Work_Order_Activity_Assignment_Rule__c assignmentRule = VTT_TestData.createAutoassignmentRule('Rule 1', vendor1.id,
		'TXN', 'WP01', null, null, 'Recipient1', 'UnloadingPoint1', '500');

		system.debug('assignmentRule');
		system.debug(assignmentRule);


		

		System.assert(VTT_Utilities.IsActivityMatchTheRule(activityCopy, assignmentRule));
	}		


	@isTest static void TestFieldValueMatchTheRule() {

		System.assert(VTT_Utilities.FieldValueMatchTheRule('111','111')); //exact match
		System.assert(VTT_Utilities.FieldValueMatchTheRule('222','111,222,333')); //comma separated list
		System.assert(VTT_Utilities.FieldValueMatchTheRule('222','111, 222 ,333')); //comma separated list with spaces
		System.assert(VTT_Utilities.FieldValueMatchTheRule('TEST','TES*')); //wild card
		System.assert(VTT_Utilities.FieldValueMatchTheRule('TEST01','111,222,TES*')); //comma separated list with wild card		
		System.assert(VTT_Utilities.FieldValueMatchTheRule('GNX1','M*, G*')); //comma separated list with wild card				
		System.assert(VTT_Utilities.FieldValueMatchTheRule('GNX1','G*, M*')); //comma separated list with wild card						
	}	
	@isTest static void TestUpdateActivityAssigneeField() {

		//Setup Data
		User runningUser = VTT_TestData.createVTTUser();
		System.runAs(runningUser) {
			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');

			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
			Work_Order_Activity__c woActivity = VTT_TestData.createWorkOrderActivity(workOrder.id);
			Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);			

			Work_Order_Activity_Assignment__c assignment1 = VTT_TestData.createWorkOrderActivityAssignment(woActivity.ID, tradesman1.ID);

			//we need to reload activity
			Work_Order_Activity__c activityCopy = [select id, Assigned_Text__c, Assigned_Vendor__c
			FROM Work_Order_Activity__c
			WHERE id = :woActivity.id][0];
			System.assertEquals('Tom Cruise', activityCopy.Assigned_Text__c, 'Tradesman name does not Match Assigned_Text__c');
			System.assertEquals(vendor1.id, activityCopy.Assigned_Vendor__c, 'Assigned_Vendor__c is not set');

			Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);
			Work_Order_Activity_Assignment__c assignment2 =  VTT_TestData.createWorkOrderActivityAssignment(woActivity.ID, tradesman2.ID);
			//we need to reload activity
			activityCopy = [select id, Assigned_Text__c, Assigned_Vendor__c
			FROM Work_Order_Activity__c
			WHERE id = :woActivity.id][0];
			System.assertEquals('Brad Pitt, Tom Cruise', activityCopy.Assigned_Text__c, 'Tradesman name does not Match Assigned_Text__c');

			assignment1.Rejected__c = true;
			update assignment1;
			//we need to reload activity
			activityCopy = [select id, Assigned_Text__c, Assigned_Vendor__c
			FROM Work_Order_Activity__c
			WHERE id = :woActivity.id][0];
			System.assertEquals('Brad Pitt', activityCopy.Assigned_Text__c, 'Tradesman name does not Match Assigned_Text__c');		


			delete assignment1;
			//we need to reload activity
			activityCopy = [select id, Assigned_Text__c, Assigned_Vendor__c
			FROM Work_Order_Activity__c
			WHERE id = :woActivity.id][0];
			System.assertEquals('Brad Pitt', activityCopy.Assigned_Text__c, 'Tradesman name does not Match Assigned_Text__c');
		}
	
	}	
	@isTest static void TestHoursToString() {

		System.assertEquals(VTT_Utilities.HoursToString(null), '');
		System.assertEquals(VTT_Utilities.HoursToString(0.5), '30 Minutes ');
		System.assertEquals(VTT_Utilities.HoursToString(1.5), '1 Hours 30 Minutes ');		
	}	

	@isTest static void TestlogError() {
		String message = 'TEST';
		VTT_Utilities.logError(message);		
		System.assert(wasMessageAdded(new ApexPages.Message(ApexPages.severity.ERROR, message)));

	}	

	private static Boolean wasMessageAdded(ApexPages.Message message) {
	      Boolean messageFound = false;

	     for(ApexPages.Message msg :  ApexPages.getMessages()) {
	         if(message.getSummary() == msg.getSummary()
	             && message.getDetail() == msg.getDetail()
	             && message.getSeverity() == msg.getSeverity()) {
	             messageFound = true;        
	         }
	     }

	     return messageFound;
	}

}