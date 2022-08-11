USE [Utils]
GO

/****** Object:  StoredProcedure [dbo].[QueryToHTML]    Script Date: 11/08/2022 9:31:54 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


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

