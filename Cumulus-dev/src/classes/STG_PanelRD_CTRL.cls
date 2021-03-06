/* 
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2014
* @description The controller for the Recurring Donations panel 
*/
public with sharing class STG_PanelRD_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelRD'; }
 
    //holds value to evaluate change in forecast months
    private integer originalForecastMonths;
    public Schedulable__c rdSched { public get; public set; }
    public boolean isRDScheduleDisabled { get; set; }
    
    public STG_PanelRD_CTRL() { }
    
    public void init(){
        originalForecastMonths = (integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c;        
        list<Schedulable__c> listSch = [select Id, Active__c from Schedulable__c where Class_Name__c = 'RD_RecurringDonations_SCHED' limit 1];
        if (listSch.size() > 0) {
            rdSched = listSch[0];
            isRDScheduleDisabled = !rdSched.Active__c;
        }
    }
    
    public override PageReference saveSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
        	List<SObject> toUpdate = new List<SObject>();
        	if(STG_Panel.stgService.stgRD != null)
        		toUpdate.add(STG_Panel.stgService.stgRD);
        	if(rdSched != null) {
                rdSched.Active__c = !isRDScheduleDisabled;
                toUpdate.add(rdSched);
        	}
            update toUpdate;
            
            strRDOppRecordTypeLabel = null;

            //if we reduced the number of forecast months, we need to trim opps
            if (originalForecastMonths > STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c){
                trimOpportunities();                
            }
            //if we added months, kick off the batch job to update the RDs
            else if (originalForecastMonths < STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c){
                STG_PanelRDBatch_CTRL rdbatch = new STG_PanelRDBatch_CTRL();
                rdbatch.runBatch();
            }
            originalForecastMonths = (integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c;           
            isEditMode = false;
        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    	return null;
    }
    
    private void trimOpportunities(){
        date limitDate = system.today().addMonths((integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c);
        string openlabel = system.label.npe03.RecurringDonationOpenStatus;
        delete [select id from Opportunity 
               where CloseDate > :limitDate 
               and isClosed != true 
               and npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c = :openLabel];
               
        map<Id, npe03__Recurring_Donation__c> mapIdRD = new map<Id, npe03__Recurring_Donation__c>([select Id from npe03__Recurring_Donation__c where npe03__Open_Ended_Status__c = :openLabel]);
        RD_RecurringDonations.updateRecurringDonationOnOppChangeFuture(mapIdRD.keySet());               
    }
        
    public list<SelectOption> listSORDCloseOptions {
        get {
        	if (listSORDCloseOptions == null) {
	            listSORDCloseOptions = new list<SelectOption>();
	            list<RD_RecurringDonations.RecurringDonationCloseOptions> CloseOptionValues = RD_RecurringDonations.RecurringDonationCloseOptions.values();       
	            for (RD_RecurringDonations.RecurringDonationCloseOptions rdco : CloseOptionValues) {
	                listSORDCloseOptions.add(new SelectOption(rdco.name(), rdco.name()));
	            }
        	}
            return listSORDCloseOptions;
        }
        private set;
    }    

    static public string strRDOppRecordTypeLabel {
        get {
            if (strRDOppRecordTypeLabel == null) {
                strRDOppRecordTypeLabel = UTIL_RecordTypes.GetRecordTypeName('Opportunity', STG_Panel.stgService.stgRD.npe03__Record_Type__c);
            }
            return strRDOppRecordTypeLabel;
        }
        private set;
    }
    
}