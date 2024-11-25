/**
* @description 
* @author  Andres Canavesi
*/
@isTest
public class NAMConfigsTest {
    
    @isTest 
    static void testAttachmentsConfigs() {
        Integer attachmentsBatchSize = NAMConfigs.getBatchSizeForAttachments();
        System.assert(attachmentsBatchSize >0);
        
        NAMConfigs.setBatchSizeForAttachments(430);
        attachmentsBatchSize = NAMConfigs.getBatchSizeForAttachments();
        System.assertEquals(430, attachmentsBatchSize);
        
        Integer dinamicBatchSizeForAttachments = NAMConfigs.getDinamicBatchSizeForAttachments();
        System.assert(dinamicBatchSizeForAttachments >0);
        
        NAMConfigs.setDinamicBatchSizeForAttachments(210);
        dinamicBatchSizeForAttachments = NAMConfigs.getDinamicBatchSizeForAttachments();
        System.assertEquals(210, dinamicBatchSizeForAttachments);
        
        Boolean enableDynamicBatchSize = NAMConfigs.getEnableDynamicBatchSize();
        System.assertEquals(false, enableDynamicBatchSize, 'enableDynamicBatchSize must be false by default');
        
        NAMConfigs.setEnableDynamicBatchSize(true);
        enableDynamicBatchSize = NAMConfigs.getEnableDynamicBatchSize();
        System.assertEquals(true, enableDynamicBatchSize);
        
        Integer minBatchSize = NAMConfigs.getMinBatchSize();
        System.assert(minBatchSize >0);
        
        NAMConfigs.setMinBatchSize(5);
        minBatchSize = NAMConfigs.getMinBatchSize();
        System.assertEquals(5, minBatchSize);
    }
    
    @isTest 
    static void testNotesConfigs() {
        Integer notesBatchSize = NAMConfigs.getBatchSizeForNotes();
        System.assert(notesBatchSize >0);
        
        NAMConfigs.setBatchSizeForNotes(120);
        notesBatchSize = NAMConfigs.getBatchSizeForNotes();
        System.assertEquals(120, notesBatchSize);
    }
    
    @isTest 
    static void testMetadataPageSize() {
        Integer metadataPageSize = NAMConfigs.getMetadataPageSize();
        System.assert(metadataPageSize >0);
        
        NAMConfigs.setMetadataPageSize(10);
        metadataPageSize = NAMConfigs.getMetadataPageSize();
        System.assertEquals(10, metadataPageSize);
    }
    
    @isTest 
    static void testResetAttachmentsConversion() {
        NAMAttachmentConversionStatus__c status = new NAMAttachmentConversionStatus__c();
        status.Name = 'status';
        upsert status;
        NAMConfigController controller = new NAMConfigController();
        controller.resetAttachmentsConversion();
        List<NAMAttachmentConversionStatus__c> results = [SELECT Id, JobId__c 
                                                       FROM NAMAttachmentConversionStatus__c 
                                                          LIMIT 1];
        System.assertEquals(0, results.size());
    }
    
     @isTest 
    static void testResetNotesConversion() {
        NAMNoteConversionStatus__c status = new NAMNoteConversionStatus__c();
        status.Name = 'status';
        upsert status;
        NAMConfigController controller = new NAMConfigController();
        controller.resetNotesConversion();
        List<NAMNoteConversionStatus__c> results = [SELECT Id, JobId__c 
                                                       FROM NAMNoteConversionStatus__c 
                                                          LIMIT 1];
        System.assertEquals(0, results.size());
    }
    
    
}