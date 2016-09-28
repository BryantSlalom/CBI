<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Populate_Unique_ID</fullName>
        <field>Unique_ID__c</field>
        <formula>CBI_US_Item_Authorization_Feature__r.Id  +   Account__r.Id</formula>
        <name>Populate Unique ID</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Populate Unique ID</fullName>
        <actions>
            <name>Populate_Unique_ID</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account_Auth_Feature__c.Unique_ID__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
