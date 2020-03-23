public class MondoSample
{
    @future(callout=true)
    public static void doCalc(List<Id> opps)
    {
    	String yr = Date.today().addYears(1).year().format().replaceAll(',', '');
    	system.debug('year: ' + yr);
    	FiscalYearSettings fys = [select StartDate from FiscalYearSettings where name = :yr limit 1];
    	
    	Date Q1Start = fys.StartDate;
    	system.debug('fys start date: ' + fys.StartDate);
    	Date Q2Start = Q1Start.addMonths(3);
    	system.debug('q2start: ' + Q2Start);
    	Date Q3Start = Q2Start.addMonths(3);
    	system.debug('q3start: ' + Q3Start);
    	Date Q4Start = Q3Start.addMonths(3);
    	system.debug('q4start: ' + Q4Start);

    	Map<Id,Integer> cToWinMap = new Map<Id,Integer>();
    	Map<Id,String> curMap = new Map<Id,String>();
    	for(Opportunity o :[select id, Confidence_to_Win__c, CurrencyIsoCode from Opportunity where id in :opps])
    	{
    		if(o.Confidence_to_Win__c != null)
    		{
    			cToWinMap.put(o.Id,integer.ValueOf(o.Confidence_to_Win__c));
    		}
    		else
    		{
    			cToWinMap.put(o.Id,0);
    		}
    		curMap.put(o.Id, o.CurrencyIsoCode);
    	}

    	Map<String,Projected_Fiscal_Quarter_Run_Rate__c> pfqrrMap = new Map<String,Projected_Fiscal_Quarter_Run_Rate__c>();
    	for(Projected_Fiscal_Quarter_Run_Rate__c pfqrr:[select id, Opportunity__c, Fiscal_Year__c, Quarter__c from Projected_Fiscal_Quarter_Run_Rate__c where Opportunity__c in :opps])
    	{
    		system.debug('existing pfqrr: ' + pfqrr.Opportunity__c + pfqrr.Quarter__c + pfqrr.Fiscal_Year__c);
    		pfqrrMap.put(pfqrr.Opportunity__c + pfqrr.Quarter__c + pfqrr.Fiscal_Year__c, pfqrr);
    	}
    	
    	Map<String,Decimal> amountMap = new Map<String, Decimal>();
    	Projected_Fiscal_Quarter_Run_Rate__c[] pfqrrInsert = new Projected_Fiscal_Quarter_Run_Rate__c[0];
    	
    	for (OpportunityLineItemSchedule olis:[Select Type, ScheduleDate, Revenue,  OpportunityLineItem.OpportunityId, OpportunityLineItemId, LastModifiedDate, Id, CurrencyIsoCode
    											From OpportunityLineItemSchedule where OpportunityLineItem.OpportunityId in :opps])
		{
			string quarter = '';
			Date schedDate = olis.ScheduleDate;
			system.debug('scheddate: ' + olis.ScheduleDate);
			Date workdate = Date.newInstance(Date.today().year(), schedDate.month(), schedDate.day());
			
			system.debug('workdate: ' + workdate);
			
			if(workdate >= Q1Start && workdate < Q2Start)
			{
				quarter = 'Q1';
				schedDate = schedDate.addYears(1);
			}
			else if(workdate >= Q2Start && workdate < Q3Start)
			{
				quarter = 'Q2';
				schedDate = schedDate.addYears(1);
			}
			else if(workdate >= Q3Start && workdate < Q4Start)
			{
				quarter = 'Q3';
				schedDate = schedDate.addYears(1);
			}
			else //if(workdate >= Q4Start && workdate < Q4Start.addMonths(3))
			{
				quarter = 'Q4';
				
			}
			
	    	string key = olis.OpportunityLineItem.OpportunityId + quarter + schedDate.year().format().replaceAll(',', '');
	    	system.debug('key: ' + key);
	    	
	    	if(amountMap.containsKey(key))
	    	{
	    		decimal newAmount = olis.Revenue + amountMap.get(key);
	    		amountMap.remove(key);
	    		amountMap.put(key,newAmount);
	    		system.debug('amountMap key: ' + key);
	    		system.debug('newamount: ' + newAmount);
	    	}
	    	else
	    	{
	    		if(pfqrrMap.containsKey(key))
	    		{
	    			amountMap.put(key,olis.Revenue);
		    		system.debug('amountMap key: ' + key);
	    			system.debug('newentryamount: ' + olis.Revenue);
	    		}
	    		else
	    		{
	    			amountMap.put(key,olis.Revenue);
	    			Projected_Fiscal_Quarter_Run_Rate__c pfqrrNew = new Projected_Fiscal_Quarter_Run_Rate__c();
	    			pfqrrNew.Opportunity__c = olis.OpportunityLineItem.OpportunityId;
	    			pfqrrNew.Fiscal_Year__c = schedDate.year().format().replaceAll(',', '');
	    			pfqrrNew.Quarter__c = quarter;
	    			pfqrrInsert.add(pfqrrNew);
		    		system.debug('amountMap key: ' + key);
	    			system.debug('newamount & pfqrr record: ' + olis.Revenue);
	    		}
	    	}
		}
		
		system.debug('looping through updates');
		Projected_Fiscal_Quarter_Run_Rate__c[] pfqrrUpdate = new Projected_Fiscal_Quarter_Run_Rate__c[0];
    	for(Projected_Fiscal_Quarter_Run_Rate__c pfqrr:[select id, Opportunity__c, Opportunity__r.Confidence_to_Win__c, Fiscal_Year__c, Quarter__c from Projected_Fiscal_Quarter_Run_Rate__c where Opportunity__c in :opps])
    	{
    		string key = pfqrr.Opportunity__c + pfqrr.Quarter__c + pfqrr.Fiscal_Year__c;
    		system.debug('update key: ' + key);
    		if(amountMap.containsKey(key))
    		{
    			pfqrr.Full_PFYRR_Amount__c = amountMap.get(key);
    			system.debug('cotwin update: ' + cToWinMap.get(pfqrr.Opportunity__c));
    			pfqrr.Factored_PFYRR_Amount__c = amountMap.get(key) * (cToWinMap.get(pfqrr.Opportunity__c) * .01);
    			pfqrrUpdate.add(pfqrr);
    		}
    		else
    		{
    			pfqrr.Full_PFYRR_Amount__c = 0;
    			pfqrr.Factored_PFYRR_Amount__c = 0;
    			pfqrrUpdate.add(pfqrr);
    		}
    	}
    	
    	system.debug('looping through inserts');
    	for(Projected_Fiscal_Quarter_Run_Rate__c pfqrr1:pfqrrInsert)
    	{
    		string key = pfqrr1.Opportunity__c + pfqrr1.Quarter__c + pfqrr1.Fiscal_Year__c;
    		system.debug('insert key: ' + key);
    		if(amountMap.containsKey(key))
    		{
    			system.debug('containskey');
    			system.debug('amount:' + amountMap.get(key));
    			pfqrr1.Full_PFYRR_Amount__c = amountMap.get(key);
    			string ctowin = pfqrr1.Opportunity__r.Confidence_to_Win__c;
    			system.debug('ctowin: ' + cToWinMap.get(pfqrr1.Opportunity__c));
    			pfqrr1.Factored_PFYRR_Amount__c = amountMap.get(key) * (cToWinMap.get(pfqrr1.Opportunity__c) * .01);
    			pfqrr1.CurrencyIsoCode = curMap.get(pfqrr1.Opportunity__c);
    		}
    	}
    	
    	if(pfqrrUpdate.size() > 0)
    	{
    		update pfqrrUpdate;
    	}
    	
    	if(pfqrrInsert.size() > 0)
    	{
    		insert pfqrrInsert;
    	}
    	
		string currentQuarter = '';
		string currentYear = '';
		currentYear = Date.today().addYears(1).year().format().replaceAll(',', '');
		
		if(system.today() >= Q1Start && system.today() < Q2Start)
		{
			currentQuarter = 'Q1';
		}
		else if(system.today() >= Q2Start && system.today() < Q3Start)
		{
			currentQuarter = 'Q2';
		}
		else if(system.today() >= Q3Start && system.today() < Q4Start)
		{
			currentQuarter = 'Q3';
		}
		else
		{
			currentQuarter = 'Q4';
			currentYear = Date.today().year().format().replaceAll(',', '');
		}
		
		Opportunity[] updateOpp = new Opportunity[0];
    	for(Opportunity o1 :[select id, PFYRR_In_Year__c, PFYRR_In_Quarter__c, Factored_PFYRR_In_Year__c, Factored_PFYRR_In_Quarter__c, Confidence_to_Win__c from Opportunity where id in :opps])
    	{
    		string key = o1.Id + currentQuarter + currentYear;
    		system.debug('currentquarter key: ' + key);
    		if(amountMap.containsKey(key))
    		{
    			o1.PFYRR_In_Quarter__c = amountMap.get(key);
    			o1.Factored_PFYRR_In_Quarter__c	 = amountMap.get(key) * (integer.ValueOf(o1.Confidence_to_Win__c) * .01);
    		}
    		
    		decimal inYear = 0;
    		
    		string key1 = o1.Id + 'Q1' + currentYear;
    		system.debug('key1: ' + key1);
    		if(amountMap.containsKey(key1))
    		{
    			inYear = inYear + amountMap.get(key1);
    		}
    		string key2 = o1.Id + 'Q2' + currentYear;
    		system.debug('key2: ' + key2);
    		if(amountMap.containsKey(key2))
    		{
    			inYear = inYear + amountMap.get(key2);
    		}
    		string key3 = o1.Id + 'Q3' + currentYear;
    		if(amountMap.containsKey(key3))
    		{
    			inYear = inYear + amountMap.get(key3);
    		}
    		string key4 = o1.Id + 'Q4' + currentYear;
    		if(amountMap.containsKey(key4))
    		{
    			inYear = inYear + amountMap.get(key4);
    		}
    		
    		o1.PFYRR_In_Year__c = inYear;
    		if(o1.Confidence_to_Win__c != null)
    		{
    			o1.Factored_PFYRR_In_Year__c = inYear * (integer.ValueOf(o1.Confidence_to_Win__c) * .01);
    		}
    		else
    		{
    			o1.Factored_PFYRR_In_Year__c = 0;
    		}
    		
    		updateOpp.add(o1);
    	}
    	
    	if(updateOpp.size() > 0)
    	{
    		system.debug('right before update');
    		PFYRRControl.inFutureContext = true;
    		update updateOpp;
    	}
    }
}