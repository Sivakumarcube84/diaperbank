/**
* @description
* @author Jessica Bernal
* @date 2017-11-07
*/
public with sharing class NAMConfigController {
    public List<AsyncApexJob> apexJobs {get; set;}
    public List<ApexTrigger> triggers {get; set;}
    public Integer TriggersOffsetSize = 0;
    public Integer TriggersQueryLimit = NAMUtils.DEFAULT_CONFIG_PAGE_SIZE;
    public Integer OffsetSize = 0;
    public Integer QueryLimit = NAMUtils.DEFAULT_CONFIG_PAGE_SIZE;
    public Integer attachmentsBatchSize {get; set;}
    public Integer notesBatchSize {get; set;}
    public Integer metadataPageSize {get; set;}
    public Integer minBatchSize {get; set;}
    public Integer bodyLength {get; set;}
    public Boolean enableBodyLength {get; set;}
    public String showHide { get; set; }
    public String message { get; set; }
    public Boolean enableDynamicBatchSize {get; set;}
    public String sucessComumunityGroupURL {get; set;}
    public String appExchangeURL {get; set;}
    public String apexjobsURL {get; set;}
    public String triggersURL {get; set;}
    public String version {get{
        return NAMUtils.PACKAGE_VERSION_NAME;
    } set;}
    
    public NAMConfigController(){
        showHide = 'slds-hide';
        sucessComumunityGroupURL = NAMUtils.SUCCESS_COMMUNITY_GROUP_URL;
        appExchangeURL = NAMUtils.APP_EXCHANGE_URL;
        attachmentsBatchSize = NAMConfigs.getBatchSizeForAttachments();
        notesBatchSize = NAMConfigs.getBatchSizeForNotes();
        enableDynamicBatchSize = NAMConfigs.getEnableDynamicBatchSize();
        minBatchSize = NamConfigs.getMinBatchSize();
        metadataPageSize = NAMConfigs.getMetadataPageSize();
        enableBodyLength = NAMConfigs.getEnableBodyLength();
        bodyLength = NAMConfigs.getBodyLength();
        apexjobsURL = URL.getSalesforceBaseUrl().toExternalForm() + '/apexpages/setup/listAsyncApexJobs.apexp'; 
        triggersURL = URL.getSalesforceBaseUrl().toExternalForm() + '/setup/build/allTriggers.apexp';
        loadApexJobs();
        loadTriggers();
        
    }
    
    public void changeConfigs(){
        NAMConfigs.setBatchSizeForAttachments(attachmentsBatchSize);
        NAMConfigs.setBatchSizeForNotes(notesBatchSize);
        NAMConfigs.setEnableDynamicBatchSize(enableDynamicBatchSize);
        NAMConfigs.setMetadataPageSize(metadataPageSize);
        NAMConfigs.setMinBatchSize(minBatchSize);
        NAMConfigs.setEnableBodyLength(enableBodyLength);
        NAMConfigs.setBodyLength(bodyLength);
        message = 'Configs saved. ';
        showHide = '';
    }
    
    public void resetAttachmentsConversion(){
        
        String className = MigratorBatch.class.getName();
        String nameSpace = '';
        if(className.contains('.')){
            nameSpace = className.substringBefore('.');
            className = className.substringAfter('.');
            
            System.debug('className '+className);
            System.debug('nameSpace '+nameSpace);
        }
        NAMUtils.abortOperation(className, nameSpace, true, true);
        message = 'Attachments reset done. ';
        showHide = '';
    }
    
    public void resetNotesConversion(){
        String className = NMTMigratorBatch.class.getName();
        String nameSpace = '';
        if(className.contains('.')){
            nameSpace = className.substringBefore('.');
            className = className.substringAfter('.');
            
            System.debug('className '+className);
            System.debug('nameSpace '+nameSpace);
        }
        NAMUtils.abortOperation(className, nameSpace, true, false);
        message = 'Notes reset done. ';
        showHide = '';
    }
    
    public Boolean getDisablePrevious(){
        if(OffsetSize > 0){
            return false;
        }
        else return true;
    }
    
    public Boolean getDisableNext() {
        if(NAMUtils.loadApexJobs(QueryLimit,NAMUtils.DEFAULT_CONFIG_PAGE_SIZE + OffsetSize).size() > 0){
            return false;
            
        } else{
            return true;
            
        }
    }
    
    public PageReference Next() {
        OffsetSize += NAMUtils.DEFAULT_CONFIG_PAGE_SIZE;
        apexJobs = NAMUtils.loadApexJobs(QueryLimit, OffsetSize);
        system.debug('OffsetSize: ' + OffsetSize);
        return null;
    }
    
    public PageReference Previous() {
        OffsetSize -= NAMUtils.DEFAULT_CONFIG_PAGE_SIZE;
        apexJobs = NAMUtils.loadApexJobs(QueryLimit, OffsetSize);
        system.debug('OffsetSize: ' + OffsetSize);
        return null;
    }
    
    public Boolean getTriggersDisablePrevious(){
        if(TriggersOffsetSize > 0){
            return false;
        }
        else return true;
    }
    
    public Boolean getTriggersDisableNext() {
        if(NAMUtils.loadTriggers(TriggersQueryLimit,NAMUtils.DEFAULT_CONFIG_PAGE_SIZE + TriggersOffsetSize).size() > 0){
            return false;
            
        } else{
            return true;
            
        }
    }
    
    public PageReference TriggersNext() {
        TriggersOffsetSize += NAMUtils.DEFAULT_CONFIG_PAGE_SIZE;
        triggers = NAMUtils.loadTriggers(TriggersQueryLimit, TriggersOffsetSize);
        return null;
    }
    
    public PageReference TriggersPrevious() {
        TriggersOffsetSize -= NAMUtils.DEFAULT_CONFIG_PAGE_SIZE;
        triggers = NAMUtils.loadTriggers(TriggersQueryLimit, TriggersOffsetSize);
        return null;
    }
    
    public PageReference loadApexJobs(){
        apexJobs = NAMUtils.loadApexJobs(QueryLimit, OffsetSize);
        return null;
    }
    
    public PageReference loadTriggers(){
        triggers = NAMUtils.loadTriggers(TriggersQueryLimit, TriggersOffsetSize);
        return null;
    }
    
    public Boolean getEmptyTriggers() { 
        return triggers.size() == 0;
    } 
    
    public Boolean getEmptyApexJobs() { 
        return apexJobs.size() == 0;
    } 
    
}