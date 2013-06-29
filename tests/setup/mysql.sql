CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(200) NOT NULL,
  `lastname` varchar(200) NOT NULL,
  `firstname` varchar(200) NOT NULL,
  `testBoolean` bit(1) NOT NULL DEFAULT b'0',
  `testNull` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `createdat` datetime NOT NULL,
  `updatedat` datetime NOT NULL,
  `post_text` varchar(1000) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `posts_user_id_users_id_idx` (`user_id`),
  CONSTRAINT `posts_user_id_users_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `createdat` datetime NOT NULL,
  `updatedat` datetime NOT NULL,
  `comment_text` varchar(1000) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `comments_user_id_users_id_idx` (`user_id`),
  KEY `comments_post_id_posts_id_idx` (`post_id`),
  CONSTRAINT `comments_user_id_users_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `comments_post_id_posts_id` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;



DELETE FROM `comments`;
DELETE FROM `posts`;
DELETE FROM `users`;

INSERT INTO `users` VALUES (1,'dzuulfci.ezyvfgpo@example.com','Herrera','Ginger','\0','5W9YJMV3QNT5W4SXI2J'),(2,'hmxuygpz.jecmnslkm@example.com','Allen','Jami','\0',NULL),(3,'icevnfe.nguxwzybf@example.com','Murillo','Erika','','TRS7H0EOUID1A2FT');

INSERT INTO `posts` VALUES (1,NULL,'2013-06-13 06:49:51','2013-06-15 02:00:49','mazim dolore Duis ii autem Investigationes eros wisi volutpat. eum nulla consectetuer autem ex dignissim'),(2,3,'2013-06-15 02:34:54','2013-06-16 05:10:01','legunt iriure eros iriure velit adipiscing congue volutpat. dolore option mazim feugait at legunt nobis'),(3,2,'2013-06-16 00:22:46','2013-06-20 09:59:57','tempor id zzril commodo blandit lius in facilisi. soluta consequat. aliquip delenit eorum nibh nonummy praesent'),(4,2,'2013-06-10 17:00:15','2013-06-16 01:21:54','claritatem amet, congue claritatem. sit congue option Ut et duis erat usus tempor Ut nulla esse iriure soluta'),(5,1,'2013-06-09 00:36:54','2013-06-15 04:46:21','eu sit lius insitam; Nam nibh quod laoreet suscipit iriure te veniam, sed velit aliquam Nam eros id congue zzril');

INSERT INTO `comments` VALUES (1,3,5,'2013-06-05 16:42:40','2013-06-11 09:58:27','Longam, regit, novum delerium. quorum linguens si non quis estis si gravis pars pars e si si Et plurissimum'),(2,3,5,'2013-06-12 03:52:16','2013-06-19 02:22:06','glavans fecit. brevens, Multum non manifestum quad gravum linguens quad quo estum. nomen estis pladior fecit, apparens Longam,'),(3,3,5,'2013-06-14 20:09:17','2013-06-18 19:20:19','nomen brevens, quoque apparens linguens habitatio Versus in transit. si novum Quad apparens novum bono'),(4,2,3,'2013-06-04 04:13:12','2013-06-07 02:00:47','et sed travissimantor e eudis e Et vantis. pars trepicandor cognitio, funem. nomen fecit, volcans eudis et'),(5,1,3,'2013-06-09 23:13:41','2013-06-10 02:13:41','transit. quad transit. quantare travissimantor si linguens estis pars Quad et Pro vobis habitatio travissimantor'),(6,2,3,'2013-06-03 21:20:31','2013-06-04 07:26:22','glavans quad nomen fecit. e egreddior Longam, homo, fecit. non homo, volcans plurissimum fecit. quad parte'),(7,3,2,'2013-06-05 00:04:32','2013-06-09 21:41:03','bono ut et eudis transit. vantis. nomen gravis eudis travissimantor novum linguens plorum si et parte'),(8,2,1,'2013-06-16 03:44:12','2013-06-19 07:42:20','essit. Pro et gravis ut volcans quo delerium. non eudis homo, nomen nomen regit, apparens quad trepicandor'),(9,3,1,'2013-06-06 13:54:02','2013-06-09 21:47:39','et essit. quorum quad Multum quad estis quartu esset plorum linguens et quad gravis transit. in novum rarendum vantis.'),(10,1,1,'2013-06-07 01:54:13','2013-06-12 07:56:18','et pladior si apparens brevens, pars linguens venit. pars non quis in non essit. trepicandor plurissimum');
