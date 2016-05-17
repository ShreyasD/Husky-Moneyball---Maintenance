List<HOG_EOJ__c> eojs = [Select Id, Name, Field_Operator1_Email__c,Field_Operator2_Email__c,
                        	Field_Operator3_Email__c, Field_Operator4_Email__c, 
                         	Service_Rig_Program__r.Route_Operator_1__r.Email, 
                         	Service_Rig_Program__r.Route_Operator_2__r.Email,
                            Service_Rig_Program__r.Route_Operator_3__r.Email,
                         	Service_Rig_Program__r.Route_Operator_4__r.Email
                         From HOG_EOJ__c];
for(HOG_EOJ__c eoj : eojs) {
    eoj.Field_Operator1_Email__c = eoj.Service_Rig_Program__r.Route_Operator_1__r.Email;
    eoj.Field_Operator2_Email__c = eoj.Service_Rig_Program__r.Route_Operator_2__r.Email;
    eoj.Field_Operator3_Email__c = eoj.Service_Rig_Program__r.Route_Operator_3__r.Email;
    eoj.Field_Operator4_Email__c = eoj.Service_Rig_Program__r.Route_Operator_4__r.Email;
}
update eojs;