IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[users]') AND type in (N'U'))
BEGIN
CREATE TABLE [users](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[email] [varchar](200) NOT NULL,
	[lastname] [varchar](200) NOT NULL,
	[firstname] [varchar](200) NOT NULL,
	[testBoolean] [bit] NOT NULL,
	[testNull] [varchar](50) NULL,
 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED 
(
	[id] ASC
) )
END


IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[posts]') AND type in (N'U'))
BEGIN
CREATE TABLE [posts](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NULL,
	[createdat] [datetime] NOT NULL,
	[updatedat] [datetime] NOT NULL,
	[post_text] [varchar](1000) NOT NULL,
 CONSTRAINT [PK_posts] PRIMARY KEY CLUSTERED 
(
	[id] ASC
) )

ALTER TABLE [posts]  WITH CHECK ADD  CONSTRAINT [FK_posts_users] FOREIGN KEY([user_id])
REFERENCES [users] ([id])

ALTER TABLE [posts] CHECK CONSTRAINT [FK_posts_users]
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[comments]') AND type in (N'U'))
BEGIN
CREATE TABLE [comments](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NOT NULL,
	[post_id] [int] NOT NULL,
	[createdat] [datetime] NOT NULL,
	[updatedat] [datetime] NOT NULL,
	[comment_text] [varchar](1000) NOT NULL,
 CONSTRAINT [PK_comments] PRIMARY KEY CLUSTERED 
(
	[id] ASC
) )

ALTER TABLE [comments]  WITH CHECK ADD  CONSTRAINT [FK_comments_posts] FOREIGN KEY([post_id])
REFERENCES [posts] ([id])

ALTER TABLE [comments] CHECK CONSTRAINT [FK_comments_posts]

ALTER TABLE [comments]  WITH CHECK ADD  CONSTRAINT [FK_comments_users] FOREIGN KEY([user_id])
REFERENCES [users] ([id])

ALTER TABLE [comments] CHECK CONSTRAINT [FK_comments_users]
END

DELETE FROM comments
DELETE FROM posts
DELETE FROM users

SET IDENTITY_INSERT [users] ON
INSERT [users] ([id], [email], [lastname], [firstname], [testBoolean], [testNull]) VALUES (1, N'dzuulfci.ezyvfgpo@example.com', N'Herrera', N'Ginger', 0, N'5W9YJMV3QNT5W4SXI2J')
INSERT [users] ([id], [email], [lastname], [firstname], [testBoolean], [testNull]) VALUES (2, N'hmxuygpz.jecmnslkm@example.com', N'Allen', N'Jami', 0, NULL)
INSERT [users] ([id], [email], [lastname], [firstname], [testBoolean], [testNull]) VALUES (3, N'icevnfe.nguxwzybf@example.com', N'Murillo', N'Erika', 1, N'TRS7H0EOUID1A2FT')
SET IDENTITY_INSERT [users] OFF



SET IDENTITY_INSERT [posts] ON
INSERT [posts] ([id], [user_id], [createdat], [updatedat], [post_text]) VALUES (1, NULL, CAST(0x0000A1DC007091A9 AS DateTime), CAST(0x0000A1DE00212FBB AS DateTime), N'mazim dolore Duis ii autem Investigationes eros wisi volutpat. eum nulla consectetuer autem ex dignissim')
INSERT [posts] ([id], [user_id], [createdat], [updatedat], [post_text]) VALUES (2, 3, CAST(0x0000A1DE002A8C49 AS DateTime), CAST(0x0000A1DF0055270E AS DateTime), N'legunt iriure eros iriure velit adipiscing congue volutpat. dolore option mazim feugait at legunt nobis')
INSERT [posts] ([id], [user_id], [createdat], [updatedat], [post_text]) VALUES (3, 2, CAST(0x0000A1DF00064110 AS DateTime), CAST(0x0000A1E300A4C910 AS DateTime), N'tempor id zzril commodo blandit lius in facilisi. soluta consequat. aliquip delenit eorum nibh nonummy praesent')
INSERT [posts] ([id], [user_id], [createdat], [updatedat], [post_text]) VALUES (4, 2, CAST(0x0000A1D9011838CC AS DateTime), CAST(0x0000A1DF00167EC5 AS DateTime), N'claritatem amet, congue claritatem. sit congue option Ut et duis erat usus tempor Ut nulla esse iriure soluta')
INSERT [posts] ([id], [user_id], [createdat], [updatedat], [post_text]) VALUES (5, 1, CAST(0x0000A1D8000A230C AS DateTime), CAST(0x0000A1DE004EA620 AS DateTime), N'eu sit lius insitam; Nam nibh quod laoreet suscipit iriure te veniam, sed velit aliquam Nam eros id congue zzril')
SET IDENTITY_INSERT [posts] OFF



SET IDENTITY_INSERT [comments] ON
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (1, 3, 5, CAST(0x0000A1D401136520 AS DateTime), CAST(0x0000A1DA00A45F41 AS DateTime), N'Longam, regit, novum delerium. quorum linguens si non quis estis si gravis pars pars e si si Et plurissimum')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (2, 3, 5, CAST(0x0000A1DB003FCB91 AS DateTime), CAST(0x0000A1E2002707D4 AS DateTime), N'glavans fecit. brevens, Multum non manifestum quad gravum linguens quad quo estum. nomen estis pladior fecit, apparens Longam,')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (3, 3, 5, CAST(0x0000A1DD014C2464 AS DateTime), CAST(0x0000A1E1013EB190 AS DateTime), N'nomen brevens, quoque apparens linguens habitatio Versus in transit. si novum Quad apparens novum bono')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (4, 2, 3, CAST(0x0000A1D300458BC5 AS DateTime), CAST(0x0000A1D600212C9D AS DateTime), N'et sed travissimantor e eudis e Et vantis. pars trepicandor cognitio, funem. nomen fecit, volcans eudis et')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (5, 1, 3, CAST(0x0000A1D8017ECA67 AS DateTime), CAST(0x0000A1D90024B8B6 AS DateTime), N'transit. quad transit. quantare travissimantor si linguens estis pars Quad et Pro vobis habitatio travissimantor')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (6, 2, 3, CAST(0x0000A1D2015FB4B4 AS DateTime), CAST(0x0000A1D3007A9991 AS DateTime), N'glavans quad nomen fecit. e egreddior Longam, homo, fecit. non homo, volcans plurissimum fecit. quad parte')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (7, 3, 2, CAST(0x0000A1D400013F65 AS DateTime), CAST(0x0000A1D8016558A1 AS DateTime), N'bono ut et eudis transit. vantis. nomen gravis eudis travissimantor novum linguens plorum si et parte')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (8, 2, 1, CAST(0x0000A1DF003D945B AS DateTime), CAST(0x0000A1E2007EFC9F AS DateTime), N'essit. Pro et gravis ut volcans quo delerium. non eudis homo, nomen nomen regit, apparens quad trepicandor')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (9, 3, 1, CAST(0x0000A1D500E513C4 AS DateTime), CAST(0x0000A1D80167294A AS DateTime), N'et essit. quorum quad Multum quad estis quartu esset plorum linguens et quad gravis transit. in novum rarendum vantis.')
INSERT [comments] ([id], [user_id], [post_id], [createdat], [updatedat], [comment_text]) VALUES (10, 1, 1, CAST(0x0000A1D6001F5F8D AS DateTime), CAST(0x0000A1DB0082D1F6 AS DateTime), N'et pladior si apparens brevens, pars linguens venit. pars non quis in non essit. trepicandor plurissimum')
SET IDENTITY_INSERT [comments] OFF