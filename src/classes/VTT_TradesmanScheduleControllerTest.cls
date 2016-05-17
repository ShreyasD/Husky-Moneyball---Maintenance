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
private class VTT_TradesmanScheduleControllerTest {
	
	@isTest static void Test_Controller_AsAdminUser() {  

        User runningUser = VTT_TestData.createVTTAdminUser();
        System.AssertNotEquals(runningUser.Id, Null);

        System.runAs(runningUser) {
        	MaintenanceServicingUtilities.executeTriggerCode = false;
        	VTT_TestData.SetupRelatedTestData();

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Account vendor2 = VTT_TestData.createVendorAccount('Vendor2');

			Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
			Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				

			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest(VTT_TestData.workOrderType);       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
            workOrder1.User_Status_Code__c = '5X';
            workOrder1.Order_Type__c = 'WP01';
            workOrder1.Plant_Section__c  = '200';       
            workOrder1.Work_Order_Priority_Number__c  = '1';    
            workOrder1.Equipment__c = VTT_TestData.equipment.Id;
            workOrder1.Location__c = VTT_TestData.location.Id;
            workOrder1.Operating_Field_AMU_Lookup__c = VTT_TestData.field.Id;
			update workOrder1;
			 

	        List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 5);
	        //fine tuning of the one activity  to be able to filter it
	        Work_Order_Activity__c woActivity = activityList1[0];
	        woActivity.Scheduled_Start_Date__c = System.now();
	        update woActivity;

	        Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

		    Test.startTest();
	        

			System.AssertEquals(true, VTT_Utilities.IsAdminUser());
			System.assertEquals(5, activityList1.size());			

            PageReference pageRef = Page.VTT_TradesmanCalendar;
            Test.setCurrentPageReference(pageRef);	


			//create some timelog data
		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
            VTT_ActivityDetailTimeLogControllerX controller1 = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			VTT_WorkFlowEngine workflowEngine = controller1.workflowEngine;			
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting Job';
            workflowEngine.GenericActivity_End();
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting At Site 1';
            workflowEngine.GenericActivity_End();            





            VTT_TradesmanScheduleController controller = new VTT_TradesmanScheduleController();

            System.AssertEquals(vendor1.id, controller.AccountID); 
            System.AssertEquals(2, controller.VendorAccoountOptions.size());  
            System.AssertEquals(2, controller.TradesmenOptions.size());              
            controller.TradesmanID = tradesman1.id;
            controller.ReloadEvents();
            System.AssertEquals(1, controller.events.size());


			controller.AccountID = vendor2.id;
			controller.LoadTradesmanList();
			//no tradesmen for second vendor
            System.AssertEquals(0, controller.TradesmenOptions.size());

            System.AssertEquals(null, controller.TradesmanID);

			Datetime currentDatetime = Datetime.now();
			String currentDatetimeStr = currentDatetime.format('yyyy-MM-dd');            
            controller.CurrentDate = currentDatetimeStr;
            System.AssertEquals(null, controller.ReloadLogEntries()); 
            System.AssertEquals(0, controller.LogEntryList.size());     

            System.AssertNotEquals(null, controller.PageReload());     
            
            //runningUser should have Work_Order_Activity__c woActivity as Current_Work_Order_Activity__c
            //so when he click on Job In Progress button he should be taken to detail page of this activity
            PageReference pagere = new PageReference('/apex/VTT_ActivityDetailTimeLog?id=' + woActivity.Id);
			System.assertEquals(pagere.getUrl(), controller.JobInProgress().getUrl());
        }
	    /////////////////
	    //* STOP TEST *//
	    /////////////////
	    Test.stopTest();    		


	}

	@isTest static void Test_Controller_AsVendorSupervisorUser() {

        User runningUser = VTT_TestData.createVendorSupervisorUser();
        System.AssertNotEquals(runningUser.Id, Null);

        System.runAs(runningUser) {
        	MaintenanceServicingUtilities.executeTriggerCode = false;  
			VTT_TestData.SetupRelatedTestData();

			Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
			Account vendor2 = VTT_TestData.createVendorAccount('Vendor2');

			Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
			Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				
 		
			HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest(VTT_TestData.workOrderType);       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
			workOrder1.User_Status_Code__c = '5X';
            workOrder1.Order_Type__c = 'WP01';
            workOrder1.Plant_Section__c  = '200';       
            workOrder1.Work_Order_Priority_Number__c  = '1';    
            workOrder1.Equipment__c = VTT_TestData.equipment.Id;
            workOrder1.Location__c = VTT_TestData.location.Id;
            workOrder1.Operating_Field_AMU_Lookup__c = VTT_TestData.field.Id;
			update workOrder1;
			 

	        List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 5);
	        //fine tuning of the one activity  to be able to filter it
	        Work_Order_Activity__c woActivity1 = activityList1[0];
	        woActivity1.Scheduled_Start_Date__c = System.now();
	        update woActivity1;

	        Work_Order_Activity__c woActivity2 = activityList1[1];
	        woActivity2.Scheduled_Start_Date__c = System.now();
	        update woActivity2;

	        Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity1.id);

		    Test.startTest();
	        

			System.AssertEquals(true, VTT_Utilities.IsVendorSupervisor());
			System.assertEquals(5, activityList1.size());			

            PageReference pageRef = Page.VTT_TradesmanCalendar;
            Test.setCurrentPageReference(pageRef);	


			//create some timelog data
		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
            VTT_ActivityDetailTimeLogControllerX controller1 = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			VTT_WorkFlowEngine workflowEngine = controller1.workflowEngine;			
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting Job';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivityCopy.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller1 = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller1.workflowEngine;

            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting At Site 1';
            workflowEngine.GenericActivity_End();

            VTT_TradesmanScheduleController controller = new VTT_TradesmanScheduleController();

            System.AssertEquals(vendor1.id, controller.AccountID); 
            System.AssertEquals(tradesman1.id, controller.TradesmanID); 
            System.AssertEquals(null, controller.VendorAccoountOptions);  
            System.AssertEquals(2, controller.TradesmenOptions.size());              
            controller.ReloadEvents();
            System.AssertEquals(2, controller.events.size());

			Datetime currentDatetime = Datetime.now();
			String currentDatetimeStr = currentDatetime.format('yyyy-MM-dd');            
            controller.CurrentDate = currentDatetimeStr;
            System.AssertEquals(null, controller.ReloadLogEntries()); 
            System.AssertEquals(2, controller.LogEntryList.size());  

			//	lets update TimeStamp__c on the first LogEntry so we get some hours
			system.debug(controller.LogEntryList);
			Work_Order_Activity_Log_Entry__c logEntryItem = controller.LogEntryList[0];
			logEntryItem.TimeStamp__c = logEntryItem.TimeStamp__c.addHours(-1);
			update logEntryItem;
			controller.ReloadLogEntries();

			system.debug('*****************controller.LogEntryList****************');
			system.debug(controller.LogEntryList);


			System.AssertEquals(1, controller.WorkOrderSummaryList.size()); 

            System.AssertNotEquals(null, controller.PageReload());     
            
          

        }

	    /////////////////
	    //* STOP TEST *//
	    /////////////////
	    Test.stopTest();
	}
}