#!/usr/bin/env bash
set -e
cd "$1/force-app/main/default/flows"
filt() { printf '        <filters>\n            <field>%s</field>\n            <operator>%s</operator>\n            <value>\n                <%s>%s</%s>\n            </value>\n        </filters>\n' "$1" "$2" "$3" "$4" "$3"; }
lookup() { # name object y next logic filters
  printf '    <recordLookups>\n        <name>%s</name>\n        <label>%s</label>\n        <locationX>176</locationX>\n        <locationY>%s</locationY>\n        <assignNullValuesIfNoRecordsFound>true</assignNullValuesIfNoRecordsFound>\n        <connector>\n            <targetReference>%s</targetReference>\n        </connector>\n        <filterLogic>%s</filterLogic>\n%s        <getFirstRecordOnly>true</getFirstRecordOnly>\n        <object>%s</object>\n        <queriedFields>Id</queriedFields>\n        <storeOutputAutomatically>true</storeOutputAutomatically>\n    </recordLookups>\n' "$1" "${1//_/ }" "$3" "$4" "$5" "$6" "$2"
}
assign() { # status x
  local n="Set_${1// /_}"
  printf '    <assignments>\n        <name>%s</name>\n        <label>Set %s</label>\n        <locationX>%s</locationX>\n        <locationY>800</locationY>\n        <assignmentItems>\n            <assignToReference>var_Status</assignToReference>\n            <operator>Assign</operator>\n            <value>\n                <stringValue>%s</stringValue>\n            </value>\n        </assignmentItems>\n        <connector>\n            <targetReference>Update_Plan_Status</targetReference>\n        </connector>\n    </assignments>\n' "$n" "$1" "$2" "$1"
}
dec() { # name y lookup yes no
  printf '    <decisions>\n        <name>%s</name>\n        <label>%s</label>\n        <locationX>176</locationX>\n        <locationY>%s</locationY>\n        <defaultConnector>\n            <targetReference>%s</targetReference>\n        </defaultConnector>\n        <defaultConnectorLabel>No</defaultConnectorLabel>\n        <rules>\n            <name>%s_Yes</name>\n            <conditionLogic>and</conditionLogic>\n            <conditions>\n                <leftValueReference>%s.Id</leftValueReference>\n                <operator>IsNull</operator>\n                <rightValue>\n                    <booleanValue>false</booleanValue>\n                </rightValue>\n            </conditions>\n            <connector>\n                <targetReference>%s</targetReference>\n            </connector>\n            <label>Yes</label>\n        </rules>\n    </decisions>\n' "$1" "${1//_/ }" "$2" "$5" "$1" "$3" "$4"
}
PLAN=$(filt Instalment_Plan__c EqualTo elementReference planId)
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<Flow xmlns="http://soap.sforce.com/2006/04/metadata">'
  echo '    <apiVersion>60.0</apiVersion>'
  assign "With Legal" 50; assign Defaulted 200; assign Late 350; assign Completed 500; assign Active 650
  dec Has_Open_Legal 300 Get_Open_Legal Set_With_Legal Has_Default
  dec Has_Default 400 Get_Default_Instalment Set_Defaulted Has_Late
  dec Has_Late 500 Get_Late_Instalment Set_Late Has_Unpaid
  dec Has_Unpaid 600 Get_Unpaid_Instalment Set_Active Set_Completed
  echo "    <description>Works out an instalment plan's Plan Status for Finance: With Legal (open or in-progress escalation), else Defaulted, else Late, else Completed (nothing unpaid), else Active. Called by Instalment_Plan_Status_From_Instalment and Instalment_Plan_Status_From_Legal.</description>"
  echo '    <environments>Default</environments>'
  echo '    <interviewLabel>Instalment Plan Recalculate Status {!$Flow.CurrentDateTime}</interviewLabel>'
  echo '    <label>AM Instalment Plan - Recalculate Status</label>'
  echo '    <processType>AutoLaunchedFlow</processType>'
  lookup Get_Default_Instalment Instalment__c 150 Get_Late_Instalment and "$PLAN$(filt Status__c EqualTo stringValue Default)"
  lookup Get_Late_Instalment Instalment__c 200 Get_Unpaid_Instalment and "$PLAN$(filt Status__c EqualTo stringValue Late)"
  lookup Get_Open_Legal Legal_Escalation__c 50 Get_Default_Instalment "1 AND (2 OR 3)" "$PLAN$(filt Status__c EqualTo stringValue Open)$(filt Status__c EqualTo stringValue 'In Progress')"
  lookup Get_Unpaid_Instalment Instalment__c 250 Has_Open_Legal and "$PLAN$(filt Status__c NotEqualTo stringValue Paid)"
  printf '    <recordUpdates>\n        <name>Update_Plan_Status</name>\n        <label>Update Plan Status</label>\n        <locationX>176</locationX>\n        <locationY>900</locationY>\n        <filterLogic>and</filterLogic>\n        <filters>\n            <field>Id</field>\n            <operator>EqualTo</operator>\n            <value>\n                <elementReference>planId</elementReference>\n            </value>\n        </filters>\n        <inputAssignments>\n            <field>Plan_Status__c</field>\n            <value>\n                <elementReference>var_Status</elementReference>\n            </value>\n        </inputAssignments>\n        <object>Instalment_Plan__c</object>\n    </recordUpdates>\n'
  printf '    <start>\n        <locationX>50</locationX>\n        <locationY>0</locationY>\n        <connector>\n            <targetReference>Get_Open_Legal</targetReference>\n        </connector>\n    </start>\n    <status>Active</status>\n'
  printf '    <variables>\n        <name>planId</name>\n        <dataType>String</dataType>\n        <isCollection>false</isCollection>\n        <isInput>true</isInput>\n        <isOutput>false</isOutput>\n    </variables>\n    <variables>\n        <name>var_Status</name>\n        <dataType>String</dataType>\n        <isCollection>false</isCollection>\n        <isInput>false</isInput>\n        <isOutput>false</isOutput>\n    </variables>\n'
  echo '</Flow>'
} > Instalment_Plan_Recalculate_Status.flow-meta.xml

trig() { # name label object description
  cat > "$1.flow-meta.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <description>$4</description>
    <environments>Default</environments>
    <interviewLabel>$1 {!\$Flow.CurrentDateTime}</interviewLabel>
    <label>$2</label>
    <processType>AutoLaunchedFlow</processType>
    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Recalculate_Plan_Status</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Instalment_Plan__c</field>
            <operator>IsNull</operator>
            <value>
                <booleanValue>false</booleanValue>
            </value>
        </filters>
        <object>$3</object>
        <recordTriggerType>CreateAndUpdate</recordTriggerType>
        <triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
    <subflows>
        <name>Recalculate_Plan_Status</name>
        <label>Recalculate Plan Status</label>
        <locationX>176</locationX>
        <locationY>215</locationY>
        <flowName>Instalment_Plan_Recalculate_Status</flowName>
        <inputAssignments>
            <name>planId</name>
            <value>
                <elementReference>\$Record.Instalment_Plan__c</elementReference>
            </value>
        </inputAssignments>
    </subflows>
</Flow>
EOF
}
trig Instalment_Plan_Status_From_Instalment "AM Instalment - Update Plan Status" Instalment__c "Recalculates the parent plan's Plan Status whenever an instalment is created or changes (paid, late, default)."
trig Instalment_Plan_Status_From_Legal "AM Legal Escalation - Update Plan Status" Legal_Escalation__c "Recalculates the linked plan's Plan Status when a legal escalation is raised or its status changes (With Legal while Open or In Progress)."
echo ok
