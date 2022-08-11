USE [Utils]
GO

/****** Object:  StoredProcedure [dbo].[Messenger]    Script Date: 11/08/2022 9:31:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Messenger]
	@Frequency		nvarchar(50) = N'Daily'
AS
BEGIN
    DECLARE @ID			int,
			@Send		bit,
			@SendIfRows bit = 0,
			@SendNoRows bit = 0,
			@SQL		nvarchar(max),
			@OrderBy	nvarchar(max),
			@HTML		nvarchar(max),
			@Message	nvarchar(max),
			@Subject	nvarchar(max),
			@Owner		nvarchar(max),
			@ToEmail	nvarchar(max),
			@FromEmail	nvarchar(max) = N'Sender Name <sender@mycompany.org>',
			@EXDate		datetime;

	SET NOCOUNT ON;

	set @ID = 0;

	while EXISTS (SELECT TOP 1 ID FROM MessengerControl WHERE Enabled = 1 AND Frequency = @Frequency AND ID > @ID)
	BEGIN
		SET @Send = 0;

		SELECT TOP 1 
			@ID		   = ID,
			@SQL	   = SQL_Statement,
			@OrderBy   = ISNULL(OrderBy, ''),
			@SendIfRows= SendIfRowsExist,
			@SendNoRows= SendIfNoRows,
			@Message   = ISNULL(EmailMessage, ''),
			@Subject   = Subject,
			@ToEmail   = ISNULL(ToAddress, @ToEmail),
			@FromEmail = ISNULL(FromAddress, @FromEmail),
			@Owner	   = ISNULL(Owner, ''),
			@EXDate    = ISNULL(LastRun, GETDATE())
		FROM MessengerControl 
		WHERE Enabled = 1 AND Frequency = @Frequency AND ID > @ID ORDER BY ID

		PRINT 'Processing message row ID: ' + cast(@ID as nvarchar);

		SET @SQL = REPLACE(@SQL, '$LASTRUN$', '''' + CONVERT(varchar(30), @EXDate, 120)+ '''');  
	   
		exec QueryToHTML 
			@query = @SQL, 
			@orderBy = @OrderBy,
			@HTML=@HTML OUTPUT;

		if @HTML like 'Failure%'
		BEGIN
			print '>>>Sending failure message!';
			SET @Send = 1;
			SET @ToEmail = CASE WHEN CHARINDEX('@', @Owner) > 0 THEN @Owner ELSE @ToEmail END;
			SET @Subject = 'ERROR in '+@Subject
		END

		if @HTML IS NULL AND @SendNoRows = 1
		BEGIN
			print '>>>Sending no row email';
			SET @Send = 1;
			SET @HTML = '<b>'+@Message+'</b><br><br>' + N'Query execution returned no rows for query below: <br><br>' + @SQL
		END

		if @HTML IS NOT NULL AND @SendIfRows = 1
		BEGIN
			print '>>>Sending email with rows returned';
			SET @Send = 1;
			SET @HTML = @Message + '<br><br>' + @HTML
		END

		IF @Send = 1
		BEGIN
			EXEC msdb.dbo.sp_send_dbmail  
				@recipients=@ToEmail,
				@subject=@Subject,
				@body=@HTML,
				@body_format='HTML',
				@from_address=@FromEmail
		END
		ELSE
			print 'No mail to send';
					
		--print 'Output: '+ @HTML;

		UPDATE MessengerControl 
			SET LastRun = GETDATE() 
		WHERE ID = @ID;
	END

END
GO

