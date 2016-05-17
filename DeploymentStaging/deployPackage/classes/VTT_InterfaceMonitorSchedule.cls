global class VTT_InterfaceMonitorSchedule implements Schedulable {
	public VTT_InterfaceMonitorSchedule() {
		
	}
	global void execute(SchedulableContext sc) {

		HOG_Interface_Monitoring_Settings__c cs;
		Integer intervalMinutes = 0;

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

		if(resultCs.size()==0)
		{
			//nothing to do
			system.debug('No custom settings');
			return;
		}
		else
		{
			cs = resultCs[0];			
		}

		system.debug('ActivityId__c,Activity_Statuses_to_Toggle__c,Job_Active__c::'+cs.ActivityId__c+' '+cs.Activity_Statuses_to_Toggle__c+' '+ cs.Job_Active__c);
		if(cs.ActivityId__c != null && cs.Activity_Statuses_to_Toggle__c != null && cs.Job_Active__c)
		{

			Boolean jobFailed = false;

			intervalMinutes = Integer.valueOf(cs.Time_Between_Job_Runs__c);
			String[] activityStatuses = cs.Activity_Statuses_to_Toggle__c.split(',');
			String newActivityUserStatusCode;

			List<Work_Order_Activity__c> activityResult = [select id, name, User_Status__c from Work_Order_Activity__c where 
			id = :cs.ActivityId__c limit 1];

			if(activityResult.size()==0)
			{
				cs.Job_Status__c = 'Failed. could not find the activity';
				jobFailed = true;
			}
			//check Activity Status is Expected Activity Status is set
			else if(activityResult[0].User_Status__c <> cs.Expected_Activity_Status__c && cs.Expected_Activity_Status__c != null)
			{
				cs.Job_Status__c = 'Failed. Activity status is ' +  activityResult[0].User_Status__c  + '. Expected status: '+ cs.Expected_Activity_Status__c;
				jobFailed = true;
				SendEmailNotification(cs);

				//Initiate SAP Update again and reschedule
				newActivityUserStatusCode = cs.Expected_Activity_Status__c;
				VTT_Utilities.SAP_UpdateWorkOrderActivityStatus(activityResult[0].id, newActivityUserStatusCode);
		 				
			}
			else
			{
				try
				{

					if(activityStatuses.size()==1)
					{
						newActivityUserStatusCode = activityStatuses[0];	
					}
					else
					{
						newActivityUserStatusCode = activityResult[0].User_Status__c <> activityStatuses[0] ? activityStatuses[0] : activityStatuses[1];
					}

					newActivityUserStatusCode = newActivityUserStatusCode.trim();

					//Initiate SAP_Update and reschedule the job
					VTT_Utilities.SAP_UpdateWorkOrderActivityStatus(activityResult[0].id, newActivityUserStatusCode); 
					cs.Expected_Activity_Status__c = newActivityUserStatusCode;
					cs.Job_Status__c = 'SAP_UpdateWorkOrderActivityStatus initiated with Activity status: ' + newActivityUserStatusCode;

				}
				Catch(Exception ex)
				{
					cs.Job_Status__c = 'Failed. ' + ex.getMessage();
					SendEmailNotification(cs);
				}				
			}

		}

		// Re-schedule ourself to run again in "intervalMinutes" time
		DateTime nextRunTime = DateTime.now().addMinutes(intervalMinutes);
		
		//reschedule, only if test is not running
		if(!Test.isRunningTest()) cs.JobID__c = ScheduleMe(nextRunTime);

		

		String log = '';
		if(cs.Job_Log__c != null)
		{
			log = DateTime.now().format() + ' ' + cs.Job_Status__c + ' \r\n' + cs.Job_Log__c;
		}
		else
		{
			log = DateTime.now().format() + ' ' + cs.Job_Status__c;
		}
		cs.Job_Log__c = log.left(255);
		update cs;

		// Abort the current job
		Id jobId = sc.getTriggerId();
		System.abortJob(jobId);  

	}	

	public static String ScheduleMe(Datetime nextRunTime)
	{
		system.debug('Executing ScheduleMe');
		String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
		    nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
		    nextRunTime.month() + ' ? ' + nextRunTime.year(); 
		return System.schedule(VTT_InterfaceMonitorSchedule.class.getName() + '-' + nextRunTime.format(), cronString, new VTT_InterfaceMonitorSchedule());
	}

	private void SendEmailNotification(HOG_Interface_Monitoring_Settings__c cs)
	{
		if(!String.isEmpty(cs.Notify_on_Failure__c)) //if there is  email adresses
		{
			String[] notifyEmailAddresses = new String[]{};
			for(String singleEmail : cs.Notify_on_Failure__c.Split('[,; \n\r]'))
			{
				if(!String.isEmpty(singleEmail) && validateEmail(singleEmail))
				{
					notifyEmailAddresses.add(singleEmail);
				}
			}

			String emailSubject='Possible problem with SAP interface';

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(notifyEmailAddresses);

			email.setSubject(emailSubject); 
			String messageBody_Plain = '' ;
			String messageBody_Html = '' ; 

			messageBody_Html+=cs.Job_Status__c;
			messageBody_Html+='<br/>Work Order Activity: ' + cs.Work_Order_Number__c + '-' + cs.Activity_Number__c;
			string url = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityDetailTimeLog?id=' + cs.ActivityId__c;
			messageBody_Html += '<br/><br/><a href="' + url +'">View Activity</a>';

			string urlMonitor = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_InterfaceMonitor';			
			messageBody_Html += '<br/><a href="' + urlMonitor +'">View Monitor</a>';

			//email.setPlainTextBody(messageBody_Plain);
            email.setHtmlBody(messageBody_Html);					

			Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {email};
			Messaging.sendEmail(emailList);
		}
	}

	public static Boolean validateEmail(String email) {
	Boolean res = true;
		
	
	String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
	// source: <a href="http://www.regular-expressions.info/email.html" target="_blank" rel="nofollow">http://www.regular-expressions.info/email.html</a>
	Pattern MyPattern = Pattern.compile(emailRegex);
	Matcher MyMatcher = MyPattern.matcher(email);

	if (!MyMatcher.matches()) 
	    res = false;
	return res;	
	}	
}