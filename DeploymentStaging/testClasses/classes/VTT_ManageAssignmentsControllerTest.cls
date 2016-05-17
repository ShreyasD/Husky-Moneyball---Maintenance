@isTest
private class VTT_ManageAssignmentsControllerTest {
    
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
         

        List<Work_Order_Activity__c> activityList =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 5);

        Test.startTest();
            
        System.runAs(runningUser) {
            System.AssertEquals(true, VTT_Utilities.IsAdminUser());
            System.assertEquals(5, activityList.size());            

            PageReference pageRef = Page.VTT_TradesmanAssignment;
            Test.setCurrentPageReference(pageRef);  

            // making a single string with comma seprated from activity list
            String idList='';
            for(Work_Order_Activity__c  activityRec : activityList)
            {
             idList += activityRec.id + '-' ;
            }

            pageRef.getParameters().put('idlist', idList);
            VTT_ManageAssignmentsController controller = new VTT_ManageAssignmentsController();

            List<Account> vendorList = VTT_ManageAssignmentsController.searchAccount('Vendor1');
            System.AssertEquals(1, vendorList.size()); 

            controller.VendorAccountId = vendor1.id;
            System.AssertEquals(vendor1.id, controller.VendorAccountId); 

            controller.PopulateTradesmanOptions();
            System.AssertEquals(2, controller.allTradesmen.size());             
            System.AssertEquals(0, controller.selectedTradesmen.size());              


            System.AssertEquals(null, controller.ClearSelection());  
            System.AssertEquals(null, controller.VendorAccountId);  


            System.AssertNotEquals(null, controller.VTT_Exit());  


            System.AssertEquals(null, controller.getSelected());              
            System.AssertEquals(5, controller.selectedActivities.size()); 

            //lets test add assignments
            controller.VendorAccountId = vendor1.id;
            System.AssertEquals(vendor1.id, controller.VendorAccountId);   
            controller.selectedTradesmen.add(new SelectOption(tradesman2.id, 'Brad Pitt'));
            System.AssertEquals(null, controller.AddAssignment());

            for(Work_Order_Activity__c  activityRec : controller.selectedActivities)
            {
                System.AssertEquals('Brad Pitt, Tom Cruise', activityRec.Assigned_Text__c);   
            }

            //lets test remove assignments
            System.AssertEquals(null, controller.ClearSelection());             
            controller.VendorAccountId = vendor1.id;
            System.AssertEquals(vendor1.id, controller.VendorAccountId);   
            controller.selectedTradesmen.add(new SelectOption(tradesman2.id, 'Brad Pitt'));
            System.AssertEquals(null, controller.RemoveAssignment());
            for(Work_Order_Activity__c  activityRec : controller.selectedActivities)
            {
                System.AssertEquals('Tom Cruise', activityRec.Assigned_Text__c);   
            }
            //remove myself
            controller.selectedTradesmen.add(new SelectOption(tradesman1.id, 'Tom Cruise'));
            System.AssertEquals(null, controller.RemoveAssignment());
            for(Work_Order_Activity__c  activityRec : controller.selectedActivities)
            {
                System.AssertEquals(null, activityRec.Assigned_Text__c);   
            }

            //remove vendor completely
            System.AssertEquals(null, controller.ClearSelection());             
            controller.VendorAccountId = vendor1.id;
            System.AssertEquals(vendor1.id, controller.VendorAccountId);  
            System.AssertEquals(null, controller.RemoveAssignment());
            System.AssertEquals(null, controller.RemoveAssignment());
            for(Work_Order_Activity__c  activityRec : controller.selectedActivities)
            {
                System.AssertEquals(null, activityRec.Assigned_Vendor__c);   
            }

            //lets test just vendor
            controller.VendorAccountId = vendor1.id;
            System.AssertEquals(vendor1.id, controller.VendorAccountId);   
            System.AssertEquals(null, controller.AddAssignment());
            for(Work_Order_Activity__c  activityRec : controller.selectedActivities)
            {
                System.AssertEquals(vendor1.id, activityRec.Assigned_Vendor__c);   
            }
        }
        /////////////////
        //* STOP TEST *//
        /////////////////
        Test.stopTest();            
    }
    }
}