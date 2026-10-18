#!/usr/bin/env bash
# Generates AutoDrive report types, reports, dashboards, folders and role home pages.
set -e
B="$1/force-app/main/default"
mkdir -p "$B/reportTypes" "$B/reports/AutoDrive_Reports" "$B/dashboards" "$B/flexipages"
H='<?xml version="1.0" encoding="UTF-8"?>'

# ---------- custom report types ----------
rt() { # name object label fields...
  local n=$1 o=$2 l=$3; shift 3
  {
    echo "$H"; echo '<ReportType xmlns="http://soap.sforce.com/2006/04/metadata">'
    echo "    <baseObject>$o</baseObject>"; echo '    <category>other</category>'; echo '    <deployed>true</deployed>'
    echo "    <description>AutoDrive: $l, for role dashboards.</description>"
    echo "    <label>AD $l</label>"; echo '    <sections>'
    for f in Name CreatedDate "$@"; do printf '        <columns>\n            <checkedByDefault>true</checkedByDefault>\n            <field>%s</field>\n            <table>%s</table>\n        </columns>\n' "$f" "$o"; done
    echo "        <masterLabel>$l</masterLabel>"; echo '    </sections>'; echo '</ReportType>'
  } > "$B/reportTypes/$n.reportType-meta.xml"
}
rt AD_Vehicles Vehicle__c Vehicles Model__c Status__c Colour__c Year__c Showroom__c
rt AD_Vehicle_Models Vehicle_Model__c "Vehicle Models" Available_Stock__c Low_stock_Threshold__c Total_Stock_Count__c List_Price__c
rt AD_Discount_Requests Discount_Request__c "Discount Requests" Opportunity__c Requested_Discount__c Current_Step__c SLA_Business_Days__c
rt AD_Instalments Instalment__c Instalments Instalment_Plan__c Due_Date__c Amount_Due__c Amount_Paid__c Status__c
rt AD_Instalment_Plans Instalment_Plan__c "Instalment Plans" Opportunity__c Plan_Status__c Term_in_Months__c Head_of_Finance_Sign_off__c Ownership_Documents_Status__c
rt AD_Payments Payment__c Payments Opportunity__c Type__c Amount__c Method__c Paid_On__c
rt AD_Reconciliation_Entries Reconciliation_Entry__c "Reconciliation Entries" Date__c Bank_Account__c Bank_Total__c Recorded_Total__c Status__c
rt AD_Legal_Escalations Legal_Escalation__c "Legal Escalations" Account__c Contract_Number__c Status__c Total_Amount_Owed__c Escalated_On__c
rt AD_Import_Requests Import_Request__c "Import Requests" Account__c Vehicle_Model__c Status__c Expected_Arrival__c

# ---------- report folder ----------
cat > "$B/reports/AutoDrive_Reports.reportFolder-meta.xml" <<EOF
$H
<ReportFolder xmlns="http://soap.sforce.com/2006/04/metadata">
    <folderShares>
        <accessLevel>View</accessLevel>
        <sharedTo>AllInternalUsers</sharedTo>
        <sharedToType>Organization</sharedToType>
    </folderShares>
    <name>AutoDrive Reports</name>
</ReportFolder>
EOF

# ---------- reports ----------
# rep NAME LABEL TYPE GROUPFIELD DATECOL INTERVAL "col[:Sum|:Average] ..." "extra xml"
rep() {
  local n=$1 l=$2 t=$3 g=$4 dc=$5 iv=$6 cols=$7 extra=$8
  {
    echo "$H"; echo '<Report xmlns="http://soap.sforce.com/2006/04/metadata">'
    for c in $cols; do
      local f=${c%%:*} a=""; [[ $c == *:* ]] && a=${c##*:}
      echo '    <columns>'; [ -n "$a" ] && echo "        <aggregateTypes>$a</aggregateTypes>"; echo "        <field>$f</field>"; echo '    </columns>'
    done
    [ -n "$extra" ] && printf '%s\n' "$extra"
    echo '    <format>Summary</format>'
    printf '    <groupingsDown>\n        <dateGranularity>Day</dateGranularity>\n        <field>%s</field>\n        <sortOrder>Asc</sortOrder>\n    </groupingsDown>\n' "$g"
    echo "    <name>$l</name>"
    [ -n "$PARAMS" ] && printf '%s\n' "$PARAMS"
    echo "    <reportType>$t</reportType>"; echo "    <scope>${SCOPE:-organization}</scope>"
    echo '    <showDetails>true</showDetails>'; echo '    <showGrandTotal>true</showGrandTotal>'; echo '    <showSubTotals>true</showSubTotals>'
    printf '    <timeFrameFilter>\n        <dateColumn>%s</dateColumn>\n        <interval>%s</interval>\n    </timeFrameFilter>\n' "$dc" "$iv"
    echo '</Report>'
  } > "$B/reports/AutoDrive_Reports/$n.report-meta.xml"
}
P_OPEN='    <params>
        <name>open</name>
        <value>open</value>
    </params>'
P_WON='    <params>
        <name>open</name>
        <value>closedwon</value>
    </params>'
OPEN_CASES='    <filter>
        <criteriaItems>
            <column>STATUS</column>
            <columnToColumn>false</columnToColumn>
            <isUnlocked>false</isUnlocked>
            <operator>notEqual</operator>
            <value>Closed</value>
        </criteriaItems>
    </filter>'
RATED='    <filter>
        <criteriaItems>
            <column>Case.CSAT_Score__c</column>
            <columnToColumn>false</columnToColumn>
            <isUnlocked>false</isUnlocked>
            <operator>greaterThan</operator>
            <value>0</value>
        </criteriaItems>
    </filter>'

PARAMS=$P_OPEN rep AD_Open_Sales_by_Stage "AD Open Sales by Stage" Opportunity STAGE_NAME CLOSE_DATE INTERVAL_CUSTOM "OPPORTUNITY_NAME ACCOUNT_NAME AMOUNT:Sum CLOSE_DATE FULL_NAME" ""
PARAMS=$P_WON rep AD_Sales_Won_This_Month "AD Sales Won This Month" Opportunity FULL_NAME CLOSE_DATE INTERVAL_THISMONTH "OPPORTUNITY_NAME ACCOUNT_NAME AMOUNT:Sum CLOSE_DATE" ""
PARAMS="" SCOPE=org rep AD_Leads_by_Channel "AD Leads by Channel" LeadList Lead.Channel__c CREATED_DATE INTERVAL_CUSTOM "FIRST_NAME LAST_NAME COMPANY STATUS OWNER" ""
PARAMS="" SCOPE=org rep AD_Leads_by_Status "AD Leads by Status" LeadList STATUS CREATED_DATE INTERVAL_CUSTOM "FIRST_NAME LAST_NAME COMPANY Lead.Channel__c OWNER" ""
PARAMS="" rep AD_Vehicles_by_Status "AD Vehicles by Status" AD_Vehicles 'Vehicle__c$Status__c' 'Vehicle__c$CreatedDate' INTERVAL_CUSTOM 'Vehicle__c$Name Vehicle__c$Model__c Vehicle__c$Colour__c Vehicle__c$Year__c' ""
PARAMS="" rep AD_Stock_by_Model "AD Stock by Model" AD_Vehicle_Models 'Vehicle_Model__c$Name' 'Vehicle_Model__c$CreatedDate' INTERVAL_CUSTOM 'Vehicle_Model__c$Available_Stock__c:Sum Vehicle_Model__c$Low_stock_Threshold__c:Sum Vehicle_Model__c$Total_Stock_Count__c:Sum' ""
PARAMS="" rep AD_Discount_Requests_by_Step "AD Discount Requests by Step" AD_Discount_Requests 'Discount_Request__c$Current_Step__c' 'Discount_Request__c$CreatedDate' INTERVAL_CUSTOM 'Discount_Request__c$Name Discount_Request__c$Opportunity__c Discount_Request__c$Requested_Discount__c Discount_Request__c$SLA_Business_Days__c' ""
PARAMS="" rep AD_Instalments_by_Status "AD Instalments by Status" AD_Instalments 'Instalment__c$Status__c' 'Instalment__c$Due_Date__c' INTERVAL_CUSTOM 'Instalment__c$Name Instalment__c$Instalment_Plan__c Instalment__c$Due_Date__c Instalment__c$Amount_Due__c:Sum Instalment__c$Amount_Paid__c:Sum' ""
PARAMS="" rep AD_Instalment_Plans_by_Status "AD Instalment Plans by Status" AD_Instalment_Plans 'Instalment_Plan__c$Plan_Status__c' 'Instalment_Plan__c$CreatedDate' INTERVAL_CUSTOM 'Instalment_Plan__c$Name Instalment_Plan__c$Opportunity__c Instalment_Plan__c$Term_in_Months__c' ""
PARAMS="" rep AD_Payments_Last_30_Days "AD Payments Last 30 Days" AD_Payments 'Payment__c$Type__c' 'Payment__c$Paid_On__c' INTERVAL_LAST30 'Payment__c$Name Payment__c$Opportunity__c Payment__c$Method__c Payment__c$Paid_On__c Payment__c$Amount__c:Sum' ""
PARAMS="" rep AD_Reconciliation_by_Status "AD Reconciliation by Status" AD_Reconciliation_Entries 'Reconciliation_Entry__c$Status__c' 'Reconciliation_Entry__c$Date__c' INTERVAL_CUSTOM 'Reconciliation_Entry__c$Name Reconciliation_Entry__c$Date__c Reconciliation_Entry__c$Bank_Total__c:Sum Reconciliation_Entry__c$Recorded_Total__c:Sum' ""
PARAMS="" rep AD_Legal_Escalations_by_Status "AD Legal Escalations by Status" AD_Legal_Escalations 'Legal_Escalation__c$Status__c' 'Legal_Escalation__c$Escalated_On__c' INTERVAL_CUSTOM 'Legal_Escalation__c$Name Legal_Escalation__c$Account__c Legal_Escalation__c$Contract_Number__c Legal_Escalation__c$Total_Amount_Owed__c:Sum' ""
PARAMS="" rep AD_Import_Requests_by_Status "AD Import Requests by Status" AD_Import_Requests 'Import_Request__c$Status__c' 'Import_Request__c$CreatedDate' INTERVAL_CUSTOM 'Import_Request__c$Name Import_Request__c$Account__c Import_Request__c$Vehicle_Model__c Import_Request__c$Expected_Arrival__c' ""
PARAMS="" rep AD_Open_Cases_by_Type "AD Open Cases by Team" CaseList Case.Routed_To__c CREATED_DATEONLY INTERVAL_CUSTOM "SUBJECT TYPE STATUS PRIORITY OWNER" "$OPEN_CASES"
PARAMS="" rep AD_Cases_by_Status "AD Cases by Status" CaseList STATUS CREATED_DATEONLY INTERVAL_CUSTOM "SUBJECT TYPE PRIORITY OWNER" ""
PARAMS="" rep AD_Satisfaction_Scores "AD Satisfaction Scores" CaseList STATUS CREATED_DATEONLY INTERVAL_CUSTOM "SUBJECT TYPE Case.CSAT_Score__c:Average" "$RATED"

# ---------- dashboards ----------
# comp TYPE REPORT HEADER GROUPCOL SUMCOL AGG   (SUMCOL RowCount => no aggregate)
comp() {
  local ty=$1 r=$2 h=$3 g=$4 s=$5 a=$6
  echo '            <dashboardComponent>'
  echo '                <autoselectColumnsFromReport>false</autoselectColumnsFromReport>'
  [ "$ty" != Metric ] && echo '                <chartAxisRange>Auto</chartAxisRange>'
  echo '                <chartSummary>'
  [ "$s" != RowCount ] && echo "                    <aggregate>$a</aggregate>"
  echo '                    <axisBinding>y</axisBinding>'
  echo "                    <column>$s</column>"
  echo '                </chartSummary>'
  echo "                <componentType>$ty</componentType>"
  echo '                <displayUnits>Auto</displayUnits>'
  [ "$ty" != Metric ] && echo "                <groupingColumn>$g</groupingColumn>"
  echo '                <groupingSortProperties/>'
  echo "                <header>$h</header>"
  if [ "$ty" = Metric ]; then echo "                <indicatorHighColor>#54C254</indicatorHighColor>"; echo "                <indicatorLowColor>#C25454</indicatorLowColor>"; echo "                <indicatorMiddleColor>#C2C254</indicatorMiddleColor>"; fi
  [ "$ty" = Donut ] && echo '                <legendPosition>Right</legendPosition>'
  echo "                <report>AutoDrive_Reports/$r</report>"
  [ "$ty" = Donut ] && echo '                <showPercentage>true</showPercentage>'
  [ "$ty" = Donut ] && echo '                <showTotal>true</showTotal>'
  [ "$ty" = Bar ] && echo '                <showValues>true</showValues>'
  [ "$ty" = Bar ] && echo '                <sortBy>RowLabelAscending</sortBy>'
  [ "$ty" = Donut ] && echo '                <sortBy>RowValueDescending</sortBy>'
  echo '                <useReportChart>false</useReportChart>'
  echo '            </dashboardComponent>'
}
WON="Metric|AD_Sales_Won_This_Month|Deals Won This Month||RowCount|"
OPEN="Bar|AD_Open_Sales_by_Stage|Deals in Pipeline by Stage|STAGE_NAME|RowCount|"
LEADS="Donut|AD_Leads_by_Channel|Leads by Channel|Lead.Channel__c|RowCount|"
LSTAT="Bar|AD_Leads_by_Status|Leads by Status|STATUS|RowCount|"
STOCK="Bar|AD_Stock_by_Model|Available Stock by Model|Vehicle_Model__c\$Name|Vehicle_Model__c\$Available_Stock__c|Sum"
VSTAT="Donut|AD_Vehicles_by_Status|Vehicles by Status|Vehicle__c\$Status__c|RowCount|"
DISC="Donut|AD_Discount_Requests_by_Step|Discount Requests by Step|Discount_Request__c\$Current_Step__c|RowCount|"
IMP="Bar|AD_Import_Requests_by_Status|Import Requests by Status|Import_Request__c\$Status__c|RowCount|"
INST="Bar|AD_Instalments_by_Status|Instalments Due by Status|Instalment__c\$Status__c|Instalment__c\$Amount_Due__c|Sum"
PLANS="Donut|AD_Instalment_Plans_by_Status|Instalment Plans by Status|Instalment_Plan__c\$Plan_Status__c|RowCount|"
PAY="Metric|AD_Payments_Last_30_Days|Payments, Last 30 Days||Payment__c\$Amount__c|Sum"
REC="Donut|AD_Reconciliation_by_Status|Reconciliation by Status|Reconciliation_Entry__c\$Status__c|RowCount|"
LEGAL="Bar|AD_Legal_Escalations_by_Status|Legal Escalations: Amount Owed|Legal_Escalation__c\$Status__c|Legal_Escalation__c\$Total_Amount_Owed__c|Sum"
LEGALM="Metric|AD_Legal_Escalations_by_Status|Total Owed in Legal||Legal_Escalation__c\$Total_Amount_Owed__c|Sum"
OCASE="Donut|AD_Open_Cases_by_Type|Open Cases by Team|Case.Routed_To__c|RowCount|"
CSTAT="Bar|AD_Cases_by_Status|Cases by Status|STATUS|RowCount|"
CSAT="Metric|AD_Satisfaction_Scores|Average Satisfaction (1-10)||Case.CSAT_Score__c|Average"

dash() { # KEY TITLE ROLE RUNUSER comps...
  local k=$1 t=$2 role=$3 ru=$4; shift 4
  local fdir="AutoDrive_${k}_Dashboards"
  mkdir -p "$B/dashboards/$fdir"
  cat > "$B/dashboards/$fdir.dashboardFolder-meta.xml" <<EOF
$H
<DashboardFolder xmlns="http://soap.sforce.com/2006/04/metadata">
    <folderShares>
        <accessLevel>View</accessLevel>
        <sharedTo>$role</sharedTo>
        <sharedToType>Role</sharedToType>
    </folderShares>
    <name>AD $t Dashboards</name>
</DashboardFolder>
EOF
  {
    echo "$H"; echo '<Dashboard xmlns="http://soap.sforce.com/2006/04/metadata">'
    echo '    <backgroundEndColor>#FFFFFF</backgroundEndColor>'; echo '    <backgroundFadeDirection>Diagonal</backgroundFadeDirection>'; echo '    <backgroundStartColor>#FFFFFF</backgroundStartColor>'
    echo '    <dashboardGridLayout>'
    local i=0
    for c in "$@"; do
      IFS='|' read -r ty r h g s a <<< "$c"
      echo '        <dashboardGridComponents>'
      echo '            <colSpan>4</colSpan>'
      echo "            <columnIndex>$(( (i % 3) * 4 ))</columnIndex>"
      comp "$ty" "$r" "$h" "$g" "$s" "$a"
      echo "            <rowIndex>$(( (i / 3) * 6 ))</rowIndex>"
      echo '            <rowSpan>6</rowSpan>'
      echo '        </dashboardGridComponents>'
      i=$((i+1))
    done
    echo '        <numberOfColumns>12</numberOfColumns>'; echo '        <rowHeight>36</rowHeight>'
    echo '    </dashboardGridLayout>'
    echo '    <dashboardType>SpecifiedUser</dashboardType>'
    echo "    <description>AutoDrive $t dashboard. Runs as the $t test user, so it shows what that role can see. Per-user (dynamic) figures are a later item.</description>"
    echo '    <isGridLayout>true</isGridLayout>'
    echo "    <runningUser>$ru</runningUser>"
    echo '    <textColor>#000000</textColor>'
    echo "    <title>AutoDrive - $t</title>"
    echo '    <titleColor>#000000</titleColor>'; echo '    <titleSize>12</titleSize>'
    echo '</Dashboard>'
  } > "$B/dashboards/$fdir/AutoDrive_${k}_Dashboard.dashboard-meta.xml"

  # role home page with the dashboard on top
  cat > "$B/flexipages/AutoDrive_Home_${k}.flexipage-meta.xml" <<EOF
$H
<FlexiPage xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>AutoDrive home page for the $t role: role dashboard, approvals waiting on the user, tasks and recent records.</description>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>dashboardName</name>
                    <value>AutoDrive_${k}_Dashboard</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>hideOnError</name>
                    <value>true</value>
                </componentInstanceProperties>
                <componentName>desktopDashboards:embeddedDashboard</componentName>
                <identifier>desktopDashboards_embeddedDashboard</identifier>
            </componentInstance>
        </itemInstances>
        <name>top</name>
        <type>Region</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentName>runtime_approval_process:pendingApprovalCard</componentName>
                <identifier>runtime_approval_process_pendingApprovalCard</identifier>
            </componentInstance>
        </itemInstances>
        <itemInstances>
            <componentInstance>
                <componentName>runtime_sales_activities:todayTaskContainer</componentName>
                <identifier>runtime_sales_activities_todayTaskContainer</identifier>
            </componentInstance>
        </itemInstances>
        <name>bottomLeft</name>
        <type>Region</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentName>home:recentRecordContainer</componentName>
                <identifier>home_recentRecordContainer</identifier>
            </componentInstance>
        </itemInstances>
        <name>bottomRight</name>
        <type>Region</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentName>home:eventContainer</componentName>
                <identifier>home_eventContainer</identifier>
            </componentInstance>
        </itemInstances>
        <name>sidebar</name>
        <type>Region</type>
    </flexiPageRegions>
    <masterLabel>AutoDrive Home - $t</masterLabel>
    <template>
        <name>home:desktopTemplate</name>
    </template>
    <type>HomePage</type>
</FlexiPage>
EOF
}
U=autodrive.group3sb.test
dash Sales_Rep "Sales Rep" Sales_Rep "test.salesrep@$U" "$LSTAT" "$LEADS" "$OPEN" "$WON"
dash Showroom_Manager "Showroom Manager" Showroom_Manager "test.showroommanager@$U" "$OPEN" "$VSTAT" "$STOCK" "$DISC" "$IMP"
dash Finance_Team "Finance Team" Finance_Team_Member "test.financeteam@$U" "$PLANS" "$PAY" "$INST" "$REC" "$DISC"
dash Head_of_Finance "Head of Finance" Head_of_Finance "test.headoffinance@$U" "$PLANS" "$PAY" "$INST" "$LEGAL" "$DISC" "$REC"
dash Customer_Service_Agent "Customer Service Agent" Customer_Service_Agent "test.csagent@$U" "$CSAT" "$OCASE" "$CSTAT"
dash Head_of_Customer_Service "Head of Customer Service" Head_of_Customer_Service "test.headofcs@$U" "$CSAT" "$OCASE" "$CSTAT"
dash Legal_Team "Legal Team" Legal_Team "test.legalteam@$U" "$LEGALM" "$LEGAL"
dash Management "Management" Management "test.management@$U" "$WON" "$PAY" "$LEGALM" "$OPEN" "$STOCK" "$CSTAT"
echo generated
