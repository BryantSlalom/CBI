<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Mark_for_Deletion</fullName>
        <field>Deletion__c</field>
        <literalValue>1</literalValue>
        <name>Mark for Deletion</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_status_when_end_date_is_past</fullName>
        <field>Status__c</field>
        <literalValue>Inactive</literalValue>
        <name>Update status when end date is past</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Mark CBI US Item Auth and Feat for Deletion</fullName>
        <actions>
            <name>Mark_for_Deletion</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>This rule will fire is to update a field.</description>
        <formula>SET_PERIOD_END_DT_ID__c  &lt;&gt; NULL</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <offsetFromField>CBI_US_Item_Authorization_Feature__c.SET_PERIOD_END_DT_ID__c</offsetFromField>
            <timeLength>365</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Update status when end date is past</fullName>
        <active>false</active>
        <formula>AND(ISPICKVAL(Status__c, &quot;Active&quot;), SET_PERIOD_END_DT_ID__c &lt;=  TODAY())</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_status_when_end_date_is_past</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>CBI_US_Item_Authorization_Feature__c.CreatedDate</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
