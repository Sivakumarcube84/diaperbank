global with sharing class NAMLastAttachmentsController {
    public List<NAMAttchmentWrapper> lastAttachments {get; set;}
    public Integer OffsetSize = 0;
    public Integer QueryLimit = NAMUtils.DEFAULT_LAST_ATTACHMENTS_PAGE_SIZE;
    public String sucessComumunityGroupURL {get; set;}
    public String appExchangeURL {get; set;}
    public String version {get{
        return NAMUtils.PACKAGE_VERSION_NAME;
    } set;}
    
    
    public Boolean migrated = true;
    public String migratedString {get; set;}
    
      //only to use the Date in the VF Page
    public ContentVersion startDateCV {get;set;}
    public ContentVersion endDateCV {get;set;}
    public String validationDateMessage{get;set;}
    
    public Date startDateFilter{ get{
        if(startDateFilter==null){
            startDateFilter = Date.today();
            startDateFilter = startDateFilter.addDays(-30);
        }
        return startDateFilter;
    } set;}
    
    public Date endDateFilter{ get{
        if(endDateFilter==null){
            endDateFilter = System.today();
        }
        return endDateFilter;
    } set;}
    
    public NAMLastAttachmentsController(){
        startDateCV = new ContentVersion();
        startDateCV.LegacyNoteConvertedDate__c = StartDateFilter;
        endDateCV = new ContentVersion();
        endDateCV.LegacyNoteConvertedDate__c = EndDateFilter;
        validationDateMessage = '';
        migratedString = 'true';
        sucessComumunityGroupURL = NAMUtils.SUCCESS_COMMUNITY_GROUP_URL;
        appExchangeURL = NAMUtils.APP_EXCHANGE_URL;
        loadLastAttachments();
    }
    
    @RemoteAction
    global static void runConvertionRemote(String attachmentId) {
        system.debug('attachmentId: ' + attachmentId);
        if(attachmentId != ''){
            String[] attachmentsIdArray = attachmentId.split(',');
            for(Integer i=0; i<attachmentsIdArray.size(); i++){
                List<Attachment> attachment = [SELECT Id, Name, Body, Description, ParentId, OwnerId, LastModifiedDate, CreatedDate, 
                                               LastModifiedById, IsPrivate 
                                               FROM Attachment 
                                               WHERE Id = :attachmentsIdArray[i]];
                
                List<ContentVersion> fileForInsert = new List<ContentVersion>();
                ContentVersion  file = createContentVersion (attachment.get(0));
                fileForInsert.add(file);
                Database.SaveResult[] srList = Database.insert(fileForInsert, false);
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        changeName(file, attachment.get(0)); 
                        Database.SaveResult[] srListUpdate = Database.update(attachment, false);
                    }else{
                           for(Database.Error err : sr.getErrors()) {
                               system.debug('error: ' + err);
                           }                        
                       }    
                   }
            }
        }
        
    }
    
      /*
* @description Create a ContentVersion from a Attachment
*/
    private static ContentVersion createContentVersion(Attachment oldAttachment) {
        ContentVersion cv = new ContentVersion();
        
        // data fields
        cv.pathOnClient = '/' + oldAttachment.name;
        cv.Title = oldAttachment.Name.substringBeforeLast('.');
        cv.Origin = 'H'; 
        if(oldAttachment.Body == null || Blob.valueOf('') == oldAttachment.Body){
            //VersionData is a required field, so we set a default value
            cv.VersionData = Blob.valueOf('null');
        }else{
            cv.VersionData = oldAttachment.Body;
        }
        cv.CreatedDate = oldAttachment.CreatedDate;
        cv.OwnerId = oldAttachment.OwnerId;
        cv.CreatedById = oldAttachment.OwnerId;                
        cv.LastModifiedById = oldAttachment.LastModifiedById;
        cv.LastModifiedDate = oldAttachment.LastModifiedDate;
        /*
* "Setting FirstPublishLocationId allows you to create a file and share it with an initial 
* record/group in a single transaction"
* ContentDocumentLink will create automatically by Salesforce
*/
        cv.FirstPublishLocationId = oldAttachment.parentId;
        if(oldAttachment.IsPrivate){
            cv.SharingPrivacy = 'P';
        } 
        
        
        return cv;
    }
    
    public static void changeName(ContentVersion file, Attachment attachment){
        String newName = '';               
        newName = transformName(file.Id, attachment.Name);
        system.debug(newName);
        system.debug(newName.length());
        if(newName.length() > 255){
            String couttedName = newName.substring(0, 254);
            attachment.Name = couttedName;
        } else {
            
            attachment.Name = newName; 
            
        }
    }
    
    public static String transformName(Id contentVersionId, String nameAttachment){
        String contentVersionIdString = '';
        contentVersionIdString = contentVersionId;
        return '[' + contentVersionIdString.substring(0,15) +']' + ' ' + nameAttachment;
        
    }
    
    public List<SelectOption> getorderByOptions (){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('true', 'only migrated'));
        options.add(new SelectOption('false', 'only not migrated'));
        return options;
    }
    
    public void orderBy(){
        if(migratedString == 'true'){
            migrated = true;            
        } else {
            migrated = false;  
        }
    }
    
    public PageReference loadLastAttachments(){ 
        lastAttachments = NAMUtils.lastAttachments(QueryLimit, OffsetSize, startDateCV.LegacyNoteConvertedDate__c, endDateCV.LegacyNoteConvertedDate__c, migrated);
        return null;
    }
    
    public Boolean getDisablePrevious(){
        if(OffsetSize > 0){
            return false;
        }
        else return true;
    }
    
    public Boolean getDisableNext() {
        if(NAMUtils.lastAttachments(QueryLimit,NAMUtils.DEFAULT_LAST_ATTACHMENTS_PAGE_SIZE + OffsetSize, startDateCV.LegacyNoteConvertedDate__c, endDateCV.LegacyNoteConvertedDate__c, migrated).size() > 0){
            return false;
            
        } else{
            return true;
            
        }
    }
    
     public PageReference Next() {
        OffsetSize += NAMUtils.DEFAULT_LAST_ATTACHMENTS_PAGE_SIZE;
        lastAttachments = NAMUtils.lastAttachments(QueryLimit, OffsetSize, startDateCV.LegacyNoteConvertedDate__c, endDateCV.LegacyNoteConvertedDate__c, migrated);
        return null;
    }
    
    public PageReference Previous() {
        OffsetSize -= NAMUtils.DEFAULT_LAST_ATTACHMENTS_PAGE_SIZE;
        lastAttachments = NAMUtils.lastAttachments(QueryLimit, OffsetSize, startDateCV.LegacyNoteConvertedDate__c, endDateCV.LegacyNoteConvertedDate__c, migrated);
        system.debug('OffsetSize: ' + OffsetSize);
        return null;
    }
    
    public PageReference loadInfo(){
        lastAttachments = new List<NAMAttchmentWrapper>();
        system.debug('lastAttachments: '+ lastAttachments);
        if(startDateCV.LegacyNoteConvertedDate__c > System.today()||endDateCV.LegacyNoteConvertedDate__c>System.today()){
            validationDateMessage = 'Select a start date and end date before today.';
            system.debug('validationDateMessage: ' + validationDateMessage);
        }else if(startDateCV.LegacyNoteConvertedDate__c>endDateCV.LegacyNoteConvertedDate__c){
            validationDateMessage = 'Select an end date that\'s on or after the start date.';
            system.debug('validationDateMessage: ' + validationDateMessage);
        }
        else{
            validationDateMessage = '';
            orderBy();
            loadLastAttachments();
        }
        return null;
    }
    
     /**
* @description
* @return
*/
    public Boolean getEmpty() { 
        return lastAttachments.size() == 0;
    } 

}