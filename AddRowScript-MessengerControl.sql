use Utils  -- Database where Messenger exists
go

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
