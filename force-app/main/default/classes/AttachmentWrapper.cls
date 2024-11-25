/**
* @author Andres Canavesi
* @description  .
* @date 2017-01
*/
public class AttachmentWrapper {
/**
* @description a desc
*/
	public Attachment attachment { get; set; }
	public Boolean selected { get; set; }
	//true if there is a batch queued or in progress migrating attachments or notes for this objectName
	public Boolean migrationInProgress { get; set; }

	public AttachmentWrapper(Attachment attachment) {
		this.attachment = attachment;
		selected = false;
		migrationInProgress = false;

	}


}