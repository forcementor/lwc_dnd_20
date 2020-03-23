public with sharing class MondoControllerExt {

    private ID bookingId {get;set;}
    private String pdfName {get;set;}
    private Booking__c booking {get;set;}   
    private Booking__c bookingRef {get;set;}
        
    private final ApexPages.StandardController controller;
        
    public string pageMessage {get;set;}
    public string pageMessageSeverity {get;set;}

    //Expense Invoice
    public Attachment expenseInvoiceAttachment  {get; set;}
    public String expenseInvoiceContentType {get; set;}
    public String expenseInvoiceFileName {get; set;}        

    //Booking Invoice
    public Attachment bookingInvoiceAttachment {get; set;} 
    public String bookingInvoiceContentType {get; set;}
    public String bookingInvoiceFileName {get; set;}        

    //Work Order
    public Attachment workOrderAttachment  {get; set;}
    public String workOrderContentType {get; set;}
    public String workOrderFileName {get; set;}     

    //Survey
    public Attachment surveyAttachment  {get; set;}
    public String surveyContentType {get; set;}
    public String surveyFileName {get; set;}     

    //Expense Report
    public Attachment expenseReportAttachment  {get; set;}
    public String expenseReportContentType {get; set;}
    public String expenseReportFileName {get; set;}     

	//Flags for conditional validation and display
	public boolean isContractor {
		get {
			return bookingRef.Trainer__r.Is_Contractor__c;	
		}
	}	
	
	public boolean isVirtualTraining {
		get {
			return bookingRef.Class__c.contains('-V');	
		}
	}

	public boolean expenseNotRequired {
		get {
			return bookingRef.Expense_Not_Required__c;	
		}
	}

	public boolean surveyNotRequired {
		get {
			return bookingRef.Survey_Not_Required__c == true;	
		}
	}
    
	public boolean expenseInvoiceRequired {
		get {
			return ( this.isContractor ) && ( !this.isVirtualTraining ) && ( !this.expenseNotRequired );	
		}
	}
		
	public boolean bookingInvoiceRequired {
		get {
			return ( this.isContractor ) ;		
		}
	}	
	 
	public boolean expenseReportRequired {
		get {
			return ( this.isContractor ) && ( !this.isVirtualTraining ) && ( !this.expenseNotRequired );	
		}
	}
	
    public BookingFinalizeControllerExt(ApexPages.StandardController pController){

        this.controller = pController;
        bookingId = this.controller.getId();
                
        bookingRef = getBookingById(bookingId);
        booking = (Booking__c)this.controller.getRecord();

        setDefaultPageMessage();
                
        //Set any pre-existing attachments.
        expenseInvoiceAttachment = getBookingAttachmentLatestforToken(bookingId, UtilityLib.EXPENSE_INVOICE_TOKEN);
        expenseInvoiceFileName = expenseInvoiceAttachment.name;

        bookingInvoiceAttachment = getBookingAttachmentLatestforToken(bookingId, UtilityLib.BOOKING_INVOICE_TOKEN);
        bookingInvoiceFileName = bookingInvoiceAttachment.name; 

        workOrderAttachment = getBookingAttachmentLatestforToken(bookingId, UtilityLib.WORK_ORDER_TOKEN);
        workOrderFileName = workOrderAttachment.name;   

        surveyAttachment = getBookingAttachmentLatestforToken(bookingId, UtilityLib.BOOKING_SURVEY_TOKEN);
        surveyFileName = surveyAttachment.name;   

		expenseReportAttachment = getBookingAttachmentLatestforToken(bookingId, UtilityLib.EXPENSE_REPORT_TOKEN); 
		expenseReportFileName = expenseReportAttachment.name;   

    }

	public boolean getAttachmentsAreComplete(){
		return this.attachmentsAreComplete();
	}

	public boolean getExpensesAreComplete(){
		return this.expensesAreComplete();
	}

    //Attach submitted documents.
    public PageReference finalizeAttachments() {

        PageReference returnTo = null;
        Savepoint spStart = Database.setSavepoint(); 
        boolean saveComplete = false;
                
        try{

                List<Attachment> attachments = new List<Attachment>();

            //Refine the attachments.
            if(expenseInvoiceAttachment.id == null && expenseInvoiceFileName != null) {
                setBookingAttachment(bookingId, expenseInvoiceAttachment, UtilityLib.EXPENSE_INVOICE_TOKEN, expenseInvoiceContentType);
                attachments.add(expenseInvoiceAttachment);
                bookingRef.Trainer_Expense_Invoice_Attached__c = true;
                        system.debug('====================finalizeAttachments().attachments add expenseInvoiceAttachment: /n' + attachments);
            }

            if(bookingInvoiceAttachment.id == null && bookingInvoiceFileName != null) {                             
                setBookingAttachment(bookingId, bookingInvoiceAttachment, UtilityLib.BOOKING_INVOICE_TOKEN, bookingInvoiceContentType);
                attachments.add(bookingInvoiceAttachment);
                bookingRef.Trainer_Booking_Invoice_Attached__c = true;
                                system.debug('====================finalizeAttachments().attachments add bookingInvoiceAttachment: /n' + attachments);
            }       

            if(workOrderAttachment.id == null && workOrderFileName != null) {                       
                setBookingAttachment(bookingId, workOrderAttachment, UtilityLib.WORK_ORDER_TOKEN, workOrderContentType);
                attachments.add(workOrderAttachment);                           
                bookingRef.Trainer_SOW_Attached__c = true;
                                system.debug('====================finalizeAttachments().attachments add workOrderAttachment: /n' + attachments);                
            }       
        
            if(surveyAttachment.id == null && surveyFileName != null) {                       
                setBookingAttachment(bookingId, surveyAttachment, UtilityLib.BOOKING_SURVEY_TOKEN, surveyContentType);
                attachments.add(surveyAttachment);                           
                bookingRef.Survey_Attached__c = true;
                                system.debug('====================finalizeAttachments().attachments add surveyAttachment: /n' + attachments);                
            }       

            if(expenseReportAttachment.id == null && expenseReportFileName != null) {
                setBookingAttachment(bookingId, expenseReportAttachment, UtilityLib.EXPENSE_REPORT_TOKEN, expenseReportContentType);
                attachments.add(expenseReportAttachment);
                bookingRef.Expense_Report_Attached__c = true;
                        system.debug('====================finalizeAttachments().attachments add expenseReportAttachment: /n' + attachments);
            }

            if(attachments.size() > 0) {
                INSERT attachments;
                UPDATE bookingRef;
                saveComplete = true;
                                system.debug('====================finalizeAttachments().saveComplete: /n' + saveComplete);                
            } else{
                //Invalid state.
            }       
 
                } catch (Exception e) {
                        
                Database.rollback(spStart);
                        ApexPages.addmessages(e);
            system.debug('Exception: ' + string.valueOf(e));
                        return returnTo;
                
                } 
                
        if(saveComplete){   
                
            //Clear attachments to reduce ViewState.
            expenseInvoiceAttachment.body = null;
            expenseInvoiceAttachment = new Attachment();
            expenseInvoiceFileName = null;
                
            bookingInvoiceAttachment.body = null;
            bookingInvoiceAttachment = new Attachment();
            bookingInvoiceFileName = null;
                
    			workOrderAttachment.body = null;
	        workOrderAttachment = new Attachment();
            workOrderFileName = null;

            surveyAttachment.body = null;
            surveyAttachment = new Attachment();
            surveyFileName = null;

            expenseReportAttachment.body = null;
            expenseReportAttachment = new Attachment();
            expenseReportFileName = null;

            returnTo = navigateTo();

                } 
            
        return returnTo;

        }

    //Enter expense report information.
    public PageReference finalizeExpenses() {

        PageReference returnTo = null;
        Savepoint spStart = Database.setSavepoint(); 
        boolean saveComplete = false;
                
        try{

            bookingRef.Expense_Report_Id__c = booking.Expense_Report_Id__c;
            bookingRef.Expense_Submitted__c = booking.Expense_Submitted__c; 
            bookingRef.Expense_Amount__c = booking.Expense_Amount__c;

            if(expensesAreComplete()) {
                UPDATE booking;
                saveComplete = true;
            } else{
                //Invalid state.
                pageMessage = '<b>All expense report information is required</b>';                          
            }       
 
        } catch (Exception e) {
                Database.rollback(spStart);
                ApexPages.addmessages(e);
	            system.debug('Exception: ' + string.valueOf(e));
    		        return returnTo;
        } 
                
        if(saveComplete){   
        		returnTo = navigateTo();
        } 
            
        return returnTo;

    }

    //Flag booking as finalized.
    public PageReference finalizeBooking() {

        PageReference returnTo = null;
        Savepoint spStart = Database.setSavepoint(); 
        boolean saveComplete = false;
                
        try{

            if(expensesAreComplete() && attachmentsAreComplete()) {
                
                bookingRef.Finalized__c = true;
                                
                //Capture the IDs of the invoices and post to the Booking. 
                bookingRef.Expense_Invoice_Attachment_ID__c = expenseInvoiceAttachment.id;
                bookingRef.Booking_Invoice_Attachment_ID__c = bookingInvoiceAttachment.id;

                UPDATE bookingRef;

                //Refresh the object instance. 
                bookingRef = getBookingById(bookingRef.id);
        
                sendNotification();             
                saveComplete = true;

            } else{
                //Invalid state.
                pageMessage = '<b>All expense report information and attachments are required</b>';                         
            }       
 
        } catch (Exception e) {
                        
            Database.rollback(spStart);
            ApexPages.addmessages(e);
            system.debug('Exception: ' + string.valueOf(e));
            return returnTo;
                
        } 
                
        if(saveComplete){   
            returnTo = navigateTo();
        } 
           
        return returnTo;

    }

    //Send to Finalize My Bookings List.
    public PageReference cancelToList(){
            PageReference returnReference; 
            returnReference = page.BookingFinalizeList;
            returnReference.setRedirect(true);
            return returnReference;
    }

    //Send to Finalize Expenses.
    public PageReference navigateToExpenses(){
            PageReference returnReference; 
            returnReference = page.BookingFinalizeExpenses;
            returnReference.getParameters().put('id',bookingId);
            returnReference.setRedirect(true);
            return returnReference;
    }

    //Send to Finalize Attachments.
    public PageReference navigateToAttachments(){
            PageReference returnReference; 
            returnReference = page.BookingFinalizeAttachments;
            returnReference.getParameters().put('id',bookingId);
            returnReference.setRedirect(true);
            return returnReference;
    }

    //Determine where to direct the user based on booking state.
    public PageReference navigateTo(){

        PageReference returnReference; 
        
        system.debug('====================navigateTo().attachmentsAreComplete(): /n' + attachmentsAreComplete());
        system.debug('====================navigateTo().expensesAreComplete(): /n' + expensesAreComplete());

        if( !expensesAreComplete() ) {

            //Expenses not complete.
            returnReference = page.BookingFinalizeExpenses;      
                
        } else if (!attachmentsAreComplete() ) {
                        
            //Expenses complete but attachments not complete.
            returnReference = page.BookingFinalizeAttachments; 

        } else {

            //Attachments and expenses complete.
            //Page determins if Finalization already complete or not.
            returnReference = page.BookingFinalizeConfirm;

        }
        
        returnReference.getParameters().put('id',bookingId);
        returnReference.setRedirect(true);      
        return returnReference;         
    }       

    //Verify all documents attached.
    private boolean attachmentsAreComplete(){
            
        boolean returnValue = false;
        
        system.debug('====================attachmentsAreComplete().bookingRef.Trainer_Expense_Invoice_Attached__c: /n' + bookingRef.Trainer_Expense_Invoice_Attached__c);
        system.debug('====================attachmentsAreComplete().bookingRef.Trainer_Booking_Invoice_Attached__c: /n' + bookingRef.Trainer_Booking_Invoice_Attached__c);
        system.debug('====================attachmentsAreComplete().bookingRef.Expense_Report_Attached__c: /n' + bookingRef.Expense_Report_Attached__c);
        system.debug('====================attachmentsAreComplete().bookingRef.Trainer_SOW_Attached__c: /n' + bookingRef.Trainer_SOW_Attached__c);
        system.debug('====================attachmentsAreComplete().bookingRef.Survey_Attached__c: /n' + bookingRef.Survey_Attached__c);        
        
        if ( 
           		(
           			//Not a contract but did attach the SOW
					(
						isContractor != true             
					)  
					||           		
					//Is a contractor and have attached an expense invoicve (if not a Virtual) and booking invoice and SOW 
             		( 
             			(
	             			(this.isVirtualTraining || this.expenseNotRequired || (bookingRef.Trainer_Expense_Invoice_Attached__c && bookingRef.Expense_Report_Attached__c) )
    	         				&&
        	      				bookingRef.Trainer_Booking_Invoice_Attached__c 
            	  				&& 
              				bookingRef.Trainer_SOW_Attached__c
              			) 
					)
                 )
                &&
                (  
              	   bookingRef.Survey_Attached__c || bookingRef.Survey_Not_Required__c             
                )
            ){
                    
            returnValue = true;                             
        }
                        
        return returnValue;
    }

    //Verify expense fields set.
    private boolean expensesAreComplete(){
            
        boolean returnValue = false;

		//Expenses are complete if:
		// Either this is a V training 
        // OR
        // Expense Not Required
		// OR
		// 	An expense rpt id has been entered AND
		//	There is a submit date AND
		// 	An amount > 0 has ben entered
        if (
				(this.isVirtualTraining)
				||
            	(bookingRef.Expense_Not_Required__c)
            	||
				(
    				(bookingRef.Expense_Report_Id__c != null)
		            && 
        		    (bookingRef.Expense_Submitted__c != null)
             		&&
             		bookingRef.Expense_Amount__c != null 
             		&&
             		bookingRef.Expense_Amount__c > 0
             	)
           ) {
                
                returnValue = true; 
        }
        
        return returnValue;
    }

    //Returns a populated booking for an Id.
    private Booking__c getBookingById(ID pId){
        
        return [SELECT 
                        Id
                    ,Name
                    ,Title__c
                    ,Trainer__r.Email
                    ,Trainer_Name__c
                    //,Owner.Email
                    ,Expense_Report_Id__c
                    ,Expense_Submitted__c 
                    ,Expense_Amount__c
                    ,Trainer_Expense_Invoice_Attached__c 
                    ,Trainer_Booking_Invoice_Attached__c
                    ,Expense_Report_Attached__c
                    ,Trainer_SOW_Attached__c
                    ,Survey_Attached__c
                    ,Finalized__c
                    ,Class__c
                    ,Account__c 
                    ,Type__c
                    ,Location__c
                    ,Start_Date__c
                    ,End_Date__c
                    ,Comment__c
                    ,Expense_Invoice_Attachment_ID__c
                    ,Expense_Invoice_Attachment_Partial_URL__c 
                    ,Booking_Invoice_Attachment_ID__c
                    ,Booking_Invoice_Attachment_Partial_URL__c  
                    ,Trainer__r.Is_Contractor__c
                		,Expense_Not_Required__c
					,Survey_Not_Required__c
                 FROM 
                    Booking__c
                WHERE
                    id =: pId
                ];      
    }

    //Fetch the newest expense invoice even if multiple.
    private Attachment getBookingAttachmentLatestforToken(ID pId, string pToken){
            
        Attachment returnAttachment = new Attachment(); 
                
        List<Attachment> tempAttachments = 
            [SELECT 
                    Id
                        ,Name
                        ,ParentId
                        ,Body 
            FROM 
                Attachment 
            WHERE
                Name LIKE : (pToken + '%')
                AND 
                parentId =: pId
            ORDER BY 
                    LastModifiedDate DESC
            LIMIT 1 
            ];      

        if(tempAttachments.size() == 1){
                tempAttachments[0].body = blob.valueOf('dummy');
                returnAttachment = tempAttachments[0]; 
        }
                
        return returnAttachment;
                                
    }

    //Set the attachment up for saving.
    private void setBookingAttachment(ID parentId, Attachment pAttachment, string pToken, string pContentType){
                
        if (pAttachment.body == null) { return; }
                
        string fileName;
        string fileExtension = '???';
                    
        //Set attachment content type.
        pAttachment.ContentType = pContentType; 
                        
        //Set the extension for the filename based on file ContentType.
        if(pAttachment.ContentType == 'application/pdf'){
            fileExtension = '.pdf';
        } else if(pAttachment.ContentType == 'text/plain'){
            fileExtension = '.txt';
        }                       

        //Exception case for Work Order.
        if(pToken == UtilityLib.WORK_ORDER_TOKEN){
            //Specific name for WO.
            pAttachment.name = UtilityLib.WORK_ORDER_TOKEN + ' ' + bookingRef.Title__c + fileExtension;
        } else {
            //All others.
            pAttachment.name = pToken + ' ' + bookingRef.Title__c + fileExtension;
        }

        pAttachment.IsPrivate = false;
        pAttachment.ParentId = bookingId;
    }

    private void setDefaultPageMessage(){
                
        if( !attachmentsAreComplete() ) {
        
            //Attachments not complete.
            pageMessageSeverity = 'error';
            pageMessage = '<b>All <i><u>required</u></i> documents must be attached to Finalize the Booking, but you may submit them one at a time and return later to add more.</b>';    
            pageMessage += '<br/>You may also submit any or all of your documents by email as follows and return later to continue:<br/>';
            pageMessage += '- Send your WORK ORDER to: workorder@me.com<br/>';                                           
            pageMessage += '- Send your EXPENSE Invoice to: expense@me.com <b>(not applicable to Virtual classes)</b><br/>';
            pageMessage += '- Send your EXPENSE REPORT to: concur@me.com <b>New! (not applicable to Virtual classes)</b><br/>';                        
            pageMessage += '- Send your BOOKING Invoice to: billing@me.com<br/>';
            pageMessage += '- Send your CLASS SURVEY to: survey@me.com<br/>';                        

            pageMessage += '<b>You MUST include the BK# in the Subject!<b/>';
                        
        } else if ( !expensesAreComplete() ) {
                        
            //Attachments complete but expenses not complete.
            pageMessageSeverity = 'error';
            pageMessage = '<b>Please insure all expense report information has been entered.</b>';      

        } else if ( !bookingRef.Finalized__c ) {

            //Attachments and expenses complete, but not finalized.
            pageMessageSeverity = 'warning';
            pageMessage = '<b>All information has been submitted - Please Finalize your booking!</b>';  

        } else {
                        
            pageMessageSeverity = 'info';
            pageMessage = '<b>This Booking has been Finalized - Thank You!</b>';        
                        
        }

    }

    private void sendNotification(){

		//Create a list for the batch of outbound emails.
        List<Messaging.SingleEmailMessage> replyEmailList = new List<Messaging.SingleEmailMessage>();

		//Create list of recipient IDs.
		List<id> recipientIdList = new List<id>();                
		
		//Populate with the trainer and the managers.
		recipientIdList.add(bookingRef.Trainer__c);
		recipientIdList.add(UtilityLib.practiceManagerEmailId);
		recipientIdList.add(UtilityLib.financialManagerEmailId);
		
		//Build the emails.
		for(ID targetUserId : recipientIdList) {
			
			Messaging.SingleEmailMessage emailOut = new Messaging.SingleEmailMessage(); 
			emailOut.setSubject( '**BOOKING FINALIZED - ' + booking.Title__c );
			emailOut.setSenderDisplayName( UtilityLib.practiceManagerEmailAddress );
			emailOut.setHtmlBody( buildEmailBody() );
			emailOut.setTargetObjectId( targetUserId );
			emailOut.setSaveAsActivity(false);				
			replyEmailList.add(emailOut); 
		}		
		
        try{

            List<Messaging.SendEmailResult> mailResults = new List<Messaging.SendEmailResult>();

            if (!Test.isRunningTest()) {
                mailResults = Messaging.sendEmail(replyEmailList);
            }
                        
            List<Trace_Log__c> logs = new List<Trace_Log__c>();         
            for (Messaging.SendEmailResult mailResult:mailResults){
                if (!mailResult.isSuccess()){
                    Trace_Log__c log = new Trace_Log__c();
                    log.trace__c = 'Error sending Finalization NotificationSOW for ' + booking.Title__c + ' to ' + booking.Trainer_Name__c  + '\n' + mailResult;
                    logs.add(log);
                }
            }

            if (logs.size() > 0) { insert logs; }

        } catch (Exception e){
            Trace_Log__c log = new Trace_Log__c();
            log.trace__c = e.getTypeName() + '\n' + e.getCause() + '\n' + e.getMessage() + '\n\Booking: ' + booking.Title__c + '\n';
            insert log;
        }

    }
        
    private string buildEmailBody(){

        //Set up the link.
        PageReference returnReference = page.BookingFinalizeConfirm;
        returnReference.getParameters().put('id',bookingId);
        string baseUrl = 'https://' + ApexPages.currentPage().getHeaders().get('Host'); //new ApexPages.StandardController(bookingRef).view().getHeaders().get('Host');  
        string pageUrl = baseUrl + returnReference.getUrl();

        string expenseInvoiceLink = '';
        string expenseInvoiceLinkHTML = '';
        string bookingInvoiceLink = '';
        string bookingInvoiceLinkHTML = '';

        system.debug('====================buildEmailBody().pageUrl: /n' + pageUrl);
                                
        String body = '<html><br/>';
        body += bookingRef.Trainer_Name__c + ' ';
        body += 'has submitted all expense information and document attachments required to finalize this booking.' + '</p><p>';
        body += 'All information and documents are now available to support the billing cycle:' + '</p><p>';
        body += 'Booking Details:' + '<br/>';
        body += '----------------------' + '<br/>';
        body += 'BK#     : ' + bookingRef.name + '<br/>';
        body += 'Class   : ' + bookingRef.Class__c + '<br/>';
        body += 'Account : ' + bookingRef.Account__c + '<br/>';
        body += 'Type    : ' + bookingRef.Type__c + '<br/>';
        body += 'Location: ' + bookingRef.Location__c + '<br/>';
        body += 'Start   : ' + bookingRef.Start_Date__c.format() + '<br/>';
        body += 'End     : ' + bookingRef.End_Date__c.format() + '<br/><br/>';

        if (bookingRef.Comment__c != null) {
                body += 'Additional Information: ' + '<br/>';
                body += '-----------------------' + '<br/>';
                body += bookingRef.Comment__c + '<br/><br/>';
        }

        body += '<p>Click the links below to access the attachments and review finalized booking information:' + '<br/>';
        body += '<p><a href="' + pageUrl + '" target="_none">' + bookingRef.title__c  + '</a><br/><br/>';

            //Invoice direct links.
            if (bookingRef.Expense_Invoice_Attachment_ID__c == null){
                    expenseInvoiceLink = 'Expense Invoice Not Available<p/>';
                    expenseInvoiceLinkHTML = expenseInvoiceLink;
            } else {
                    expenseInvoiceLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + bookingRef.Expense_Invoice_Attachment_Partial_URL__c;
                    expenseInvoiceLinkHTML = '<i><a href="' + expenseInvoiceLink + '" >Click Here For Contractor Expense Invoice</a></i><p/>' ;                               
            }
            body += expenseInvoiceLinkHTML;

        if (bookingRef.Booking_Invoice_Attachment_ID__c == null){
                bookingInvoiceLink = 'Booking Invoice Not Available<p/>';
                bookingInvoiceLinkHTML = bookingInvoiceLink;
        } else {
                bookingInvoiceLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + bookingRef.Booking_Invoice_Attachment_Partial_URL__c;
                bookingInvoiceLinkHTML = '<i><a href="' + bookingInvoiceLink + '" >Click Here For Contractor Booking Invoice</a></i><p/>' ;                               
        }
        body += bookingInvoiceLinkHTML;

        body += 'If any issues arise please call George ASAP at 415-555-5555.' + '<br/><br/>';
        body += 'Thanks!' + '<br/>';
        body += '(Your Me.com Daemon)<p/></body></html>'; 
                
        return body;
    }         

}