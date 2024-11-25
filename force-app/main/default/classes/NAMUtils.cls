/**
* @description contains common code for the three tools: attachment converter, notes converter and update page layout
* @author Jessica Bernal, Dayana Daniel, Andres Canavesi
* @date 2017-10
*/
public class NAMUtils {
    
    public static String DATE_TIME_FORMAT = 'yyyy-MM-dd\'T00:00:00z\'';
    
    public static String SUCCESS_COMMUNITY_GROUP_URL = 'https://success.salesforce.com/_ui/core/chatter/groups/GroupProfilePage?g=0F93A000000LgpS';
    
    public static String APP_EXCHANGE_URL = 'https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000EHAmyUAH';
    
    public static Integer DEFAULT_NOTE_PAGE_SIZE = 100; 
    
    public static Integer DEFAULT_LAST_PAGE_SIZE = 25;
    
    public static Integer DEFAULT_LAST_ATTACHMENTS_PAGE_SIZE = 25;
    
    public static Integer DEFAULT_CONFIG_PAGE_SIZE = 10; 
    
    /**
* @description timeout in millis to get and count records in given date range if we
* do not use this limit we reach out a query limit
*/
    public static Integer LIMIT_TIME_OUT = 12000;//12 seconds
    
    //TODO I think we do not use this contant, otherwise add a comment
    public static Integer NUMBER_ERRORS = 5;
    /**
* @description to warn users to migrate up to this quantity in order to keep inside Salesforce Content Publication limits
*/
    public static Integer ORG_LIMIT_MIGRATE = 100000;
    
    public static Integer LIMIT_QUERIES_OBJECTS = 1000;
    public static Integer DEFAULT_PAGE_SIZE = 10; 
    
    /**
* @description After a successful migration, we rename the attachments with the ContentVersion id (the file created). 
* All migrated attachments start with this pattern. This way we are able to distinguish the migrated attachments
*/
    public static String MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN = '[068%';
    
    /**
* @description a list of supported objects. We also include custom objects
* the tool supports. These objects will be added in nexts releases: 
* 'Emailmessage', '00X', 'Goal', 'Metric', 'WorkCoaching', 'SocialPost'
*/
    public static String[] PARENT_TYPE_GREENS = new String[] {'Account', 'Asset', 'Campaign', 'Case', 'Contact', 'Contract', 'Lead', 'Opportunity', 'Product2', 'Quote', 'Solution', 'Order',  'ServiceContract', 'Entitlement'};
        /**
* @description Event and Task have a different behavior(they have the parent.type blank in the query)
* so we need to work with them in a different way
*/  
        public static String[] OTHER_PARENT_TYPE_GREENS = new String[] {'Event','Task'};
            
        public static String[] OTHER_PARENT_TYPE_GREENS_PREFIX = new String[] {'00U','00T'};
            
            /**
* @description a map with Standard Object Record ID Prefix
*/    
            public static Map<String,String> STANDARD_OBJECT_PREFIX = new Map<String, String> {'00U' => 'Event', '00T' => 'Task'};
                
                /**
* @description enable / disable notes test when enhanced notes are not enabled in the org.
*/    
                public static boolean ENABLE_NOTES_TESTS = true;
    
    /**
* @description to be able to see what version user has installed on the org
*/ 
    public static String PACKAGE_VERSION_NAME = 'V2.5';
    /**
* @description error text from Salesforce when we reach out CPU limit.
*/
    public static String APEX_CPU_LIMIT_TEXT = 'Apex CPU time limit exceeded';
    /**
* @description error text from Salesforce when we reach out heap size limit.
*/
    public static String APEX_HEAP_LIMIT_TEXT = 'heap limit';
    /**
* @description error text from Salesforce when there is a Salesforce internal unmanaged error.
* We faced these type of error when we try to migrate special characters
*/
    public static String INTERNAL_ERROR = 'Internal Salesforce.com Error';
    /**
* @description SOAP API version
*/
    public static String API_VERSION = '41.0';
    
    /**
* @description these objects have not parent type in Attachment object (for some strange reason)
*/
    public static String BLANK_PARENT_TYPES = 'Task and Event';
    
    /**
* @description map to store known conversion errors, to send them in the email to the 
* administrator to suggest a common solution to fix It
*/
    public static Map<String, NAMTroubleshooting> knownMigrationErrors = new Map<String, NAMTroubleshooting>{
        String.valueOf(System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY) => new NAMTroubleshooting(String.valueOf(System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY),
                                                                                                         'There is a trigger in the Content Version that is failing.',
                                                                                                         'Disable the trigger during migration.'),
            String.valueOf(System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) => new NAMTroubleshooting(String.valueOf(System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION),
                                                                                                          'There is a validation rule in the Content Version.',
                                                                                                          'Disable that validation rule during migration.'),
            String.valueOf(System.StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION) => new NAMTroubleshooting(String.valueOf(System.StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION),
                                                                                                          'There is a filter validation in the Content Version.',
                                                                                                          'Disable that filter validation during migration.'),
            String.valueOf(System.StatusCode.REQUIRED_FIELD_MISSING) => new NAMTroubleshooting(String.valueOf(System.StatusCode.REQUIRED_FIELD_MISSING),
                                                                                               'There is a field required in the Content Version.',
                                                                                               'Make that field not required during migration.'),
            String.valueOf(System.StatusCode.STORAGE_LIMIT_EXCEEDED) => new NAMTroubleshooting(String.valueOf(System.StatusCode.STORAGE_LIMIT_EXCEEDED),
                                                                                               'The org has reached the storage limit.',
                                                                                               'Delete migrated attachments to  free up space.')};
                                                                                                   
                                                                                                   
                                                                                                   /**
* @description 
* @return a list of all custom objects in the org
*/ 
                                                                                                   public static String[] getCustomObject(){
                                                                                                       
                                                                                                       String[]  stdObjectNames = new String[]{};
                                                                                                           for ( Schema.SObjectType typ : Schema.getGlobalDescribe().values() ) {
                                                                                                               if (typ.getDescribe().isCustom()) {
                                                                                                                   stdObjectNames.add(String.valueOf(typ));
                                                                                                               }
                                                                                                           }
                                                                                                       return stdObjectNames;
                                                                                                   }
    
    /**
* TODO move this method to MetadataController
* @desccription TODO
* @return true if... TODO
*/
    public static Boolean countLayouts(Integer limitQuery,Integer Offset){
        Boolean moreLayouts = false;
        if (Test.isRunningTest()) {
            //We can't do callout during testing, so we mock them
            Test.setMock(HTTPCalloutMock.class, new NMTRetrieveMetadataMock());
        }
        HttpRequest req=new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('content-Type','application/json');
        string domainUrl=URL.getSalesforceBaseUrl().toExternalForm();
        req.setEndpoint(domainUrl+'/services/data/v'+NAMUtils.API_VERSION+'/tooling/query/?q=Select+EntityDefinitionId,+EntityDefinition.DeveloperName,+Name+from+Layout+Where+EntityDefinition.QualifiedApiName+LIKE+\'%25__c\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Lead%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Account%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Asset%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Contact%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Opportunity%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Contract%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Order%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Goal%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Metric%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'Idea%25\'+OR+EntityDefinition.QualifiedApiName+LIKE+\'WorkAccess%25\'+order+by+Name+limit+'+limitQuery+'+OFFSET+'+Offset);
        req.setMethod('GET');
        Http h=new Http();
        HttpResponse res=h.send(req);
        if(res.getStatusCode()==200){
            moreLayouts = newPageLayouts(res.getBody());
        }
        return moreLayouts;
    }
    
    /**
* 
* @desccription TODO
* @return true if... TODO
*/
    public static Boolean isPendingNotesToBeConverted(){
        Boolean pendingNotes = false;
        List<NMTSObjectWrapperNotes> quantities = new List<NMTSObjectWrapperNotes>();
        List<NMTSObjectWrapperNotes> migratedquantities = new List<NMTSObjectWrapperNotes>();
        List<List<NMTSObjectWrapperNotes>> notesresults = new List<List<NMTSObjectWrapperNotes>>();
        // String[] customobjects = getCustomObject();
        for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Title) Quantity
                                        FROM Note 
                                        GROUP BY Parent.Type
                                        ORDER BY Parent.Type ASC
                                        LIMIT :LIMIT_QUERIES_OBJECTS]){
                                            for (AggregateResult ar : results) {
                                                Integer migrated = countPublicNotesMigratedPerObjectMetadata((String)ar.get('ObjectName'));
                                                Integer unmigrated = (Integer)ar.get('Quantity')-migrated;
                                                if(unmigrated>0){
                                                    return true;
                                                }
                                            }
                                            
                                        }
        return pendingNotes;
    }
    
    /**
*  TODO move this method to MetadataController
* @desccription TODO
* @return true if... TODO
*/
    public static Boolean newPageLayouts(String jsonStr){
        List<String> layoutsNameAux = new List<String>(); 
        NMTMetadataLayout.Layout2 r = NMTMetadataLayout.parse(jsonStr);
        List<NMTMetadataLayout.Records> records = r.records;
        List<String> results = new List<String>();
        for(NMTMetadataLayout.Records record: records){
            String text = '';
            String tempText = record.EntityDefinitionId;
            // First, instantiate a new Pattern object "MyPattern"
            Pattern MyPattern = Pattern.compile('([a-zA-Z0-9]{18}?|[a-zA-Z0-9]{15}?)');
            
            // Then instantiate a new Matcher object "MyMatcher"
            Matcher MyMatcher = MyPattern.matcher(tempText);
            
            if(MyMatcher.matches()&& record.EntityDefinition!=null){
                layoutsNameAux.add(record.EntityDefinition.DeveloperName+'__c');
            }
            else{
                layoutsNameAux.add(tempText);
            }
        }
        return layoutsNameAux.size() > 0;
    }
    
    /**
* @description Used for csv column is Private
* @param isPrivate
* @return 'Yes' or 'No' depending on isPrivate param
*/
    public static String isPrivateResult (Boolean isPrivate){
        if(isPrivate){
            return 'Yes';
        } else {
            return 'No';
        }
    }
    
    /**
* @description 
* @param theLimit this value wil be 100 always because the pagination is complicated
* The first query that we paginate is over Legacy Notes, converted or not
* @param theOffset 
* @param startdate 
* @param endDate 
* @param byCreateDate false we want to count public notes by LastModifiedDate 
* @return
*/
    public static List<List<NMTSObjectWrapperNotes>> countPublicNotesPerObject(Integer theLimit, 
                                                                               Integer theOffset, 
                                                                               Date startdate, 
                                                                               Date endDate, 
                                                                               Boolean byCreateDate){
                                                                                   List<NMTSObjectWrapperNotes> quantities = new List<NMTSObjectWrapperNotes>();
                                                                                   List<NMTSObjectWrapperNotes> migratedquantities = new List<NMTSObjectWrapperNotes>();
                                                                                   List<List<NMTSObjectWrapperNotes>> notesresults = new List<List<NMTSObjectWrapperNotes>>();
                                                                                   Time firstTime = Time.newInstance(0, 0, 0, 0);
                                                                                   Time endTime = Time.newInstance(23, 59, 59, 0);
                                                                                   DateTime dtstart = DateTime.newInstance(startDate,firstTime);
                                                                                   DateTime dtend = DateTime.newInstance(endDate,endTime);
                                                                                   
                                                                                   if(byCreateDate){
                                                                                       for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Title) Quantity
                                                                                                                       FROM Note 
                                                                                                                       WHERE createdDate >= :dtstart
                                                                                                                       AND createdDate <= :dtend
                                                                                                                       GROUP BY Parent.Type
                                                                                                                       ORDER BY Parent.Type ASC
                                                                                                                       LIMIT :theLimit
                                                                                                                       OFFSET :theOffset]){
                                                                                                                           
                                                                                                                           for (AggregateResult ar : results) {
                                                                                                                               Integer migrated = countPublicNotesMigratedPerObject((String)ar.get('ObjectName'), dtstart, dtend, byCreateDate);
                                                                                                                               if(migrated==null){
                                                                                                                                   migrated = 0;
                                                                                                                               }
                                                                                                                               Integer unmigrated = (Integer)ar.get('Quantity')-migrated;
                                                                                                                               if(unmigrated>0){
                                                                                                                                   quantities.add(new NMTSObjectWrapperNotes(ar, unmigrated));
                                                                                                                               }
                                                                                                                               if(migrated>0){
                                                                                                                                   migratedquantities.add(new NMTSObjectWrapperNotes(ar, migrated));
                                                                                                                               }
                                                                                                                           }
                                                                                                                       }
                                                                                   } else {
                                                                                       for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Title) Quantity
                                                                                                                       FROM Note 
                                                                                                                       WHERE lastModifiedDate >= :dtstart
                                                                                                                       AND lastModifiedDate <= :dtend
                                                                                                                       GROUP BY Parent.Type
                                                                                                                       ORDER BY Parent.Type ASC
                                                                                                                       LIMIT :theLimit
                                                                                                                       OFFSET :theOffset]){
                                                                                                                           
                                                                                                                           for (AggregateResult ar : results) {
                                                                                                                               Integer migrated = countPublicNotesMigratedPerObject((String)ar.get('ObjectName'), dtstart, dtend, byCreateDate);
                                                                                                                               if(migrated==null){
                                                                                                                                   migrated = 0;
                                                                                                                               }
                                                                                                                               Integer unmigrated = (Integer)ar.get('Quantity')-migrated;
                                                                                                                               if(unmigrated>0){
                                                                                                                                   quantities.add(new NMTSObjectWrapperNotes(ar, unmigrated));
                                                                                                                               }
                                                                                                                               if(migrated>0){
                                                                                                                                   migratedquantities.add(new NMTSObjectWrapperNotes(ar, migrated));
                                                                                                                               }
                                                                                                                           } 
                                                                                                                       }
                                                                                   }
                                                                                   notesresults.add(quantities);
                                                                                   notesresults.add(migratedquantities);
                                                                                   return notesresults;
                                                                               } 
    
    /**
* @description	
* @return 
*/
    public static Integer countPublicNotesMigratedPerObjectMetadata(String ObjectName){
        //This is because of a null pointer exception that we can't reproduce.  
        //I think that it could be because a note's parent.type is null.
        if(ObjectName!=null){
            String query = 'SELECT count() from contentDocumentLink where linkedEntityId in (Select id from ';
            query+=String.escapeSingleQuotes(ObjectName);
            query+=') And contentDocument.latestPublishedVersion.LegacyNoteConvertedId__c != null';
            integer count= database.countQuery(query);
            return count;
        }
        return 0;
    }
    
    /**
* @description	the same by date
*/
    public static Integer countPublicNotesMigratedPerObject(String ObjectName, DateTime startDate, DateTime endDate, Boolean byCreateDate){
        //This is because of a null pointer exception that we can't reproduce.  
        //I think that it could be because a note's parent.type is null.
        if(ObjectName!=null){
            String startMonth = String.valueOf(startDate.month());
            if(startMonth.length()==1){
                startMonth = '0'+startMonth;
            }
            
            String startDay = String.valueOf(startDate.day());
            if(startDay.length()==1){
                startDay = '0'+startDay;
            }
            
            String endMonth = String.valueOf(endDate.month());
            if(endMonth.length()==1){
                endMonth = '0'+endMonth;
            }
            
            String endDay = String.valueOf(endDate.day());
            if(endDay.length()==1){
                endDay = '0'+endDay;
            }
            String sstart = startDate.year()+'-'+startMonth+'-'+startDay;
            String send = endDate.year()+'-'+endMonth+'-'+endDay;
            System.debug('send:'+send);
            String query = 'SELECT count() from contentDocumentLink where linkedEntityId in (Select id from ';
            query+=String.escapeSingleQuotes(ObjectName) + ') ';
            if(byCreateDate){
                query+=' And contentDocument.latestPublishedVersion.LegacyNoteConvertedId__c != null And contentDocument.latestPublishedVersion.LegacyNoteConvertedDate__c >= ';
                query+=sstart;
                query+=' and contentDocument.latestPublishedVersion.LegacyNoteConvertedDate__c <= ';
                query+=send;
                query+=' ';
                
            } else {
                query+=' And contentDocument.latestPublishedVersion.LegacyNoteConvertedId__c != null And contentDocument.latestPublishedVersion.LegacyNoteConvertedLastModifiedDate__c  >= ';
                query+=sstart;
                query+=' and contentDocument.latestPublishedVersion.LegacyNoteConvertedLastModifiedDate__c  <= ';
                query+=send;
                query+=' ';
            }
            
            system.debug('query countPublicNotesMigratedPerObject:');
            system.debug(query);
            integer count= database.countQuery(query);
            return count;
        }
        return 0;
    }
    
    /**
* @description 
* @throws NAMForbiddenException if the user has not enough permissions on objects and fields we need during conversion
*/
    public static void validatePermissions(){
        Id userProfileId = UserInfo.getProfileId(); 
        List<Profile> profilePermissionsModifyAllData = [SELECt id, PermissionsModifyAllData 
                                                         FROM Profile 
                                                         WHERE id = :userProfileId limit 1];
        if(profilePermissionsModifyAllData.size() ==0 ||!profilePermissionsModifyAllData.get(0).PermissionsModifyAllData){
            throw new NAMForbiddenException('You don’t have permission ‘Modify All Data’. Ask your Salesforce admin for help.');          
        }
        if(!Schema.sObjectType.ContentVersion.fields.CreatedDate.isCreateable()
           ||!Schema.sObjectType.ContentVersion.fields.CreatedById.isCreateable()){
               throw new NAMForbiddenException('You don’t have permission to access these fields on ContentVersion. Ask your Salesforce admin for help.');
           }
        if(!Schema.sObjectType.NAMNoteConversionStatus__c.fields.Status__c.isCreateable()
           || !Schema.sObjectType.NAMNoteConversionStatus__c.fields.Status__c.isUpdateable()
           || !Schema.sObjectType.NAMNoteConversionStatus__c.isDeletable()
           || !Schema.sObjectType.NAMNoteConversionStatus__c.fields.JobId__c.isCreateable()
           || !Schema.sObjectType.NAMNoteConversionStatus__c.fields.JobId__c.isUpdateable()
           || !Schema.sObjectType.NAMNoteConversionStatus__c.fields.Type__c.isCreateable()
           || !Schema.sObjectType.NAMNoteConversionStatus__c.fields.Type__c.isUpdateable() ){
               throw new NAMForbiddenException('You don’t have permission to access these fields on NAMNoteConversionStatus__c. Ask your Salesforce admin for help.');
               
           }
        if(!Schema.sObjectType.ContentDocumentLink.fields.ContentDocumentId.isCreateable()
           || !Schema.sObjectType.ContentDocumentLink.fields.LinkedEntityId.isCreateable()
           || !Schema.sObjectType.ContentDocumentLink.fields.ShareType.isCreateable()
           || !Schema.sObjectType.ContentDocumentLink.fields.ShareType.isUpdateable()){
               throw new NAMForbiddenException('You don’t have permission to access these fields on ContentDocumentLink. Ask your Salesforce admin for help.');
               
           } 
        if(!Schema.sObjectType.ContentVersion.fields.LegacyNoteConvertedId__c.isCreateable()
           || !Schema.sObjectType.ContentVersion.fields.LegacyNoteConvertedId__c.isUpdateable()){
               throw new NAMForbiddenException('You don’t have permission to access these fields on ContentVersion - LegacyNoteConvertedId__c. Ask your Salesforce admin for help.');
               
           }   
    }
    
    /**
* @description 
* @param objectIds
* @param mapMigration
* @return TODO... the key represnets... and the value represents...
*/
    public static Map<String,String> validateEnteredObjectIDs(List<Id> objectIds, Map<String,String> mapMigration){
        String idString = '';
        for(Id objectId : objectIds){
            Schema.SObjectType sobjectType = objectId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            try{
                SObject record = Database.query('Select Id, Name From ' + sobjectName + ' Where Id = :objectId');
                if(record != null && sobjectName != 'Attachment' && sobjectName != 'Note'){
                    idString= objectId;
                    if(idString.length() == 18){
                        mapMigration.remove(idString.substring(0, 15));
                    } 
                    mapMigration.remove(idString);
                } 
            } catch(Exception e){
                //TODO we chould even throw a custom exception or remove this try-catch block
                //TODO if we throw an exception the error should contain '...verify you have permissions on :sobjectName'
                system.debug('Exception: ' + e.getMessage());
            }
        } 
        return mapMigration;
    } 
    
    /**
* @description
* @return
* @param objectIds
* @param mapMigration
* @param isAttachment
*/
    public static Map<String,String> validateNoRecordsObjectIDs(List<Id> objectIds, 
                                                                Map<String,String> mapMigration, 
                                                                Boolean isAttachment){
                                                                    String idString = '';
                                                                    if(isAttachment){
                                                                        for(Id objectId : objectIds){
                                                                            List<Attachment> valid = [SELECT Id FROM Attachment WHERE ParentId = :objectId LIMIT 1];
                                                                            if(!valid.isEmpty()){
                                                                                idString= objectId;
                                                                                if(idString.length() == 18){
                                                                                    mapMigration.remove(idString.substring(0, 15));
                                                                                } 
                                                                                mapMigration.remove(idString);
                                                                            }
                                                                        } 
                                                                        
                                                                    } else {
                                                                        for(Id objectId : objectIds){
                                                                            List<Note> valid = [SELECT Id FROM Note WHERE ParentId = :objectId LIMIT 1];
                                                                            if(!valid.isEmpty()){
                                                                                idString= objectId;
                                                                                if(idString.length() == 18){
                                                                                    mapMigration.remove(idString.substring(0, 15));
                                                                                } 
                                                                                mapMigration.remove(idString);
                                                                            }
                                                                        } 
                                                                    }
                                                                    return mapMigration;
                                                                } 
    /**
* @description 
* @return
*/
    public static Map<String,String> validateEnteredIDs(List<Id> idsToMigrate, Map<String,String> mapMigration, boolean isAttachment){
        if(isAttachment){
            List<Attachment> valid = [SELECT Id FROM Attachment WHERE Id IN :idsToMigrate LIMIT :LIMIT_QUERIES_OBJECTS];
            for(Attachment idToMigrate : valid){
                String idString= idToMigrate.Id;
                if(idString.length() == 18){
                    mapMigration.remove(idString.substring(0, 15));
                } 
                mapMigration.remove(idString);
            } 
            
        } else {
            List<Note> valid = [SELECT Id FROM Note WHERE Id IN :idsToMigrate LIMIT :LIMIT_QUERIES_OBJECTS];
            for(Note idToMigrate : valid){
                String idString= idToMigrate.Id;
                if(idString.length() == 18){
                    mapMigration.remove(idString.substring(0, 15));
                } 
                mapMigration.remove(idString);
            }  
        }
        
        return mapMigration;
    } 
    
    /**
* @description Some special characters are not supported in enhanced notes.
* It cleans up some special characters from the note body. 
* Most of the cases It replaces by an empty character
* @param noteBody the raw note body
* @return the note body without special characters
*/
    public static String cleanUpNoteBody(String noteBody){
        
        // per Salesforce we must escape certain special characters
        // logic inspired by David Reed (http://www.ktema.org//2016/08/24/importing-notes-into-salesforce/)
        // https://help.salesforce.com/apex/HTViewSolution?id=000230867&language=en_US
        // https://douglascayers.com/2015/10/10/salesforce-convert-attachments-to-chatter-files/
        String body = ( String.isBlank( noteBody ) ? '<p></p>' : noteBody )
            // the escape entity for '&' is '&amp;'
            // so it includes '&' in its own escape sequence, which is a problem
            // because escapeXml() changes '&' to '&amp;' as well
            // so a single '&' would become '&amp;amp;'
            // therefore we first find any normal '&'
            // and replace them with a token value that will
            // be later replaced with '&amp;'
            .replaceAll('&', 'sfdcAMPERSANDsfdc')
            .escapeXml()
            .replaceAll('sfdcAMPERSANDsfdc', '&amp;')
            // handle nitpick on apostrophe html entity
            .replaceAll('&apos;', '&#39;')
            // handle known unsupported non-ascii characters
            // oddly, other symbols like ® ™ are ok unescaped
            .replaceAll('©', '&copy;')
            // handle new lines
            .replaceAll('\r\n', '<br>')
            .replaceAll('\r', '<br>')
            .replaceAll('\n', '<br>')
            .replaceAll('\u2028', '<br>')
            .replaceAll('\u2029','<br>')
            .replaceAll('','')
            .replaceAll('\uFFFD','')
            //handle controls
            .replaceAll('[\\x7F-\\x9F\\x00-\\x1F]','')
            .replaceAll('[\\uD800-\\uDFFF]','');
        
        //'[\\uD800-\\uDFFF]' To remove emojis that may cause internal error when trying to convert
        
        
        // content version cannot have a null or empty string body
        // so set to empty paragraph which will appear as blank note.
        // we do this after escaping the original note body otherwise
        // the <p> tag would get escaped
        if ( String.isBlank( body ) ) {
            body = '<p></p>';
        }
        
        //keep html tags
        body = body.replace('&lt;p&gt;&lt;/p&gt;', '<p></p>');
        return body;
    }
    
    /**
* TODO move this to NMTNotesMigrationController
* @description
* @param notes all notes in the batch
* @param totalToMigrateBatch
* @return the notes to be migrated
*/
    public static List<Note> filterNotesToMigrate(List<Note> notes, Integer totalToMigrateBatch){
        List<Note> notesToMigrate = new List<Note>();
        List<String> notesParentsIds = new List<String>();
        List<String> notesIds = new List<String>();
        for(Note note :notes){
            notesIds.add(String.valueOf(note.Id));
            notesParentsIds.add(String.valueOf(note.ParentId));
        }
        
        //look for notes already converted
        //we cannot query from ContenVersion because we cannot access to them if not the owner (although if I am admin)
        List<ContentDocumentLink> notesContentDocumentLinks = [SELECT contentDocument.latestPublishedVersion.id, contentDocument.latestPublishedVersionId,
                                                               contentDocument.latestPublishedVersion.LegacyNoteConvertedId__c
                                                               FROM
                                                               ContentDocumentLink
                                                               WHERE
                                                               linkedEntityId in :notesParentsIds
                                                               AND
                                                               contentDocument.latestPublishedVersion.LegacyNoteConvertedId__c in :notesIds]; 
        
        for(Note note :notes){
            boolean add = true;
            //look if the note was already migrated
            for(ContentDocumentLink cl: notesContentDocumentLinks){
                if(String.valueOf(note.Id) == cl.contentDocument.latestPublishedVersion.LegacyNoteConvertedId__c){
                    add = false;
                    break;
                } 
            } 
            if(add && notesToMigrate.size() < totalToMigrateBatch){
                notesToMigrate.add(note);
            }
        }
        return notesToMigrate;
    }
    
    /**
* @description this method is used in MetadataController and NotesMigrationController to know if the org has Enhanced Notes enabled
* @param address 
* @param subject 
* @param body 
*/
    public static boolean isEnhancedNotesEnabled(){
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        return gd.containsKey('ContentNote');
    }
    
    /**
* @description 
* @return  
*/
    public static Boolean isPendingAttachmentsToBeConverted (){
        String[] customobjects = getCustomObject();
        List<Attachment> quantities = new List<Attachment>();
        if(NAMConfigs.getEnableBodyLength()){
            Integer bodyLengthValue = NAMConfigs.getBodyLength() * 1024 * 1024; 
            quantities = [SELECT id
                          FROM Attachment 
                          WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                          AND bodyLength != 0
                          AND bodyLength <= :bodyLengthValue
                          AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                          LIMIT 1];
            
        } else {
            quantities = [SELECT id
                          FROM Attachment 
                          WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                          AND bodyLength != 0
                          AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                          LIMIT 1];
            
        }
        return quantities.size() > 0;
    } 
    
    
    
    /*
* @description send an email after the migration completes to the user that request it
*/
    public static void emailSetupAndSend(Boolean isAttachments, String objectName, List<NAMMigrationResults> migrationResults, Integer totalFiles, Boolean limitError, Boolean storage, Integer objectsToBeMigrated, Integer totalFilesFailed, List<String> listIds, String limitMessage){  
        String objectOfMigration;
        if(isAttachments){
            objectOfMigration = 'attachment';
        } else {
            objectOfMigration = 'note';
        }
        String subjectEmail = 'Your '; 
        if(objectName != null){
            subjectEmail += objectName + ' ';
        }
        subjectEmail += objectOfMigration + ' conversion job has completed';
        String signature = '<br/><br/><br/>Salesforce';
        String footer = 'You’re registered as '+UserInfo.getUserEmail()+' in the Salesforce org '+UserInfo.getOrganizationName()+'. Need help? Contact Salesforce Support. <br/>Package Version ' + PACKAGE_VERSION_NAME + '.';
        String name = UserInfo.getFirstName();
        String emailReport = '';
        if(name != null){
            emailReport = '<p>Hello '+UserInfo.getFirstName()+',</p>';
        }else{
            emailReport = '<p>Hello '+UserInfo.getLastName()+',</p>';
        }        
        
        if(totalFilesFailed > 0 || limitError || storage){
            if(limitError){ 
                subjectEmail = 'Your ';
                if(objectName != null){
                    subjectEmail += objectName + ' ';  
                }
                subjectEmail += objectOfMigration + ' conversion job has completed, but you exceeded your daily limit. Please open for errors.';
            } else{
                
                if(storage){
                    subjectEmail = 'Your '+ objectName + ' ' + objectOfMigration + ' conversion job has completed, but you exceeded your storage limit. Please open for errors.';
                } else{
                    subjectEmail = 'Your '+ objectName + ' ' + objectOfMigration + ' conversion job has completed. Please open for errors.';             
                }
            }    
        }
        
        if(objectsToBeMigrated > 0){
            emailReport += '<div>The conversion of ';
            if(objectName != null){
                emailReport +=objectName + ' ';
            }
            if(isAttachments){
                emailReport += 'attachments to Salesforce Files is complete.<br/>';
            } else {
                emailReport += 'Classic notes to Enhanced notes is complete.<br/>';
            }
            
            if(totalFiles == objectsToBeMigrated){
                emailReport += 'Number of ' + objectOfMigration + 's to convert: ' + objectsToBeMigrated + '<br/>'+
                    + 'Number of ' + objectOfMigration + 's converted: ' + totalFiles + '<br/>'+
                    + 'Number of errors: ' + totalFilesFailed + '<div>';
                if(isAttachments){
                    emailReport += '<p>Since they are converted to files, these attachments can now be deleted.</p>';
                } else {
                    emailReport += '<p>Since they are converted to Enhanced notes, these Classic notes can now be deleted.</p>'; 
                }
                
            }else{
                if(limitError){
                    emailReport += 'Number of '+ objectOfMigration + 's converted: ' + totalFiles + '<br/>';
                    emailReport += '<p>Your org has exceeded at least one daily limit, such as content publication limits or Apex limits.' 
                        +'Please contact Salesforce support to resolve this issue. The limit will reset after 24 hours.<p>';
                    if(limitMessage!=null&&String.isNotBlank(limitMessage)&&String.isNotEmpty(limitMessage)){
                        emailReport +='<br/><br/>'
                            +'<b>Apex Job Status Message:</b> '+limitMessage;
                        if(limitMessage.toLowerCase().contains(APEX_CPU_LIMIT_TEXT.toLowerCase())){
                            if(!NAMConfigs.getEnableDynamicBatchSize()&&NAMConfigs.getBatchSizeForAttachments()>NAMConfigs.getMinBatchSize()){
                                emailReport +='<br/><br/>'
                                    +'Migration used '+NAMConfigs.getBatchSizeForAttachments()+' batch size. Set a smaller batch size or enable the dynamic batch size in the configuration page.';
                            }else{
                                emailReport +='<br/><br/>'
                                    +'Migration used the minimum batch size. You may have a large record that the tool cannot migrate, please review and migrate it manually.';
                            }
                        }
                    }
                }else{
                    if(storage){
                        emailReport += 'Number of '+ objectOfMigration + 's converted: ' + totalFiles + '<br/>';
                        emailReport += '<p>Some '+ objectOfMigration + 's could not be converted because your org has exceeded the storage limit. '
                            +'Delete converted '+ objectOfMigration + 's or other files to free up storage space. '
                            +'<a href="https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_overview.htm"  target = "_blank">See Salesforce Files Limits </a></p>';
                    }else{
                        emailReport += 'Number of ' + objectOfMigration + 's to convert: ' + objectsToBeMigrated + '<br/>'+
                            + 'Number of ' + objectOfMigration + 's converted: ' + totalFiles + '<br/>'+
                            + 'Number of errors: ' + totalFilesFailed + '<div>';
                        
                        //to log errors
                        Set<NAMTroubleshooting> errors = new Set<NAMTroubleshooting>();
                        for(NAMMigrationResults result: migrationResults){
                            String[] statusCode = result.ErrorMessage.split(':');
                            if(!statusCode.isEmpty()&&knownMigrationErrors.containsKey(statusCode[0]))
                            {
                                NAMTroubleshooting newtroubleshooting = knownMigrationErrors.get(statusCode[0]);
                                errors.add(newtroubleshooting);
                            }
                        }
                        
                        if(!errors.isEmpty()){
                            emailReport += '<div><br/><br/>We found these errors:<br/><br/>';
                            for(NAMTroubleshooting error: errors){
                                emailReport +='<b>'+error.errorCode+'</b>: '+error.cause+' '+error.solution+'<br/><br/>';
                            }
                            emailReport += 'Open the csv file to see more details.<br/>'
                                +'<a href="https://appexchange.salesforce.com/servlet/servlet.FileDownload?file=00P3A00000aB532UAC"  target = "_blank">Learn More</a></div>';
                            
                        }
                    } 
                }
            }  
        } else{
            if(objectsToBeMigrated == 0 ){
                if(listIds != null){
                    emailReport += '<br/>We can\'t find the ' + objectOfMigration + 's or Objects with the following ids, ' + objectOfMigration + 's were deleted OR already migrated:<br/>';
                    emailReport += '<p>'+ listIds +'<p><br/>';
                }else if(objectName!=null){
                    if(isAttachments){
                        emailReport += '<br/>We can\'t find Attachments in '+ objectName +' object, ' + objectOfMigration + 's were deleted OR already migrated:<br/>';
                        
                    } else {
                        emailReport += '<br/>We can\'t find Notes in '+ objectName +' object, ' + objectOfMigration + 's were deleted OR already migrated:<br/>';
                        
                    }
                }
            }
        }
        //send an email to the user with the result of the migration.
        NAMUtils.sendMailWithCSV(UserInfo.getUserId(), subjectEmail, emailReport, signature, footer, migrationResults, isAttachments, false);
    }
    
    /**
* @description 
* @param address 
* @param subject 
* @param body 
* @param signature 
* @param footer 
* @param migrationResults
*/
    public static void sendMailWithCSV(Id address, String subject, String body, String signature, String footer, List<NAMMigrationResults> migrationResults, Boolean isAttachments, Boolean isDeleteProcess) {
        system.debug('migrationResults ' + migrationResults.size());
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setTargetObjectId(address);
        system.debug(address);
        mail.saveAsActivity = false;
        mail.setSubject(subject);
        String bodyemail = '<html><head></head><body>' + body +'<div><br/>' + signature +'<div><br/>' + '<footer>' + footer + '</footer></body></html>';
        system.debug('bodyemail');
        system.debug(bodyemail);
        
        mail.setHtmlBody(bodyemail);
        
        if(migrationResults!=null && migrationResults.size()>0){
            string header;
            if(isDeleteProcess){
                if(isAttachments){
                    header = 'Attachment Id, Name, Is Private, Status, Error Description \n';   
                } else {
                    header = 'Classic Note Id, Title, Is Private, Status, Error Description \n';
                }
                
            } else {
                
                if(isAttachments){
                    header = 'Attachment Id, File Id , Is Private, Status, Error Description \n';   
                } else {
                    header = 'Classic Note Id, Enhanced Note Id , Is Private, Status, Error Description \n';
                }
                
            }
            string finalstr = header ;
            for(NAMMigrationResults migrationResult: migrationResults)
            {
                
                string recordString = migrationResult.OldId+','+migrationResult.NewId+','+migrationResult.IsPrivate+','+migrationResult.Status+','+migrationResult.ErrorMessage +'\n';
                finalstr = finalstr +recordString;  
                
            }
            system.debug(finalstr);
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(finalstr);
            string csvname;
            if(isAttachments){
                csvname= 'AttachmentMigration.csv';
            } else {
                csvname= 'NotesMigration.csv';
            }
            
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
            
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            
        }
        
        // Pass this email message to the built-in sendEmail method 
        // of the Messaging class
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { mail });
        
        // Call a helper method to inspect the returned results
        inspectResults(results);
    }
    
    /**
* @description 
* @param results 
* @return
*/
    private static Boolean inspectResults(Messaging.SendEmailResult[] results) {
        Boolean sendResult = true;
        
        // sendEmail returns an array of result objects.
        // Iterate through the list to inspect results. 
        // In this class, the methods send only one email, 
        // so we should have only one result.
        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                System.debug('Email sent successfully.');
            }
            else {
                sendResult = false;
                System.debug('[Email] The following errors occurred: ' + res.getErrors());                 
            }
        }
        return sendResult;
    }
    
    /**
* @description 
* @return  
*/
    public static Integer countTotalPublicUnmigratedAttachmentsPerObject(Date startdate, Date endDate, Boolean byCreateDate){
        
        List<SObjectWrapper> quantities = new List<SObjectWrapper>();
        String[] customobjects = getCustomObject();
        Time firstTime = Time.newInstance(0, 0, 0, 0);
        Time endTime = Time.newInstance(23, 59, 59, 0);
        
        DateTime dtstart = DateTime.newInstance(startDate,firstTime);
        DateTime dtend = DateTime.newInstance(endDate,endTime);
        if(NAMConfigs.getEnableBodyLength()){
            Integer bodyLengthValue = NAMConfigs.getBodyLength() * 1024 * 1024; 
            if(byCreateDate){
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND bodyLength <= :bodyLengthValue
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow);
                        }
                    }                          
                }
                
            } else {
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND bodyLength <= :NAMConfigs.getBodyLength()
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow);
                        }
                    }                          
                }
                
            }
            
        }  else {
            if(byCreateDate){
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow);
                        }
                    }                          
                }
                
            } else {
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow);
                        }
                    }                          
                }
                
            }
            
        }
        return quantities.size();
    } 
    
    /**
* @description 
* @return
*/
    public static Integer countTotalMigratedAttachmentsPerObject(Date startdate, Date endDate, Boolean byCreateDate){
        
        List<ObjectCount> quantities = new List<ObjectCount>();
        Time firstTime = Time.newInstance(0, 0, 0, 0);
        Time endTime = Time.newInstance(23, 59, 59, 0);
        
        DateTime dtstart = DateTime.newInstance(startDate,firstTime);
        DateTime dtend = DateTime.newInstance(endDate,endTime);
        
        if(NAMConfigs.getEnableBodyLength()){
            Integer bodyLengthValue = NAMConfigs.getBodyLength() * 1024 * 1024; 
            if(byCreateDate){
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results  :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :bodyLengthValue
                                                 GROUP BY Parent.Type
                                                 LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                     
                                                     for (AggregateResult ar : results) {
                                                         String objectType = (String) ar.get('ObjectName');
                                                         if(objectType != null && !objectType.equals('')){
                                                             ObjectCount oc = new ObjectCount(ar);
                                                             quantities.add(oc);
                                                         }
                                                     }
                                                 }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc);
                        }
                    }                          
                }
            } else {
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results  :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 GROUP BY Parent.Type
                                                 LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                     
                                                     for (AggregateResult ar : results) {
                                                         String objectType = (String) ar.get('ObjectName');
                                                         if(objectType != null && !objectType.equals('')){
                                                             ObjectCount oc = new ObjectCount(ar);
                                                             quantities.add(oc);
                                                         }
                                                     }
                                                 }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc);
                        }
                    }                          
                }
                
            }
            
            
        } else{
            
            if(byCreateDate){
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results  :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend
                                                 AND bodyLength != 0
                                                 GROUP BY Parent.Type
                                                 LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                     
                                                     for (AggregateResult ar : results) {
                                                         String objectType = (String) ar.get('ObjectName');
                                                         if(objectType != null && !objectType.equals('')){
                                                             ObjectCount oc = new ObjectCount(ar);
                                                             quantities.add(oc);
                                                         }
                                                     }
                                                 }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc);
                        }
                    }                          
                }
            } else {
                //LIMIT we assume that there are not more than 1000 objects in the org
                for(AggregateResult[] results  :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend
                                                 AND bodyLength != 0
                                                 GROUP BY Parent.Type
                                                 LIMIT :LIMIT_QUERIES_OBJECTS]){
                                                     
                                                     for (AggregateResult ar : results) {
                                                         String objectType = (String) ar.get('ObjectName');
                                                         if(objectType != null && !objectType.equals('')){
                                                             ObjectCount oc = new ObjectCount(ar);
                                                             quantities.add(oc);
                                                         }
                                                     }
                                                 }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc);
                        }
                    }                          
                }
                
            }
        }
        return quantities.size();
    } 
    
    /**
* @description 
* @param theLimit 
* @param theOffset
* @return example: [{Account, 22}, {Contact, 38}, {Lead,18}] where the number represents the quantity 
* of migrated public attachments for that object
*/
    public static List<ObjectCount> countMigratedAttachmentsPerObject(Integer theLimit, Integer theOffset, Date startdate, Date endDate, Boolean byCreateDate){
        
        List<ObjectCount> quantities = new List<ObjectCount>();
        Map<String, ObjectCount> types = new Map<String, ObjectCount>();
        String[] customobjects = getCustomObject();
        
        Time firstTime = Time.newInstance(0, 0, 0, 0);
        Time endTime = Time.newInstance(23, 59, 59, 0);
        
        DateTime dtstart = DateTime.newInstance(startDate,firstTime);
        DateTime dtend = DateTime.newInstance(endDate,endTime);
        if(NAMConfigs.getEnableBodyLength()){
            Integer bodyLengthValue = NAMConfigs.getBodyLength() * 1024 * 1024; 
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND bodyLength <= :bodyLengthValue
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                GROUP BY Parent.Type
                                                LIMIT :thelimit
                                                OFFSET :theOffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        String objectType = (String) ar.get('ObjectName');
                                                        if(objectType != null && !objectType.equals('')){
                                                            ObjectCount oc = new ObjectCount(ar);
                                                            quantities.add(oc);
                                                        }
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(oc);   
                            }
                        }
                    }                          
                }
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND bodyLength <= :NAMConfigs.getBodyLength()
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                GROUP BY Parent.Type
                                                LIMIT :thelimit
                                                OFFSET :theOffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        String objectType = (String) ar.get('ObjectName');
                                                        if(objectType != null && !objectType.equals('')){
                                                            ObjectCount oc = new ObjectCount(ar);
                                                            quantities.add(oc);
                                                        }
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(oc);   
                            }
                        }
                    }                          
                }
                
            }
            
        } else{
            
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                GROUP BY Parent.Type
                                                LIMIT :thelimit
                                                OFFSET :theOffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        String objectType = (String) ar.get('ObjectName');
                                                        if(objectType != null && !objectType.equals('')){
                                                            ObjectCount oc = new ObjectCount(ar);
                                                            quantities.add(oc);
                                                        }
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(oc);   
                            }
                        }
                    }                          
                }
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                GROUP BY Parent.Type
                                                LIMIT :thelimit
                                                OFFSET :theOffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        String objectType = (String) ar.get('ObjectName');
                                                        if(objectType != null && !objectType.equals('')){
                                                            ObjectCount oc = new ObjectCount(ar);
                                                            quantities.add(oc);
                                                        }
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(oc);   
                            }
                        }
                    }                          
                }
            }
        }
        return quantities;
    } 
    
    /**
* TODO I think this method also counts private attachments, the name should be countPublicUnmigratedAttachmentsPerObject
* @description 
* @param theLimit 
* @param theOffset 
* @return
*/
    public static List<SObjectWrapper> countPublicUnmigratedAttachmentsPerObject(Integer theLimit, Integer theOffset, Date startdate, Date endDate, Boolean byCreateDate){
        
        List<SObjectWrapper> quantities = new List<SObjectWrapper>();
        String[] customobjects = getCustomObject();
        Time firstTime = Time.newInstance(0, 0, 0, 0);
        Time endTime = Time.newInstance(23, 59, 59, 0);
        
        DateTime dtstart = DateTime.newInstance(startDate,firstTime);
        DateTime dtend = DateTime.newInstance(endDate,endTime);
        if(NAMConfigs.getEnableBodyLength()){
            Integer bodyLengthValue = NAMConfigs.getBodyLength() * 1024 * 1024; 
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND bodyLength <= :bodyLengthValue
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :theLimit
                                                OFFSET :theoffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(ow);
                            }
                        }
                    }                          
                }
                
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND bodyLength <= :NAMConfigs.getBodyLength()
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :theLimit
                                                OFFSET :theoffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(ow);
                            }
                        }
                    }                          
                }                
            }
        } else {
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :theLimit
                                                OFFSET :theoffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(ow);
                            }
                        }
                    }                          
                }
                
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC
                                                LIMIT :theLimit
                                                OFFSET :theoffset]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            if(quantities.size()<thelimit){
                                quantities.add(ow);
                            }
                        }
                    }                          
                }
            }
        }
        return quantities;
    } 
    
    /**
* @description 
* @param startdate 
* @param endDate 
* @return
*/
    public static List<SObjectWrapper> countTotalUnmigratedAttachments(Date startdate, Date endDate, Boolean byCreateDate){
        
        List<SObjectWrapper> quantities = new List<SObjectWrapper>();
        String[] customobjects = getCustomObject();
        Time firstTime = Time.newInstance(0, 0, 0, 0);
        Time endTime = Time.newInstance(23, 59, 59, 0);
        
        DateTime dtstart = DateTime.newInstance(startDate,firstTime);
        DateTime dtend = DateTime.newInstance(endDate,endTime);
        if(NAMConfigs.getEnableBodyLength()){
            Integer bodyLengthValue = NAMConfigs.getBodyLength() * 1024 * 1024; 
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND bodyLength <= :bodyLengthValue
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow); 
                        }
                    }                          
                }
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND bodyLength <= :NAMConfigs.getBodyLength()
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow); 
                        }
                    }                          
                }
                
            }
            
        } else {
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow); 
                        }
                    }                          
                }
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                FROM Attachment 
                                                WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                AND bodyLength != 0
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                AND (Parent.Type IN :PARENT_TYPE_GREENS OR Parent.Type IN :customobjects)
                                                GROUP BY Parent.Type
                                                ORDER BY Parent.Type ASC]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        SObjectWrapper ow = new SObjectWrapper(ar);
                                                        quantities.add(ow);
                                                    }
                                                }
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            SObjectWrapper ow = new SObjectWrapper(ar,differentType);
                            quantities.add(ow); 
                        }
                    }                          
                }
            }
        }
        return quantities;
    }
    
    /**
* @description 
* @param startdate 
* @param endDate
*/
    public static List<ObjectCount> countTotalMigratedAttachments(Date startdate, Date endDate, Boolean byCreateDate){
        
        List<ObjectCount> quantities = new List<ObjectCount>();
        String[] customobjects = getCustomObject();
        
        Time firstTime = Time.newInstance(0, 0, 0, 0);
        Time endTime = Time.newInstance(23, 59, 59, 0);
        
        DateTime dtstart = DateTime.newInstance(startDate,firstTime);
        DateTime dtend = DateTime.newInstance(endDate,endTime);
        
        if(NAMConfigs.getEnableBodyLength()){
            Integer bodyLengthValue = NAMConfigs.getBodyLength() * 1024 * 1024; 
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND bodyLength <= :bodyLengthValue
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                GROUP BY Parent.Type]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        ObjectCount oc = new ObjectCount(ar);
                                                        quantities.add(oc);
                                                    }
                                                }
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc); 
                        }
                    }                          
                }
                
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND bodyLength <= :NAMConfigs.getBodyLength()
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                GROUP BY Parent.Type]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        ObjectCount oc = new ObjectCount(ar);
                                                        quantities.add(oc);
                                                    }
                                                }
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND bodyLength <= :NAMConfigs.getBodyLength()
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc); 
                        }
                    }                          
                }
                
            }
            
        } else {
            if(byCreateDate){
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND createdDate >= :dtstart
                                                AND createdDate <= :dtend
                                                GROUP BY Parent.Type]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        ObjectCount oc = new ObjectCount(ar);
                                                        quantities.add(oc);
                                                    }
                                                }
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND createdDate >= :dtstart
                                                 AND createdDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc); 
                        }
                    }                          
                }
                
            } else {
                for(AggregateResult[] results :[SELECT Parent.Type ObjectName, COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize  
                                                FROM Attachment 
                                                WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                AND bodyLength != 0
                                                AND lastModifiedDate >= :dtstart
                                                AND lastModifiedDate <= :dtend
                                                GROUP BY Parent.Type]){
                                                    
                                                    for (AggregateResult ar : results) {
                                                        ObjectCount oc = new ObjectCount(ar);
                                                        quantities.add(oc);
                                                    }
                                                }
                
                for(String differentType : NAMUtils.OTHER_PARENT_TYPE_GREENS){
                    AggregateResult[] results = [SELECT COUNT(Name) Quantity, SUM(BodyLength) totalBytesSize
                                                 FROM Attachment 
                                                 WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                                 AND bodyLength != 0
                                                 AND (Parent.Type = :differentType)
                                                 AND lastModifiedDate >= :dtstart
                                                 AND lastModifiedDate <= :dtend];
                    for (AggregateResult ar : results) {
                        Integer count = (Integer) ar.get('Quantity');
                        if(count>0){
                            ObjectCount oc = new ObjectCount(ar,differentType);
                            quantities.add(oc); 
                        }
                    }                          
                } 
            }
        }
        return quantities;
    } 
    
    /**
* @description It looks for potential Salesforce internal error (Salesforce unmanaged errors) during
* conversion. We detected that some special characters makes the tool fail and we don't know when an 
* Apex job got stuck, so we need to look for this kind of errors in Apex jobs proactively
* PRECONDITION: It requires a remote setting with the org base URL since we need to do a callout to query Apex logs
* @param className
* @param nameSpace
* @return the class id that provoked the error or '-1' If ther's no error
*/
    public static String detectInternalSalesforceError(String className, String nameSpace){
        List<NAMNoteConversionStatus__c> noteConversionStatus = NMTNoteConversionStatus.find();
        DateTime lastDate;
        if(noteConversionStatus!=null&&!noteConversionStatus.isEmpty()){
            lastDate = noteConversionStatus.get(0).LastModifiedDate;
            
            //select the logs with internal salesforce errors
            List<ApexLog> logsError = [SELECT Id FROM ApexLog Where status = :NAMUtils.INTERNAL_ERROR AND LastModifiedDate >= :lastDate ORDER BY StartTime DESC];
            if(logsError!=null && !logsError.isEmpty()){
                
                HttpRequest req=new HttpRequest();
                req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
                req.setHeader('content-Type','application/json');
                string domainUrl=URL.getSalesforceBaseUrl().toExternalForm();
                for(ApexLog log:logsError){
                    System.debug('Log Internal Salesforce Error Id '+log.Id);
                    req.setEndpoint(domainUrl+'/services/data/v'+NAMUtils.API_VERSION+'/sobjects/ApexLog/'+log.Id+'/Body');
                    req.setMethod('GET');
                    Http h=new Http();
                    HttpResponse res=h.send(req);
                    if(res.getStatusCode()==200){
                        //read the body of the logs
                        String body = res.getBody();
                        System.debug('Log Body '+ body.contains(className));
                        //if one body contains the className, select the id of the class
                        if(body.contains(className)){
                            List<ApexClass> classesId = new List<ApexClass>();
                            if(String.isEmpty(nameSpace)){
                                classesId = [SELECT Id FROM ApexClass WHERE Name = :className LIMIT 1];
                            }else{
                                classesId = [SELECT Id FROM ApexClass WHERE Name = :className AND NamespacePrefix = :nameSpace LIMIT 1];
                            }
                            if(classesId!=null && !classesId.isEmpty()){
                                Integer jobsProcessed = 0;
                                //Select the Job that is processing for that class
                                List<AsyncApexJob> jobs = [SELECT Id, JobItemsProcessed, Status FROM AsyncApexJob WHERE ApexClassId = :classesId[0].id AND Status != 'Completed' AND Status != 'Aborted' ORDER BY CreatedDate DESC];
                                if(jobs!=null&&!jobs.isEmpty()){
                                    return classesId[0].id;
                                }
                            }
                        }
                    }
                }
            }
        }
        return '-1';
    }
    
    /**
* @description
* @param className
* @param nameSpace
* @param forcedTerminate
* @param isAttachment
*/
    public static void abortOperation(String className, String nameSpace, Boolean forcedTerminate,  Boolean isAttachment){
        List<ApexClass> classesId = new List<ApexClass>();
        if(String.isEmpty(nameSpace)){
            classesId = [SELECT Id FROM ApexClass WHERE Name = :className LIMIT 1];
        }else{
            classesId = [SELECT Id FROM ApexClass WHERE Name = :className AND NamespacePrefix = :nameSpace LIMIT 1];
        }
        if(classesId!=null && !classesId.isEmpty()){
            Integer jobsProcessed = 0;
            //Select the Job that is processing for that class
            List<AsyncApexJob> jobs = [SELECT Id, JobItemsProcessed, Status FROM AsyncApexJob WHERE ApexClassId = :classesId[0].id AND Status != 'Completed' AND Status != 'Aborted' ORDER BY CreatedDate DESC];
            if(jobs!=null&&!jobs.isEmpty()){
                for(AsyncApexJob job:jobs){
                    //Abort that Job
                    String jobId = job.id;
                    System.abortJob(jobId.substring(0, 15));
                }
                if(isAttachment){
                    AttachmentConversionStatus.deleteAllAttachmentConversionStatus(); 
                } else {
                    NMTNoteConversionStatus.changeStatus('Completed', null,'Convertion');
                }
            }
        }
        if(forcedTerminate){
            if(isAttachment){
                AttachmentConversionStatus.deleteAllAttachmentConversionStatus();
            } else {
                NMTNoteConversionStatus.deleteAllNoteConversionStatus();
            }
        }
    }
    
    public static List<ContentDocument> lastContentDocument(Integer theLimit, Integer theOffset){
        List<ContentDocument> lastConverted = [SELECT Id, Title, ContentModifiedDate, FileType, Owner.FirstName    
                                               FROM ContentDocument
                                               ORDER BY ContentModifiedDate  DESC
                                               LIMIT :theLimit
                                               OFFSET :theOffset];
        return lastConverted;
        
    }
    
    
    /**
* @description
* @param theLimit
* @param theOffset
* @return
*/
    public static List<NAMAttchmentWrapper> lastAttachments(Integer theLimit, Integer theOffset, Date startdate, Date endDate, Boolean migrated){
        
        List<NAMAttchmentWrapper> lastAttachments = new List<NAMAttchmentWrapper>();
        String[] customobjects = getCustomObject();
        Time firstTime = Time.newInstance(0, 0, 0, 0);
        Time endTime = Time.newInstance(23, 59, 59, 0);
        
        DateTime dtstart = DateTime.newInstance(startDate,firstTime);
        DateTime dtend = DateTime.newInstance(endDate,endTime);
        
        if(migrated){
            for (Attachment attachment : [SELECT Id,  Parent.Type, ParentId, Name, CreatedDate, BodyLength, Owner.FirstName    
                                          FROM Attachment
                                          WHERE Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN
                                          AND createdDate >= :dtstart
                                          AND createdDate <= :dtend
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT :theLimit
                                          OFFSET :theOffset]){
                                              boolean supported = checkIfObjectIsSupported(attachment.Parent.Type, attachment.BodyLength, attachment.Id);   
                                             
                                              if(!supported){
                                                  String parentType = attachment.Parent.Type;
                                                  for(String differentType : OTHER_PARENT_TYPE_GREENS){
                                                      List<Attachment> attachments = [SELECT Id FROM Attachment WHERE Id = :attachment.Id AND (Parent.Type = :differentType) LIMIT 1];
                                                      
                                                      if(attachments.size() > 0){
                                                          supported = true;  
                                                          parentType = differentType;
                                              
                                                      }
                                                  }
                                                  lastAttachments.add(new NAMAttchmentWrapper(attachment.Id, attachment.Name, attachment.ParentId, parentType, attachment.Owner.FirstName, attachment.BodyLength, attachment.CreatedDate, supported));      
                                              
                                                  
                                              } else {
                                                  lastAttachments.add(new NAMAttchmentWrapper(attachment.Id, attachment.Name, attachment.ParentId, attachment.Parent.Type, attachment.Owner.FirstName, attachment.BodyLength, attachment.CreatedDate, supported));      
                                              }
                                          }
            
            
        } else {
            for (Attachment attachment : [SELECT Id,  Parent.Type, ParentId, Name, CreatedDate, BodyLength, Owner.FirstName    
                                          FROM Attachment
                                          WHERE (NOT Name LIKE :MIGRATED_ATTACHMENTS_STARTS_WIDTH_PATTERN)
                                          AND createdDate >= :dtstart
                                          AND createdDate <= :dtend
                                          ORDER BY LastModifiedDate DESC
                                          LIMIT :theLimit
                                          OFFSET :theOffset]){
                                              boolean supported = checkIfObjectIsSupported(attachment.Parent.Type, attachment.BodyLength, attachment.Id);   
                                              
                                              if(!supported){
                                                  String parentType = attachment.Parent.Type;
                                                  for(String differentType : OTHER_PARENT_TYPE_GREENS){
                                                      List<Attachment> attachments = [SELECT Id FROM Attachment WHERE Id = :attachment.Id AND (Parent.Type = :differentType) LIMIT 1];
                                                      
                                                      if(attachments.size() > 0){
                                                          supported = true;  
                                                          parentType = differentType;
                                              
                                                      }
                                                  }
                                                  lastAttachments.add(new NAMAttchmentWrapper(attachment.Id, attachment.Name, attachment.ParentId, parentType, attachment.Owner.FirstName, attachment.BodyLength, attachment.CreatedDate, supported));      
                                              
                                                  
                                              } else {
                                                  lastAttachments.add(new NAMAttchmentWrapper(attachment.Id, attachment.Name, attachment.ParentId, attachment.Parent.Type, attachment.Owner.FirstName, attachment.BodyLength, attachment.CreatedDate, supported));      
                                              }
                                              
                                              
                                              
                                          }
            
        }
        return lastAttachments;
        
    }
    
    
    public static Boolean checkIfObjectIsSupported(String objectType, Decimal body, String attachmentId){
        if(body <= 0){
            return false;
        }
        
        if(objectType != null && objectType.toLowerCase().endsWith('_c')){
            return true;
        } else{
            if(objectType != null){
                for(String objectTypeName : PARENT_TYPE_GREENS){
                    if(objectTypeName.equalsIgnoreCase(objectType)){
                        return true;  
                    }
                }
                
                for(String objectTypeName : OTHER_PARENT_TYPE_GREENS ){
                    if(objectTypeName.equalsIgnoreCase(objectType)){
                        return true;  
                    }
                }
                
                for(String objectTypeName : OTHER_PARENT_TYPE_GREENS_PREFIX ){
                    if(objectTypeName.equalsIgnoreCase(objectType)){
                        return true;  
                    }
                }
            }
            
            return false;
        }
    }
    
    /**
* @description
* @param theLimit
* @param theOffset
* @return
*/
    public static List<AsyncApexJob> loadApexJobs(Integer theLimit, Integer theOffset){
        
        String name = NMTMigratorBatch.class.getName();
        String nameAttachment = MigratorBatch.class.getName();
        String nameSpace = '';
        String nameSpaceAttachment = '';
        List<ApexClass> className = new List<ApexClass>();
        List<ApexClass> classNameAttachment = new List<ApexClass>();
        if(name.contains('.')){
            nameSpace = name.substringBefore('.');
            name = name.substringAfter('.');
            className = [SELECT id FROM ApexClass WHERE name = :name AND namespaceprefix=:namespace LIMIT 1];
        }else{
            className = [SELECT id FROM ApexClass WHERE name = :name LIMIT 1];
        }
        
        if(nameAttachment.contains('.')){
            nameSpaceAttachment = nameAttachment.substringBefore('.');
            nameAttachment = nameAttachment.substringAfter('.');
            classNameAttachment = [SELECT id FROM ApexClass WHERE name = :nameAttachment AND namespaceprefix=:nameSpaceAttachment LIMIT 1];
        }else{
            classNameAttachment = [SELECT id FROM ApexClass WHERE name = :nameAttachment LIMIT 1];
        }
        
        //If an error is thrown during change of status, job (AsyncApexJob) status will be 'Completed'
        //In progress label will be hidden anyway
        List<AsyncApexJob> jobs = [SELECT ApexClass.Name, ApexClassID , Status, ExtendedStatus, JobType, CompletedDate,
                                   JobItemsProcessed, MethodName, NumberOfErrors, TotalJobItems 
                                   FROM AsyncApexJob 
                                   WHERE ApexClassID  = :className.get(0).Id 
                                   OR ApexClassID  = :classNameAttachment.get(0).Id
                                   ORDER BY CreatedDate DESC
                                   LIMIT :theLimit
                                   OFFSET :theOffset];
        return jobs;
        
    }
    
    public static List<ApexTrigger> loadTriggers(Integer theLimit, Integer theOffset){
        List<ApexTrigger> triggers = [SELECT Name, TableEnumOrId, NamespacePrefix, ApiVersion, Status, IsValid
                                      FROM ApexTrigger
                                      WHERE (TableEnumOrId = 'Attachment' 
                                      OR TableEnumOrId = 'ContentDocumentLink' 
                                      OR TableEnumOrId = 'ContentVersion' 
                                      OR TableEnumOrId = 'Note'
                                      OR TableEnumOrId = 'ContentDocument')
                                      AND (NOT Name LIKE 'NMTNotesDeletionTrigger')
                                      ORDER BY TableEnumOrId ASC
                                      LIMIT :theLimit
                                      OFFSET :theOffset];
            
            return triggers;
        
    }
}