/*
Design Sync SSIS Project Scripts
Type : Design Version related scripts
Contributor : Rohit Agalave
*/




--------------------------------------------------------------------------------
-- To Check If The FormDesignVersion Is Present At Target Or Not
-- If FDV Is Present Then It Returns 1 Else It Will Return 0
--------------------------------------------------------------------------------
ALTER proc [sync].[IsFDVDPresent] @FDVID int
as 
begin
declare @ID int
declare @flag int
select @ID = formdesignversionid from ui.FormDesignVersion where FormDesignVersionID = @FDVID

if(@ID is not null)
begin
	set @flag = 1
end
else
begin
	set @flag = 0
end

select @flag
end


-------------------------------------------------------------------------------------------------------------
-- Delete all the existing DocumentRules and DocumentRuleEventMap entries specific to a FormDesignVersionID
-------------------------------------------------------------------------------------------------------------
create proc [sync].[DeleteExistingDocRulesAndDocumentRuleEventMap] @FDVID int
as 
begin
	Delete from ui.DocumentRuleEventMap where DocumentRuleID in (select DocumentRuleID from ui.DocumentRule where FormDesignVersionID = @FDVID)
	Delete from UI.DocumentRule where FormDesignVersionID = @FDVID
end



-------------------------------------------------------------------------------------------------------------
-- This SP will Insert New JSOn Or Replace Old JSON In mdm.SchemaUpdateTracker
-------------------------------------------------------------------------------------------------------------

ALTER PROCEDURE [sync].[SyncUpdateMDMTable] @FDID INT, @FDVID INT
AS
DECLARE @SID AS INT
Declare @JsonHash NVARCHAR(MAX)
set  @JsonHash = (select dbo.GZip(FormDesignVersionData) from ui.FormDesignVersion where FormDesignVersionID = @FDVID)
SET @SID = (SELECT schemaupdatetrackerid FROM mdm.SchemaUpdateTracker WHERE FormdesignID = @FDID and FormdesignVersionID = @FDVID)

IF(@SID is null)
BEGIN
	INSERT INTO mdm.SchemaUpdateTracker(FormDesignID,FormDesignVersionID,Status,OldJsonHash,CurrentJsonHash,AddedDate) 
	VALUES(@FDID,@FDVID,1,'',@JsonHash,GETDATE())
END
ELSE
BEGIN
	DECLARE @TempCurrentJsonHash AS NVARCHAR(MAX)
	SET @TempCurrentJsonHash = (SELECT CurrentJsonHash FROM mdm.SchemaUpdateTracker WHERE FormdesignID = @FDID and FormdesignVersionID = @FDVID)
	UPDATE MDM.SchemaUpdateTracker
	SET Status = 3, OldJsonHash = @TempCurrentJsonHash, CurrentJsonHash = @JsonHash,UpdatedDate = GETDATE() WHERE FormdesignID = @FDID and FormdesignVersionID = @FDVID
END
