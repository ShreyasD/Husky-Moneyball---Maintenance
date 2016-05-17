@isTest
private class VTT_InterfaceMonitorScheduleTest {
	
	public static String CRON_EXP = '0 0 0 15 3 ? 2022';

	@isTest
	static void Test_ScheduleExecute() {
		
		User runningUser = VTT_TestData.createVTTUser();

		System.runAs(runningUser) {

			SetupData(runningUser);

			Test.startTest();
				DateTime nextRunTime = DateTime.now().addMinutes(5);
				String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
				    nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
				    nextRunTime.month() + ' ? ' + nextRunTime.year();

				// Schedule job
				String jobId = VTT_InterfaceMonitorSchedule.ScheduleMe(nextRunTime);

				// Get the information from the CronTrigger API object
				CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
									FROM CronTrigger WHERE id = :jobId];

				// Verify the expressions are the same					
				System.assertEquals(cronString,ct.CronExpression);
				// Verify the next time the job will run
				System.assertEquals(String.valueOf(nextRunTime),String.valueOf(ct.NextFireTime));
			Test.stopTest();

		}
	}

	private static void SetupData(User runningUser){

		Account vendor1 = VTT_TestData.createVendorAccount('Vendor1');
        Contact tradesman1 = VTT_TestData.createTradesmanContact('Tom', 'Cruise',  vendor1.id, runningUser.id);

        MaintenanceServicingUtilities.executeTriggerCode = false;

        VTT_TestData.SetupRelatedTestData();
		HOG_Service_Request_Notification_Form__c serviceRequest = VTT_TestData.createServiceRequest(VTT_TestData.workOrderType);       
        HOG_Maintenance_Servicing_Form__c workOrder1 = VTT_TestData.createWorkOrder(serviceRequest.Id, VTT_TestData.notificationType.Id);
        workOrder1.User_Status_Code__c = '5X';
        workOrder1.Order_Type__c = 'WP01';
        workOrder1.Plant_Section__c  = '200';       
        workOrder1.Work_Order_Priority_Number__c  = '1';    
        workOrder1.Equipment__c = VTT_TestData.equipment.Id;
        workOrder1.Location__c = VTT_TestData.location.Id;
        workOrder1.Operating_Field_AMU_Lookup__c = VTT_TestData.field.Id;
        workOrder1.Work_Order_Number__c = '100'; 
        update workOrder1;

        MaintenanceServicingUtilities.executeTriggerCode = true; 

        List<Work_Order_Activity__c> activityList1 =  VTT_TestData.createWorkOrderActivitiesWithAssignments(workOrder1.ID, tradesman1.ID, 1);
        //fine tuning of the one activity  to be able to filter it
        Work_Order_Activity__c woActivity = activityList1[0];
        woActivity.Work_Center__c ='100';
        woActivity.Scheduled_Start_Date__c = System.now();
        woActivity.Operation_Number__c = '10';
        update woActivity;

		HOG_Interface_Monitoring_Settings__c cs = new HOG_Interface_Monitoring_Settings__c();		
		cs.Work_Order_Number__c = workOrder1.Work_Order_Number__c;
		cs.Activity_Number__c = woActivity.Operation_Number__c;
		cs.ActivityId__c = woActivity.Id;
		cs.Activity_Statuses_to_Toggle__c = 'Status1, Status2';
		cs.Notify_on_Failure__c = 'test@test.com';
		cs.Time_Between_Job_Runs__c = 1;
		cs.Job_Active__c = true;
		cs.Expected_Activity_Status__c = 'Status3';
		cs.Notify_on_Failure__c = 'test1@test.com, test2@test.com';
		insert cs;


	}

}