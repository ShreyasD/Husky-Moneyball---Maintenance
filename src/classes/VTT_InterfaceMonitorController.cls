public with sharing class VTT_InterfaceMonitorController {
	public String WorkOrderNumber {get; set;}
	public String ActivityNumber {get; set;}
	public String ActivityStatusesToToggle {get; set;}
	public String NotifyOnFailure {get; set;}
	public String JobStatus {get; private set;}
	public Decimal TimeBetweenJobRuns {get; set;}

	public String JobID {get; private set;}
	public String ActivityID {get; private set;}
	public Boolean JobActive {get; set;}
	public String JobLog {get; private set;}

	public Boolean ViewMode {get; set;}

	public HOG_Interface_Monitoring_Settings__c cs {get; set;}

	public VTT_InterfaceMonitorController() {

		ViewMode = true;
		RefreshData();
	}

	public void RefreshData()
	{


		List<HOG_Interface_Monitoring_Settings__c> resultCs = [select id, name, 
				Work_Order_Number__c, 
				Activity_Number__c,
				Activity_Statuses_to_Toggle__c,
				Notify_on_Failure__c,
				Job_Status__c,
				Time_Between_Job_Runs__c,
				ActivityId__c,
				Expected_Activity_Status__c,
				JobID__c,
				Job_Log__c,
				Job_Active__c
				from HOG_Interface_Monitoring_Settings__c limit 1];
		if(resultCs.size()==0 )
		{
			cs = new HOG_Interface_Monitoring_Settings__c();
		}
		else
		{
			cs = resultCs[0];			
		}

		WorkOrderNumber = cs.Work_Order_Number__c;
		ActivityNumber = cs.Activity_Number__c;
		ActivityStatusesToToggle = cs.Activity_Statuses_to_Toggle__c;
		NotifyOnFailure = cs.Notify_on_Failure__c;
		JobStatus = cs.Job_Status__c;
		TimeBetweenJobRuns = cs.Time_Between_Job_Runs__c;	

		JobLog = cs.Job_Log__c;
		JobActive = cs.Job_Active__c;
		JobID = cs.JobID__c;

	}
	public void StartEdit()
	{
		ViewMode = false;
	}
	public void CancelEdit()
	{
		ViewMode = true;
	}

	public PageReference SaveSettings()
	{
		List<Work_Order_Activity__c> activityResult = [select id, name from Work_Order_Activity__c where 
		Maintenance_Work_Order__r.Work_Order_Number__c =:WorkOrderNumber and Operation_Number__c =:ActivityNumber limit 1];

		//in case if we running test we don't want to enfore this check, 
		//otherwise we will have to create test data for work order and activity 
		//and all related parent objects
		if(activityResult.size()==0 && !Test.isRunningTest())
		{
			String message = 'Can\'t find this work order activity.';
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, message));
			return null;
		}
		
		if(activityResult.size()!=0)
		{
			cs.ActivityId__c =activityResult[0].id;
		}

		cs.Work_Order_Number__c =WorkOrderNumber;
		cs.Activity_Number__c = ActivityNumber;
		cs.Activity_Statuses_to_Toggle__c = ActivityStatusesToToggle;
		cs.Notify_on_Failure__c = NotifyOnFailure;
		cs.Time_Between_Job_Runs__c = TimeBetweenJobRuns;
		cs.Expected_Activity_Status__c = null;
		cs.Job_Status__c = null;
		cs.Job_Log__c = null;
		cs.Job_Active__c =JobActive; 
		cs.JobID__c = null;

		try
		{
			upsert cs;
		}
		catch(Exception ex)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Update failed.' + ex.getMessage()));					
			return null;
		}


		RefreshData();
		ViewMode = true;

		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Configuration saved.'));		
		return null;		
	}

	public PageReference ScheduleJob()
	{
		DateTime now  = DateTime.now();
		DateTime nextRunTime = now.addMinutes(1);
		cs.JobID__c = VTT_InterfaceMonitorSchedule.ScheduleMe(nextRunTime);
		JobID = cs.JobId__c;
		cs.Job_Active__c = true;
		JobActive = true;
		upsert cs;
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Monitoring Job was scheduled.'));	
		return null;
	}
	public PageReference Deactivate()
	{
		RefreshData(); //just in case if interface were running and job ID was updated already
		if(cs.JobID__c!=null)
		{
			try
			{
				System.abortJob(cs.JobID__c);  
			}
			catch(Exception ex)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Monitoring Job could not be cancelled.' + ex.getMessage()));					
				return null;
			}
		}
		cs.JobID__c = null;
		cs.Job_Active__c = false;
		JobActive = false;
		JobID = null;
		upsert cs;
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Monitoring Job was cancelled.'));	
		return null;
	}	
}