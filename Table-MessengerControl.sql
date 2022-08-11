USE [Utils]
GO

/****** Object:  Table [dbo].[MessengerControl]    Script Date: 11/08/2022 10:30:56 PM ******/
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

