/**
*
*/
@isTest
public class DeleteBatchTest {
    
    //Seconds to sleep after the migration in order to give time to the batch process to finish the migration
    private static final Integer SLEEP_AFTER_MIGRATION = 2;
    
    
    @isTest
    public static void attachmentsDeletionTest(){
        Test.startTest();
        //setup
        ATFTestUtils.createAttachmentForNAMConfig(3, false, 'sample3');
        AttachmentsToFilesController controller = new AttachmentsToFilesController();
        controller.deleteAfterMigration = false;
        //end setup
        
        //  controller.runMigration();
        string json = 'NAMConfig__c' + ',' + '3' + '|';
        String dateSt = Datetime.now().format('yyyy-MM-dd');
        String dateEn = Datetime.now().format('yyyy-MM-dd');
        AttachmentsToFilesController.runMigrationRemote(json,'byObject',dateSt, dateEn, true);
        
        //sleeps some seconds to give time to the background migration (batch process)
        ATFTestUtils.sleep(SLEEP_AFTER_MIGRATION);
        AttachmentsToFilesController.deleteMigratedByObjectNameRemote('NAMConfig__c',dateSt, dateEn, true);
        //end setup
        Test.stopTest();
        List <Attachment> attachments = new List <Attachment>();
        attachments = [SELECT Id, Name FROM Attachment WHERE Name LIKE :NAMUtils.MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN];
        System.assertEquals(0, attachments.size());
        
    }
        
    
    /**
    * @description tests delete attachments can only be migrated one of same object at same time
    * Test Case Name: Delete any object
    */
    @isTest
    public static void deleteInProgress(){
        Test.startTest();
        //setup
        ATFTestUtils.createAttachmentForNAMConfig(100, false, 'sample3');
        AttachmentsToFilesController controller = new AttachmentsToFilesController();
        controller.deleteAfterMigration = false;
        //end setup
        
        //  controller.runMigration();
        string json = 'NAMConfig__c' + ',' + '100' + '|';
        String dateSt = Datetime.now().format('yyyy-MM-dd');
        String dateEn = Datetime.now().format('yyyy-MM-dd');
        AttachmentsToFilesController.runMigrationRemote(json,'byObject',dateSt, dateEn, true);
        
        //sleeps some seconds to give time to the background migration (batch process)
        ATFTestUtils.sleep(SLEEP_AFTER_MIGRATION);
        AttachmentsToFilesController.deleteMigratedByObjectNameRemote('NAMConfig__c',dateSt, dateEn, true);
        List<NAMAttachmentConversionStatus__c> attachmentStatus = AttachmentConversionStatus.findInProgressObjectsDeletion();
        Boolean isInProgress = AttachmentConversionStatus.containsObjectByName(attachmentStatus, 'NAMConfig__c');
        
        //end setup
        Test.stopTest();
        System.assertEquals(true, isInProgress );
        
    }
    
    
    
    
    //test that only already migrated attachments are deleted
    @isTest
    public static void deleteNothing(){
        Test.startTest();
        //setup
        ATFTestUtils.createAttachmentForNAMConfig(30, false, 'sample3');
        string objectName = 'NAMConfig__c';
        //end setup
        String dateSt = Datetime.now().format('yyyy-MM-dd');
        String dateEn = Datetime.now().format('yyyy-MM-dd');
        AttachmentsToFilesController.deleteMigratedByObjectNameRemote(objectName,dateSt, dateEn, true);
        ATFTestUtils.sleep(SLEEP_AFTER_MIGRATION);
        //end setup
        Test.stopTest();
        List <Attachment> attachments = new List <Attachment>();
        attachments = [SELECT Id, Name FROM Attachment];
        System.assertEquals(30, attachments.size());
        
    }
    
    //test error while delete
    @isTest
    public static void deleteError(){
        Test.startTest();
        //setup
        ATFTestUtils.createAttachmentForNAMConfig(50, false, 'sample3');
        List <Attachment> attachments = new List <Attachment>();
        List <Id> attachmentsId = new List <Id>();        
        attachments = [SELECT Id, Name FROM Attachment];
        for(Attachment attachment: attachments){
            attachmentsId.add(attachment.Id);
        }
        //end setup
        DeleteBatch batch = new DeleteBatch('SELECT Id FROM NAMConfig__c','NAMConfig__c');
      //  batch.deleteError = 1;  
        batch.listAttachmentsFail = attachmentsId;
        Id batchId = Database.executeBatch(batch);  
        //end setup
        Test.stopTest();    
        system.assert(batchId != null);
    }    
    
}