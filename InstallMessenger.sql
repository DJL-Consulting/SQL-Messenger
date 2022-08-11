USE Utils
GO

--Table MessengerControl
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MessengerControl](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Owner] [nvarchar](max) NULL,
	[EmailMessage] [nvarchar](max) NULL,
	[SQL_Statement] [nvarchar](max) NULL,
	[OrderBy] [nvarchar](max) NULL,
	[ToAddress] [nvarchar](max) NULL,
	[FromAddress] [nvarchar](max) NULL,
	[Subject] [nvarchar](max) NULL,
	[SendIfRowsExist] [bit] NULL,
	[SendIfNoRows] [bit] NULL,
	[Frequency] [nvarchar](50) NULL,
	[Enabled] [bit] NULL,
	[LastRun] [datetime] NULL,
 CONSTRAINT [PK_MessengerControl] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[MessengerControl] ADD  CONSTRAINT [DF_MessengerControl_SendIfRowsExist]  DEFAULT ((1)) FOR [SendIfRowsExist]
GO

ALTER TABLE [dbo].[MessengerControl] ADD  CONSTRAINT [DF_MessengerControl_SendIfNoRows]  DEFAULT ((0)) FOR [SendIfNoRows]
GO

ALTER TABLE [dbo].[MessengerControl] ADD  CONSTRAINT [DF_MessengerControl_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO

Declare @AddSampleMonitor char(1) = 'Y' -- If Yes, a sample row will be added to the control table 

--Add sample/test row to control table
INSERT INTO MessengerControl 
	(Owner, EmailMessage, SQL_Statement, OrderBy, ToAddress, FromAddress, Subject, SendIfRowsExist, SendIfNoRows, Frequency, Enabled)
Select 	'Dan' as Owner,  -- The owner of this notification, if an email address, any errors will be sent to this address
		'These are the tables in the Master database.' as EmailMessage, -- Text at the top of the email
		'select * from Master.sys.tables' as SQL_Statement, -- SQL to execute, make sure to leave out the ORDER BY
		'name' as OrderBy, -- Just the ORDER BY expression (can be multiple columns)
		'DAN@mycompany.org' as ToAddress, -- Email address(es) to send message to, separte multiple with semicolons (;)
		'DBA Group <DBA@mycompany.org>' as FromAddress,  -- Email from - Can be name <address@domain> or just email address
		'Master DB tables' as Subject,  -- Email subject line
		1 as SendIfRowsExist, -- if true (1), will send if the qeury returns any rows
		0 SendIfNoRows, -- If true (1), will send if the query does NOT return any rows
		'Daily' as Frequency, -- Frequency, can be any value, as long as stored proc is run with the same
		1 as Enabled;


/****** Object:  StoredProcedure [dbo].[QueryToHTML]    Script Date: 11/08/2022 9:31:54 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


--Stored Proc QueryToHTML

/*  
Description: Turns a SQL query into a formatted HTML table. Useful for emails. 
Any ORDER BY clause needs to be passed in the separate ORDER BY parameter.
=============================================
EXAMPLE USAGE:
declare @html nvarchar(max)
exec QueryToHTML 
	@query = N'Select * from AdventureWorks.sys.tables', 
	@orderBy = N' order by name', 
	@html=@html OUTPUT
print @html
*/

CREATE PROCEDURE [dbo].[QueryToHTML] 
(
  @Query nvarchar(MAX), --SQL query to execute, do NOT include an ORDER BY clause.
  @OrderBy nvarchar(MAX) = N'', --An optional ORDER BY clause. It should contain the words 'ORDER BY'.
  @HTML nvarchar(MAX) = NULL OUTPUT --The HTML (text) output of the procedure.
)
AS
BEGIN   
	SET NOCOUNT ON;
	
	BEGIN TRY

		SET @OrderBy = REPLACE(@OrderBy, '''', '''''');

		DECLARE @RealQuery nvarchar(MAX) = '
			DECLARE @headerRow nvarchar(MAX);
			DECLARE @cols nvarchar(MAX);    

			SELECT * INTO #dynSql FROM (' + @Query + ') sub;

			SELECT @cols = COALESCE(@cols + '', '''''''', '', '''') + ''['' + name + ''] AS ''''td''''''
			FROM tempdb.sys.columns 
			WHERE object_id = object_id(''tempdb..#dynSql'')
			ORDER BY column_id;

			SET @cols = ''SET @html = CAST(( SELECT '' + @cols + '' FROM #dynSql ' + @OrderBy + ' FOR XML PATH(''''tr''''), ELEMENTS XSINIL) AS nvarchar(max))''    

			EXEC sys.sp_executesql @cols, N''@html nvarchar(MAX) OUTPUT'', @html=@html OUTPUT

			SELECT @headerRow = COALESCE(@headerRow + '''', '''') + ''<th>'' + name + ''</th>'' 
			FROM tempdb.sys.columns 
			WHERE object_id = object_id(''tempdb..#dynSql'')
			ORDER BY column_id;

			SET @headerRow = ''<tr>'' + @headerRow + ''</tr>'';

			SET @html = ''<table border="1">'' + @headerRow + @html + ''</table>'';    
			';

		EXEC sys.sp_executesql 
			@RealQuery, 
			N'@html nvarchar(MAX) OUTPUT', 
			@HTML = @HTML OUTPUT;
	END TRY
	BEGIN CATCH
		SET @HTML = 'Failure of query execution for SQL statement:<br><br>'+@Query+'<br><br>Error Messsage: ' + ERROR_MESSAGE();
	END CATCH
END
GO

--Stored Proc Messenger

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
