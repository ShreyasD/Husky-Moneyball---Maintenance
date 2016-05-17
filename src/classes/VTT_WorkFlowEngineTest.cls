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
private class VTT_WorkFlowEngineTest {
    @isTest static void Test_InitialLoad_TradesmanWorkingOnAnotherActivity() {

        User runningUser = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {

            MaintenanceServicingUtilities.executeTriggerCode = false;  
            //SetupTestData();



            Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
            Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
            Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);              

            MaintenanceServicingUtilities.executeTriggerCode = false;
            HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
             

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 2);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity1 = activityList1[0];
            woActivity1.Work_Center__c ='100';
            woActivity1.Scheduled_Start_Date__c = System.now();
            update woActivity1;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity1.id, tradesman2.id);


            Work_Order_Activity__c woActivity2 = activityList1[1];
            tradesman1.Current_Work_Order_Activity__c = woActivity2.id;
            tradesman1.Tradesman_Status__c=VTT_Utilities.TRADESMAN_STATUS_PREWORK;
            update tradesman1;

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity1.id);

            Test.startTest();
            

            System.AssertEquals(false, VTT_Utilities.IsAdminUser());
            System.assertEquals(2, activityList1.size());           

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);  

            ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
            pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);          


            VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;

            System.AssertEquals(tradesman1.id, workflowEngine.Tradesman.ID, 'Not the same User');   
            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(false, workflowEngine.CanExecuteAction,'Tradesmanis working on another activity so he should be able to perform actions');            
            /////////////////
            //* STOP TEST *//
            /////////////////
            Test.stopTest();  

        }
   
    }
    @isTest static void Test_InitialLoad_WorkOrderOnHold() {
        MaintenanceServicingUtilities.executeTriggerCode = false;  
        //SetupTestData();

        User runningUser = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {        

            Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
            Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
            Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);              

            MaintenanceServicingUtilities.executeTriggerCode = false;       
            HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
            workOrder1.User_Status_Code__c = '5X HOLD';
            update workOrder1;
             

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 2);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity1 = activityList1[0];
            woActivity1.Work_Center__c ='100';
            woActivity1.Scheduled_Start_Date__c = System.now();
            update woActivity1;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity1.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity1.id);

            Test.startTest();
            

            System.AssertEquals(false, VTT_Utilities.IsAdminUser());
            System.assertEquals(2, activityList1.size());           

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);  

            ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
            pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);          


            VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;

            System.AssertEquals(tradesman1.id, workflowEngine.Tradesman.ID, 'Not the same User');   
            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(false, workflowEngine.CanExecuteAction,'Tradesmanis working on another activity so he should be able to perform actions');            
      
            /////////////////
            //* STOP TEST *//
            /////////////////
            Test.stopTest();  
          }   
    }

	
	@isTest static void Test_InitialLoad_AssignedTradesman() {
		MaintenanceServicingUtilities.executeTriggerCode = false;  
		//SetupTestData();

        User runningUser = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {

    		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
    		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
    		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				

    		MaintenanceServicingUtilities.executeTriggerCode = false; 		
    		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
    		 

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

    	    Test.startTest();
	        

			System.AssertEquals(false, VTT_Utilities.IsAdminUser());
			System.assertEquals(1, activityList1.size());			

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);	

		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
		    pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			


			VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;


            System.AssertEquals(tradesman1.id, workflowEngine.Tradesman.ID, 'Not the same User');   
            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(true, workflowEngine.userHasEditAccess,'As Assigned Tradesman Current User should be able to perform actions');

            System.AssertEquals(false, workflowEngine.CanCompleteJob,'Can not complete the job yet');
            System.AssertEquals(true, workflowEngine.CanExecuteAction);            
            System.AssertEquals(false, workflowEngine.CanPutActivityOnHold);
            System.AssertEquals(true, workflowEngine.CanRejectActivity);            
            /////////////////
            //* STOP TEST *//
            /////////////////
            Test.stopTest();         
        }
    
	}
	@isTest static void Test_InitialLoad_NotAssignedTradesman() {
		MaintenanceServicingUtilities.executeTriggerCode = false;  
		//SetupTestData();

        User runningUser = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {

    		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
    		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
    		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				

    		MaintenanceServicingUtilities.executeTriggerCode = false; 		
    		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
    		 

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman2.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

    	    Test.startTest();
	        

			System.AssertEquals(false, VTT_Utilities.IsAdminUser());
			System.assertEquals(1, activityList1.size());			

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);	

		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
		    pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			


			VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;

            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(false, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should not be assigned Tradesman');

            System.AssertEquals(false, workflowEngine.userHasEditAccess,'As Not Assigned Tradesman Current User should not be able to perform actions');

            System.AssertEquals(false, workflowEngine.CanCompleteJob,'Can not complete the job yet');
            System.AssertEquals(false, workflowEngine.CanExecuteAction);            
            System.AssertEquals(false, workflowEngine.CanPutActivityOnHold);
            System.AssertEquals(false, workflowEngine.CanRejectActivity);            
       
    	    /////////////////
    	    //* STOP TEST *//
    	    /////////////////
    	    Test.stopTest(); 
            }   
	}
	

	
	@isTest static void Test_Reject_Activity() {
		MaintenanceServicingUtilities.executeTriggerCode = false;  
		//SetupTestData();

        User runningUser = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {

    		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
    		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
    		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				

    		MaintenanceServicingUtilities.executeTriggerCode = false; 		
    		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
    		 

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

    	    Test.startTest();
			System.AssertEquals(false, VTT_Utilities.IsAdminUser());
			System.assertEquals(1, activityList1.size());			

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);	

		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
		    pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			


			VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;

            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(true, workflowEngine.userHasEditAccess,'As Assigned Tradesman Current User should be able to perform actions');

            System.AssertEquals(false, workflowEngine.CanCompleteJob,'Can not complete the job yet');
            System.AssertEquals(true, workflowEngine.CanExecuteAction);            
            System.AssertEquals(false, workflowEngine.CanPutActivityOnHold);
            System.AssertEquals(true, workflowEngine.CanRejectActivity);            

            //Start Reject Activity
            workflowEngine.RejectActivity_Start();

            System.AssertEquals(false, workflowEngine.ViewMode); 
            System.AssertEquals(true, workflowEngine.ActionMode_RejectActivity); 
			System.AssertEquals('Confirm', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity - Reject Activity', workflowEngine.ViewScreenDescription); 

            //Cancel Reject Activity
            workflowEngine.VTT_CancelEdit();

            System.AssertEquals(true, workflowEngine.ViewMode); 
            System.AssertEquals(false, workflowEngine.ActionMode_RejectActivity); 
			System.AssertEquals('Save', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity', workflowEngine.ViewScreenDescription); 


            //Start Reject Activity Again
            workflowEngine.RejectActivity_Start();
			workflowEngine.ActionComment = 'Test';
			workflowEngine.RejectActivity_End();

			List<Work_Order_Activity_Assignment__c> result = [select id, Tradesman__c, Rejected__c, Reject_Reason__c 
	         from Work_Order_Activity_Assignment__c 
	         where Tradesman__c = :workflowEngine.tradesman.id
	         and Work_Order_Activity__c = :woActivityCopy.id
	         and Rejected__c = true];

			System.AssertEquals(1, result.size());
			System.AssertEquals('Test', result[0].Reject_Reason__c);			
       
    	    /////////////////
    	    //* STOP TEST *//
    	    /////////////////
    	    Test.stopTest(); 
        }        
	}


	@isTest static void Test_StartAndFinishForTheDay() {
		MaintenanceServicingUtilities.executeTriggerCode = false;  
		//SetupTestData();

        User runningUser = VTT_TestData.createVTTUser();
            
        System.runAs(runningUser) {

    		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
    		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
    		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				

    		MaintenanceServicingUtilities.executeTriggerCode = false; 		
    		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
    		 

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

			System.AssertEquals(false, VTT_Utilities.IsAdminUser());
			System.assertEquals(1, activityList1.size());			

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);	

		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
		    pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;


            System.AssertEquals(null, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, workflowEngine.Tradesman.Tradesman_Status__c);


            System.AssertEquals(tradesman1.id, workflowEngine.Tradesman.ID, 'Not the same User');   
            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(true, workflowEngine.userHasEditAccess,'As Assigned Tradesman Current User should be able to perform actions');

            System.AssertEquals(false, workflowEngine.CanCompleteJob,'Can not complete the job yet');
            System.AssertEquals(true, workflowEngine.CanExecuteAction);            
            System.AssertEquals(false, workflowEngine.CanPutActivityOnHold);
            System.AssertEquals(true, workflowEngine.CanRejectActivity);        

            //Start Job
            workflowEngine.GenericActivity_Start1();
            System.AssertEquals(workflowEngine.WorkFlowActions[0].ActionName, workflowEngine.ActionName); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewTradesmanStatus, workflowEngine.NewTradesmanStatus); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewActivityStatus, workflowEngine.NewActivityStatus); 


            System.AssertEquals(false, workflowEngine.ViewMode); 
            System.AssertEquals(true, workflowEngine.ActionMode_Generic); 
			System.AssertEquals('Confirm', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity - ' + workflowEngine.ActionName, workflowEngine.ViewScreenDescription); 

            //Cancel Starting Activity
            workflowEngine.VTT_CancelEdit();

            System.AssertEquals(true, workflowEngine.ViewMode); 
            System.AssertEquals(false, workflowEngine.ActionMode_RejectActivity); 
			System.AssertEquals('Save', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity', workflowEngine.ViewScreenDescription); 

			//STEP 1
            //Start Job Again
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting Job';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_PREWORK, workflowEngine.Tradesman.Tradesman_Status__c);    

            Test.startTest();

			//STEP 2
            //Start At Site
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting At Site 1';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_WORKING, workflowEngine.Tradesman.Tradesman_Status__c);    


			//STEP 3
            //Finish At Site
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Finishing At Site 1';
            workflowEngine.GenericActivity_End();

            //reload controllers
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_POSTWORK, workflowEngine.Tradesman.Tradesman_Status__c);    
            //now we have 2 options - Start At Site again and Finish for the Day
            System.AssertEquals(2, workflowEngine.WorkFlowActions.size()); 
            //also we can complete the job
            System.AssertEquals(true, workflowEngine.CanCompleteJob);             


/*
			//STEP 3.1
            //Start At Site Again
            System.debug
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting At Site 2';
            workflowEngine.GenericActivity_End();

            //reload controllers
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_WORKING, workflowEngine.Tradesman.Tradesman_Status__c);    

			//STEP 3.2 Again
            //Finish At Site
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Finishing At Site 2';
            workflowEngine.GenericActivity_End();

            //reload controllers
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_POSTWORK, workflowEngine.Tradesman.Tradesman_Status__c);    
*/
			//STEP 4
            //finish for The day
            workflowEngine.GenericActivity_Start2();
            System.debug('Test_StartAndFinishForTheDay->finishForTheDay->actionName: ' + workflowEngine.ActionName);
			workflowEngine.ActionComment = 'Finish for The Day';
            workflowEngine.GenericActivity_End();

            //reload controllers
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            //System.AssertEquals(null, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            //System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, workflowEngine.Tradesman.Tradesman_Status__c);    

        
    	    /////////////////
    	    //* STOP TEST *//
    	    /////////////////
    	    Test.stopTest();     
        }    
	}
	@isTest static void Test_StartAndCompleteJob() {
		MaintenanceServicingUtilities.executeTriggerCode = false;  
		//SetupTestData();

        User runningUser = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {

    		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
    		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
    		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				

    		MaintenanceServicingUtilities.executeTriggerCode = false; 		
    		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
    		 

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);


            System.AssertEquals(false, VTT_Utilities.IsAdminUser());
            System.assertEquals(1, activityList1.size());           

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);	

		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
		    pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;


            System.AssertEquals(null, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, workflowEngine.Tradesman.Tradesman_Status__c);           


            System.AssertEquals(tradesman1.id, workflowEngine.Tradesman.ID, 'Not the same User');   
            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(true, workflowEngine.userHasEditAccess,'As Assigned Tradesman Current User should be able to perform actions');

            System.AssertEquals(false, workflowEngine.CanCompleteJob,'Can not complete the job yet');
            System.AssertEquals(true, workflowEngine.CanExecuteAction);            
            System.AssertEquals(false, workflowEngine.CanPutActivityOnHold);
            System.AssertEquals(true, workflowEngine.CanRejectActivity);        

            Test.startTest();

            //Start Job
            workflowEngine.GenericActivity_Start1();
            System.AssertEquals(workflowEngine.WorkFlowActions[0].ActionName, workflowEngine.ActionName); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewTradesmanStatus, workflowEngine.NewTradesmanStatus); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewActivityStatus, workflowEngine.NewActivityStatus); 


            System.AssertEquals(false, workflowEngine.ViewMode); 
            System.AssertEquals(true, workflowEngine.ActionMode_Generic); 
			System.AssertEquals('Confirm', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity - ' + workflowEngine.ActionName, workflowEngine.ViewScreenDescription); 

            //Cancel Starting Activity
            workflowEngine.VTT_CancelEdit();

            System.AssertEquals(true, workflowEngine.ViewMode); 
            System.AssertEquals(false, workflowEngine.ActionMode_RejectActivity); 
			System.AssertEquals('Save', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity', workflowEngine.ViewScreenDescription); 

			//STEP 1
            //Start Job Again
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting Job';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_PREWORK, workflowEngine.Tradesman.Tradesman_Status__c);    

			//STEP 2
            //Start At Site
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting At Site 1';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_WORKING, workflowEngine.Tradesman.Tradesman_Status__c);    

			//STEP 3
            //Finish At Site
   //         workflowEngine.GenericActivity_Start1();
			//workflowEngine.ActionComment = 'Finishing At Site 1';
   //         workflowEngine.GenericActivity_End();

   //         //reload controllers
   //         woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			//stdController = new ApexPages.StandardController(woActivityCopy);
			//controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			//workflowEngine = controller.workflowEngine;
			////check Tradesman Status
   //         System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
   //         System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_POSTWORK, workflowEngine.Tradesman.Tradesman_Status__c);    
   //         //now we have 2 options - Start At Site again and Finish for the Day
   //         System.AssertEquals(2, workflowEngine.WorkFlowActions.size()); 
   //         //also we can complete the job
   //         System.AssertEquals(true, workflowEngine.CanCompleteJob);             

   //         System.AssertEquals(null, workflowEngine.GenericActivity_Start2());
   //         workflowEngine.ActionComment = 'Test';
   //         System.AssertEquals(null, workflowEngine.VTT_CancelEdit());            



			//STEP 4
            //Job Complete
            System.AssertEquals(null, workflowEngine.JobComplete_Start());
			workflowEngine.ActionComment = 'Job Complete';
            System.AssertNotEquals(null, workflowEngine.JobComplete_End());


/*
            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(null, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, workflowEngine.Tradesman.Tradesman_Status__c);    
*/
        
    	    /////////////////
    	    //* STOP TEST *//
    	    /////////////////
    	    Test.stopTest(); 
        }        
	}
	@isTest static void Test_StartAndPutJobOnHold() {
		MaintenanceServicingUtilities.executeTriggerCode = false;  
		//SetupTestData();

        User runningUser = VTT_TestData.createVTTUser();
        User tradesman2User = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {

    		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
    		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
    		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id, tradesman2User.id);				

    		MaintenanceServicingUtilities.executeTriggerCode = false; 		
    		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
    		 

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

    	    Test.startTest();
    	        

			System.AssertEquals(false, VTT_Utilities.IsAdminUser());
			System.assertEquals(1, activityList1.size());			

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);	

		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
		    pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;


            System.AssertEquals(null, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, workflowEngine.Tradesman.Tradesman_Status__c);           


            System.AssertEquals(tradesman1.id, workflowEngine.Tradesman.ID, 'Not the same User');   
            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(true, workflowEngine.userHasEditAccess,'As Assigned Tradesman Current User should be able to perform actions');

            System.AssertEquals(false, workflowEngine.CanCompleteJob,'Can not complete the job yet');
            System.AssertEquals(true, workflowEngine.CanExecuteAction);            
            System.AssertEquals(false, workflowEngine.CanPutActivityOnHold);
            System.AssertEquals(true, workflowEngine.CanRejectActivity);     

            System.assertEquals(null, workflowEngine.AvailableCrewMembers);
            System.assertEquals(1, workflowEngine.AssignedTradesmenList.size());   

            //Start Job
            workflowEngine.GenericActivity_Start1();
            System.AssertEquals(workflowEngine.WorkFlowActions[0].ActionName, workflowEngine.ActionName); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewTradesmanStatus, workflowEngine.NewTradesmanStatus); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewActivityStatus, workflowEngine.NewActivityStatus); 


            System.AssertEquals(false, workflowEngine.ViewMode); 
            System.AssertEquals(true, workflowEngine.ActionMode_Generic); 
			System.AssertEquals('Confirm', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity - ' + workflowEngine.ActionName, workflowEngine.ViewScreenDescription); 

            //Cancel Starting Activity
            workflowEngine.VTT_CancelEdit();

            System.AssertEquals(true, workflowEngine.ViewMode); 
            System.AssertEquals(false, workflowEngine.ActionMode_RejectActivity); 
			System.AssertEquals('Save', workflowEngine.SaveButtonLabel); 
			System.AssertEquals('Work Order Activity', workflowEngine.ViewScreenDescription); 

			//STEP 1
            //Start Job Again
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting Job';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_PREWORK, workflowEngine.Tradesman.Tradesman_Status__c);    

            /*
			//STEP 2
            //Start At Site
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Starting At Site 1';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_WORKING, workflowEngine.Tradesman.Tradesman_Status__c);    

            
			//STEP 3
            //Finish At Site
            workflowEngine.GenericActivity_Start1();
			workflowEngine.ActionComment = 'Finishing At Site 1';
            workflowEngine.GenericActivity_End();

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_POSTWORK, workflowEngine.Tradesman.Tradesman_Status__c);    
            //now we have 2 options - Start At Site again and Finish for the Day
            System.AssertEquals(2, workflowEngine.WorkFlowActions.size()); 
            //also we can complete the job
            System.AssertEquals(true, workflowEngine.CanCompleteJob);             
            */

			//STEP 4
            //Put On Hold
            workflowEngine.ActivityOnHold_Start();
			workflowEngine.ActionComment = 'Put On Hold';
			workflowEngine.OnHoldStatusReason = 'Pulled off activity';
            workflowEngine.ActivityOnHold_End();

            //reload controllers
			stdController = new ApexPages.StandardController(woActivityCopy);
			controller = new VTT_ActivityDetailTimeLogControllerX(stdController);			
			workflowEngine = controller.workflowEngine;
			//check Tradesman Status
            System.AssertEquals(null, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, workflowEngine.Tradesman.Tradesman_Status__c);    

        
    	    /////////////////
    	    //* STOP TEST *//
    	    /////////////////
    	    Test.stopTest(); 
            }    
	}

    @isTest static void Test_ThermalWorkFlow() {
        User runningUser = VTT_TestData.createVTTUser();
        System.runAs(runningUser) {

            Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
            Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
            Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);              

            MaintenanceServicingUtilities.executeTriggerCode = false;
            VTT_TestData.SetupRelatedTestData();
            VTT_TestData.field.Name = 'Field Thermal';
            update VTT_TestData.field;       
            HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
            HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
            workOrder1.User_Status_Code__c = '5X';
            workOrder1.Order_Type__c = 'WP01';
            workOrder1.Plant_Section__c  = '200';       
            workOrder1.Work_Order_Priority_Number__c  = '1';    
            workOrder1.Equipment__c = VTT_TestData.equipment.Id;
            workOrder1.Location__c = VTT_TestData.location.Id;
            workOrder1.Operating_Field_AMU_Lookup__c = VTT_TestData.field.Id;  
            update workOrder1;
             

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;
            VTT_TestData.createWorkOrderActivityAssignment(woActivity.id, tradesman2.id);

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);


            System.AssertEquals(false, VTT_Utilities.IsAdminUser());
            System.assertEquals(1, activityList1.size());           

            PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
            Test.setCurrentPageReference(pageRef);  

            ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
            pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);          
            VTT_WorkFlowEngine workflowEngine = controller.workflowEngine;


            System.AssertEquals(null, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_NOTWORKING, workflowEngine.Tradesman.Tradesman_Status__c);           


            System.AssertEquals(tradesman1.id, workflowEngine.Tradesman.ID, 'Not the same User');   
            System.AssertEquals(false, workflowEngine.IsAdmin, 'Not Admin User');   
            System.AssertEquals(false, workflowEngine.CanManageAssignments,'Should not be able to manage assignments');
            System.AssertEquals(true, workflowEngine.ViewMode,'ViewMode should be true when page loaded.');
            System.AssertEquals(true, workflowEngine.CurrentUserIsAssignedTradesman,'Current User should be assigned Tradesman');

            System.AssertEquals(true, workflowEngine.userHasEditAccess,'As Assigned Tradesman Current User should be able to perform actions');

            System.AssertEquals(false, workflowEngine.CanCompleteJob,'Can not complete the job yet');
            System.AssertEquals(true, workflowEngine.CanExecuteAction);            
            System.AssertEquals(false, workflowEngine.CanPutActivityOnHold);
            System.AssertEquals(true, workflowEngine.CanRejectActivity);
            System.AssertEquals(true, workflowEngine.CanStartJobAtEquipment);        

            Test.startTest();

            //Start Job At Equipment
            workflowEngine.StartJobAtEquipment_Start();
            System.AssertEquals(workflowEngine.WorkFlowActions[0].ActionName, workflowEngine.ActionName); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewTradesmanStatus, workflowEngine.NewTradesmanStatus); 
            System.AssertEquals(workflowEngine.WorkFlowActions[0].NewActivityStatus, workflowEngine.NewActivityStatus); 


            System.AssertEquals(false, workflowEngine.ViewMode); 
            System.AssertEquals(true, workflowEngine.ActionMode_StartJobAtEquipment); 
            System.AssertEquals('Confirm', workflowEngine.SaveButtonLabel); 
            System.AssertEquals('Work Order Activity - Start Job at Equipment', workflowEngine.ViewScreenDescription); 
            
            workflowEngine.ActionComment = 'Starting Job At Equipment';
            workflowEngine.GenericActivity_End();

            //Simulate another user working on the activity
            tradesman2.Current_Work_Order_Activity__c = woActivityCopy.Id;
            tradesman2.Tradesman_Status__c = VTT_Utilities.TRADESMAN_STATUS_WORKING;
            update tradesman2;  

            //reload controllers
            woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);
            stdController = new ApexPages.StandardController(woActivityCopy);
            controller = new VTT_ActivityDetailTimeLogControllerX(stdController);           
            workflowEngine = controller.workflowEngine;
            //check Tradesman Status
            System.AssertEquals(woActivityCopy.id, workflowEngine.Tradesman.Current_Work_Order_Activity__c); 
            System.AssertEquals(VTT_Utilities.TRADESMAN_STATUS_WORKING, workflowEngine.Tradesman.Tradesman_Status__c);          

            //STEP 4
            //Job Complete
            System.AssertEquals(null, workflowEngine.JobComplete_Start());
            workflowEngine.ActionComment = 'Job Complete';
            System.AssertEquals(null, workflowEngine.JobComplete_End());
        
            /////////////////
            //* STOP TEST *//
            /////////////////
            Test.stopTest(); 
        }
    }	
}