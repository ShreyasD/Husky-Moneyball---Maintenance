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
private class VTT_ActivityDetailTimeLogControllerXTest {    
    @isTest static void Test_Entire_Controller() {

        User runningUser = VTT_TestData.createVTTUser();

        System.runAs(runningUser) {        
            MaintenanceServicingUtilities.executeTriggerCode = false;  
            VTT_TestData.SetupRelatedTestData();


            System.AssertNotEquals(runningUser.Id, Null);

            Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
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

            MaintenanceServicingUtilities.executeTriggerCode = true; 

            List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
            //fine tuning of the one activity  to be able to filter it
            Work_Order_Activity__c woActivity = activityList1[0];
            woActivity.Work_Center__c ='100';
            woActivity.Scheduled_Start_Date__c = System.now();
            update woActivity;

            Work_Order_Activity__c woActivityCopy = VTT_TestData.reloadWorkOrderActivity(woActivity.id);

            Test.startTest();
                
            System.runAs(runningUser) {
                System.AssertEquals(false, VTT_Utilities.IsAdminUser());
                System.assertEquals(1, activityList1.size());           

                PageReference pageRef = Page.VTT_ActivityDetailTimeLog;
                Test.setCurrentPageReference(pageRef);  

                ApexPages.StandardController stdController = new ApexPages.StandardController(woActivityCopy);
                pageRef.getParameters().put('id', woActivityCopy.Id);
                VTT_ActivityDetailTimeLogControllerX controller = new VTT_ActivityDetailTimeLogControllerX(stdController);          

                System.AssertEquals(true, controller.EquipmentWorkOrder); 
                System.AssertEquals(vendor1.id, controller.assignedVendor); 


                
                System.AssertEquals(1, controller.vendorAccounts.size());  
                System.AssertEquals(2, controller.allTradesmen.size());              

                System.AssertNotEquals(null, controller.getOperatorOnCall());


                System.AssertNotEquals(null, controller.VTT_Assignment());             
                System.AssertNotEquals(null, controller.UpdateAssignment()); 
                System.AssertNotEquals(null, controller.VTT_Cancel());  
                System.AssertNotEquals(null, controller.ExitAssignment());
                System.AssertEquals(null, controller.JobComplete());  

                System.AssertNotEquals(0, controller.getPartsOptions().size());  
                System.AssertNotEquals(0, controller.getDamagesOptions().size());              
                System.AssertNotEquals(0, controller.getCausesOptions().size());                          
                System.AssertNotEquals(1, controller.getUsersOptions().size());

                //Test File Attachments for Coverage
                controller.attachmentFile.Name = 'Test Attachment File';
                controller.attachmentFile.Body = Blob.valueOf('Unit Test Attachment Body.');
                controller.Upload();
                List<Attachment> attachments = controller.getAttachments();
                //List<Attachment> woattachments = controller.getWorkOrderAttachments();
                System.assertEquals(1, attachments.size());
                //System.assertEquals(1, woattachments.size());


            }

            /////////////////
            //* STOP TEST *//
            /////////////////
            Test.stopTest();  
        }           
    }          
}