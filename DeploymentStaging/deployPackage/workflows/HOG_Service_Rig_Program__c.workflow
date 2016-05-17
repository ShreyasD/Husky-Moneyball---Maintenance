<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>HOG_Service_Program_Step_Approved</fullName>
        <description>HOG - Service Program Step Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Production_Engineer__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Service_Rig_Planner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>HOG_Email_Templates/HOG_Service_Rig_Program_Step_Approved</template>
    </alerts>
    <alerts>
        <fullName>HOG_Service_Program_Step_Rejected</fullName>
        <description>HOG - Service Program Step Rejected</description>
        <protected>false</protected>
        <recipients>
            <field>Production_Engineer__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Service_Rig_Planner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>HOG_Email_Templates/HOG_Service_Rig_Program_Step_Rejected</template>
    </alerts>
    <alerts>
        <fullName>HOG_Service_Rig_Program_Approved</fullName>
        <description>HOG - Service Rig Program Approved</description>
        <protected>false</protected>
        <recipients>
            <recipient>HOG_Service_Rig_Planner_Delegate</recipient>
            <type>group</type>
        </recipients>
        <recipients>
            <field>Production_Engineer__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Service_Rig_Planner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>HOG_Email_Templates/HOG_Service_Rig_Program_Overall_Approved</template>
    </alerts>
    <alerts>
        <fullName>HOG_Service_Rig_Program_Created_Notification</fullName>
        <ccEmails>LloydSWM@huskyenergy.com</ccEmails>
        <description>HOG - Service Rig Program Created Notification</description>
        <protected>false</protected>
        <recipients>
            <field>Field_Senior__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Production_Engineer__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Route_Operator_1__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Route_Operator_2__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Route_Operator_3__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Route_Operator_4__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>HOG_Email_Templates/HOG_Service_Rig_Program_Created_Notification</template>
    </alerts>
    <alerts>
        <fullName>HOG_Service_Rig_Program_Released_Notification</fullName>
        <description>HOG - Service Rig Program Released Notification</description>
        <protected>false</protected>
        <recipients>
            <field>Field_Senior__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Production_Engineer__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Service_Rig_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Service_Rig_Planner__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>HOG_Email_Templates/HOG_Service_Rig_Program_Released_Notification</template>
    </alerts>
    <fieldUpdates>
        <fullName>HOG_Rig_Program_Approved</fullName>
        <field>Status__c</field>
        <literalValue>Approved</literalValue>
        <name>HOG - Rig Program Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>HOG_Rig_Program_Awaiting_Approval</fullName>
        <field>Status__c</field>
        <literalValue>Awaiting Approval</literalValue>
        <name>HOG - Rig Program Awaiting Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>HOG_Rig_Program_Cancelled</fullName>
        <field>Status__c</field>
        <literalValue>Cancelled</literalValue>
        <name>HOG - Rig Program Cancelled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>HOG_Set_RigProgram_RecordType_Approved</fullName>
        <description>Set the record type of the Rig Program to approved.</description>
        <field>RecordTypeId</field>
        <lookupValue>Approved_Service_Rig_Program</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>HOG - Set RigProgram RecordType Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>HOG_Set_RigProgram_RecordType_PreAppr</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Pre_Approval_Service_Rig_Program</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>HOG - Set RigProgram RecordType PreAppr</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>HOG_Set_Rig_Program_RecordType_Release</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Released_Service_Rig_Program</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>HOG - Set Rig Program RecordType Release</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>HOG - Service Rig Program Approval Criteria Satisfied</fullName>
        <actions>
            <name>HOG_Set_RigProgram_RecordType_PreAppr</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>HOG_Service_Rig_Program__c.Status__c</field>
            <operation>equals</operation>
            <value>Started</value>
        </criteriaItems>
        <criteriaItems>
            <field>HOG_Service_Rig_Program__c.Production_Coordinator__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>HOG_Service_Rig_Program__c.Service_Rig_Coordinator__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>HOG - Service Rig Program Cancelled</fullName>
        <actions>
            <name>HOG_Set_Rig_Program_RecordType_Release</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>HOG_Service_Rig_Program__c.Status__c</field>
            <operation>equals</operation>
            <value>Cancelled</value>
        </criteriaItems>
        <description>When a Service Rig Program is put on Cancelled Status.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>HOG - Service Rig Program Created</fullName>
        <actions>
            <name>HOG_Service_Rig_Program_Created_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>HOG_Service_Rig_Program__c.HOG_Service_Request_Notification_Form_Id__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Email notification sent when a new Service Rig Request gets created</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>HOG - Service Rig Program Released</fullName>
        <actions>
            <name>HOG_Service_Rig_Program_Released_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>RecordType.DeveloperName == &apos;Released_Service_Rig_Program&apos;</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
