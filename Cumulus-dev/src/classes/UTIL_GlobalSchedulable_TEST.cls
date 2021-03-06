/*
    Copyright (c) 2014 Salesforce.com Foundation
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
@isTest
public with sharing class UTIL_GlobalSchedulable_TEST {

    /**
     * NOTE: the UTIL_GlobalSchedulable class is deprecated. We cannot remove it from the package
     * because there are clients that already have it installed and scheduled. This test is here
     * just for test coverage purposes.
     **/
    public static testmethod void scheduleJob() {
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_BATCH', Active__c = true));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppAccRollup_BATCH', Active__c = true));
        insert jobs;
    
        Test.startTest();
        //Schedule a job
        String jobName = 'Global Scheduler'; 
        String fireTime = '0 15 23 * * ?';
        System.schedule(jobName, fireTime, new UTIL_GlobalSchedulable());
        
        List<CronTrigger> triggers = [select Id, CronExpression, TimesTriggered from CronTrigger 
                            where CronJobDetail.Name = :jobName and CronJobDetail.JobType = '7'];
        
        //Verify it was added to the queue                    
        System.assertEquals(1, triggers.size());
        
        //Verify the expressions are the same
        System.assertEquals(fireTime, triggers[0].CronExpression);
        
        Test.stopTest();        
    }
}