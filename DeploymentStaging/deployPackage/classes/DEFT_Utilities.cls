/*-------------------------------------------------------------------------------------------------
Author     : Shreyas Dhond
Company    : Husky Energy
Description: A Global Utility class for Downhole Equipment Failure Tracking
Inputs     : N/A
Test Class : DEFT_UtilitiesTest
History    : 05.05.16 ssd: Initial revision - End of Job Insert Trigger Handler (Populate Email Fields)         
---------------------------------------------------------------------------------------------------*/ 
global without sharing class DEFT_Utilities {
	
	//End of Job Status'
	public final static String EOJ_STATUS_NEW = 'New';
	public final static String EOJ_STATUS_SUBMITTED = 'Submitted';

	//Flag for trigger execution
	public static Boolean executeTriggerCode = true;

	//Permission Set Names
	public final static String SNR_PERMISSIONSET_NAME = 'HOG_SNR_User';
	public final static String SRP_PERMISSIONSET_NAME = 'HOG_Service_Rig_Program_Read_Write';

	/**************************************** Trigger Handlers *************************************/
	public static void TriggerBeforeInsertEOJ(final List<HOG_EOJ__c> pEndOfJobList) {
		System.debug('TriggerBeforeInsertEOJ');
		if(executeTriggerCode) {
			PopulateEOJEmailFieldsFromRigProgram(pEndOfJobList);
		}
	}

	/**************************************** Utility Functions ************************************/
	//Copy email fields for workflows on creation from Service Rig Programs
	public static void PopulateEOJEmailFieldsFromRigProgram(final List<HOG_EOJ__c> pEndOfJobList) {
		Set<Id> serviceRigProgramIds = new Set<Id>();
		Map<Id, HOG_Service_Rig_Program__c> rigProgramMap = new Map<Id, HOG_Service_Rig_Program__c>();


		//Create map of Service Rig Programs
		for(HOG_EOJ__c endOfJob : pEndOfJobList) {
			serviceRigProgramIds.add(endOfJob.Service_Rig_Program__c);
		}
		rigProgramMap = new Map<Id, HOG_Service_Rig_Program__c>([Select Id, Production_Engineer__r.Email, 
																	Route_Operator_1__r.Email,
																	Route_Operator_2__r.Email, 
																	Route_Operator_3__r.Email,
																	Route_Operator_4__r.Email, 
																	Field_Senior__r.Email, 
																	Production_Coordinator__r.Email, 
																	Operations_Coordinator__r.Email,
																	Service_Rig_Coordinator__r.Email,
																	Service_Rig_Planner__r.Email
																   From HOG_Service_Rig_Program__c
																   Where Id In :serviceRigProgramIds]);



		for(HOG_EOJ__c endOfJob : pEndOfJobList) {
			HOG_Service_Rig_Program__c rigProgram = rigProgramMap.get(endOfJob.Service_Rig_Program__c);
			endOfJob.Production_Engineer_Email__c = rigProgram.Production_Engineer__r.Email;
			endOfJob.Field_Operator1_Email__c = rigProgram.Route_Operator_1__r.Email;
			endOfJob.Field_Operator2_Email__c = rigProgram.Route_Operator_1__r.Email;
			endOfJob.Field_Operator3_Email__c = rigProgram.Route_Operator_1__r.Email;
			endOfJob.Field_Operator4_Email__c = rigProgram.Route_Operator_1__r.Email;
			endOfJob.Field_Senior_Email__c = rigProgram.Field_Senior__r.Email;
			endOfJob.Production_Coordinator_Email__c = rigProgram.Production_Coordinator__r.Email;
			endOfJob.Operations_Coordinator_Email__c = rigProgram.Operations_Coordinator__r.Email;
			endOfJob.Service_Rig_Coordinator_Email__c = rigProgram.Service_Rig_Coordinator__r.Email;
			endOfJob.Service_Rig_Planner_Email__c = rigProgram.Service_Rig_Planner__r.Email;
			System.debug('PopulateEOJEmailFieldsFromRigProgram->eoj: ' + endOfJob);
		}
	}
}