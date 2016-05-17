@isTest
private class VTT_EmailNotificationsTest {
	
	@isTest static void Test_MISSINGVENDOR() {
		//Setup Data
		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');

		MaintenanceServicingUtilities.executeTriggerCode = false; 		
		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

		workOrder.Order_Type__c = 'WP01';
        workOrder.MAT_Code__c = 'TXN';
        update workOrder;
        //create 10unassigned  activities
		VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.id, null, 10);

		//set generic email address for field scheduler
        HOG_Settings__c settingsHOG = new HOG_Settings__c();
        settingsHOG.VTT_Generic_Field_Scheduler__c = 'test@test.com'; 
        insert settingsHOG;


		Test.startTest();
		VTT_EmailNotifications notificationBatch = new VTT_EmailNotifications(VTT_EmailNotifications.NOTIFICATIONTYPE_MISSINGVENDOR);
		ID batchprocessid = Database.executeBatch(notificationBatch);

		System.assertNotEquals(null, notificationBatch.query);

		String query = notificationBatch.query;
		List<Work_Order_Activity__c> workOrderActivityList = (List<Work_Order_Activity__c>)	Database.query(query);	

		//should be 10 activities
		System.assertEquals(10, workOrderActivityList.size());

		//should be 1 email generated
		Messaging.SingleEmailMessage[] emailList = notificationBatch.GenerateMissingVendorEmails(workOrderActivityList);
		System.assertEquals(1, emailList.size());

		Test.StopTest();

		//System.assertNotEquals(0, VTT_EmailNotifications.emailLimits);
	}
	
	@isTest static void Test_MISSINGTRADESMAN() {
		//Setup Data
		User supervisorUser1 = VTT_TestData.createVendorSupervisorUser();
		User supervisorUser2 = VTT_TestData.createVendorSupervisorUser();


        System.runAs(supervisorUser1) {

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, supervisorUser1.id);	
			Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id, supervisorUser2.id);	
		

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        	HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

			workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;
	        //create 10 unassigned  activities
			List<Work_Order_Activity__c> activityList = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.id, null, 5);
			//assign these activities to vendor 1
			for(Work_Order_Activity__c activityRec : activityList)
			{
				activityRec.Scheduled_Start_Date__c = Date.today();
				activityRec.Assigned_Vendor__c = vendor1.id;
			}
			update activityList;


			//set generic email address for field scheduler
	        HOG_Settings__c settingsHOG = new HOG_Settings__c();
	        settingsHOG.VTT_Generic_Field_Scheduler__c = 'test@test.com'; 
	        insert settingsHOG;


			Test.startTest();
			VTT_EmailNotifications notificationBatch = new VTT_EmailNotifications(VTT_EmailNotifications.NOTIFICATIONTYPE_MISSINGTRADESMAN);
			ID batchprocessid = Database.executeBatch(notificationBatch);

			System.assertNotEquals(null, notificationBatch.query);

			String query = notificationBatch.query;
			List<Work_Order_Activity__c> workOrderActivityList = (List<Work_Order_Activity__c>)	Database.query(query);	
			system.debug(query);

			//should be 5 activities
			System.assertEquals(5, workOrderActivityList.size());

			//should be 1 email generated for both vendor supervisors because of the same account
			Messaging.SingleEmailMessage[] emailList = notificationBatch.GenerateMissingTradesmanEmails(workOrderActivityList);
			System.assertEquals(1, emailList.size());
			system.debug(emailList[0]);

			Test.StopTest();
		}

	}

	@isTest static void Test_ACTIVITYINPROGRESS() {
		//Setup Data
		//set generic email address for field scheduler
		User tradesmanUser1 = VTT_TestData.createVTTUser();
		User supervisorUser1 = VTT_TestData.createVendorSupervisorUser();
		User runningUser = VTT_TestData.createVTTAdminUser();	
			
		System.runAs(runningUser) {
	        HOG_Settings__c settingsHOG = new HOG_Settings__c();
	        settingsHOG.VTT_Generic_Field_Scheduler__c = 'test@test.com'; 
	        insert settingsHOG;

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');

			Contact contact1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, tradesmanUser1.id);	
			

			Contact contact2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id, supervisorUser1.id);	

			//tradesman reports to supervisor
			contact1.ReportsToId = contact2.id;

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        	HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

			workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;
	        //create 10 unassigned  activities
			List<Work_Order_Activity__c> activityList = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.id, contact1.id, 5);
			//assign these activities to vendor 1
			for(Work_Order_Activity__c activityRec : activityList)
			{
				activityRec.Scheduled_Start_Date__c = Date.today();
				activityRec.Assigned_Vendor__c = vendor1.id;
			}
			update activityList;

			Work_Order_Activity_Log_Entry__c logEntry = VTT_Utilities.CreateLogEntry(contact1, 
	        							activityList[0], 
	        							VTT_Utilities.LOGENTRY_STARTJOB,
	        							0,
	        							0,
	        							null,
	        							'Starting Job');
			//lets make it 3 hours ago
			logEntry.TimeStamp__c = Datetime.now().addHours(-3);
			insert logEntry;
			VTT_Utilities.UpdateTradesmanStatus(contact1,  VTT_Utilities.TRADESMAN_STATUS_PREWORK, activityList[0].id);
			contact1.Tradesman_Status_Date__c =Datetime.now().addHours(-3);
			update contact1;

			Test.startTest();
			VTT_EmailNotifications notificationBatch = new VTT_EmailNotifications(VTT_EmailNotifications.NOTIFICATIONTYPE_ACTIVITYINPROGRESS);
			ID batchprocessid = Database.executeBatch(notificationBatch);

			System.assertNotEquals(null, notificationBatch.query);

			String query = notificationBatch.query;
			List<Work_Order_Activity__c> workOrderActivityList = (List<Work_Order_Activity__c>)	Database.query(query);	
			system.debug(query);

			//should be 1 in progress activity
			System.assertEquals(1, workOrderActivityList.size());

			//should be 2 emails generated, one for tradesman, one for vendor supervisor
			Messaging.SingleEmailMessage[] emailList = notificationBatch.GenerateActivitiesInProgressEmails(workOrderActivityList);
			System.assertEquals(2, emailList.size());
			system.debug(emailList[0]);

			Test.StopTest();
		}
	}

	@isTest static void Test_ACTIVITYASSIGNMENT_TRADESMAN() {
		//Setup Data
		User tradesmanUser1 = VTT_TestData.createVTTUser();
		User runningUser =VTT_TestData.createVTTAdminUser();

		System.runAs(runningUser) {
			//Setup configurable days for Notification
	        HOG_Settings__c settingsHOG = new HOG_Settings__c();
	        settingsHOG.VTT_AssignedEmailNotificationDuration__c = 14; 
	        insert settingsHOG;

			//Create Vendors and Tradesman
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact contact1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, tradesmanUser1.id);

			//Create Work Order and Activities
			MaintenanceServicingUtilities.executeTriggerCode = false;
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        	HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
			workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;
	        //create 5 unassigned  activities
			List<Work_Order_Activity__c> activityList = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.Id, contact1.Id, 5);
			//assign these activities to vendor 1
			for(Work_Order_Activity__c activityRec : activityList)
			{
				activityRec.Scheduled_Start_Date__c = Date.today().addDays(Integer.valueOf(settingsHOG.VTT_AssignedEmailNotificationDuration__c));
				activityRec.Assigned_Vendor__c = vendor1.id;
			}
			update activityList;

			Test.startTest();
			VTT_EmailNotifications notificationBatch = new VTT_EmailNotifications(VTT_EmailNotifications.NOTIFICATIONTYPE_ACTIVITYASSIGNMENT_TRADESMAN);
			System.debug('Test_ACTIVITYASSIGNMENT_TRADESMAN: ' + notificationBatch.query);
			Id batchprocessid = Database.executeBatch(notificationBatch);

			System.assertNotEquals(null, notificationBatch.query);

			String query = notificationBatch.query;
			List<Work_Order_Activity__c> workOrderActivityList = (List<Work_Order_Activity__c>)	Database.query(query);	

			//should be 5 assigned activities at Duration
			System.assertEquals(5, workOrderActivityList.size());

			//should be 5 email generated for field scheduler
			Messaging.SingleEmailMessage[] emailList = notificationBatch.GenerateTradesmanAssignmentApproachingEmail(workOrderActivityList);
			System.assertEquals(5, emailList.size());
			system.debug(emailList[0]);

			Test.StopTest();			
		}
	}

	@isTest static void Test_MISSINGTRADESMAN_NotifyFieldScheduler() {
		//Setup Data
		User supervisorUser1 = VTT_TestData.createVendorSupervisorUser();
		User supervisorUser2 = VTT_TestData.createVendorSupervisorUser();
		User runningUser = VTT_TestData.createVTTAdminUser();	
			
		System.runAs(runningUser) {
			//set generic email address for field scheduler
	        HOG_Settings__c settingsHOG = new HOG_Settings__c();
	        settingsHOG.VTT_Generic_Field_Scheduler__c = 'test@test.com'; 
	        insert settingsHOG;

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');


			Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, supervisorUser1.id);	

			Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id, supervisorUser2.id);	
		

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        	HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

			workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;
	        //create 10 unassigned  activities
			List<Work_Order_Activity__c> activityList = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.id, null, 5);
			//assign these activities to vendor 1
			for(Work_Order_Activity__c activityRec : activityList)
			{
				activityRec.Scheduled_Start_Date__c = Date.today();
				activityRec.Assigned_Vendor__c = vendor1.id;
			}
			update activityList;

			Test.startTest();
			VTT_EmailNotifications notificationBatch = new VTT_EmailNotifications(VTT_EmailNotifications.NOTIFICATIONTYPE_MISSINGTRADESMAN_FIELDSCHEDULER);
			ID batchprocessid = Database.executeBatch(notificationBatch);

			System.assertNotEquals(null, notificationBatch.query);

			String query = notificationBatch.query;
			List<Work_Order_Activity__c> workOrderActivityList = (List<Work_Order_Activity__c>)	Database.query(query);	
			system.debug(query);

			//should be 5 activities
			System.assertEquals(5, workOrderActivityList.size());

			//should be 1 email generated for field scheduler
			Messaging.SingleEmailMessage[] emailList = notificationBatch.GenerateFieldSchedulerMissingTradesmanEmails(workOrderActivityList);
			System.assertEquals(1, emailList.size());
			system.debug(emailList[0]);

			Test.StopTest();
		}

	}

	@isTest static void Test_GenerateVendorSupervisorRejectedActivityEmails() {
		User supervisorUser = VTT_TestData.createVendorSupervisorUser();
		User runningUser = VTT_TestData.createVTTAdminUser();	
			
		System.runAs(runningUser) {
			//Setup Data
			Account vendor = VTT_TestData.createVendorAccount('Vendor1');
			Contact tradesman = VTT_TestData.createTradesmanContact('Test', 'Tradesman', vendor.Id);
			Contact supervisor = VTT_TestData.createTradesmanContact('Test', 'Supervisor',  vendor.Id, supervisorUser.Id);

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();               
        	HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

			workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;

	        //Create and assign work order activity
	        List<Work_Order_Activity__c> activityList = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.Id, tradesman.Id, 1);
	        activityList[0].Scheduled_Start_Date__c = Date.today();
			activityList[0].Assigned_Vendor__c = vendor.id;
			activityList[0].Vendor_Supervisor__c = supervisor.id;
			update activityList;

			Test.startTest();
				List<Work_Order_Activity_Assignment__c> assignmentList = [Select Id, Name, Work_Order_Activity__c, Tradesman__c,
																				Reject_Reason__c
																		  From Work_Order_Activity_Assignment__c
																		  Where Work_Order_Activity__c =: activityList[0].Id];

				VTT_EmailNotifications notificationBatch = new VTT_EmailNotifications();
				Messaging.SingleEmailMessage[] emailList = notificationBatch.GenerateVendorSupervisorRejectedActivityEmails(assignmentList);
				System.assertEquals(1, emailList.size());
				system.debug(emailList[0]);
			Test.stopTest();
		}
	}
	
	@isTest static void Test_GenerateVendorSupervisorAutoAssignEmails() {

		User supervisorUser1 = VTT_TestData.createVendorSupervisorUser();
		User supervisorUser2 = VTT_TestData.createVendorSupervisorUser();
		User runningUser = VTT_TestData.createVTTAdminUser();	
			
		System.runAs(runningUser) {

			//Setup Data
			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Contact supervisor1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, supervisorUser1.id);	
			Contact supervisor2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id, supervisorUser2.id);	
		

			MaintenanceServicingUtilities.executeTriggerCode = false; 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        	HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);

			workOrder.Order_Type__c = 'WP01';
	        workOrder.MAT_Code__c = 'TXN';
	        update workOrder;
	        //create 5 activities assigned to vendor but without assigned tradesman
			List<Work_Order_Activity__c> activityList = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.id, null, 5);
			for(Work_Order_Activity__c activityRec : activityList)
			{
				activityRec.Scheduled_Start_Date__c = Date.today();
				activityRec.Assigned_Vendor__c = vendor1.id;
				activityRec.Vendor_Supervisor__c = supervisor1.id;
			}
			update activityList;

			Test.startTest();

			VTT_EmailNotifications notificationBatch = new VTT_EmailNotifications();

			List<Work_Order_Activity__c> activityListForNotification = [select Id, Name, Assigned_Vendor__c, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, 
			 	Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c,
				Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, 
				Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c ,
		        Vendor_Supervisor__c,
	    	    Vendor_Supervisor__r.email,
	    	    Functional_Location_Description_SAP__c,
	    	    Description_of_Equipment__c
		        FROM Work_Order_Activity__c
	    	    WHERE id in :activityList];


			Messaging.SingleEmailMessage[] emailList = notificationBatch.GenerateVendorSupervisorAutoAssignEmails(activityListForNotification);
			System.assertEquals(1, emailList.size());
			system.debug(emailList[0]);

			Test.StopTest();

		}
	}

	@isTest static void Test_EmailNotificationsSchedule() {
		
		Test.startTest();
			List<String> jobNames = new List<String> {
				'VTT Email Notification - Activity Assignment - 1 AM',
				'VTT Email Notification to Vendor - Missing Tradesman - 10 AM',
				'VTT Email Notification to Vendor - Missing Tradesman - 2 PM',
				'VTT Email Notification to Field Scheduler - Missing Vendor - 10 AM',
				'VTT Email Notification to Field Scheduler - Missing Vendor - 2 PM',
				'VTT Email Notification to Field Scheduler - Missing Tradesman - 10 AM',
				'VTT Email Notification to Field Scheduler - Missing Tradesman - 2 PM',
				'VTT Email Notification - Activity In Progress - 5 PM',
				'VTT Email Notification - Activity In Progress - 6 PM',
				'VTT Email Notification - Activity In Progress - 7 PM',
				'VTT Email Notification - Activity In Progress - 8 PM',
				'VTT Email Notification - Activity In Progress - 9 PM',
				'VTT Email Notification - Activity In Progress - 10 PM',
				'VTT Email Notification - Activity In Progress - 11 PM',
				'VTT Email Notification - Activity In Progress - Midnight'
			};

			VTT_EmailNotificationSchedule.scheduleThisJob();

			List<CronTrigger> cts = [SELECT Id, CronJobDetail.Name
         							 FROM CronTrigger
         							 Where CronJobDetail.Name In :jobNames];
         	System.assertEquals(jobNames.size(), cts.size());
		Test.stopTest();
	}
}