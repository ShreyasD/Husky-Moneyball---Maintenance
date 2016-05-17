@isTest
private class DEFT_UtilitiesTest {
	
	@isTest static void TestTriggerBeforeInsertEOJ() {
		User runningUser = DEFT_TestData.createDeftUser();
		User productionCoordinator = DEFT_TestData.createProductionCoordinator();
		User serviceRigCoordinator = DEFT_TestData.createServiceRigCoordinator();
		User serviceRigPlanner = DEFT_TestData.createServiceRigPlanner();

		System.runAs(runningUser) {
			Route__c route = RouteTestData.createRoute('Test Route');
			route.Operator_1_User__c = runningUser.Id;
			route.Operator_2_User__c = runningUser.Id;
			route.Operator_3_User__c = runningUser.Id;
			route.Operator_4_User__c = runningUser.Id;
			insert route;

			HOG_Service_Rig_Program__c serviceRigProgram = DEFT_TestData.createServiceRigProgram(runningUser, productionCoordinator, serviceRigCoordinator);
			serviceRigProgram.Service_Rig_Planner__c = serviceRigPlanner.Id;
			update serviceRigProgram;

			HOG_EOJ__c eoj = DEFT_TestData.createEOJReport(serviceRigProgram);

			//Test Email Fields
			eoj = [Select Id, Name, Production_Engineer_Email__c, Field_Operator1_Email__c, Field_Operator2_Email__c,
					Field_Operator3_Email__c, Field_Operator4_Email__c, Field_Senior_Email__c, Production_Coordinator_Email__c,
					Operations_Coordinator_Email__c, Service_Rig_Coordinator_Email__c, Service_Rig_Planner_Email__c
				   From HOG_EOJ__c
				   Where Id =: eoj.Id];
			System.assert(eoj.Production_Engineer_Email__c.equalsIgnoreCase(runningUser.Email));
			System.assert(eoj.Field_Operator1_Email__c.equalsIgnoreCase(runningUser.Email));
			System.assert(eoj.Field_Operator2_Email__c.equalsIgnoreCase(runningUser.Email));
			System.assert(eoj.Field_Operator3_Email__c.equalsIgnoreCase(runningUser.Email));
			System.assert(eoj.Field_Operator4_Email__c.equalsIgnoreCase(runningUser.Email));
			System.assert(eoj.Field_Senior_Email__c.equalsIgnoreCase(runningUser.Email));
			System.assert(eoj.Production_Coordinator_Email__c.equalsIgnoreCase(productionCoordinator.Email));
			System.assert(eoj.Operations_Coordinator_Email__c.equalsIgnoreCase(runningUser.Email));
			System.assert(eoj.Service_Rig_Coordinator_Email__c.equalsIgnoreCase(serviceRigCoordinator.Email));
			System.assert(eoj.Service_Rig_Planner_Email__c.equalsIgnoreCase(serviceRigPlanner.Email));
		}
	}
}