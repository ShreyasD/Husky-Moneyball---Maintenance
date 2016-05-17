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
private class VTT_TradesmanAssignmentControllerXTest {
	
	@isTest static void Test_Entire_Controller() {
		MaintenanceServicingUtilities.executeTriggerCode = false;  
		//SetupTestData();

        User runningUser = VTT_TestData.createVTTAdminUser();
        System.AssertNotEquals(runningUser.Id, Null);

        System.runAs(runningUser) {

		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);
		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);				

		MaintenanceServicingUtilities.executeTriggerCode = false; 		
		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
		workOrder1.User_Status_Code__c = '5X';
		workOrder1.Order_Type__c = 'WP01';
		workOrder1.Plant_Section__c  = '200';		
		workOrder1.Work_Order_Priority_Number__c  = '1';	
		update workOrder1;
		 

        List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
        //fine tuning of the one activity  to be able to filter it
        Work_Order_Activity__c woActivity = activityList1[0];
        woActivity.Work_Center__c ='100';
        woActivity.Scheduled_Start_Date__c = System.now();
        update woActivity;

        Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

	    Test.startTest();
	        
        System.runAs(runningUser) {
			System.AssertEquals(true, VTT_Utilities.IsAdminUser());
			System.assertEquals(1, activityList1.size());			

            PageReference pageRef = Page.VTT_TradesmanAssignment;
            Test.setCurrentPageReference(pageRef);	

		    ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
		    pageRef.getParameters().put('id', woActivityCopy.Id);
            VTT_TradesmanAssignmentControllerX controller = new VTT_TradesmanAssignmentControllerX(stdController);			

            System.AssertEquals(vendor1.id, controller.assignedVendor); 


            
            System.AssertEquals(1, controller.vendorAccounts.size());  
            System.AssertEquals(1, controller.allTradesmen.size());              
            System.AssertEquals(1, controller.selectedTradesmen.size());              

            System.AssertNotEquals(null, controller.UpdateAssignment());  
            System.AssertNotEquals(null, controller.ExitAssignment());  

        }
	    /////////////////
	    //* STOP TEST *//
	    /////////////////
	    Test.stopTest();    		

	}
	}

}