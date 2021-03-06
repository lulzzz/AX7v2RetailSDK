﻿/*
SAMPLE CODE NOTICE

THIS SAMPLE CODE IS MADE AVAILABLE AS IS.  MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED, 
OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.  
THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.  
NO TECHNICAL SUPPORT IS PROVIDED.  YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
*/
CREATE PROCEDURE [dbo].[CREATECARDPAYMENTRESULT]
    @id_EntryId                [uniqueidentifier],
    @b_Retrieved               [bit],
    @id_ResultAccessCode       [uniqueidentifier],
    @nvc_ResultData            [nvarchar](max),
    @nvc_ServiceAccountId      [nvarchar](255)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @i_ReturnCode                           INT;
    DECLARE @i_RowCount                             INT;
    DECLARE @i_TransactionIsOurs                    INT;
    DECLARE @i_Error                                INT;

    -- initializes the return code and assume the transaction is not ours by default
    SET @i_ReturnCode = 0;
    SET @i_TransactionIsOurs = 0;

    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;

        SELECT @i_Error = @@ERROR;
        IF @i_Error <> 0
        BEGIN
            SET @i_ReturnCode = @i_Error;
            GOTO exit_label;
        END;

        SET @i_TransactionIsOurs = 1;
    END;

    -- CHECK CARDPAYMENTENTRY EXISTS AND IS NOT USED ALREADY
    SELECT [RECORDID]
    FROM [dbo].[CARDPAYMENTENTRY]
    WHERE [ENTRYID] = @id_EntryId
      AND [SERVICEACCOUNTID] = @nvc_ServiceAccountId
      AND [USED] = 0;

    SELECT @i_Error = @@ERROR, @i_Rowcount = @@ROWCOUNT;

    IF @i_Error <> 0
    BEGIN
        SET @i_ReturnCode = @i_Error;
        GOTO exit_label;
    END;

    IF @i_RowCount = 0
    BEGIN;
       SET @i_ReturnCode = 100001; -- Not found
       GOTO exit_label;
    END;

    -- INSERT CARDPAYMENTRESULT
    INSERT INTO [dbo].[CARDPAYMENTRESULT]
           ([ENTRYID]
           ,[RETRIEVED]
           ,[RESULTACCESSCODE]
           ,[RESULTDATA]
           ,[SERVICEACCOUNTID])
     VALUES
           (@id_EntryId
           ,@b_Retrieved
           ,@id_ResultAccessCode
           ,@nvc_ResultData
           ,@nvc_ServiceAccountId);

    SELECT @i_Error = @@ERROR;
    IF @i_Error <> 0
    BEGIN
        SET @i_ReturnCode = @i_Error;
        GOTO exit_label;
    END;

    IF @i_TransactionIsOurs = 1
    BEGIN
        COMMIT TRANSACTION;

        SET @i_Error = @@ERROR;
        IF @i_Error <> 0
        BEGIN
            SET @i_ReturnCode = @i_Error;
            GOTO exit_label;
        END;

        SET @i_TransactionIsOurs = 0;
    END;

exit_label:
    IF @i_TransactionIsOurs = 1
    BEGIN
        ROLLBACK TRANSACTION;
    END;
    RETURN @i_ReturnCode;
END;
GO
