@isTest
private class VTT_InterfaceMonitorControllerTest
{
	private static HOG_Interface_Monitoring_Settings__c cs;
	static 
	{
		SetupData();
	}

	@isTest
	static void RefreshDataTest()
	{
		VTT_InterfaceMonitorController ctrl = new VTT_InterfaceMonitorController();

		system.assertEquals(cs.Work_Order_Number__c, ctrl.WorkOrderNumber);
		system.assertEquals(cs.Activity_Number__c, ctrl.ActivityNumber);
		system.assertEquals(cs.Activity_Statuses_to_Toggle__c, ctrl.ActivityStatusesToToggle);
		system.assertEquals(cs.Notify_on_Failure__c, ctrl.NotifyOnFailure);
		system.assertEquals(cs.Time_Between_Job_Runs__c, ctrl.TimeBetweenJobRuns);
	}
	@isTest
	static void SaveSettingsTest()
	{
		VTT_InterfaceMonitorController ctrl = new VTT_InterfaceMonitorController();

		system.assertEquals(cs.Work_Order_Number__c, ctrl.WorkOrderNumber);
		system.assertEquals(cs.Activity_Number__c, ctrl.ActivityNumber);
		system.assertEquals(cs.Activity_Statuses_to_Toggle__c, ctrl.ActivityStatusesToToggle);
		system.assertEquals(cs.Notify_on_Failure__c, ctrl.NotifyOnFailure);
		system.assertEquals(cs.Time_Between_Job_Runs__c, ctrl.TimeBetweenJobRuns);
		
		Test.startTest();
		ctrl.NotifyOnFailure = 'test1@test.com';
		ctrl.SaveSettings();

		HOG_Interface_Monitoring_Settings__c updatedCS = HOG_Interface_Monitoring_Settings__c.getInstance();
		system.assertEquals(updatedCS.Notify_on_Failure__c, ctrl.NotifyOnFailure);
		Test.stopTest();	
	}


	@isTest
	static void ScheduleJobTest()
	{
		VTT_InterfaceMonitorController ctrl = new VTT_InterfaceMonitorController();
		Test.startTest();
		
		ctrl.ScheduleJob();
		system.assertNotEquals(null, ctrl.JobID);
		system.assertEquals(true, ctrl.JobActive);

		ctrl.Deactivate();
		system.assertEquals(null, ctrl.JobID);
		system.assertEquals(false, ctrl.JobActive);

		Test.stopTest();	
	}
	@isTest
	static void StartEditTest()
	{
		VTT_InterfaceMonitorController ctrl = new VTT_InterfaceMonitorController();
		Test.startTest();
		system.assertEquals(true, ctrl.ViewMode);
		
		ctrl.StartEdit();
		system.assertEquals(false, ctrl.ViewMode);

		ctrl.CancelEdit();
		system.assertEquals(true, ctrl.ViewMode);

		Test.stopTest();	
	}

	private static void SetupData()
	{
		cs = new HOG_Interface_Monitoring_Settings__c();		
		cs.Work_Order_Number__c ='100';
		cs.Activity_Number__c = '10';
		cs.Activity_Statuses_to_Toggle__c = 'Status1, Status2';
		cs.Notify_on_Failure__c = 'test@test.com';
		cs.Time_Between_Job_Runs__c = 1;
		upsert cs;		
	}
}