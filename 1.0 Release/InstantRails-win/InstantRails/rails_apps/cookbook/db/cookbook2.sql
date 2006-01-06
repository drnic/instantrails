# MySQL-Front 3.2  (Build 7.5)
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES 'latin1' */;


# Host: localhost    Database: cookbook
# ------------------------------------------------------
# Server version 4.1.9-max

#
# Table structure for table categories
#

DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` int(6) unsigned NOT NULL auto_increment,
  `name` varchar(50) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

#
# Dumping data for table categories
#
INSERT INTO `categories` VALUES (1,'Snacks');
INSERT INTO `categories` VALUES (2,'Beverages');


#
# Table structure for table recipes
#

DROP TABLE IF EXISTS `recipes`;
CREATE TABLE `recipes` (
  `id` int(6) unsigned NOT NULL auto_increment,
  `title` varchar(255) NOT NULL default '',
  `description` varchar(255) default NULL,
  `date` date default NULL,
  `instructions` text,
  `category_id` int(6) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

#
# Dumping data for table recipes
#
INSERT INTO `recipes` VALUES (1,'Hot Chips','Only for the brave!','2004-11-11','    Sprinkle hot-pepper sauce on corn chips.\r\n  ',1);
INSERT INTO `recipes` VALUES (2,'Ice Water','Everyone\'s favorite.','2004-11-11','Put ice cubes in a glass of water.\r\n  \r\n  \r\n  \r\n  \r\n  ',2);
INSERT INTO `recipes` VALUES (3,'Killer Mushrooms','The last one you\'ll ever need.','2005-09-13','Serve randomly collected forest mushrooms.',1);


/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
