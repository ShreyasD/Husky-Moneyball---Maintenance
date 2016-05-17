<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>End_Of_Job_Report_Submitted_Notification</fullName>
        <ccEmails>LloydSWM@huskyenergy.com, bill.down@huskyenergy.com</ccEmails>
        <description>End Of Job Report Submitted Notification</description>
        <protected>false</protected>
        <recipients>
            <field>Field_Operator1_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Field_Operator2_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Field_Operator3_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Field_Operator4_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Field_Senior_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Operations_Coordinator_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Production_Coordinator_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Production_Engineer_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Service_Rig_Coordinator_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Service_Rig_Planner_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <recipient>Well_Servicing_Manager</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>HOG_Email_Templates/HOG_End_Of_Job_Report_Submitted</template>
    </alerts>
    <fieldUpdates>
        <fullName>HOG_EOJ_RecordType_Submitted</fullName>
        <field>RecordTypeId</field>
        <lookupValue>End_Of_Job_Submitted</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>HOG - EOJ RecordType Submitted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Production_Coordinator_Email_Update</fullName>
        <field>Production_Coordinator_Email__c</field>
        <formula>Service_Rig_Program__r.Production_Coordinator__r.Email</formula>
        <name>Production Coordinator Email Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>HOG - End of Job Submitted</fullName>
        <actions>
            <name>End_Of_Job_Report_Submitted_Notification</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>HOG_EOJ_RecordType_Submitted</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>HOG_EOJ__c.Status__c</field>
            <operation>equals</operation>
            <value>Submitted</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>