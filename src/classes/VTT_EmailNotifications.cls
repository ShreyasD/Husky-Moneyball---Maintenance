/*-------------------------------------------------------------------------------------------------
Author     : Sergey Makarov
Company    : Husky Energy
Description: A Email Notification Utility class for Vendor Time Tracking
Inputs     : N/A
Test Class : VTT_EmailNotificationsTest
            02.17.16 sm  changes to  VTT_Utilities.GetNotificationPlannerGroupEmailPerActivity to populate a Map with multiple email adresses
                         and check for User.isActive.  
                         Replaced GenerateMissingTradesmanEmails with GenerateVendorSupervisorAutoAssignEmails
                         in NotifyVendorSupervisorsAutoAssignment method
            04.14.16 ssd made tradesman assignment email configurable with number of days to be notified
            			 as a setting in HOG Settings
---------------------------------------------------------------------------------------------------*/ 

global class VTT_EmailNotifications implements Database.Batchable<sObject> {
	
	public static final String ROLE_FIELDSCHEDULER = 'Field Scheduler';
	public static final String ROLE_TRADESMANLEAD = 'Tradesman Lead';	
	

	public static final String NOTIFICATIONTYPE_MISSINGVENDOR = 'MISSINGVENDOR';
	public static final String NOTIFICATIONTYPE_MISSINGTRADESMAN = 'MISSINGTRADESMAN';	
	public static final String NOTIFICATIONTYPE_ACTIVITYINPROGRESS = 'ACTIVITYINPROGRESS';	
	public static final String NOTIFICATIONTYPE_MISSINGTRADESMAN_FIELDSCHEDULER = 'MISSINGTRADESMAN_FIELDSCHEDULER';
	public static final String NOTIFICATIONTYPE_ACTIVITYASSIGNMENT_TRADESMAN = 'ACTIVITYASSIGNMENT_TRADESMAN';	


	@TestVisible static Integer emailLimits;

	public String NotificationType {get; private set;}
	public String FieldSchedulerGenericEmail {get; private set;}	
	public Integer Notification_Days_VendorSupervisor {get; private set;}	
	public Integer Notification_Days_FieldScheduler {get; private set;}
	public Integer Notification_Days_TradesmanAssignment {get; private set;}
	public DateTime Notification_TradesmanAssignment_Date_Cutoff {get; private set;}		
	public String query {get; private set;}

	//activities with no vendor assigned
	//SM 01.04.2016 added condition to exclude activities 'On Hold' and with Work Center = OPER
	String queryFieldScheduler = 'select Id, Name, Assigned_Vendor__c, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Functional_Location_Description_SAP__c,' 
	+ ' Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c, '
	+ ' Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, Maintenance_Work_Order__r.Functional_Location_Description_SAP__c,Description_of_Equipment__c, ' 
	+ ' Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c ' 
	+ ' from Work_Order_Activity__c ' 
	+ ' where Assigned_Vendor__c = null and SAP_Deleted__c = false and Status__c <> \'Completed\''
	+ ' and Maintenance_Work_Order__r.On_Hold__c = false and Work_Center__c <> \'OPER\'';

	//activities with vendor assigned but without assigned tradesman
	String queryVendorSupervisor = 'select Id, Name, Assigned_Vendor__c, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Vendor_Supervisor__c, Functional_Location_Description_SAP__c,' 
	+ ' Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c, '
	+ ' Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, Maintenance_Work_Order__r.Functional_Location_Description_SAP__c,Description_of_Equipment__c,' 
	+ ' Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c ' 
	+ ' from Work_Order_Activity__c '
	+ ' where Assigned_Vendor__c <> null and Number_of_assigned_people__c=0 and SAP_Deleted__c = false and Status__c <> \'Completed\'';



	//activities with vendor assigned but without assigned tradesman
	String queryActivitiesInProgress = 'select Id, Name, Assigned_Text__c, Assigned_Vendor__c, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Vendor_Supervisor__c, Functional_Location_Description_SAP__c,' 
	+ ' Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c, '
	+ ' Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, Maintenance_Work_Order__r.Functional_Location_Description_SAP__c, Description_of_Equipment__c,' 
	+ ' Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c, ' 
	+ ' (select id, name, email, Tradesman_Status__c, Tradesman_Status_Date__c, Tradesman_Status_Duration__c, ReportsTo.email, User__c, User__r.email from Working_Tradesmen__r), '
	+ ' (select id, Date__c, Tradesman__c, Started_New__c, Started_At_Equipment_New__c,Total_Man_Hours__c from Work_Order_Activity_Logs__r)'
	+ ' from Work_Order_Activity__c '
	+ ' where id in (select Current_Work_Order_Activity__c from Contact where Current_Work_Order_Activity__c <> null) '
	+ ' and SAP_Deleted__c = false and Status__c <> \'Completed\'';


	String queryActivitiesGeneric = 'select Id, Name, Assigned_Text__c, Assigned_Vendor__c, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Vendor_Supervisor__c, Functional_Location_Description_SAP__c,' 
	+ ' Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c, '
	+ ' Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, Maintenance_Work_Order__r.Functional_Location_Description_SAP__c,Description_of_Equipment__c,' 
	+ ' Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c, ' 
	+ ' (select id, name, email, Tradesman_Status__c, Tradesman_Status_Date__c, Tradesman_Status_Duration__c, ReportsTo.email from Working_Tradesmen__r), '
	+ ' (select id, Date__c, Tradesman__c, Started_New__c, Started_At_Equipment_New__c,Total_Man_Hours__c from Work_Order_Activity_Logs__r)'
	+ ' from Work_Order_Activity__c ';

	String queryAssignedActivitiesScheduled = 'select Id, Name, Assigned_Text__c, Assigned_Vendor__c, Assigned_Vendor__r.Name, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Vendor_Supervisor__c,' 
	+ '	Functional_Location_Description_SAP__c, Description_of_Equipment__c,'
	+ '	Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c,' 
	+ '	Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c,' 
	+ '	Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c,'
	+ ' ('
	+ '	select id, Tradesman__r.Tradesman_Status__c, Tradesman__r.email, Tradesman__r.User__c, Tradesman__r.User__r.email'  
	+ ' from Work_Order_Activity_Assignments__r' 
	+ '	where' 
	+ '		('
	+ '			Tradesman__r.Tradesman_Status__c = null or Tradesman__r.Tradesman_Status__c = \'' + VTT_Utilities.TRADESMAN_STATUS_NOTWORKING + '\''
    + '		)'
	+ '		and (Tradesman__r.email <> null or Tradesman__r.User__r.email <> null)'
	+ ' )'
	+ ' from Work_Order_Activity__c '
	+ ' where Number_of_assigned_people__c > 0 and SAP_Deleted__c = false and Status__c In (\'' + VTT_Utilities.ACTIVITY_STATUS_NEW + '\','
	+ ' \'' + VTT_Utilities.ACTIVITY_STATUS_SCHEDULED + '\')';


	global VTT_EmailNotifications() {
		this(NOTIFICATIONTYPE_MISSINGVENDOR);
	}
	
	global VTT_EmailNotifications(String pNotificationType) {
		this.NotificationType = pNotificationType;

        HOG_Settings__c settingsHOG = HOG_Settings__c.getInstance();
        FieldSchedulerGenericEmail = settingsHOG.VTT_Generic_Field_Scheduler__c;        
		Notification_Days_VendorSupervisor = Integer.valueOf(settingsHOG.VTT_Notification_Days_1__c);
		Notification_Days_FieldScheduler = Integer.valueOf(settingsHOG.VTT_Notification_Days_2__c);
		Notification_Days_TradesmanAssignment = Integer.valueOf(settingsHOG.VTT_AssignedEmailNotificationDuration__c);

		Notification_Days_VendorSupervisor = (Notification_Days_VendorSupervisor == null? 7 : Notification_Days_VendorSupervisor ); //use default 7 days in case if custom settings are not set
		Notification_Days_FieldScheduler = (Notification_Days_FieldScheduler == null? 5 : Notification_Days_FieldScheduler ); //use default 7 days in case if custom settings are not set
		Notification_Days_TradesmanAssignment = (Notification_Days_TradesmanAssignment == null ? 14 : Notification_Days_TradesmanAssignment); //use default 14 days in case if custom settings are not set


		//ssd make tradesman assignment email notification duration configurable
		Notification_TradesmanAssignment_Date_Cutoff = DateTime.newInstance(Date.today().addDays(Notification_Days_TradesmanAssignment-1), Time.newInstance(0, 0, 0, 0));
		System.debug('Notification_TradesmanAssignment_Date_Cutoff: ' + Notification_TradesmanAssignment_Date_Cutoff);

		query ='';
		if(NotificationType == NOTIFICATIONTYPE_MISSINGVENDOR)
		{
			query = queryFieldScheduler;
		}
		else if(NotificationType == NOTIFICATIONTYPE_MISSINGTRADESMAN)
		{
			query = queryVendorSupervisor + ' and Scheduled_Start_Date__c <= NEXT_N_DAYS:' + Notification_Days_VendorSupervisor ;
		}
		else if(NotificationType == NOTIFICATIONTYPE_MISSINGTRADESMAN_FIELDSCHEDULER)
		{
			query = queryVendorSupervisor + ' and Scheduled_Start_Date__c <= NEXT_N_DAYS:' + Notification_Days_FieldScheduler ;
		}
		else if(NotificationType == NOTIFICATIONTYPE_ACTIVITYINPROGRESS)
		{
			query = queryActivitiesInProgress;
		}
		else if(NotificationType == NOTIFICATIONTYPE_ACTIVITYASSIGNMENT_TRADESMAN)
		{
			System.debug('NOTIFICATIONTYPE_ACTIVITYASSIGNMENT_TRADESMAN executing ...: ');
			System.debug('Date Range: ' + Notification_TradesmanAssignment_Date_Cutoff.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' to ' +
				Notification_TradesmanAssignment_Date_Cutoff.addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
			query = queryAssignedActivitiesScheduled + ' and (Scheduled_Start_Date__c >= ' + Notification_TradesmanAssignment_Date_Cutoff.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
			+ ' and Scheduled_Start_Date__c <= ' + Notification_TradesmanAssignment_Date_Cutoff.addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') +')';
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		System.debug('VTT_EmailNotifications.start-> NotificationType: ' + NotificationType + ' query: ' + query);
		return Database.getQueryLocator(query);
	}



   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

		List<Work_Order_Activity__c> workOrderActivityList = (List<Work_Order_Activity__c>)scope;
		Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};

		system.debug('NotificationType: ' + NotificationType);
		if(NotificationType == NOTIFICATIONTYPE_MISSINGVENDOR)
		{
			emailList =  GenerateMissingVendorEmails(workOrderActivityList);
		}
		else if(NotificationType == NOTIFICATIONTYPE_MISSINGTRADESMAN)
		{
			emailList =  GenerateMissingTradesmanEmails(workOrderActivityList);
		}
		else if(NotificationType == NOTIFICATIONTYPE_ACTIVITYINPROGRESS)
		{
			emailList =  GenerateActivitiesInProgressEmails(workOrderActivityList);
		}		
		else if(NotificationType == NOTIFICATIONTYPE_MISSINGTRADESMAN_FIELDSCHEDULER)
		{
			emailList =  GenerateFieldSchedulerMissingTradesmanEmails(workOrderActivityList);
		}
		else if(NotificationType == NOTIFICATIONTYPE_ACTIVITYASSIGNMENT_TRADESMAN)
		{
			System.debug('VTT_EmailNotifications->execute: workOrderActivityList: ' + workOrderActivityList);
			emailList =  GenerateTradesmanAssignmentApproachingEmail(workOrderActivityList);
		}

		List<Messaging.SingleEmailMessage> sanitizedEmailList = GetSanitizedEmailList(emailList);
		System.debug('VTT_EmailNotifications->execute: emailList.size: ' + emailList.size() + ' sanitizedEmailList.size: ' + sanitizedEmailList.size());
		if(sanitizedEmailList.size()> 0)
		{
			if(Limits.getEmailInvocations() + sanitizedEmailList.size() < Limits.getLimitEmailInvocations())
				Messaging.sendEmail(sanitizedEmailList);			
		}


	}
	
	global void finish(Database.BatchableContext BC) {
            VTT_EmailNotifications.emailLimits = Limits.getEmailInvocations();
	}

	public Messaging.SingleEmailMessage[] GenerateActivitiesInProgressEmails(List<Work_Order_Activity__c> pWorkOrderActivityList)
	{
		system.debug('GenerateActivitiesInProgressEmails executing...');

  		List<HOG_Planner_Group__c> plannerGroupList = [select id, Name, 
  			(select id, Order_Type_Text__c, Work_Center__c, 
  				Contact__r.email, Contact__r.User__c, Contact__r.User__r.email, Contact__r.User__r.isActive
  			from HOG_Planner_Group_Notification_Types__r 
  			WHERE Role_Type__c = :ROLE_TRADESMANLEAD) 
			from HOG_Planner_Group__c];

   		Map<String, List<Work_Order_Activity__c>> notificationMap = new Map<String, List<Work_Order_Activity__c>>();

	    Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};

		for (Work_Order_Activity__c activityRecord : pWorkOrderActivityList) 
		{

			/*
			special check, if tradesman updated activity in less then 2 hours 
			we still want to send notification in case if he was working on this activity 
			for more than 2 hours
			*/
			Boolean skipActivity = false;

			for(Contact tradesman : activityRecord.working_tradesmen__r)
			{
				Datetime startTime = GetDailyLogStartTime(activityRecord, tradesman);
				if(startTime == null) {
					skipActivity = true;
				}
				else {	
					Decimal hoursWorked = Decimal.valueOf(Datetime.now().getTime() - startTime.getTime())/(1000*60*60);
					if(hoursWorked < 2) {
						skipActivity= true;
					}
				}
			}
			if(skipActivity)
			{
				continue;
			}


			Boolean fieldSchedulerFound = FindNotificationContact(plannerGroupList, activityRecord, notificationMap);


			List<String> emailAddresses = new List<String>();
			for(Contact tradesman : activityRecord.working_tradesmen__r)
			{
				system.debug(tradesman);
				if(Tradesman.User__c <> null && Tradesman.User__r.email <> null)
				{
					emailAddresses.add(tradesman.User__r.email);	
				}				
				if(tradesman.email <> null)
				{
					emailAddresses.add(tradesman.email);	
				}
				if(tradesman.reportsto <> null && tradesman.reportsto.email <> null)
				{
					emailAddresses.add(tradesman.reportsto.email);	
				}				
			}
			

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(emailAddresses);

			email.setSubject('Tradesman Still Working'); 
			String messageBody_Plain = '' ;
			String messageBody_Html = '' ; 
			String idList = '';				

			messageBody_Html  += GenerateSingleActivityInProgressEmailBody(activityRecord);	
			idList += activityRecord.id + ',';

            email.setHtmlBody(messageBody_Html);					

			emailList.add(email);
		}

		for(String tradesmanLeadEmail: notificationMap.keySet())
		{
			List<Work_Order_Activity__c> activityList = (List<Work_Order_Activity__c>)notificationMap.get(tradesmanLeadEmail);

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(new String[] {tradesmanLeadEmail});

			email.setSubject('Tradesman Still Working'); 
			String messageBody_Plain = '' ;
			String messageBody_Html = '' ; 
			String idList = '';				
			for(Work_Order_Activity__c activityRecord: activityList)
			{
				//messageBody_Plain  = messageBody_Plain + activityRecord.Name + '\n';
				messageBody_Html  += GenerateSingleActivityInProgressEmailBody(activityRecord);	
				idList += activityRecord.id + ',';
			}
			if(activityList.size() > 1)
			{
				string url = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityListView?idlist=' + idList;
				messageBody_Html = '<a href="' + url +'">View All '+ activityList.size() + ' Activities</a><br/><br/><hr/>' + messageBody_Html;
			}

			//email.setPlainTextBody(messageBody_Plain);
            email.setHtmlBody(messageBody_Html);					

			emailList.add(email);
		}	
		system.debug('************** GenerateActivitiesInProgressEmails generates ' + emailList.size() + ' emails');
		system.debug(emailList);
	    return emailList;
	}


	public void NotifyVendorSupervisorsAutoAssignment(List<Work_Order_Activity__c> pWorkOrderActivityList)
	{
		Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};

		List<Work_Order_Activity__c> workOrderActivityList = [
		select Id, Name, Assigned_Text__c, Assigned_Vendor__c, Assigned_Vendor__r.Name, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Vendor_Supervisor__r.Email, 
		Functional_Location_Description_SAP__c, Description_of_Equipment__c,
		Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c, 
		Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, 
		Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c
		from Work_Order_Activity__c 
		where id in :pWorkOrderActivityList];

		//emailList =  GenerateMissingTradesmanEmails(workOrderActivityList);
		//SM 2.17/2016
		emailList =  GenerateVendorSupervisorAutoAssignEmails(workOrderActivityList);
		if(Limits.getEmailInvocations() + emailList.size() < Limits.getLimitEmailInvocations())
			Messaging.sendEmail(emailList);		
	}

	public void NotifyTradesmanAfterActivtyAssignment(List<Work_Order_Activity_Assignment__c>  pAssignmentsList)
	{
		
		Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};
		emailList =  GenerateTradesmanAfterActivtyAssignmentEmails(pAssignmentsList);
		if(Limits.getEmailInvocations() + emailList.size() < Limits.getLimitEmailInvocations())
			Messaging.sendEmail(emailList);	
	}

	public void NotifySupervisorsRejectedActivityAssignment(List<Work_Order_Activity_Assignment__c> pAssignmentsList) 
	{
		System.debug('VTT_EmailNotifications->NotifySupervisorsRejectedActivityAssignment');
		Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};
		emailList = GenerateVendorSupervisorRejectedActivityEmails(pAssignmentsList);
		if(Limits.getEmailInvocations() + emailList.size() < Limits.getLimitEmailInvocations())
			Messaging.sendEmail(emailList);
	}

	public Messaging.SingleEmailMessage[] GenerateVendorSupervisorRejectedActivityEmails(List<Work_Order_Activity_Assignment__c> pRejectedAssignmentsList) 
	{
		System.debug('VTT_EmailNotifications->GenerateVendorSupervisorRejectedActivityEmails');
		Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};
		
		Set<Id> activitySet = new Set<Id>();
		Set<Id> tradesmanSet = new Set<Id>(); 
		for(Work_Order_Activity_Assignment__c assignmentRec : pRejectedAssignmentsList) {
			activitySet.add(assignmentRec.Work_Order_Activity__c);
			tradesmanSet.add(assignmentRec.Tradesman__c);
		}

		//Get Work Order Activities
		Map<Id, Work_Order_Activity__c> activityMap = new Map<Id, Work_Order_Activity__c>([
		select Id, Name, Assigned_Text__c, Assigned_Vendor__c, Assigned_Vendor__r.Name, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Vendor_Supervisor__c, 
		Functional_Location_Description_SAP__c, Description_of_Equipment__c,
		Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c, 
		Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, 
		Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c,
		(
			select Id, Reject_Reason__c 
			from Work_Order_Activity_Assignments__r 
			where Id in :pRejectedAssignmentsList
		)		 
		from Work_Order_Activity__c 
		where 
		Id in :activitySet
		]);

		//Get Tradesman that rejected activity
		Map<Id, Contact> tradesmanMap = new Map<Id, Contact>([
			Select Id, Name, ReportsTo.Email, ReportsTo.User__c, ReportsTo.User__r.Email, User__r.Email, User__r.isActive, ReportsTo.User__r.isActive
			From Contact
			Where Id In :tradesmanSet
		]);

		//Get TradesmandLeadMap Per Activity
		Map<Id, List<String>> tradesmanEmailPerActivity = VTT_Utilities.GetNotificationPlannerGroupEmailPerActivity(activityMap.values(), ROLE_TRADESMANLEAD);
		//Get FieldSchedulerMap Per Activity
		Map<Id, List<String>> fieldSchedulerEmailPerActivity = VTT_Utilities.GetNotificationPlannerGroupEmailPerActivity(activityMap.values(), ROLE_FIELDSCHEDULER);


		for(Work_Order_Activity_Assignment__c assignmentRec : pRejectedAssignmentsList)
		{
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			Work_Order_Activity__c activity = activityMap.get(assignmentRec.Work_Order_Activity__c);
			Contact tradesman = tradesmanMap.get(assignmentRec.Tradesman__c);
			

			List<String> toAddresses = new List<String>();
			if(tradesman.User__r.Email != null) toAddresses.add(tradesman.User__r.Email); //Add tradesman email address
			if(tradesman.ReportsTo.Email != null) toAddresses.add(tradesman.ReportsTo.Email); //Add Reports To Email Address			
			if(tradesman.ReportsTo.User__c != null && tradesman.ReportsTo.User__r.Email != null) toAddresses.add(tradesman.ReportsTo.User__r.Email); //Add Reports To Email Address

			if(tradesmanEmailPerActivity.get(activity.ID) != null) toAddresses.addall(tradesmanEmailPerActivity.get(activity.ID)); //Add TrademanLead Email
			if(fieldSchedulerEmailPerActivity.get(activity.ID) != null) toAddresses.addall(fieldSchedulerEmailPerActivity.get(activity.ID)); //Add FieldScheduler Email


			String emailSubject = 'Activity \"' + activity.Name + '\" Rejected';
			String messageBody_Plain = '' ;
			String messageBody_Html = '' ; 
			
			//Create Email
			email.setToAddresses(toAddresses);
			email.setSubject(emailSubject);
			messageBody_Html = GenerateSingleActivityRejectedEmailBody(activity, assignmentRec);
			email.setHtmlBody(messageBody_Html);

			emailList.add(email);
		}
		return emailList;
	}

	public Messaging.SingleEmailMessage[] GenerateTradesmanAfterActivtyAssignmentEmails(List<Work_Order_Activity_Assignment__c> pAssignmentsList)
	{
		System.debug(pAssignmentsList);
	    Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};		

		Set<ID> activitySet = new Set<ID>();
		for(Work_Order_Activity_Assignment__c assignmentRec :pAssignmentsList)
		{
			activitySet.add(assignmentRec.Work_Order_Activity__c);
		}

		List<Work_Order_Activity__c> workOrderActivityList = [
		select Id, Name, Assigned_Text__c, Assigned_Vendor__c, Assigned_Vendor__r.Name, Description__c, Operation_Number__c, Scheduled_Start_Date__c, Status__c, Work_Center__c, Vendor_Supervisor__c, 
		Functional_Location_Description_SAP__c, Description_of_Equipment__c,
		Maintenance_Work_Order__r.Work_Order_Number__c, Maintenance_Work_Order__r.Order_Description__c, 
		Maintenance_Work_Order__r.Description_of_Equipment__c, Maintenance_Work_Order__r.Functional_Location__c, 
		Maintenance_Work_Order__r.Order_Type__c, Maintenance_Work_Order__r.Planner_Group__c, Maintenance_Work_Order__r.Plant_Section__c,
		(
			select id, Tradesman__r.Tradesman_Status__c, Tradesman__r.email, Tradesman__r.User__c, Tradesman__r.User__r.email  
			from Work_Order_Activity_Assignments__r 
			where 
				(
					Tradesman__r.Tradesman_Status__c = null or Tradesman__r.Tradesman_Status__c = :VTT_Utilities.TRADESMAN_STATUS_NOTWORKING
				)
				and (Tradesman__r.email <> null or Tradesman__r.User__r.email <> null)
	 			and id in :pAssignmentsList
		)		 
		from Work_Order_Activity__c 
		where 
		((Scheduled_Start_Date__c <= :Notification_TradesmanAssignment_Date_Cutoff AND Scheduled_Start_Date__c >= TODAY)
		 or Scheduled_Start_Date__c <: Datetime.now())
		AND id in :activitySet];


		system.debug('GenerateTradesmanAfterActivtyAssignmentEmails ActivityList: ' + workOrderActivityList);
   		for(Work_Order_Activity__c activityRecord : workOrderActivityList)
   		{

   			if(activityRecord.Work_Order_Activity_Assignments__r.size()>0)
   			{
				//SM 3/24/2016 use setTargetObjectId instead of setToAddresses to avoid 1000 emails limit
                for(Work_Order_Activity_Assignment__c assignmentRecord : activityRecord.Work_Order_Activity_Assignments__r) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                    //Set Target Object Id
                    email.setTargetObjectId(assignmentRecord.Tradesman__r.User__c != null ? 
                        assignmentRecord.Tradesman__r.User__c :
                        assignmentRecord.Tradesman__c);

                    String emailSubject =  String.format('Activity has been assigned to {0} for {1}', 
                        new List<String>{activityRecord.Assigned_Vendor__r.Name , activityRecord.Assigned_Text__c} );
                    email.setSubject(emailSubject); 
                    String messageBody_Plain = '' ;
                    String messageBody_Html = '' ; 
                    String idList = ''; 
                    messageBody_Html  += GenerateSingleActivityEmailBody(activityRecord);   

                    email.setHtmlBody(messageBody_Html);
                    email.setSaveAsActivity(false);                 

                    emailList.add(email);
                }				
			}		

   		}
	    return emailList;	    
	}

	public Messaging.SingleEmailMessage[] GenerateTradesmanAssignmentApproachingEmail(List<Work_Order_Activity__c> pWorkOrderActivityList)
	{
		system.debug('GenerateTradesmanAssignmentApproachingEmail executing...');

		Messaging.SingleEmailMessage[] emailList = new List<Messaging.SingleEmailMessage>();

		for(Work_Order_Activity__c activityRecord : pWorkOrderActivityList)
   		{

   			if(activityRecord.Work_Order_Activity_Assignments__r.size()>0)
   			{
                for(Work_Order_Activity_Assignment__c assignmentRecord : activityRecord.Work_Order_Activity_Assignments__r) {
                    System.debug('');

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                    //Set Target Object Id
                    email.setTargetObjectId(assignmentRecord.Tradesman__r.User__c != null ? 
                        assignmentRecord.Tradesman__r.User__c :
                        assignmentRecord.Tradesman__c);

                    String emailSubject =  String.format('Activity has been assigned to {0} for {1}', 
                        new List<String>{activityRecord.Assigned_Vendor__r.Name , activityRecord.Assigned_Text__c} );
                    email.setSubject(emailSubject); 
                    String messageBody_Plain = '' ;
                    String messageBody_Html = '' ; 
                    String idList = ''; 
                    messageBody_Html  += GenerateSingleActivityEmailBody(activityRecord);   

                    email.setHtmlBody(messageBody_Html);
                    email.setSaveAsActivity(false);                 

                    emailList.add(email);
                }				
			}		

   		}
	    return emailList;
	}

	public Messaging.SingleEmailMessage[] GenerateMissingTradesmanEmails(List<Work_Order_Activity__c> pWorkOrderActivityList)
	{
		system.debug('GenerateMissingTradesmanEmails executing...');

   		//we need to find all vendor supervisors first
   		Set<ID> accountSet = new Set<ID>();
		Map<ID, List<Work_Order_Activity__c>> vendorActivityMap = new Map<ID, List<Work_Order_Activity__c>>();

   		for(Work_Order_Activity__c activityRecord : pWorkOrderActivityList)
   		{
   			accountSet.add(activityRecord.Assigned_Vendor__c);

			if(vendorActivityMap.containsKey(activityRecord.Assigned_Vendor__c))
			{
				vendorActivityMap.get(activityRecord.Assigned_Vendor__c).add(activityRecord);
			}
			else
			{
				vendorActivityMap.put(activityRecord.Assigned_Vendor__c, new List<Work_Order_Activity__c>{activityRecord});
			}

   		}
   		List<Account> vendorList = [select id, name, 
   				(select id, name, email, User__c, User__r.email 
   					from Contacts where email <> null or (User__r.email <> null and User__r.isActive = true)
   				) 
			from Account where id in :accountSet];
   		Set<ID> vendorUserSet = new Set<ID>();
   		for(Account acc: vendorList)
   		{
   			for(Contact contactRecord : acc.Contacts)
   			{
   				vendorUserSet.add(contactRecord.User__c);
   			}
   		}
		PermissionSet ps = [select id, name from PermissionSet where name = :VTT_Utilities.VENDORSUPERVISOR_PERMISSIONSET_NAME limit 1];
        List<PermissionSetAssignment> psalist = [select id, AssigneeId from PermissionSetAssignment where AssigneeId in :vendorUserSet and PermissionSetId =:ps.id];
		Set<ID> vendorSupervisorUserSet = new Set<ID>();  
		for(PermissionSetAssignment psaRecord :psalist)
		{
			vendorSupervisorUserSet.add(psaRecord.AssigneeId);
		}

		system.debug('vendorSupervisorUserSet');
		system.debug(vendorSupervisorUserSet);		

		//prepare map with Account Id as a key and list of emails for vendor supervisors
        Map<ID, List<String>> vendorSupervisorMap = new Map<ID, List<String>>();
   		for(Account acc: vendorList)
   		{
   			List<string> vendorSupervisorEmailList = new List<string>();
   			for(Contact contactRecord : acc.Contacts)
   			{
   				if(vendorSupervisorUserSet.contains(contactRecord.User__c))
   				{
   					String email = contactRecord.User__c == null ? contactRecord.email : contactRecord.User__r.email;
   					if(email <> null)
   					{
   						vendorSupervisorEmailList.add(email);   						
   					}

   				}
   			}
   			vendorSupervisorMap.put(acc.id, vendorSupervisorEmailList);
   		}
   		system.debug('vendorSupervisorMap');
   		system.debug(vendorSupervisorMap);

	    Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};

		for (ID accountID : vendorActivityMap.keySet()) 
		{
			List<Work_Order_Activity__c> activityList = (List<Work_Order_Activity__c>)vendorActivityMap.get(accountID);

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

			List<string> vendorSupervisorEmailList = vendorSupervisorMap.get(accountID);

			if(vendorSupervisorEmailList.size()>0)
			{
				email.setToAddresses(vendorSupervisorEmailList);

				email.setSubject('TRADESPERSON(S) NOT ASSIGNED'); 
				String messageBody_Plain = '' ;
				String messageBody_Html = '' ; 
				String idList = '';	
							
				for(Work_Order_Activity__c activityRecord: activityList)
				{
					//messageBody_Plain  = messageBody_Plain + activityRecord.Name + '\n';
					messageBody_Html  += GenerateSingleActivityEmailBody(activityRecord);	
					idList += activityRecord.id + ',';
				}

				if(activityList.size() > 1)
				{
					string url = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityListView?idlist=' + idList;
					messageBody_Html = '<a href="' + url +'">View All '+ activityList.size() + ' Activities</a><br/><br/><hr/>' + messageBody_Html;
				}

				//email.setPlainTextBody(messageBody_Plain);
	            email.setHtmlBody(messageBody_Html);					

				emailList.add(email);				
			}

		}


		//generate emails for TradesmanLeads

		//Get TradesmandLeadMap Per Activity
		Map<Id, List<String>> tradesmanLeadEmailPerActivity = VTT_Utilities.GetNotificationPlannerGroupEmailPerActivity(pWorkOrderActivityList, ROLE_TRADESMANLEAD);
		Map<String, String> tradesmanLeadEmailMap = new Map<String, String>();

		String idList = '';		
		for(Work_Order_Activity__c activityRecord: pWorkOrderActivityList)
		{

			if(tradesmanLeadEmailPerActivity.get(activityRecord.ID) != null) 
			{
				List<String> emailAddressList = tradesmanLeadEmailPerActivity.get(activityRecord.ID);

				for(String email : emailAddressList)
				{
					String emailbody;

					if(tradesmanLeadEmailMap.containsKey(email))
					{
						emailbody = tradesmanLeadEmailMap.get(email);
						emailbody += GenerateSingleActivityEmailBody(activityRecord);
					}
					else
					{
						emailbody = GenerateSingleActivityEmailBody(activityRecord);
					}
					tradesmanLeadEmailMap.put(email, emailbody);

					
				}

				idList += activityRecord.id + ',';
			}
					
		}
		for(String emailAddress : tradesmanLeadEmailMap.keySet())
		{

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(new String[]{emailAddress});

			email.setSubject('TRADESPERSON(S) NOT ASSIGNED'); 
			String messageBody_Plain = '' ;
			String messageBody_Html = tradesmanLeadEmailMap.get(emailAddress);				
			if(idList!='')
			{
				string url = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityListView?idlist=' + idList;
				messageBody_Html = '<a href="' + url +'">View All Activities</a><br/><br/><hr/>' + messageBody_Html;
			}
			email.setHtmlBody(messageBody_Html);					
			emailList.add(email);	

		}


	    return emailList;
	}

	public Messaging.SingleEmailMessage[] GenerateVendorSupervisorAutoAssignEmails(List<Work_Order_Activity__c> pWorkOrderActivityList)
	{
		system.debug('GenerateVendorSupervisorAutoAssignEmails executing...');

		Map<String, List<Work_Order_Activity__c>> vendorActivityMap = new Map<String, List<Work_Order_Activity__c>>();
   		for(Work_Order_Activity__c activityRecord : pWorkOrderActivityList)
   		{
   			String vendorSupervisorEmail = activityRecord.Vendor_Supervisor__r.email;

   			if(vendorSupervisorEmail <> null)
   			{
				if(vendorActivityMap.containsKey(vendorSupervisorEmail))
				{
					vendorActivityMap.get(vendorSupervisorEmail).add(activityRecord);
				}
				else
				{
					vendorActivityMap.put(vendorSupervisorEmail, new List<Work_Order_Activity__c>{activityRecord});
				}   				
   			}
   		}
   		system.debug('vendorActivityMap');
		system.debug(vendorActivityMap);

	    Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};

		for (String vendorSupervisorEmail : vendorActivityMap.keySet()) 
		{
			List<Work_Order_Activity__c> activityList = (List<Work_Order_Activity__c>)vendorActivityMap.get(vendorSupervisorEmail);

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

			email.setToAddresses( new String[]{vendorSupervisorEmail});

			email.setSubject('TRADESPERSON(S) NOT ASSIGNED'); 
			String messageBody_Plain = '' ;
			String messageBody_Html = '' ; 
			String idList = '';	
						
			for(Work_Order_Activity__c activityRecord: activityList)
			{
				//messageBody_Plain  = messageBody_Plain + activityRecord.Name + '\n';
				messageBody_Html  += GenerateSingleActivityEmailBody(activityRecord);	
				idList += activityRecord.id + ',';
			}

			if(activityList.size() > 1)
			{			
				string url = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityListView?idlist=' + idList;
				messageBody_Html = '<a href="' + url +'">View All '+ activityList.size() + ' Activities</a><br/><br/><hr/>' + messageBody_Html;
			}
			//email.setPlainTextBody(messageBody_Plain);
            email.setHtmlBody(messageBody_Html);					

			emailList.add(email);
		}


	    return emailList;
	}


	public Messaging.SingleEmailMessage[] GenerateMissingVendorEmails(List<Work_Order_Activity__c> pWorkOrderActivityList)
	{

		system.debug('GenerateMissingVendorEmails executing...');		
  		List<HOG_Planner_Group__c> plannerGroupFieldSchedulerList = [select id, Name, 
  			(select id, Order_Type_Text__c,Work_Center__c,
  			Contact__r.email, Contact__r.User__c, Contact__r.User__r.email 
  			from HOG_Planner_Group_Notification_Types__r 
  			WHERE Role_Type__c = :ROLE_FIELDSCHEDULER) 
			from HOG_Planner_Group__c];

  		List<HOG_Planner_Group__c> plannerGroupTradesmanLeadList = [select id, Name, 
  			(select id, Order_Type_Text__c, Work_Center__c,
  			Contact__r.email, Contact__r.User__c, Contact__r.User__r.email 
  			from HOG_Planner_Group_Notification_Types__r 
  			WHERE Role_Type__c = :ROLE_TRADESMANLEAD) 
			from HOG_Planner_Group__c];




   		Map<String, List<Work_Order_Activity__c>> notificationMap = new Map<String, List<Work_Order_Activity__c>>();

		for (Work_Order_Activity__c activityRecord : pWorkOrderActivityList) 
		{
			//find field scheduler
			FindNotificationContact(plannerGroupFieldSchedulerList, activityRecord, notificationMap);
			//find tradesman lead
			FindNotificationContact(plannerGroupTradesmanLeadList, activityRecord, notificationMap);			
	    }

	    //Now lets go thru the map and build emails
	    Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};

		for(String emailAddress: notificationMap.keySet())
		{
			List<Work_Order_Activity__c> activityList = (List<Work_Order_Activity__c>)notificationMap.get(emailAddress);

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(new String[] {emailAddress});

			email.setSubject('MISSING VENDOR - Activities do not have a vendor assigned'); 
			String messageBody_Plain = '' ;
			String messageBody_Html = '' ; 
			String idList = '';				
			for(Work_Order_Activity__c activityRecord: activityList)
			{
				//messageBody_Plain  = messageBody_Plain + activityRecord.Name + '\n';
				messageBody_Html  += GenerateSingleActivityEmailBody(activityRecord);	
				idList += activityRecord.id + ',';
			}
			if(activityList.size() > 1)
			{
				string url = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityListView?idlist=' + idList;
				messageBody_Html = '<a href="' + url +'">View All '+ activityList.size() + ' Activities</a><br/><br/><hr/>' + messageBody_Html;
			}

			//email.setPlainTextBody(messageBody_Plain);
            email.setHtmlBody(messageBody_Html);					

			emailList.add(email);
		}		    
		return emailList;
	}	
	public Messaging.SingleEmailMessage[] GenerateFieldSchedulerMissingTradesmanEmails(List<Work_Order_Activity__c> pWorkOrderActivityList)
	{

		system.debug('GenerateFieldSchedulerEmails executing...');

		String emailSubject =  'TRADESPERSON(S) NOT ASSIGNED';  

  		List<HOG_Planner_Group__c> plannerGroupFieldSchedulerList = [select id, Name, 
  				(
				select id,  Order_Type_Text__c, Work_Center__c,
  				Contact__r.email, Contact__r.User__c, Contact__r.User__r.email 
  				from HOG_Planner_Group_Notification_Types__r 
  				WHERE Role_Type__c = :ROLE_FIELDSCHEDULER
  				) 
				from HOG_Planner_Group__c];

  		List<HOG_Planner_Group__c> plannerGroupTradesmanLeadList = [select id, Name, 
  			(select id,  Order_Type_Text__c, Work_Center__c,
  			Contact__r.email, Contact__r.User__c, Contact__r.User__r.email 
  			from HOG_Planner_Group_Notification_Types__r 
  			WHERE Role_Type__c = :ROLE_TRADESMANLEAD) 
			from HOG_Planner_Group__c];


   		Map<String, List<Work_Order_Activity__c>> notificationMap = new Map<String, List<Work_Order_Activity__c>>();

		for (Work_Order_Activity__c activityRecord : pWorkOrderActivityList) 
		{

			//find field scheduler
			FindNotificationContact(plannerGroupFieldSchedulerList, activityRecord, notificationMap);
			//find tradesman lead
			FindNotificationContact(plannerGroupTradesmanLeadList, activityRecord, notificationMap);	
		}

	    //Now lets go thru the map and build emails
	    Messaging.SingleEmailMessage[] emailList = new Messaging.SingleEmailMessage[] {};
		for(String emailAddress: notificationMap.keySet())
		{
			List<Work_Order_Activity__c> activityList = (List<Work_Order_Activity__c>)notificationMap.get(emailAddress);

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(new String[] {emailAddress});

			email.setSubject(emailSubject); 
			String messageBody_Plain = '' ;
			String messageBody_Html = '' ; 
			String idList = '';				
			for(Work_Order_Activity__c activityRecord: activityList)
			{
				//messageBody_Plain  = messageBody_Plain + activityRecord.Name + '\n';
				messageBody_Html  += GenerateSingleActivityEmailBody(activityRecord);	
				idList += activityRecord.id + ',';
			}
			if(activityList.size() > 1)
			{
				string url = 'https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityListView?idlist=' + idList;
				messageBody_Html = '<a href="' + url +'">View All '+ activityList.size() + ' Activities</a><br/><br/><hr/>' + messageBody_Html;
			}

			//email.setPlainTextBody(messageBody_Plain);
            email.setHtmlBody(messageBody_Html);					

			emailList.add(email);
		}		    
		return emailList;
	}	

	private String GenerateSingleActivityEmailBody(Work_Order_Activity__c pActivityRecord)	
	{
		String messageBody_Html = '';
		String urlWorkOrder = '<a target="vtt_workorder" href="https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/' + pActivityRecord.Maintenance_Work_Order__c + '">View Work Order</a>';
		String urlActivity= '<a target="vtt_activvity" href="https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityDetailTimeLog?id=' + pActivityRecord.id + '">View Activity</a>';

		String scheduledStartDate = (pActivityRecord.Scheduled_Start_Date__c == null?  '' : pActivityRecord.Scheduled_Start_Date__c.format());

		messageBody_Html  += '<table>';
		messageBody_Html  += '<tr><td>Work Order #:</td><td>' + pActivityRecord.Maintenance_Work_Order__r.Work_Order_Number__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Work Order Description:</td><td>' +  pActivityRecord.Maintenance_Work_Order__r.Order_Description__c + '<td/></tr>';					
		messageBody_Html  += '<tr><td>Activity #:</td><td>' + pActivityRecord.Operation_Number__c + '<td/></tr>';				
		messageBody_Html  += '<tr><td>Activity Description:</td><td>' +  pActivityRecord.Description__c + '<td/></tr>';										
		messageBody_Html  += '<tr><td>Functional Location Description:</td><td>' + pActivityRecord.Functional_Location_Description_SAP__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Equipment Description:</td><td>' + pActivityRecord.Description_of_Equipment__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Route:</td><td>' + pActivityRecord.Maintenance_Work_Order__r.Plant_Section__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Planner Group:</td><td>' + pActivityRecord.Maintenance_Work_Order__r.Planner_Group__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Work Center:</td><td>' + pActivityRecord.Work_Center__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Activity Start Date:</td><td>' + scheduledStartDate + '<td/></tr>';
		messageBody_Html  += '<tr><td>' + urlWorkOrder+'</td><td>' + urlActivity + '<td/></tr>';
		messageBody_Html  += '</table>';	
		messageBody_Html  += '<hr/>';

		return messageBody_Html;
	}
	private String GenerateSingleActivityInProgressEmailBody(Work_Order_Activity__c pActivityRecord)	
	{
		String messageBody_Html = '';
		String urlWorkOrder = '<a target="vtt_workorder" href="https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/' + pActivityRecord.Maintenance_Work_Order__c + '">View Work Order</a>';
		String urlActivity= '<a target="vtt_activvity" href="https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityDetailTimeLog?id=' + pActivityRecord.id + '">View Activity</a>';

		String scheduledStartDate = (pActivityRecord.Scheduled_Start_Date__c == null?  '' : pActivityRecord.Scheduled_Start_Date__c.format()); 

		String timeNow = DateTime.now().format('HH:00 a');
		messageBody_Html  += 'It is past ' + timeNow + ' ' +  UserInfo.getTimeZone().getDisplayName() + 
			' and tradesmen has been working on an activity more than 2 hours.<br/>';
		messageBody_Html  += '<table>';
		for(Contact tradesman : pActivityRecord.working_tradesmen__r)
		{
			messageBody_Html  += '<tr><td>Assigned Tradesman:</td><td>' + tradesman.Name + '<td/></tr>';			
			messageBody_Html  += '<tr><td>Tradesman Status:</td><td>' + tradesman.Tradesman_Status__c + '<td/></tr>';
			messageBody_Html  += '<tr><td>Tradesman Started Activity</td><td>' + GetDailyLogStartTime(pActivityRecord, tradesman).format('d/M/yyyy h:mm a') + '<td/></tr>';			
		}		
		messageBody_Html  += '<tr><td>Work Order #:</td><td>' + pActivityRecord.Maintenance_Work_Order__r.Work_Order_Number__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Work Order Description:</td><td>' +  pActivityRecord.Maintenance_Work_Order__r.Order_Description__c + '<td/></tr>';					
		messageBody_Html  += '<tr><td>Activity #:</td><td>' + pActivityRecord.Operation_Number__c + '<td/></tr>';				
		messageBody_Html  += '<tr><td>Activity Description:</td><td>' +  pActivityRecord.Description__c + '<td/></tr>';										
		messageBody_Html  += '<tr><td>Functional Location Description:</td><td>' + pActivityRecord.Functional_Location_Description_SAP__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Equipment Description:</td><td>' + pActivityRecord.Description_of_Equipment__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Route:</td><td>' + pActivityRecord.Maintenance_Work_Order__r.Plant_Section__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Planner Group:</td><td>' + pActivityRecord.Maintenance_Work_Order__r.Planner_Group__c + '<td/></tr>';
		messageBody_Html  += '<tr><td>Work Center:</td><td>' + pActivityRecord.Work_Center__c + '<td/></tr>';
		//messageBody_Html  += '<tr><td>Activity Start Date:</td><td>' + scheduledStartDate + '<td/></tr>';

		messageBody_Html  += '<tr><td>' + urlWorkOrder+'</td><td>' + urlActivity + '<td/></tr>';
		messageBody_Html  += '</table>';	
		messageBody_Html  += '<hr/>';

		return messageBody_Html;
	}

	private String GenerateSingleActivityRejectedEmailBody(Work_Order_Activity__c pActivityRecord, Work_Order_Activity_Assignment__c pAssignmentRecord) 
	{
		String messageBody_Html = '';
		String urlWorkOrder = '<a target="vtt_workorder" href="https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/' + pActivityRecord.Maintenance_Work_Order__c + '">View Work Order</a>';
		String urlActivity= '<a target="vtt_activvity" href="https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/apex/VTT_ActivityDetailTimeLog?id=' + pActivityRecord.id + '">View Activity</a>';

		String scheduledStartDate = (pActivityRecord.Scheduled_Start_Date__c == null?  '' : pActivityRecord.Scheduled_Start_Date__c.format());

		Contact trademanWhoRejected = [Select Id, Name
									   From Contact
									   Where Id = :pAssignmentRecord.Tradesman__c];

		messageBody_Html += 'This Activity has been rejected by ' + trademanWhoRejected.Name +'.<br/><br/>';
		messageBody_Html += '<table>';
		messageBody_Html += '<tr><td>Reason: </td><td>' + ((pAssignmentRecord.Reject_Reason__c == null) ? '' : pAssignmentRecord.Reject_Reason__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Work Order #: </td><td>' + ((pActivityRecord.Maintenance_Work_Order__r.Work_Order_Number__c == null) ? '' : pActivityRecord.Maintenance_Work_Order__r.Work_Order_Number__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Work Order Short Text: </td><td>' + ((pActivityRecord.Maintenance_Work_Order__r.Order_Description__c == null) ? '' : pActivityRecord.Maintenance_Work_Order__r.Order_Description__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Activity #: </td><td>' + ((pActivityRecord.Operation_Number__c == null) ? '' : pActivityRecord.Operation_Number__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Activity Short Text: </td><td>' + ((pActivityRecord.Description__c == null) ? '' : pActivityRecord.Description__c) + '<td/></tr>';
		//messageBody_Html += '<tr><td>Functional Location Description: </td><td>' + ((pActivityRecord.Maintenance_Work_Order__r.Functional_Location_Description_SAP__c == null) ? '' : pActivityRecord.Maintenance_Work_Order__r.Functional_Location_Description_SAP__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Functional Location Description: </td><td>' + ((pActivityRecord.Functional_Location_Description_SAP__c == null) ? '' : pActivityRecord.Functional_Location_Description_SAP__c) + '<td/></tr>';

		messageBody_Html += '<tr><td>Equipment Description: </td><td>' + ((pActivityRecord.Description_of_Equipment__c == null) ? '' : pActivityRecord.Description_of_Equipment__c) + '<td/></tr>';		

		messageBody_Html += '<tr><td>Activity Route: </td><td>' + ((pActivityRecord.Maintenance_Work_Order__r.Plant_Section__c == null) ? '' : pActivityRecord.Maintenance_Work_Order__r.Plant_Section__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Planner Group: </td><td>' + ((pActivityRecord.Maintenance_Work_Order__r.Planner_Group__c == null) ? '' : pActivityRecord.Maintenance_Work_Order__r.Planner_Group__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Work Center: </td><td>' + ((pActivityRecord.Work_Center__c == null) ? '' : pActivityRecord.Work_Center__c) + '<td/></tr>';
		messageBody_Html += '<tr><td>Activity Start Date: </td><td>' + scheduledStartDate + '<td/></tr>';

		messageBody_Html  += '<tr><td>' + urlWorkOrder + '</td><td>' + urlActivity + '<td/></tr>';
		messageBody_Html  += '</table>';	
		messageBody_Html  += '<hr/>';

		return messageBody_Html;
	}

	/*
	this method will take a plannerGrouList and Work Order Activity as a input parameters and update pNotificationMap 
	- will add activity to the list associated with the email address in pNotificationMap in case if activity could be match with the contact in 
	pPlannerGroupList by planner group and Work Order Type
	*/
	private Boolean FindNotificationContact(List<HOG_Planner_Group__c> pPlannerGroupList, Work_Order_Activity__c pActivityRecord, Map<String, List<Work_Order_Activity__c>> pNotificationMap)
	{
		Boolean fieldSchedulerFound = false;

		for(HOG_Planner_Group__c plannerGroup: pPlannerGroupList){

			if(pActivityRecord.Maintenance_Work_Order__r.Planner_Group__c == plannerGroup.Name)
			{
				for(HOG_Planner_Group_Notification_Type__c notificationTypeRecord : plannerGroup.HOG_Planner_Group_Notification_Types__r)	
				{
					if(
						//notificationTypeRecord.Order_Type__c.Contains(pActivityRecord.Maintenance_Work_Order__r.Order_Type__c)
						(
                            VTT_Utilities.FieldValueMatchTheRule(pActivityRecord.Maintenance_Work_Order__r.Order_Type__c, notificationTypeRecord.Order_Type_Text__c)
                            || notificationTypeRecord.Order_Type_Text__c ==null
                        )
						&&
						(
							VTT_Utilities.FieldValueMatchTheRule(pActivityRecord.Work_Center__c, notificationTypeRecord.Work_Center__c)
							|| notificationTypeRecord.Work_Center__c == null
						)
					)
					{

						String fieldSchedulerEmail = notificationTypeRecord.Contact__r.User__c == null?  notificationTypeRecord.Contact__r.email : notificationTypeRecord.Contact__r.User__r.email ;

						if(fieldSchedulerEmail <> null)		
						{
							if(pNotificationMap.containsKey(fieldSchedulerEmail))
							{
								List<Work_Order_Activity__c> activityList = (List<Work_Order_Activity__c>)pNotificationMap.get(fieldSchedulerEmail);
								activityList.add(pActivityRecord);
							}
							else
							{
								List<Work_Order_Activity__c> activityList = new List<Work_Order_Activity__c>();
								activityList.add(pActivityRecord);
								pNotificationMap.put(fieldSchedulerEmail, activityList);
							}

							fieldSchedulerFound = true;
							//SM 2/17/2016 - we keep going till we find all matching contacts
							//break;	
						}
					}
				}
			}
			//SM 2/17/2016 - we keep going till we find all matching contacts
			//if(fieldSchedulerFound)
			//{
			//	break;
			//}
		}

		//if we didn't find field scheduler, notify generic email
		if(fieldSchedulerFound == false && fieldSchedulerGenericEmail <> null)
		{
			if(pNotificationMap.containsKey(fieldSchedulerGenericEmail))
			{
				List<Work_Order_Activity__c> activityList = (List<Work_Order_Activity__c>)pNotificationMap.get(fieldSchedulerGenericEmail);
				activityList.add(pActivityRecord);
			}
			else
			{
				List<Work_Order_Activity__c> activityList = new List<Work_Order_Activity__c>();
				activityList.add(pActivityRecord);
				pNotificationMap.put(fieldSchedulerGenericEmail, activityList);
			}
		}

		return fieldSchedulerFound;

	}

	private List<Messaging.SingleEmailMessage> GetSanitizedEmailList(Messaging.SingleEmailMessage[] emailList) {
		List<Messaging.SingleEmailMessage> validEmailList = new List<Messaging.SingleEmailMessage>();
		for(Messaging.SingleEmailMessage email : emailList) {
			if(IsValidEmail(email)) {
				validEmailList.add(email);
			}
		}
		return validEmailList;
	}

	private Boolean IsValidEmail(Messaging.SingleEmailMessage email) {
		return (email.getToAddresses() != null && email.getToAddresses().size() > 0) || 
			(email.targetObjectId != null);
	}
	
	private Datetime GetDailyLogStartTime(Work_Order_Activity__c activity, Contact tradesman) {
		for(Work_Order_Activity_Log__c dailyLogRecord : activity.Work_Order_Activity_Logs__r) {
			if(dailyLogRecord.Date__c == Date.today() &&
				dailyLogRecord.Tradesman__c == tradesman.Id) {
				return dailyLogRecord.Started_New__c;
			}
		}

		return null;
	}
}