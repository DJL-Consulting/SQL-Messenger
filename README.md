# SQL Messenger

## About
The SQL Messenger project is designed to provide a simple mechanism for database monitoring.  The service uses a single control table (MessengerControl), and two stored procedures (Messenger and QueryToHTML, a handy utility which will convert the row result of a SQL query execution to an HTML table).  Each row in the control table contains a SQL query to execute, email to-address(es) for recipients, a subject and header for the email, and a Frequency selector.  The SQL query can be any executable SQL, so the possiblities are unlimited:  Send a list of orders that haven't been completed to the shipping department, send the DBA team a list of any databases that are offline, send data quality check reports to data stewards, etc.  The Frequency option is the parameter that gets passed to the Messenger procedure, and the proc loops through all queries with the Fequency value passed in, so you can have different checks running on different schedules (hourly, daily, weekly, etc).

## Getting Started
Once you've cloned this repo, installation is a snap:  To install everything, just run the script InstallMessenger.sql (change the USE Utils to your database name if needed; Messenger can reside in any database you wish), this will create the control table & add a test row, and create the stored procedures needed to run Messenger.  Alternatively, you can review and individually run the individual scripts to create the table (Table-MessengerControl.sql) and stored procs (StoredProc-Messenger.sql and StoredProc-QueryToHTML.sql) - Just remember to check the USING statement at the top of each script to make sure you're creating objects in the right database.

## Adding Monitors
Once you have all the objects created, you can add rows to table MessengerControl (use AddRowScript-MessengerControl.sql for a template and some guidance on values for each column).  Each row will represent a SQL query that gets run, and assuming the send criteria is met, results will be emailed to the specified recipients.  If you'd like to have a query that checks against the last execution date/time, just substitute `$LASTRUN$`, for example:  `SELECT * FROM SQL_Errors WHERE ErrorDateTime > $LASTRUN$`

## Scheduling Alerts
Scheduling the Messenger service couldn't be easier, running the stored procedure Messenger with the single paramter for the Frequncy you wish to run (default is Daily).  A script to create a SQL agent jobs for the Daily frequency (AgentJob-Daily.sql) is included as well, just remember to check the database name on line 40.  Messenger can be run from any other scheudling service, just by running the Messenger proc like below:
 
    EXEC Messenger 'Weekly' -- Runs monitor queries with the Weekly frequncy

## Feedback & Improvements
If you discover any bugs or additional feature requests, please send me an email!
