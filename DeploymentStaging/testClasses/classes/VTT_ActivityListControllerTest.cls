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
private class VTT_ActivityListControllerTest {
	
	@isTest static void Test_Entire_Controller() {
        User runningUser = VTT_TestData.createVTTAdminUser();
        System.AssertNotEquals(runningUser.Id, Null);

        System.runAs(runningUser) {
		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
		Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id);	
		Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);	

		MaintenanceServicingUtilities.executeTriggerCode = false;		
		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
		workOrder.User_Status_Code__c = '5X';
		workOrder.Order_Type__c = 'WP01';
		workOrder.Plant_Section__c  = '200';		
		workOrder.Work_Order_Priority_Number__c  = '1';			
		update workOrder;
		MaintenanceServicingUtilities.executeTriggerCode = true; 

        List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.ID, tradesman1.ID, 3);
        List<Work_Order_Activity__c> activityList2 = VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.ID, tradesman2.ID, 2);
        //fine tuning of the one activity  to be able to filter it
        Work_Order_Activity__c woActivity = activityList1[0];
        woActivity.Work_Center__c ='100';
        woActivity.Scheduled_Start_Date__c = System.now();
        update woActivity;

        String pageFilterString;
	 	//////////////////
	    //* START TEST *//
	    //////////////////

	    Test.startTest();
	        

			System.Assert(VTT_Utilities.IsAdminUser());
			System.assertEquals(3, activityList1.size());			
			System.assertEquals(2, activityList2.size());

            PageReference pageRef = Page.VTT_ActivityListView;
            Test.setCurrentPageReference(pageRef);


            //now lets create controller
            VTT_ActivityListController controller = new VTT_ActivityListController();
            //we should have 5 total records
            System.AssertEquals(5, controller.getActivityRecords().size());  
            System.AssertNotEquals(0, controller.getActivityStatuses().size());  
            System.AssertEquals(3, controller.VendorOptions.size());  

			controller.ClearFilter();
            controller.pageFilter.priorityFilter = '1'; 
            controller.RefreshData();
            //we should have 5 results
            System.AssertEquals(5, controller.getActivityRecords().size());  


			controller.ClearFilter();
            controller.pageFilter.vendorFilter = '1'; //unassigned
            controller.RefreshData();
            //we should have 0 results
            System.AssertEquals(0, controller.getActivityRecords().size());  

			controller.ClearFilter();
            controller.pageFilter.vendorFilter = vendor1.id; //assigned to the vendor1
            controller.RefreshData();
            //we should have 5 results
            System.AssertEquals(5, controller.getActivityRecords().size());  

			controller.PopulateTradesmanOptions();
            System.AssertEquals(4, controller.TradesmanOptions.size());  

			controller.ClearFilter();
            controller.pageFilter.workOrderStatusFilter  = '5X';
            controller.RefreshData();
            //we should have 5 results
            System.AssertEquals(5, controller.getActivityRecords().size());  
                       
			controller.ClearFilter();
            controller.pageFilter.tradesmanFilter   = tradesman1.id;
            controller.RefreshData();
            //we should have 3 results
            System.AssertEquals(3, controller.getActivityRecords().size());  

			controller.ClearFilter();
            controller.pageFilter.tradesmanFilter   = '1';
            controller.RefreshData();
            //we should have 0 results
            System.AssertEquals(0, controller.getActivityRecords().size());  

			controller.ClearFilter();
            controller.pageFilter.orderTypeFilter = 'WP01';
            controller.RefreshData();
            //we should have 5 results
            System.AssertEquals(5, controller.getActivityRecords().size());  

			controller.ClearFilter();
            controller.pageFilter.workCenterFilter = '100';
            controller.RefreshData();
            //we should have 1 results
            System.AssertEquals(1, controller.getActivityRecords().size());  
			pageFilterString = controller.PageFilterString;


			controller.ClearFilter();
            controller.pageFilter.routeFilter  = '200';
            controller.RefreshData();
            //we should have 5 results
            System.AssertEquals(5, controller.getActivityRecords().size());  
 
			controller.ClearFilter();
            controller.pageFilter.scheduledFilter   = 'TODAY';
            controller.RefreshData();
            //we should have 1 results
            System.AssertEquals(1, controller.getActivityRecords().size());  

			controller.ClearFilter();
            controller.pageFilter.filterName    = 'Test Name';
            controller.RefreshData();
            //we should have 5 results
            System.AssertEquals(5, controller.getActivityRecords().size());  

			controller.ClearFilter();
            controller.pageFilter.activityStatusFilter = 'New';
            controller.RefreshData();
            //we should have 5 results
            System.AssertEquals(5, controller.getActivityRecords().size());  

			//controller.ClearFilter();
   //         controller.pageFilter.amuFilter = 'xxxxx';
   //         controller.RefreshData();
   //         //we should have 0 results
   //         System.AssertEquals(0, controller.getActivityRecords().size());  

            System.AssertNotEquals(null, controller.JobInProgress());  

            String idlist = activityList1[0].id + ',' + activityList1[1].id;
			pageRef.getParameters().put('idlist', idlist);
			controller = new VTT_ActivityListController();
            System.AssertNotEquals(null, controller.idlist); 
            controller.RefreshData();
            //we should have 2 results
            System.AssertEquals(2, controller.getActivityRecords().size());  

			pageRef.getParameters().put('idlist', null);
			pageRef.getParameters().put('filter', pageFilterString);
			controller = new VTT_ActivityListController();
            System.AssertEquals('100', controller.pageFilter.workCenterFilter); 
            controller.RefreshData();
            //we should have 1 results
            System.AssertEquals(1, controller.getActivityRecords().size());
            
            //Test start work popup
            controller.StartWork_Start(); 
            System.AssertEquals(true, controller.showStartWorkPopup);
            
            //Test start work confirmation when user accept
            controller.startWorkConfirm = true;
            PageReference endWork = controller.StartWork_End();
            System.AssertEquals(null, endWork);
            
            //Test start work confirmation when user declines 
            controller.startWorkConfirm = false;
            PageReference endWork2 = controller.StartWork_End();
            System.AssertEquals(false, controller.showStartWorkPopup);
            
            controller.startWorkConfirm = true;
           	controller.GetCanStartWork();
            
            //Test if its Mobile
            controller.isMobileDevice = true;
            controller.SetIsMobileDevice();
            
            //Test setGeoLocations
            ApexPages.currentPage().getParameters().put('latitude', '39.003444');
			ApexPages.currentPage().getParameters().put('longitude', '125.736401');
            controller.SetGeolocation();
            System.assertEquals(true, controller.isGeolocationAvailable);
            
            
            controller.SetBrowserVariables();
            
        }
	    /////////////////
	    //* STOP TEST *//
	    /////////////////
	    Test.stopTest(); 
	}

    @isTest static void Test_ManageAssignments() {
        User runningUser = VTT_TestData.createVTTAdminUser();
        System.AssertNotEquals(runningUser.Id, Null);

        System.runAs(runningUser) {
        Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
        Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id); 
        Contact tradesman2 = VTT_TestData.createTradesmanContact('Brad', 'Pitt',  vendor1.id);  

        MaintenanceServicingUtilities.executeTriggerCode = false;
        HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest();       
        HOG_Maintenance_Servicing_Form__c workOrder = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
        workOrder.User_Status_Code__c = '5X';
        workOrder.Order_Type__c = 'WP01';
        workOrder.Plant_Section__c  = '200';        
        workOrder.Work_Order_Priority_Number__c  = '1';         
        update workOrder;
        MaintenanceServicingUtilities.executeTriggerCode = true; 

        List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder.ID, tradesman1.ID, 100);

        String pageFilterString;
        //////////////////
        //* START TEST *//
        //////////////////

        Test.startTest();
            

            System.Assert(VTT_Utilities.IsAdminUser());
            System.assertEquals(100, activityList1.size());           
            PageReference pageRef = Page.VTT_ActivityListView;
            Test.setCurrentPageReference(pageRef);


            //now lets create controller
            VTT_ActivityListController controller = new VTT_ActivityListController();
            //we should have 20 total records
            System.AssertEquals(20, controller.getActivityRecords().size());  

            controller.next();
            System.AssertEquals(2, controller.getPageNumber());
            controller.previous();
            System.AssertEquals(1, controller.getPageNumber());            
            controller.last();
            System.AssertEquals(5, controller.getPageNumber());
            controller.first();
            System.AssertEquals(1, controller.getPageNumber()); 

            System.AssertNotEquals(null, controller.JobInProgress());
            System.AssertEquals(null, controller.ManageAssignments());  


            List<VTT_ActivityListController.ActivityWrapper> activityList = controller.currentPageActivities;
            activityList[0].selected = true;
            activityList[1].selected = true;
            controller.getSelected();
            System.AssertEquals(2, controller.selectedActivities.size());
            System.AssertNotEquals(null, controller.ManageAssignments()); 

            System.AssertEquals(null, controller.RunAutoAssignments());  
			
			//Run autoAssignemenets with no selected Activities
            controller.selectedActivities.clear();
            System.AssertEquals(null, controller.RunAutoAssignments()); 

        }
        /////////////////
        //* STOP TEST *//
        /////////////////
        Test.stopTest(); 
    }

    @isTest static void testSearchCriteriaFilters() {
        User runningUser = VTT_TestData.createVTTAdminUser();

        System.runAs(runningUser) {
            Test.startTest();

            PageReference pageRef = Page.VTT_ActivityListView;
            Test.setCurrentPageReference(pageRef);

            //now lets create controller
            VTT_ActivityListController controller = new VTT_ActivityListController();
            System.assertNotEquals(controller.pageFilter, null);

            //Lets Save a dummy filter Filter
            controller.pageFilter.vendorFilter = 'Test Vendor';
            controller.pageFilter.tradesmanFilter = 'Test Tradesman';
            controller.pageFilter.scheduledFilter = 'This Month';
            controller.pageFilter.amuFilter = 'Test AMU';
            controller.pageFilter.routeFilter = 'Test Route Filter';
            controller.pageFilter.plannerGroupFilter = 'Test Planner Group';
            controller.pageFilter.orderTypeFilter = 'Test OrderType';
            controller.pageFilter.priorityFilter = 'Test Priority';
            controller.pageFilter.workCenterFilter = 'Test WorkCenter';
            controller.pageFilter.workOrderStatusFilter = 'Test WorkOrderStatus';
            controller.pageFilter.activityMultiStatusFilter.add('Test ActivityStatus1');
            controller.pageFilter.activityMultiStatusFilter.add('Test ActivityStatus2');
            controller.pageFilter.hideCompletedFilter = true;
            controller.pageFilter.filterName = 'Any Text';
            controller.SaveFilter_Start();
            System.assertEquals(controller.searchFilterName, '');
            System.assertEquals(controller.showSearchCriteriaNamePopUp, true);
            controller.searchFilterName = 'Test Filter1';
            controller.saveConfirm = true;
            controller.SaveFilter_End();

            //Save Another One
            controller.pageFilter.vendorFilter = 'Test Vendor2';
            controller.pageFilter.tradesmanFilter = 'Test Tradesman2';
            controller.SaveFilter_Start();
            controller.searchFilterName = 'Test Filter2';
            controller.saveConfirm = true;
            controller.SaveFilter_End();
            
            //Test Saving Filter
            List<Work_Order_Activity_Search_Criteria__c> filtersResult = VTT_Utilities.GetUserActivitySearchFilters(runningUser.Id);
            System.assertEquals(JSON.serialize(controller.pageFilter), filtersResult[1].Filter_String__c);

            //Test Filter Change
            System.assertEquals(filtersResult[0].Last_Search_Criteria_Selected__c, false);
            controller.selectedFilterId = filtersResult[0].Id;
            controller.FilterChanged();
            filtersResult = VTT_Utilities.GetUserActivitySearchFilters(runningUser.Id);
            System.assertEquals(filtersResult[0].Last_Search_Criteria_Selected__c, true);
			
            //Test Delete Filter
            controller.DeleteFilter();
            filtersResult = VTT_Utilities.GetUserActivitySearchFilters(runningUser.Id);
            System.assertEquals(filtersResult.size(), 1);

            //Simulate 'None' Option
            controller.selectedFilterId = filtersResult[0].Id;
            controller.FilterChanged();
            filtersResult = VTT_Utilities.GetUserActivitySearchFilters(runningUser.Id);
            System.assertEquals(filtersResult[0].Last_Search_Criteria_Selected__c, true);
            controller.ClearLastSelectedFilter();
            filtersResult = VTT_Utilities.GetUserActivitySearchFilters(runningUser.Id);
            System.assertEquals(filtersResult[0].Last_Search_Criteria_Selected__c, false);
            
        
        }
    }
}