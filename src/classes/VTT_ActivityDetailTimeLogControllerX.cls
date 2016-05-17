/*-------------------------------------------------------------------------------------------------
Author     : Sergey Makarov
Company    : Husky Energy
Description: A extension controller for Activity Detail view serves both desktop and mobile views
Inputs     : N/A
Test Class : VTT_ActivityDetailTimeLogControllerXTest
History    : 04.14.2016 ssd added logic to get operator on call from Activity, and added 
                            error handling for no operator on call found
------------------------------------------------------------------------------------------------*/
public without sharing class VTT_ActivityDetailTimeLogControllerX {


    private final Work_Order_Activity__c woActivity;
    private final HOG_Maintenance_Servicing_Form__c workOrder;

    private final String retUrl;

    private List<SelectOption> partsOptions = new List<SelectOption>();
    private List<SelectOption> damagesOptions = new List<SelectOption>();
    private List<SelectOption> causesOptions = new List<SelectOption>();
    private List<SelectOption> usersOptions = new List<SelectOption>();

    private final static String NONE_ITEM = '--None--';
    private Boolean isReloadAttachments;
    private List<Attachment> attachments;
    private List<Attachment> woattachments;    
    
    private User operatorOnCall;

    private Map<String, String> mapPartCode = new Map<String, String>();    

    public Boolean renderErrorMessageOnMobile {get; private set;}

    public String partItem {get; set;}
    public String damageItem {get; set;}
    public String damageText {get; set;}    
    public String causeItem {get; set;}    
    public String causeText {get; set;}     
    public String userItem {get; set;} 



    public SelectOption[] selectedTradesmen { get; set; }
    public SelectOption[] allTradesmen { get; set; }    
    public SelectOption[] vendorAccounts { get; set; }
    public ID assignedVendor {get; set;}
 
    public Work_Order_Activity__c  damageRecord {get; private set;}   
    public VTT_WorkFlowEngine workflowEngine {get; private set;} 
    public Boolean EquipmentWorkOrder {get; private set;}
    public String filter {get; private set;}
    public Boolean showPartsDamageCause {get; private set;}
    public List<Work_Order_Activity_Assignment__c> tradesmanAssignments {get; private set;}

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public VTT_ActivityDetailTimeLogControllerX(ApexPages.StandardController stdController) {

        retUrl = ApexPages.currentPage().getParameters().get('retURL');
        this.woActivity = (Work_Order_Activity__c)stdController.getRecord();


        workflowEngine = new VTT_WorkflowEngine(stdController);

        filter = System.currentPageReference().getParameters().get('filter');

        //damageListLoad();
        //damageRecord = new Work_Order_Activity_Damage__c();
        //damageRecord.Work_Order_Activity__c = this.woActivity.ID;

        damageRecord = woActivity;
        workOrder = [Select Id,
                        Equipment__r.Catalogue_Code__c,
                        HOG_Service_Request_Notification_Form__c,
                        MAT_Code__c,
                        Order_Type__c
                    From HOG_Maintenance_Servicing_Form__c
                    Where Id =: woActivity.Maintenance_Work_Order__c];
        tradesmanAssignments = [Select Id, Name, Tradesman__r.Name, Tradesman__r.Tradesman_Status__c,
                                       Tradesman__r.Tradesman_Status_Date__c, Tradesman__r.Tradesman_Status_Duration__c
                                From Work_Order_Activity_Assignment__c
                                Where Work_Order_Activity__c =: woActivity.Id];
        

        EquipmentWorkOrder =  (this.woActivity.Maintenance_Work_Order__r.Equipment__c <> null && this.woActivity.Maintenance_Work_Order__r.Equipment__r.Catalogue_Code__c <> null);        
        showPartsDamageCause = !MaintenanceServicingUtilities.SkipPartsDamageCause(workOrder) &&
            !MaintenanceServicingUtilities.SkipPartsDamageCauseSysAdmin(workOrder);
        partsSelection();
        causesSelection();

        VendorAccountsSetup();

        assignedVendor = this.woActivity.Assigned_Vendor__c; 
        TradesmanAssignmentSetup();
        
        isReloadAttachments = true; //To load 
        renderErrorMessageOnMobile = false; //Don't want to load pagemessages from workflowengine on mobile unless specified
    }

    public List<SelectOption> getPartsOptions()
    {
        return partsOptions;
    }

    public List<SelectOption> getDamagesOptions()
    {
        return damagesOptions;
    }

    public List<SelectOption> getCausesOptions()
    {
        return causesOptions;
    }

    public List<SelectOption> getUsersOptions()
    {
        return usersOptions;
    }

    public Attachment attachmentFile {
        get {
            if(attachmentFile == null)
                attachmentFile = new Attachment();
            return attachmentFile;
        }
        private set;
    }

    public List<Attachment> getAttachments() {
        if(isReloadAttachments) {
            attachments = [Select Id, Name, ParentId, Description
                            From Attachment
                            Where ParentId =: woActivity.Id];
            isReloadAttachments = false;
        }

        return attachments;
    }

    public List<Attachment> getWorkOrderAttachments() {
        if(isReloadAttachments) {
            woattachments = [Select Id, Name, ParentId, Description
                            From Attachment
                            Where ParentId =: woActivity.Maintenance_Work_Order__c];
            //isReloadAttachments = false;
        }

        return woattachments;
    } 

    public User getOperatorOnCall() {

        if(operatorOnCall == null) {
            Id locationId = (woActivity.Maintenance_Work_Order__r.Location__c != null) ? 
                             woActivity.Maintenance_Work_Order__r.Location__c :
                             (woActivity.Location__c != null) ? woActivity.Location__c :
                             null;

            Id facilityId = (woActivity.Maintenance_Work_Order__r.Facility__c != null) ?
                             woActivity.Maintenance_Work_Order__r.Facility__c :
                             (woActivity.Facility__c != null) ? woActivity.Facility__c :
                             null;
            
            if(locationId != null) {
                Location__c location = [Select Id, Route__r.Operator_On_Call__r.Operator__c
                           From Location__c
                           Where Id =: locationId];

                List<User> operatorsOnCall = [Select Id, Name, Phone, MobilePhone
                                              From User
                                              Where Id =: location.Route__r.Operator_On_Call__r.Operator__c];
                operatorOnCall = (operatorsOnCall != null && !operatorsOnCall.isEmpty()) ? operatorsOnCall[0] : null;
            } else if (facilityId != null) {
                Facility__c facility = [Select Id, Plant_Section__r.Operator_On_Call__r.Operator__c
                                        From Facility__c
                                        Where Id =: facilityId];

                List<User> operatorsOnCall = [Select Id, Name, Phone, MobilePhone
                                              From User
                                              Where Id =: facility.Plant_Section__r.Operator_On_Call__r.Operator__c];
                operatorOnCall = (operatorsOnCall != null && !operatorsOnCall.isEmpty()) ? operatorsOnCall[0] : null;
            }
        }

        return operatorOnCall;
    }
        
    // Builds picklist of parts   
    public void partsSelection()
    {
        partsOptions.clear();

        String catalogueCode = '';
        String partCode = NONE_ITEM;
        String partDescription = NONE_ITEM;
        
        if (EquipmentWorkOrder)
        {
            catalogueCode = this.woActivity.Maintenance_Work_Order__r.Equipment__r.Catalogue_Code__c;            
            partCode = this.woActivity.Part__r.Part_Code__c;
            partDescription = this.woActivity.Part__r.Part_Description__c;
        }
        else
        {
            return;
        }
                    
        final HOG_Part__c[] results = 
            [Select
                    Id,
                    Part_Code__c,
                    Part_Description__c
                From HOG_Part__c 
                Where Catalogue_Code__c = :catalogueCode
            ];
                
        mapPartCode.clear();

        final Map<String, String> mapResults = new Map<String, String>();
        
        for (HOG_Part__c r : results)
        {
            mapResults.put(r.Part_Code__c, r.Part_Description__c);
            mapPartCode.put(r.Part_Code__c, r.Id);           
        }
                                          
        partItem = 
            selectionOption
            (
                partsOptions, 
                mapResults, 
                partCode,
                partDescription,
                true              
            );
                
        damagesSelection();      
    }   

    // Builds picklist of damages   
    public void damagesSelection()
    {
        damagesOptions.clear();
        system.debug('partItem');
        system.debug(partItem);

        final HOG_Damage__c[] results = 
            [Select
                    Id,
                    Damage_Code__c,
                    Damage_Description__c
                From HOG_Damage__c 
                Where Part_Code__c = :partItem
            ];
                
        final Map<String, String> mapResults = new Map<String, String>();
        
        for (HOG_Damage__c r : results)
        {
            mapResults.put(r.Id, r.Damage_Description__c);
        }

        damageItem = 
            selectionOption
            (
                damagesOptions, 
                mapResults, 
                NONE_ITEM,
                NONE_ITEM,
                true              
            );                            
    }

    // Builds picklist of causes
    public void causesSelection()
    {
        causesOptions.clear();
                    
        final HOG_Cause__c[] results = 
            [Select
                    Id,
                    Cause_Code__c,
                    Cause_Description__c
                From HOG_Cause__c 
            ];
        
        final Map<String, String> mapResults = new Map<String, String>();
        
        for (HOG_Cause__c r : results)
        {
            mapResults.put(r.Id, r.Cause_Description__c);
        }           
                                                 
        causeItem = 
            selectionOption
            (
                causesOptions, 
                mapResults, 
                NONE_ITEM,
                NONE_ITEM,
                true              
            );                                             
    } 

    public PageReference JobComplete()
    {

        if(workflowengine.OptimisticLockCheck() == false)
        {
            return null;
        }

        try
        {
            if (EquipmentWorkOrder)
            {
                damageRecord.Part__c = partItem == NONE_ITEM ? null : mapPartCode.get(partItem);
                damageRecord.Damage__c = damageItem == NONE_ITEM ? null : damageItem;
                damageRecord.Cause__c = causeItem == NONE_ITEM ? null : causeItem;
           }
            else
            {
                List<HOG_Cause__c> result = [Select Id, Cause_Code__c, Cause_Description__c From HOG_Cause__c WHERE Cause_Description__c like'Other%' limit 1];
                if(result.size()>0)
                {
                    damageRecord.Cause__c = result[0].id;
                }
            }
            VTT_Utilities.executeTriggerCode = false;
            upsert damageRecord;
            VTT_Utilities.executeTriggerCode = true;            
            this.workflowEngine.JobComplete_End();        
            return null;
        }
        catch(Exception ex)
        {
            VTT_Utilities.logError(ex);
        }        
        return null;
    }

    public PageReference executeWSUpdateNotification()
    { 
        VTT_Utilities.SAP_UpdateNotification(damageRecord.id);
        return this.workflowEngine.ReloadCurrentPage();  
    }

    public PageReference VTT_Cancel()
    {
        PageReference pageRef;

        if(retUrl != null && !String.isEmpty(retUrl)) {
            //Redirect to Calendar
            pageRef = new PageReference(retUrl);
        } else {
            pageRef = new PageReference('/apex/VTT_ActivityListView');
            if(filter <> null)
            {
                pageRef.getParameters().put('filter',filter);
            }
        }
        pageRef.setRedirect(true);


        return pageRef;  
    }

    public PageReference VTT_Assignment()
    {

        PageReference pageRef = new PageReference('/apex/VTT_TradesmanAssignment?id=' + this.woActivity.id);
        pageRef.setRedirect(true);
        return pageRef;  
    }

    public PageReference UpdateAssignment()
    {

        //first delete everything from assignment table

        List<Work_Order_Activity_Assignment__c> assignmentList =  [select id, Tradesman__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Work_Order_Activity__c = :woActivity.id];
        delete assignmentList;

        assignmentList = new List<Work_Order_Activity_Assignment__c>();

        for ( SelectOption so : selectedTradesmen ) {
            Work_Order_Activity_Assignment__c assinmentRecord = new Work_Order_Activity_Assignment__c();
            assinmentRecord.Tradesman__c = so.getValue();
            assinmentRecord.Work_Order_Activity__c = this.woActivity.id;
            assignmentList.add(assinmentRecord);
        }
        system.debug('this.woActivity.id');
        system.debug(this.woActivity.id);        


        system.debug('assignmentList');
        system.debug(assignmentList);
        insert assignmentList;

        this.woActivity.Assigned_Vendor__c = this.assignedVendor;
        upsert this.woActivity;

        PageReference pageRef = new PageReference('/apex/VTT_ActivityDetailTimeLog?id=' + this.woActivity.id);
        pageRef.setRedirect(true);
        return pageRef;  
    }

    public PageReference ExitAssignment()
    {

        PageReference pageRef = new PageReference('/apex/VTT_ActivityDetailTimeLog');
        //pageRef.setRedirect(true);
        return pageRef;  
    }

    private void  VendorAccountsSetup()
    {

        ID VendorAccountRecordTypeID;
       //assign recordtype SMakarov
        List<RecordType>  recTypes = [select id, name, sobjectType,developername from recordtype where sobjecttype = 'Account' and developername = 'HOG_Vendor_Account_Record' LIMIT 1];
        if(recTypes .size()>0)
        {
            VendorAccountRecordTypeID = recTypes[0].id; 
        }            

        List<Account> accountList = [select id, name from Account where recordtypeID = :VendorAccountRecordTypeID order by name];

        vendorAccounts = new List<SelectOption>();
        for(Account acc: accountList)
        {
            SelectOption accOption = new SelectOption(acc.id, acc.Name);
            vendorAccounts.add(accOption);
        }
    }

    public void  TradesmanAssignmentSetup()
    {
        selectedTradesmen = new List<SelectOption>();
        allTradesmen  = new List<SelectOption>();

        //assignedVendor; 

        List<Contact> contactList = [select id, name from Contact where AccountID = :assignedVendor 
        and User__c <> null order by name
        limit 1000];

        for(Contact contactRec: contactList)
        {
            SelectOption accOption = new SelectOption(contactRec.id, contactRec.Name);
            allTradesmen.add(accOption);
        }  


        
        Set<ID> contactSet = new Set<ID>();
        for(Work_Order_Activity_Assignment__c woaa : [select id, Tradesman__c from Work_Order_Activity_Assignment__c where Rejected__c <> true and Work_Order_Activity__c = :woActivity.id])
        {
            contactSet.add(woaa.Tradesman__c);
        }

        for(Contact tradesmancontact : [select id, name, Phone, email, Tradesman_Status__c, Current_Work_Order_Activity__c, Tradesman_Status_Date__c, User__c 
                                        from Contact where id in :contactSet order by name limit 1000])
        {
            SelectOption accOption = new SelectOption(tradesmancontact.id, tradesmancontact.Name);
            selectedTradesmen.add(accOption);
        }
    }

    public PageReference Upload() {
        attachmentFile.OwnerId = UserInfo.getUserId();
        attachmentFile.ParentId = woActivity.Id;
        attachmentFile.IsPrivate = false;

        try {
            System.debug('attachmentFile.Name: ' + attachmentFile.Name);
            insert attachmentFile;
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error uploading attachment: ' + e.getMessage()));
            renderErrorMessageOnMobile = true;
            return null;
        } finally {
            attachmentFile = new Attachment();
        }

        isReloadAttachments = true;
        return null;
    }

    // Create a picklist selection of items
    // Can be moved to the Utilities class
    private String selectionOption
    (
        List<SelectOption> optionList, // the picklist
        Map<String, String> mapItems, // the items in picklist
        String selectedId, // the selected item value
        String selectedName, // the selected item label
        Boolean selectPickNone // to select the "--None--" in Add mode
    )
    {                
        final String pickNone = NONE_ITEM;
        String selectedValue = selectedId;
        
        optionList.add(new SelectOption(pickNone, pickNone));

        for(String key : mapItems.keySet())
        {
            selectedValue = key;
            optionList.add(new SelectOption(selectedValue, mapItems.get(key)));            
        }
                    
        if (selectedId != pickNone)
        {
            selectedValue = selectedId;
        }
                           
        // sort the items
        sortSelectOption(optionList);
                      
        return selectPickNone ? selectedId : selectedValue;
    }

    // Sorts items/labels in SelectOption
    private void sortSelectOption(List<Selectoption> opts) 
    {        
        final Map<String, Selectoption> mapping = new Map<String, Selectoption>();
        
        // Suffix to avoid duplicate values like same labels or values are in inbound list 
        Integer suffix = 1;
        for (Selectoption opt : opts)
        { 
            mapping.put(opt.getLabel() + suffix++, opt);  
        }
                                    
        final List<String> sortKeys = new List<String>();
        sortKeys.addAll(mapping.keySet());
        sortKeys.sort();
        
        // clear the original collection to rebuild it
        opts.clear();
        
        for (String key : sortKeys)
        { 
            opts.add(mapping.get(key));
        }
    }        
}