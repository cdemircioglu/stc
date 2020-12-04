-- --------------------------------------------------------
-- Host:                         dbcreovenus.mysql.database.azure.com
-- Server version:               8.0.15 - Source distribution
-- Server OS:                    Win64
-- HeidiSQL Version:             10.3.0.5771
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Dumping database structure for db_work
CREATE DATABASE IF NOT EXISTS `db_work` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */;
USE `db_work`;

-- Dumping structure for table db_work.assettransactions
CREATE TABLE IF NOT EXISTS `assettransactions` (
  `assetTransactionId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `issuerId` int(11) NOT NULL,
  `assetId` int(11) NOT NULL,
  `subscriberId` int(11) NOT NULL,
  `assetTransactionOperation` varchar(50) NOT NULL,
  `assetTransactionJSON` json DEFAULT NULL,
  `createDate` datetime NOT NULL,
  PRIMARY KEY (`assetTransactionId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table db_work.systemlogs
CREATE TABLE IF NOT EXISTS `systemlogs` (
  `createDate` datetime NOT NULL,
  `userActivity` varchar(500) NOT NULL,
  `logJSON` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table db_work.usernotifications
CREATE TABLE IF NOT EXISTS `usernotifications` (
  `userId` int(11) NOT NULL,
  `userNotificationJSON` json DEFAULT NULL,
  `createDate` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table db_work.userprofiletransactions
CREATE TABLE IF NOT EXISTS `userprofiletransactions` (
  `userProfileTransactionId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `userProfileTransactionOperation` varchar(50) NOT NULL,
  `userProfileTransactionJSON` json DEFAULT NULL,
  `userProfileTransactionHash` varchar(5000) DEFAULT NULL,
  `createDate` datetime NOT NULL,
  PRIMARY KEY (`userProfileTransactionId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table db_work.users
CREATE TABLE IF NOT EXISTS `users` (
  `userId` int(11) NOT NULL,
  `userName` varchar(55) COLLATE utf8_unicode_ci NOT NULL,
  `userPassword` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
  `userJSON` json DEFAULT NULL,
  PRIMARY KEY (`userId`)
) /*!50100 TABLESPACE `innodb_system` */ ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.

-- Dumping structure for view db_work.vw_currentassistants
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `vw_currentassistants` (
	`issuerid` LONGTEXT NULL COLLATE 'utf8mb4_bin',
	`assetid` LONGTEXT NULL COLLATE 'utf8mb4_bin',
	`transactionJSON` LONGTEXT NULL COLLATE 'utf8mb4_bin'
) ENGINE=MyISAM;

-- Dumping structure for view db_work.vw_currentauctiondetails
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `vw_currentauctiondetails` (
	`userId` INT(11) NOT NULL,
	`assetId` INT(11) NOT NULL,
	`assetTransactionJSON` JSON NULL,
	`createDate` DATETIME NOT NULL,
	`auctionStatus` LONGTEXT NULL COLLATE 'utf8mb4_bin'
) ENGINE=MyISAM;

-- Dumping structure for view db_work.vw_currentlistingdetails
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `vw_currentlistingdetails` (
	`userid` INT(11) NOT NULL,
	`issuerid` LONGTEXT NULL COLLATE 'utf8mb4_bin',
	`assetid` LONGTEXT NULL COLLATE 'utf8mb4_bin',
	`assetTransactionJSON` JSON NULL
) ENGINE=MyISAM;

-- Dumping structure for view db_work.vw_currentprofiledetails
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `vw_currentprofiledetails` (
	`userid` INT(11) NOT NULL,
	`userProfileTransactionJSON` JSON NULL
) ENGINE=MyISAM;

-- Dumping structure for procedure db_work.spc_AssetTransactionCreate
DELIMITER //
CREATE PROCEDURE `spc_AssetTransactionCreate`(uuserId int, uuserAssetTransactionOperation varchar(50) ,uuserAssetTransactionJSON json)
BEGIN
#This procedure creates assets in the database
#Sample call 
#CALL spc_AssetTransactionCreate(8,'Create Listing Details','{"firstname":"cem","lastname":"demircioglu","dateofbirth":"11/11/2010"}');

#Find the highest userAssetTransactionId and get a salt from users table
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @createDate = (SELECT CASE WHEN JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.auctionstatus')) = 'Deleted' THEN JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.createdate')) ELSE @createDate END);
SET @assetTransactionId = (SELECT COALESCE(MAX(assetTransactionId),0)+1 FROM assettransactions);
SET @assetTransactionJSON = (SELECT JSON_SET(uuserAssetTransactionJSON,'$.createdate',@createDate) COLLATE utf8mb4_unicode_ci);
SET @assetTransactionId = (SELECT COALESCE(MAX(assetTransactionId),0)+1 FROM assettransactions);
SET @assetId = (SELECT COALESCE(JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.assetid')),0) AS assetid);
SET @issuerId = (SELECT COALESCE(JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.issuerid')),0) AS issuerId);
SET @subscriberId = (SELECT COALESCE(JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.subscriberid')),0) AS subscriberId);

#if we are creating a new subscription then, it will not have any subscriptionid. hence we need to start from 1. 
IF (uuserAssetTransactionOperation = 'Create Subscription') THEN
	SET @subscriptionId = (SELECT JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.subscriptionid')) AS subscriptionid);
    IF @subscriptionId IS NULL THEN 
		#This is a new subscription, hence find the last subscription of that user and increment by one
		SET @subscriptionId = (SELECT CAST(MAX(JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid'))) AS UNSIGNED) + 1 AS subscriptionid FROM assettransactions	WHERE assetTransactionOperation = 'Create Subscription' AND issuerid = @issuerId AND assetid = @assetId AND subscriberid = @subscriberId); #AND userid = @subscriberId
        SET @subscriptionId = (SELECT COALESCE(@subscriptionId,1) AS subscriptionId); 
        SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.subscriptionid',@subscriptionId));
    END IF;
END IF;

##Asset statuses: Created > Pending > Listed / Rejected > Sold / Deleted
##SET @assetVerification = (SELECT COALESCE(JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.assetverification')),JSON_OBJECT('verificationstatus', 'Created')) AS assetstatus);
##SET @contractAddress = (SELECT JSON_UNQUOTE(JSON_EXTRACT(uuserAssetTransactionJSON,'$.contractaddress')) AS contractaddress);


#This means this a brand new listing
#IF @assetId IS NULL THEN
IF @assetId = 0 THEN
	SET @assetId = (SELECT MAX(assetid) AS assetid FROM (SELECT JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.assetid'))+1 AS assetid FROM assettransactions WHERE userid = uuserId UNION SELECT 1) a);
END IF;
	SET @assetId = CAST(@assetId AS CHAR(10));
    
#Insert or reset the asset id into the json 
SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.assetid',@assetId ) COLLATE utf8mb4_unicode_ci);

#Add the asset ownerid when the user is creating the asset and the asset status
#IF uuserAssetTransactionOperation = 'Create Listing Details' THEN
#	#SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.assetownerid',uuserid, '$.assetstatus',@assetStatus,'$.@contractaddress',@contractAddress ) COLLATE utf8mb4_unicode_ci);
#    SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.assetownerid',uuserid, '$.assetverification',@assetVerification) COLLATE utf8mb4_unicode_ci);
#	#SELECT JSON_SET(@assetTransactionJSON,'$.assetownerid',uuserid, '$.assetstatus.verificationstatus',@assetStatus);
#END IF;
 
#Insert the profile data into the userprofiletransactions table
INSERT INTO assettransactions (assetTransactionId, userId, subscriberId, issuerId, assetId, assetTransactionOperation, assetTransactionJSON, createDate)
VALUES(@assetTransactionId, uuserId, @subscriberId, @issuerId, @assetId, uuserAssetTransactionOperation, @assetTransactionJSON, @createDate);

#Log activity 
SET @UuserJSON = (SELECT JSON_INSERT(CAST("{}" AS JSON), '$.spcProcedure', 'spc_AssetTransactionCreate'));   
#INSERT INTO systemlogs (createDate, userActivity, logJSON)
#VALUES (@createDate, uuserAssetTransactionOperation ,@assetTransactionJSON);

SELECT JSON_OBJECT(
	'assetid',@assetId,
    'issuerid',@issuerId,
    'subscriberid',@subscriberId,
    'subscriptionid', @subscriptionId
    ) AS transactionJSON;
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_AssetTransactionPerAsset
DELIMITER //
CREATE PROCEDURE `spc_AssetTransactionPerAsset`(iissuerId int, aassetId int)
ProfileTransaction: BEGIN
#This procedure returns the details of a transaction, could be attached documents or listing details. 
#CALL spc_AssetTransactionPerAsset(1,1);
DECLARE iiissuerid INT; 
DECLARE aaassetid INT;
DECLARE sssubscriberid INT;
DECLARE sssubscriptionid INT;
DECLARE aaassettransactionJSON longtext;

#Create the cursor
DECLARE subscribers CURSOR FOR
	SELECT 
		issuerid, assetid, subscriberid, JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) AS subscriptionid, assetTransactionJSON
	FROM assettransactions 
	WHERE assetTransactionOperation = 'Create Subscription' AND issuerId = iissuerid AND assetid = aassetId; #I know this is not correct, otherwise Ugur is going to blow up. 
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET @done = 1;
SET group_concat_max_len = 9000000;
SET @done = 0;

#Drop the temp table
DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

#Create the temp table
CREATE TEMPORARY TABLE mysubscriptions
( 
	issuerid INT, 
	assetid INT, 
	subscriberid INT,
	subscriptionid INT,
	assettransactionJSON JSON,
	PRIMARY KEY (issuerid, assetid, subscriberid, subscriptionid)
);

#Drop the temp table
DROP TEMPORARY TABLE IF EXISTS myassettransaction;

#Create the temp table
CREATE TEMPORARY TABLE myassettransaction
( 
	assettransactionJSON JSON
);


#Loop on the subscribers
OPEN subscribers;
	REPEAT
	  FETCH subscribers
	  INTO iiissuerid,aaassetid,sssubscriberid,sssubscriptionid,aaassettransactionJSON;
		IF NOT @done THEN
		
			INSERT INTO mysubscriptions
				VALUES (iiissuerid,aaassetid,sssubscriberid,sssubscriptionid,aaassettransactionJSON)
			ON DUPLICATE KEY UPDATE
				issuerid = iiissuerid, assetid = aaassetid, subscriptionid = sssubscriptionid,  assettransactionJSON = JSON_MERGE_PATCH(assettransactionJSON,aaassettransactionJSON);

		END IF;
	UNTIL @done
	END REPEAT;
CLOSE subscribers;
 
	SET SESSION group_concat_max_len = 9000000;

    #Get the most recent listing
	SET @assetTransactionJSON = (SELECT assetTransactionJSON FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT(assetTransactionJSON,'$.createDate') ORDER BY createdate DESC) AS rownumber FROM assettransactions WHERE issuerId = iissuerId AND assetId = aassetId AND assetTransactionOperation = 'Create Listing' ) a WHERE rownumber = 1);
    
    SET @assetStatus = (SELECT assetTransactionJSON FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT(assetTransactionJSON,'$.createDate') ORDER BY createdate DESC) AS rownumber 
	FROM assettransactions WHERE issuerId = iissuerId AND assetId = aassetId AND assetTransactionOperation IN ('Create Listing','Check Listing') ) a WHERE rownumber = 1);
    SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.status', JSON_EXTRACT(@assetStatus,'$.status')   )); 



    
    #Get all the active documents
    SET @documentArray = (    
		SELECT CAST(CONCAT('[',GROUP_CONCAT(a.assetTransactionJSON ORDER BY JSON_EXTRACT(a.assetTransactionJSON,'$.createdate') DESC),']') AS JSON) 
		FROM
		(
		SELECT *, ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT(assetTransactionJSON,'$.documenthash'),JSON_EXTRACT(assetTransactionJSON,'$.documenttype') ORDER BY createDate DESC) AS rownumber
		FROM assettransactions WHERE issuerid = iissuerId AND assetId = aassetId AND assetTransactionOperation = 'Attach Document' 
		) a    
		WHERE JSON_EXTRACT(a.assetTransactionJSON,'$.documentstatus') = 'Created' AND a.rownumber = 1);
	SET @documentArray = (SELECT COALESCE(@documentArray, CAST('[]' AS JSON))); 
    
	#Get the latest status of listings
    SET @listingVerification = (SELECT CAST(COALESCE(assetTransactionJSON,'{"verificationstatus": "Created"}') AS JSON) FROM 
		(	
		SELECT assetTransactionJSON, ROW_NUMBER() OVER (PARTITION BY issuerid, assetid ORDER BY createDate DESC) AS rownumber FROM assettransactions
		WHERE issuerid = iissuerId AND assetId = aassetId AND assetTransactionOperation = 'Check Listing'
		) a WHERE a.rownumber = 1); 
	SET @listingVerification = (SELECT COALESCE(@listingVerification, CAST('{"verificationstatus": "Created"}' AS JSON))); 
    
    
    #Get the assistants of the listings
    #SET @assistants = (SELECT CAST(CONCAT('[',GROUP_CONCAT(f.transactionJSON ORDER BY JSON_EXTRACT(f.transactionJSON,'$.createdate') DESC),']') AS JSON)
    INSERT INTO myassettransaction
    SELECT transactionJSON FROM
    (
    SELECT JSON_SET(a.userProfileTransactionJSON,
			'$.inviterid',inviterid,
			'$.assistanttype',assistanttype,
            '$.invitestatus',invitestatus
			) AS transactionJSON
			FROM 
			(
			SELECT userProfileTransactionJSON, userId, ROW_NUMBER() OVER (PARTITION BY userId ORDER BY createDate DESC) AS rownum
			FROM 
				userprofiletransactions 
					WHERE 
						userProfileTransactionOperation = 'Create Profile' AND 
						userid IN (SELECT assistantid FROM vw_currentassistants, JSON_TABLE(transactionJSON,"$[*]" COLUMNS(assistantid INT PATH "$.assistantid")) k WHERE issuerid = iissuerId AND assetid = aassetid ) 
			) a INNER JOIN 
			(
			SELECT  
				assistantid,
				inviterid,
				assistanttype
			FROM vw_currentassistants, JSON_TABLE(transactionJSON,"$[*]" COLUMNS(
				assistantid INT PATH "$.assistantid",
				inviterid INT PATH "$.inviterid",
				assistanttype VARCHAR(100) PATH "$.assistanttype"
				)) k WHERE issuerid = iissuerid AND assetid = aassetid
			) b ON a.userid = b.assistantid 
            LEFT JOIN 
            (
				SELECT DISTINCT bb.userid,bb.issuerid, bb.assetid, JSON_UNQUOTE(JSON_EXTRACT(bb.assetTransactionJSON,'$.status')) AS invitestatus
				FROM assettransactions bb INNER JOIN vw_currentprofiledetails cc ON JSON_UNQUOTE(JSON_EXTRACT(bb.assetTransactionJSON,'$.assistantid')) = cc.userid WHERE bb.assetTransactionOperation = 'Add Assistant' AND bb.subscriberId >= 0 #ORDER BY bb.createdate DESC
            ) d ON d.issuerid = iissuerid AND d.assetid = aassetid AND d.userid = b.assistantid #AND d.subscriberid = a.subscriberid
			WHERE a.rownum = 1
		) f;
	
    
    #Add the inviter type
    UPDATE myassettransaction m LEFT JOIN (SELECT userid, JSON_UNQUOTE(JSON_EXTRACT(userProfileTransactionJSON,'$.usertype')) usertype FROM vw_currentprofiledetails) w
	ON JSON_UNQUOTE(JSON_EXTRACT(m.assetTransactionJSON,'$.inviterid'))  = w.userid
	SET assettransactionJSON = JSON_SET(m.assettransactionJSON,'$.invitertype',w.usertype);

    SET @assistants = (SELECT CAST(CONCAT('[',GROUP_CONCAT(f.assetTransactionJSON ORDER BY JSON_EXTRACT(f.assetTransactionJSON,'$.createdate') DESC),']') AS JSON) FROM myassettransaction f);
	#SELECT @assistants;
    


	
	#Get the subscriptions
	SET @subscriptions = (SELECT CAST(CONCAT('[',GROUP_CONCAT(assettransactionJSON ORDER BY JSON_EXTRACT(assettransactionJSON,'$.createdate') DESC),']') AS JSON) FROM mysubscriptions ORDER BY JSON_EXTRACT(assettransactionJSON,'$.createdate') DESC );
    
	SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,
						'$.documents', CAST(@documentArray AS JSON), 
                        '$.assetverification',CAST(@listingVerification AS JSON),
                        '$.assistants', CAST(@assistants AS JSON),
                        '$.subscriptions', CAST(@subscriptions AS JSON)
                        ) AS assetJSON);
	

    #Get all the auctions
	#SET @auctionArray = (SELECT CAST(CONCAT('[',GROUP_CONCAT(c.assetTransactionJSON),']') AS JSON) FROM
	#	(    
	#	SELECT 
	#		a.userId, 
	#		a.assetId, 
	#		JSON_SET(
	#			a.assetTransactionJSON,
	#			'$.buyername',REPLACE(CONCAT(JSON_UNQUOTE(JSON_EXTRACT(b.userProfileTransactionJSON,'$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(b.userProfileTransactionJSON,'$.middlename')), ' ', JSON_UNQUOTE(JSON_EXTRACT(b.userProfileTransactionJSON,'$.lastname'))),'  ',' '), 
	#			'$.sellername',REPLACE(CONCAT(JSON_UNQUOTE(JSON_EXTRACT(s.userProfileTransactionJSON,'$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(s.userProfileTransactionJSON,'$.middlename')), ' ', JSON_UNQUOTE(JSON_EXTRACT(s.userProfileTransactionJSON,'$.lastname'))),'  ',' ')) AS assetTransactionJSON
    #    FROM assettransactions a INNER JOIN  
	#	vw_currentprofiledetails s ON  JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.selleruserid')) = s.userId INNER JOIN 
	#	vw_currentprofiledetails b ON  CAST(b.userid AS CHAR(10)) = CAST(JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.buyeruserid')) AS CHAR(10)) INNER JOIN 
    #    vw_currentauctiondetails ad ON ad.createdate = a.createdate AND ad.auctionStatus = 'Active'
	#	WHERE 
	#		JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.selleruserid')) = uuserid AND 
    #        a.assetId = aassetId AND a.assetTransactionOperation = 'Auction Asset'
	#) c
    #);
	#SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.auction', CAST(COALESCE(@auctionArray,'[{ "assetid": null, "biddate": null, "bidprice": null, "buyername": null, "createdate": null, "sellername": null, "buyeruserid": null, "selleruserid": null, "auctionstatus":null}]') AS JSON)) AS assetJSON);
  
	#Get the current max bid or zero if there is no bid.    
    #SET @currentMaxBid = (SELECT MAX(bidprice) AS bidprice
    # FROM
    #   JSON_TABLE(
    #     JSON_EXTRACT(@assetTransactionJSON,'$.auction'),
    #     "$[*]"
    #     COLUMNS(bidprice DOUBLE PATH "$.bidprice",assetid DOUBLE PATH "$.assetid",selleruserid DOUBLE PATH "$.selleruserid")
    #   ) data WHERE selleruserid = uuserid AND assetId = aassetId);
    #SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.currentmaxbid', COALESCE(@currentMaxBid,0)) AS assetJSON);
    
    #Let's get the user's fixed salt to retreive 
    #SET @assetTransactionJSON = (SELECT 
	#			JSON_SET(@assetTransactionJSON,'$.userfixedsalt', 
	#				(SELECT JSON_EXTRACT(userJSON,'$.userfixedsalt') FROM users WHERE userid = uuserid)
    #            ));
    
  
    #Get the status of the purchase
	#SET @purchase = (SELECT assetTransactionJSON FROM assettransactions WHERE userId = uuserId AND assetId = aassetId AND assetTransactionOperation = 'Purchase Asset' ORDER BY createDate DESC LIMIT 1);
	#SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.purchase', CAST(@purchase AS JSON)) AS assetJSON);


	SELECT @assetTransactionJSON AS transactionJSON;
    #Changed by Mehmet.
    #SELECT assetTransactionJSON  FROM db_work.assettransactions WHERE issuerId = 15 AND assetId = 1 ORDER BY assetTransactionJSON DESC LIMIT 1;
END ProfileTransaction//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_AssetTransactionPerOperationShow
DELIMITER //
CREATE PROCEDURE `spc_AssetTransactionPerOperationShow`(iissuerid int, aassetId int, aassetTransactionOperation varchar(50) )
BEGIN
#This procedure returns the details of a transaction, could be attached documents or listing details. 
#CALL spc_AssetTransactionPerOperationShow(1,1,'Create Listing');
	SET SESSION group_concat_max_len = 1000000;

    #Get the most recent listing
	SET @assetTransactionJSON = (
			SELECT assetTransactionJSON FROM (
				SELECT *,ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT(assetTransactionJSON,'$.createDate') ORDER BY createdate DESC) AS rownumber FROM assettransactions 
				WHERE issuerid = iissuerid AND assetId = aassetId AND assetTransactionOperation = aassetTransactionOperation 
                ) a 
            WHERE rownumber = 1);
    
    #Get all the active documents
    #SET @documentArray = (    
	#	SELECT CAST(CONCAT('[',GROUP_CONCAT(a.assetTransactionJSON),']') AS JSON) 
	#	FROM
	#	(
	#	SELECT *, ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT(assetTransactionJSON,'$.documenthash'),JSON_EXTRACT(assetTransactionJSON,'$.documenttype') ORDER BY createDate DESC) AS rownumber
	#	FROM assettransactions WHERE issuerid = iissuerid AND assetId = aassetId AND assetTransactionOperation = 'Attach Document' 
	#	) a    
	#	WHERE JSON_EXTRACT(a.assetTransactionJSON,'$.documentstatus') = 'Created' AND a.rownumber = 1);
	#SET @documentArray = (SELECT COALESCE(@documentArray, CAST('[]' AS JSON))); 
    
	#Get the latest status of listings
    #SET @listingVerification = (SELECT CAST(COALESCE(assetTransactionJSON,'{"verificationstatus": "Created"}') AS JSON) FROM 
	#	(	
	#	SELECT assetTransactionJSON, ROW_NUMBER() OVER (PARTITION BY issuerid, assetid ORDER BY createDate DESC) AS rownumber FROM assettransactions
	#	WHERE issuerid = iissuerid AND assetId = aassetId AND assetTransactionOperation = 'Check Listing'
	#	) a WHERE a.rownumber = 1); 
	#SET @listingVerification = (SELECT COALESCE(@listingVerification, CAST('{"verificationstatus": "Created"}' AS JSON))); 
    
	#SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.documents', CAST(@documentArray AS JSON), '$.assetverification',CAST(@listingVerification AS JSON)) AS assetJSON);
	

    #Get all the auctions
	#SET @auctionArray = (SELECT CAST(CONCAT('[',GROUP_CONCAT(c.assetTransactionJSON),']') AS JSON) FROM
	#	(    
	#	SELECT 
	#		a.userId, 
	#		a.assetId, 
	#		JSON_SET(
	#			a.assetTransactionJSON,
	#			'$.buyername',REPLACE(CONCAT(JSON_UNQUOTE(JSON_EXTRACT(b.userProfileTransactionJSON,'$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(b.userProfileTransactionJSON,'$.middlename')), ' ', JSON_UNQUOTE(JSON_EXTRACT(b.userProfileTransactionJSON,'$.lastname'))),'  ',' '), 
	#			'$.sellername',REPLACE(CONCAT(JSON_UNQUOTE(JSON_EXTRACT(s.userProfileTransactionJSON,'$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(s.userProfileTransactionJSON,'$.middlename')), ' ', JSON_UNQUOTE(JSON_EXTRACT(s.userProfileTransactionJSON,'$.lastname'))),'  ',' ')) AS assetTransactionJSON
    #    FROM assettransactions a INNER JOIN  
	#	vw_currentprofiledetails s ON  JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.selleruserid')) = s.userId INNER JOIN 
	#	vw_currentprofiledetails b ON  CAST(b.userid AS CHAR(10)) = CAST(JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.buyeruserid')) AS CHAR(10)) INNER JOIN 
    #    vw_currentauctiondetails ad ON ad.createdate = a.createdate AND ad.auctionStatus = 'Active'
	#	WHERE 
	#		JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.selleruserid')) = uuserid AND 
    #        a.assetId = aassetId AND a.assetTransactionOperation = 'Auction Asset'
	#) c
    #);
	#SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.auction', CAST(COALESCE(@auctionArray,'[{ "assetid": null, "biddate": null, "bidprice": null, "buyername": null, "createdate": null, "sellername": null, "buyeruserid": null, "selleruserid": null, "auctionstatus":null}]') AS JSON)) AS assetJSON);
  
	#Get the current max bid or zero if there is no bid.    
    #SET @currentMaxBid = (SELECT MAX(bidprice) AS bidprice
    # FROM
    #   JSON_TABLE(
    #     JSON_EXTRACT(@assetTransactionJSON,'$.auction'),
    #     "$[*]"
    #     COLUMNS(bidprice DOUBLE PATH "$.bidprice",assetid DOUBLE PATH "$.assetid",selleruserid DOUBLE PATH "$.selleruserid")
    #   ) data WHERE selleruserid = uuserid AND assetId = aassetId);
    #SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.currentmaxbid', COALESCE(@currentMaxBid,0)) AS assetJSON);
    
    #Let's get the user's fixed salt to retreive 
    #SET @assetTransactionJSON = (SELECT 
	#			JSON_SET(@assetTransactionJSON,'$.userfixedsalt', 
	#				(SELECT JSON_EXTRACT(userJSON,'$.userfixedsalt') FROM users WHERE userid = uuserid)
    #            ));
    
  
    #Get the status of the purchase
	#SET @purchase = (SELECT assetTransactionJSON FROM assettransactions WHERE userId = uuserId AND assetId = aassetId AND assetTransactionOperation = 'Purchase Asset' ORDER BY createDate DESC LIMIT 1);
	#SET @assetTransactionJSON = (SELECT JSON_SET(@assetTransactionJSON,'$.purchase', CAST(@purchase AS JSON)) AS assetJSON);


	SELECT @assetTransactionJSON AS transactionJSON;
    #Changed by Mehmet.
    #SELECT assetTransactionJSON  FROM db_work.assettransactions WHERE issuerId = 15 AND assetId = 1 ORDER BY assetTransactionJSON DESC LIMIT 1;
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_AssetTransactionPerSubscription
DELIMITER //
CREATE PROCEDURE `spc_AssetTransactionPerSubscription`(iissuerId int, aassetId int, ssubscriberId int, ssubscriptionId int)
BEGIN
#This procedure returns the details of a transaction, could be attached documents or listing details. 
#CALL spc_AssetTransactionPerSubscription(1,1,21,1);
DECLARE iiissuerid INT; 
DECLARE aaassetid INT;
DECLARE sssubscriberid INT;
DECLARE sssubscriptionid INT;
DECLARE ssqlquery longtext;

#Create the cursor
DECLARE subscribers CURSOR FOR
SELECT issuerid,assetid,subscriberid, ssubscriptionId AS subscriptionid ,CONCAT('INSERT INTO mysubscriptions SELECT ',issuerid,' AS isuerid, ',assetid, ' AS assetid, ' , subscriberid,' AS subscriberid,', ssubscriptionId,' AS subscriptionid, JSON_MERGE_PATCH(''{"createdate": "20200101"}'', ',GROUP_CONCAT("'",assetTransactionJSON,"'" ORDER BY createdate ASC),') AS sqlquery;') AS sqlquery
FROM 
(
	SELECT issuerId, assetId, subscriberId, ssubscriptionId AS subscriptionid, assetTransactionOperation, assetTransactionJSON, createdate
	FROM assettransactions WHERE assetTransactionOperation = 'Create Subscription' AND issuerid = iissuerId AND assetid = aassetid AND 
    subscriberid = ssubscriberid AND JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) = ssubscriptionId
	ORDER BY issuerid,assetid, createdate DESC 
) a
GROUP BY issuerid,assetid, subscriberid;
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET @done = 1;
SET group_concat_max_len = 9000000;
SET @done = 0;

#drop the temp table
DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

#Create the temp table
CREATE TEMPORARY TABLE mysubscriptions
( 
	issuerid INT, 
	assetid INT, 
	subscriberid INT,
    subscriptionid INT,
	transactionJSON JSON
);

#Loop on the subscribers
OPEN subscribers;
	REPEAT
	  FETCH subscribers
	  INTO iiissuerid,aaassetid,sssubscriberid,sssubscriptionid,ssqlquery;
		IF NOT @done THEN
			#SELECT @querystring;
			SET @querystring := (SELECT ssqlquery);
			PREPARE stmt FROM @querystring;
			EXECUTE stmt;
			DEALLOCATE PREPARE stmt; 		  
		END IF;
	UNTIL @done
	END REPEAT;
CLOSE subscribers;


#Get all the active documents
SET @documentArray = (    
	SELECT CAST(CONCAT('[',GROUP_CONCAT(a.assetTransactionJSON ORDER BY JSON_EXTRACT(a.assetTransactionJSON,'$.createdate') DESC),']') AS JSON) 
	FROM
	(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY JSON_EXTRACT(assetTransactionJSON,'$.documenthash'),JSON_EXTRACT(assetTransactionJSON,'$.documenttype') ORDER BY createDate DESC) AS rownumber
	FROM assettransactions WHERE issuerid = iissuerId AND assetId = aassetId AND subscriberid = ssubscriberId AND JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) = ssubscriptionId
    AND assetTransactionOperation = 'Attach Subscription Document' 
	) a    
	WHERE JSON_EXTRACT(a.assetTransactionJSON,'$.documentstatus') = 'Created' AND a.rownumber = 1);
SET @documentArray = (SELECT COALESCE(@documentArray, CAST('[]' AS JSON))); 

#Get all the actions against this subscription
SET @actionArray = (
	SELECT CAST(CONCAT('[',GROUP_CONCAT(a.assetTransactionJSON),']') AS JSON) 
	FROM
	(
	SELECT assetTransactionJSON
	FROM assettransactions WHERE 
    issuerid = iissuerId AND assetId = aassetId AND subscriberid = ssubscriberId AND JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) = ssubscriptionId AND assetTransactionOperation = 'Create Action' 
	) a    
);
SET @actionArray = (SELECT COALESCE(@actionArray, CAST('[]' AS JSON))); 


#Return query
SELECT 	
		JSON_SET(userProfileTransactionJSON, 
		'$.subscription', a.transactionJSON,
		'$.assetid', a.assetid,
		'$.subscriberid', a.subscriberid,
		'$.issuerid', a.issuerid,
        '$.subscriptiondocuments',CAST(@documentArray AS JSON),
        '$.subscriptionactions',CAST(@actionArray AS JSON),
		'$.assistants', (SELECT
        	CAST(CONCAT('[',GROUP_CONCAT(d.assetTransactionJSON ORDER BY JSON_EXTRACT(d.assetTransactionJSON,'$.createdate') DESC),']') AS JSON) AS assetTransactionJSON
FROM 
(
SELECT
	ROW_NUMBER() OVER (PARTITION BY JSON_UNQUOTE(JSON_EXTRACT(b.assetTransactionJSON,'$.assistantid'))  ORDER BY b.createdate DESC) AS rownum,
	JSON_UNQUOTE(JSON_EXTRACT(b.assetTransactionJSON,'$.assistantid')) AS assistantid, 
    b.createdate,
	#CAST(CONCAT('[',GROUP_CONCAT(
        JSON_SET(
		JSON_MERGE_PATCH(b.assetTransactionJSON,c.userProfileTransactionJSON)
        ,'$.invitestatus',JSON_EXTRACT(b.assetTransactionJSON,'$.status') ) AS assetTransactionJSON
    #    ),']') AS JSON) AS assetTransactionJSON
FROM 
	assettransactions b INNER JOIN 
    vw_currentprofiledetails c ON JSON_UNQUOTE(JSON_EXTRACT(b.assetTransactionJSON,'$.assistantid')) = c.userid 
WHERE 
	b.assetTransactionOperation = 'Add Assistant' AND 
    b.issuerid = a.issuerid AND 
    b.assetid = a.assetid AND 
    b.subscriberid = a.subscriberid AND
    JSON_UNQUOTE(JSON_EXTRACT(b.assetTransactionJSON,'$.subscriptionid')) = ssubscriptionId
ORDER BY 
	b.createdate DESC
) d WHERE d.rownum = 1

        
        
        ),
		'$.signatures', COALESCE((SELECT CAST(CONCAT('[',GROUP_CONCAT(assetTransactionJSON),']') AS JSON) FROM assettransactions WHERE assetTransactionOperation = 'Sign Subscription' AND issuerid = a.issuerid AND assetid = a.assetid AND subscriberid = a.subscriberid AND JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) = a.subscriptionid ORDER BY createdate DESC),CAST('[]' AS JSON))
		) AS transactionJSON 
FROM 
(
	SELECT DISTINCT issuerid, assetid, subscriberid, subscriptionid, transactionJSON FROM mysubscriptions
) a INNER JOIN vw_currentprofiledetails w ON a.subscriberid = w.userid; 



#SELECT * FROM assettransactions
#WHERE assetTransactionOperation = 'Create Subscription' AND issuerId = iissuerId 
#AND assetid = aassetId #AND subscriberid = ssubscriberid
#ORDER BY issuerid,assetid,subscriberid, createdate DESC;
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_AssetTransactionPerSubscriptionReject
DELIMITER //
CREATE PROCEDURE `spc_AssetTransactionPerSubscriptionReject`(iissuerid int, aassetid int, ssubscriberid int, ssubscriptionid int)
BEGIN
#This procedure is designed to reject signatures of a subscription, by updating the signatures to cancelled. 
#CALL spc_AssetTransactionPerSubscriptionReject(2,1,16,2)

UPDATE assettransactions
SET assetTransactionOperation = 'Sign Subscription Rejected'
WHERE 
	issuerid = iissuerid AND 
	assetId = aassetid AND 
	subscriberid = ssubscriberid AND 
	JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) = ssubscriptionid AND 
	assetTransactionOperation = 'Sign Subscription';
    
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_AssetTransactionPerSubscriptionTEST
DELIMITER //
CREATE PROCEDURE `spc_AssetTransactionPerSubscriptionTEST`()
BEGIN
#This procedure returns the details of a transaction, could be attached documents or listing details. 
#CALL spc_AssetTransactionPerSubscription(1,1,21,1);
DECLARE iiissuerid INT; 
DECLARE aaassetid INT;
DECLARE sssubscriberid INT;
DECLARE sssubscriptionid INT;
DECLARE aaassettransactionJSON longtext;

#Create the cursor
DECLARE subscribers CURSOR FOR
	SELECT 
		issuerid, assetid, subscriberid, JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) AS subscriptionid, assetTransactionJSON
	FROM assettransactions 
	WHERE assetTransactionOperation = 'Create Subscription' AND subscriberid = 36;
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET @done = 1;
SET group_concat_max_len = 9000000;
SET @done = 0;

#drop the temp table
DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

#Create the temp table
CREATE TEMPORARY TABLE mysubscriptions
( 
	issuerid INT, 
	assetid INT, 
	subscriberid INT,
    subscriptionid INT,
	assettransactionJSON JSON,
    PRIMARY KEY (issuerid, assetid, subscriberid)
);

#Loop on the subscribers
OPEN subscribers;
	REPEAT
	  FETCH subscribers
	  INTO iiissuerid,aaassetid,sssubscriberid,sssubscriptionid,aaassettransactionJSON;
		IF NOT @done THEN
		#SELECT iiissuerid;

		INSERT INTO mysubscriptions
		VALUES (iiissuerid,aaassetid,sssubscriberid,sssubscriptionid,aaassettransactionJSON)
		ON DUPLICATE KEY UPDATE
		issuerid = iiissuerid, assetid = aaassetid, assettransactionJSON = JSON_MERGE_PATCH(assettransactionJSON,aaassettransactionJSON);




		END IF;
	UNTIL @done
	END REPEAT;
CLOSE subscribers;



END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_CreateSurvey
DELIMITER //
CREATE PROCEDURE `spc_CreateSurvey`(surveyFromUserJSON json)
BEGIN
INSERT INTO surveys (Id,surveyJSON) VALUES (2,surveyFromUserJSON);
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_ProfileTransactionCreate
DELIMITER //
CREATE PROCEDURE `spc_ProfileTransactionCreate`(uuserId int, uuserProfileTransactionOperation varchar(50) ,uuserProfileTransactionJSON json)
BEGIN
#This procedure creates users in the database
#Sample call 
#CALL spc_ProfileTransactionCreate(8,'Create Profile','{"firstname":"cem","lastname":"demircioglu","dateofbirth":"11/11/2010"}');

#Find the highest userProfileTransactionId and get a salt from users table
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @createDateJSON = (SELECT JSON_UNQUOTE(JSON_EXTRACT(uuserProfileTransactionJSON,'$.createdate')));
SET @createDateJSON = (SELECT CASE WHEN @createDateJSON = 'null' THEN null ELSE @createDateJSON END);
SET @userProfileTransactionId = (SELECT COALESCE(MAX(userProfileTransactionId),0)+1 FROM userprofiletransactions);
SET @userProfileTransactionJSON = (SELECT JSON_SET(uuserProfileTransactionJSON,'$.createdate',COALESCE(@createDateJSON,@createDate)) COLLATE utf8mb4_unicode_ci);
SET @userSalt = (SELECT JSON_UNQUOTE(JSON_EXTRACT(userJSON,'$.usersalt')) FROM users WHERE userID = uuserId);
SET @userProfileTransactionHash = (SELECT SHA2(CONCAT(@userProfileTransactionJSON,@userSalt),256));

#Insert the profile data into the userprofiletransactions table
INSERT INTO userprofiletransactions (userProfileTransactionId, userId, userProfileTransactionOperation, userProfileTransactionJSON, userProfileTransactionHash, createDate)
VALUES(@userProfileTransactionId, uuserId, uuserProfileTransactionOperation, @userProfileTransactionJSON, @userProfileTransactionHash, @createDate);

#Log activity
SET @UuserJSON = (SELECT JSON_INSERT(CAST("{}" AS JSON), '$.spcProcedure', 'spc_ProfileTransactionCreate'));   
INSERT INTO systemlogs (createDate, userActivity, logJSON)
VALUES (@createDate, uuserProfileTransactionOperation ,@userProfileTransactionJSON);

SELECT uuserId AS userid, JSON_OBJECT("returnvalue",1) AS transactionJSON;
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_ProfileTransactionPerOperationShow
DELIMITER //
CREATE PROCEDURE `spc_ProfileTransactionPerOperationShow`(uuserId int, uuserProfileTransactionOperation varchar(50), displayOrder varchar(50))
ProfileTransaction: BEGIN
#This is a dynamic parser of JSON documents. It will parse any type of operation. 
#DisplayOrder could be all, newest, oldest
#CALL spc_ProfileTransactionPerOperationShow(1,'Attach Document', 'All');
SET SESSION group_concat_max_len = 1000000;

#Basic parameters
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));

#Get the JSON signature of the operation. 
#SET @SampleJSONDocument = (SELECT JSON_KEYS(userProfileTransactionJSON) FROM userprofiletransactions WHERE userid = uuserid AND userProfileTransactionOperation = uuserProfileTransactionOperation LIMIT 1);

IF (uuserProfileTransactionOperation = "Attach Document") THEN #Here we need to handle the deleted files
	#Only get the json document of a user  
	SELECT userid, transactionJSON FROM (
	SELECT 
		userid, userProfileTransactionJSON AS transactionJSON, ROW_NUMBER() OVER (PARTITION BY userid, JSON_EXTRACT(userProfileTransactionJSON,'$.createdate') ORDER BY createDate DESC) as rownumber 
    FROM userprofiletransactions 
	WHERE userProfileTransactionOperation = uuserProfileTransactionOperation AND userid = uuserid
	) a WHERE a.rownumber = CASE WHEN displayOrder = 'Newest' THEN 1 ELSE a.rownumber END;
ELSE #This should show the latest status per operation. 
	SELECT userid, transactionJSON FROM (
	SELECT 
		userid, userProfileTransactionJSON AS transactionJSON, ROW_NUMBER() OVER (PARTITION BY userid ORDER BY createDate DESC) as rownumber 
    FROM userprofiletransactions 
	WHERE userProfileTransactionOperation = uuserProfileTransactionOperation AND userid = uuserid
	) a WHERE a.rownumber = CASE WHEN displayOrder = 'Newest' THEN 1 ELSE a.rownumber END;
END IF;




/*
#Create the dynamic sql document
SET @SQLString = (
	SELECT GROUP_CONCAT(B.arrayValue)
    FROM 
		(SELECT
			CONCAT("JSON_UNQUOTE(JSON_EXTRACT(userProfileTransactionJSON,'$.",JSON_UNQUOTE(arrayValue),"')) AS ",LOWER(JSON_UNQUOTE(arrayValue))) AS arrayValue 
		FROM
		JSON_TABLE(
		   @SampleJSONDocument,
			 '$[*]'
			COLUMNS(
				arrayValue JSON PATH '$')
		) AS a WHERE a.arrayValue <> 'assetid' ORDER BY a.arrayValue) B 
);

#This ordering is special for attached documents
IF (displayOrder = "All") THEN
	SET @SQLStringDisplayOrder = " createdate DESC;";
END IF;

IF (displayOrder = "Newest") THEN
	SET @SQLStringDisplayOrder = " createdate DESC LIMIT 1;";
END IF;

IF (displayOrder = "Oldest") THEN
	SET @SQLStringDisplayOrder = " createdate ASC LIMIT 1;";
END IF;

#Add the necessary concat strings
SET @SQLString = (SELECT CONCAT("CREATE TEMPORARY TABLE IF NOT EXISTS profileshowtable AS SELECT * FROM (SELECT  userProfileTransactionOperation AS userprofiletransactionoperation, userid, userprofiletransactionid,", @SQLString, " FROM userprofiletransactions) A WHERE A.userId = ", uuserId, " AND A.userProfileTransactionOperation = '",  uuserProfileTransactionOperation, "'"));

#In case there are no documents return nothing. 
IF (length(@SQLString) > 10) THEN
	#Execute the string 
	PREPARE stmt1 FROM @SQLString; 
	EXECUTE stmt1; 
	DEALLOCATE PREPARE stmt1; 
END IF;

#Check if the profile show table exits
CALL sys.table_exists('db_work', 'profileshowtable', @exists);

#This means user does not exits, leaves the stored procedure
IF CASE WHEN @exists = "" then 1 else 0 end = 1 THEN
	LEAVE ProfileTransaction;
END IF; 

SET @SQLString = (SELECT CONCAT('SELECT * FROM profileshowtable ORDER BY ', @SQLStringDisplayOrder));

#In case there are no documents return nothing. 
IF (length(@SQLString) > 10) THEN
	#Execute the string 
	PREPARE stmt1 FROM @SQLString; 
	EXECUTE stmt1; 
	DEALLOCATE PREPARE stmt1; 
END IF;

#Drop the temp table
DROP TEMPORARY TABLE IF EXISTS profileshowtable;

#Log activity
SET @UuserJSON = (SELECT JSON_INSERT(JSON_OBJECT("sqlstring", @SQLString), '$.spcProcedure', 'spc_ProfileTransactionPerOperationShow'));   
INSERT INTO systemlogs (createDate, userActivity, logJSON)
VALUES (@createDate,'Profile transaction query completed.',@uuserJSON);
*/

END ProfileTransaction//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserAdminCreate
DELIMITER //
CREATE PROCEDURE `spc_UserAdminCreate`(uuserEmail VARCHAR(55),uuserPassword VARCHAR(55))
CreateUser: BEGIN
#This procedure assign user to be an admin, should be deleted after the first use
#Sample call 
#CALL spc_UserAdminCreate('cem@cem.com','passcem123');

#####Create an ordinary user
CALL spc_UserCreate(uuserEmail,uuserPassword);
#####
UPDATE db_work.users
SET userJSON = JSON_SET(userJSON,'$.isadmin',1)
WHERE userName = uuserEmail;
#####
UPDATE db_work.users
SET userJSON = JSON_SET(userJSON,'$.publickey','0xdEfCe4fd5D6eDa9caac6bB2fa3E7516cC077d5c8','$.email',uuserEmail)
WHERE userName = uuserEmail;
####Select the admin using the following code
#CALL spc_UserAdminSelect('cem@cem.com','passcem123');


END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserAdminProcessShow
DELIMITER //
CREATE PROCEDURE `spc_UserAdminProcessShow`(iissuerid int, aassetTransactionOperation varchar(50))
BEGIN
#This procedure is designed for the admin for checking the activities of a user
#Soon this query needed to be changed to include display order functionality, all, newest, oldest. 
#CALL spc_UserAdminProcessShow(3,'Create Listing Details');
DECLARE iiissuerid INT; 
DECLARE aaassetid INT;
DECLARE sssubscriberid INT;
DECLARE sssubscriptionid INT;
DECLARE aaassettransactionJSON longtext;

#Create the cursor
DECLARE subscribers CURSOR FOR
	SELECT 
		issuerid, assetid, subscriberid, JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid')) AS subscriptionid, assetTransactionJSON
	FROM assettransactions 
	WHERE assetTransactionOperation = 'Create Subscription' AND subscriberid = iissuerid #I know this is not correct, otherwise Ugur is going to blow up. 
    ORDER BY createdate ASC; 
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET @done = 1;
SET group_concat_max_len = 9000000;
SET @done = 0;

#Chech subscriptions, there is a name mix here, that is intentional to avoid Ugur changing his code
IF aassetTransactionOperation = 'Create Subscription' THEN

	#Drop the temp table
	DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

	#Create the temp table
	CREATE TEMPORARY TABLE mysubscriptions
	( 
		issuerid INT, 
		assetid INT, 
		subscriberid INT,
		subscriptionid INT,
		assettransactionJSON JSON,
		PRIMARY KEY (issuerid, assetid, subscriberid, subscriptionid)
	);

	#Loop on the subscribers
	OPEN subscribers;
		REPEAT
		  FETCH subscribers
		  INTO iiissuerid,aaassetid,sssubscriberid,sssubscriptionid,aaassettransactionJSON;
			IF NOT @done THEN
            
				INSERT INTO mysubscriptions
					VALUES (iiissuerid,aaassetid,sssubscriberid,sssubscriptionid,aaassettransactionJSON)
				ON DUPLICATE KEY UPDATE
					issuerid = iiissuerid, assetid = aaassetid, subscriptionid = sssubscriptionid,  assettransactionJSON = JSON_MERGE_PATCH(assettransactionJSON,aaassettransactionJSON);

			END IF;
		UNTIL @done
		END REPEAT;
	CLOSE subscribers;

	#Final query
	SELECT 
		JSON_SET(b.assettransactionJSON,
        '$.issuerid',b.issuerid,
        '$.assetid',b.assetid, 
        '$.subscriberid',b.subscriberid,
        '$.subscriptionid',b.subscriptionid,
		'$.issuername', JSON_EXTRACT(a.assettransactionJSON,'$.issuername'),
        '$.fundname',JSON_EXTRACT(a.assettransactionJSON,'$.fundname'),
        '$.status',JSON_EXTRACT(a.assettransactionJSON,'$.status')
		) AS transactionJSON
	FROM mysubscriptions b INNER JOIN vw_currentlistingdetails a ON a.userid = b.issuerid AND a.assetid = b.assetid
    ORDER BY JSON_EXTRACT(b.assettransactionJSON,'$.createdate') DESC;
	#FROM mysubscriptions b INNER JOIN vw_currentsubscriptions a ON a.issuerid = b.issuerid AND a.assetid = b.assetid;
    
END IF;

IF aassetTransactionOperation = 'Create Listing' THEN
DROP TEMPORARY TABLE IF EXISTS assetshowtable;

	#The query returns the results of listings	
    #This ordering is special for attached documents
	#IF (displayOrder = "All") THEN
	#	SET @SQLStringDisplayOrder = " ";
    #    SET @SQLStringDisplayOrderEnd = " ;";
	#END IF;

	#IF (displayOrder = "Newest") THEN
	#	SET @SQLStringDisplayOrder = " DESC ";
    #    SET @SQLStringDisplayOrderEnd = "WHERE a.rownumber = 1;";
	#END IF;

	#IF (displayOrder = "Oldest") THEN
	#	SET @SQLStringDisplayOrder = " ASC ";
    #    SET @SQLStringDisplayOrderEnd = "WHERE a.rownumber = 1;";
	#END IF;
    
	#Create the dynamic sql document
	#SET @SQLString = (SELECT CONCAT("CREATE TEMPORARY TABLE IF NOT EXISTS assetshowtable AS SELECT assetTransactionJSON FROM ( SELECT *, ROW_NUMBER() OVER (PARTITION BY assetId ORDER BY assetTransactionId ",@SQLStringDisplayOrder,") AS rownumber FROM db_work.assettransactions WHERE userid = ",uuserid," AND assetTransactionOperation = '",aassetTransactionOperation,"' ) a ",@SQLStringDisplayOrderEnd)); 
	#SELECT @SQLString;
    
   	DROP TEMPORARY TABLE IF EXISTS assetverification;
	CREATE TEMPORARY TABLE assetverification AS        
	SELECT 
		b.userid, b.issuerid, b.assetid, b.assetTransactionJSON
	FROM 
	(
		SELECT a.*,ROW_NUMBER() OVER (PARTITION BY issuerid, assetid ORDER BY createDate DESC) as rownumber 
		FROM assettransactions a 
		WHERE a.assetTransactionOperation = 'Create Listing' AND a.issuerid = iissuerid
	) b WHERE b.rownumber = 1;


	SELECT 
		w.issuerid, w.assetid, 
		JSON_SET(w.assetTransactionJSON,'$.issuerid',w.issuerid,'$.assetid',w.assetid,
        '$.assetverification',a.assetTransactionJSON
		) AS transactionJSON
    FROM
	(
	SELECT assetid, issuerid,CAST(COALESCE(assetTransactionJSON,'{"verificationstatus": "Created"}') AS JSON) AS assetTransactionJSON FROM 
		(	
			SELECT assetTransactionJSON, assetid, issuerid, ROW_NUMBER() OVER (PARTITION BY issuerid, assetid ORDER BY createDate DESC) AS rownumber FROM assettransactions
			WHERE issuerid = iissuerId AND assetTransactionOperation = 'Check Listing'
		) a WHERE a.rownumber = 1 
     ) w LEFT JOIN assetverification a ON w.issuerid = a.issuerid AND w.assetid = a.assetid
    WHERE w.issuerid = iissuerid 
    ORDER BY JSON_EXTRACT(w.assetTransactionJSON,'$.createdate') DESC;   

	#SELECT 
	#	w.issuerid, w.assetid, 
	#	JSON_SET(w.assetTransactionJSON,'$.issuerid',w.issuerid,'$.assetid',w.assetid,
    #    '$.assetverification',a.assetTransactionJSON
	#	) AS transactionJSON
	#FROM vw_currentlistingdetails w LEFT JOIN assetverification a ON w.issuerid = a.issuerid AND w.assetid = a.assetid
    #WHERE w.issuerid = iissuerid;



    DROP TEMPORARY TABLE IF EXISTS assetverification;
    
	#In case there are no documents return nothing. 
	#IF (length(@SQLString) > 10) THEN
	#	#Execute the string 
	#	PREPARE stmt1 FROM @SQLString; 
	#	EXECUTE stmt1; 
	#	DEALLOCATE PREPARE stmt1; 
	#END IF;

	#Get the verification statuses per asset
    
    #Get the auction process per asset
    
    #Get the purchasing processs per asset 
	#SELECT assetTransactionJSON FROM assetshowtable;
    

END IF;

END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserAdminSelect
DELIMITER //
CREATE PROCEDURE `spc_UserAdminSelect`(uuserEmail VARCHAR(55),uuserPassword VARCHAR(55))
BEGIN
#This procedure returns the user json column if userid is provided
#CALL spc_UserAdminSelect('cem@cem.com','passcem123');

#Check if the user is accredited
SELECT JSON_REMOVE(userJSON,'$.usersalt') AS transactionJSON FROM users u WHERE 
JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.isadmin')) = 1 AND
JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.useremail')) = uuserEmail AND `userPassword` = SHA2(CONCAT(uuserPassword,JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.usersalt'))),256);




END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserAdminShowAll
DELIMITER //
CREATE PROCEDURE `spc_UserAdminShowAll`(object varchar(50), objectFilter varchar(50))
ProfileTransaction: BEGIN
#This procedure is designed to show users, listings, auctions, and purchases. 
#CALL spc_UserAdminShowAll('users','All');
#CALL spc_UserAdminShowAll('listings','All');
#CALL spc_UserAdminShowAll('auctions','All');
#CALL spc_UserAdminShowAll('subscriptions','All');
#CALL spc_UserAdminShowAll('assistants','All');
#CALL spc_UserAdminShowAll('subscribers','All');


DECLARE iissuerid INT; 
DECLARE aassetid INT;
DECLARE ssubscriberid INT;
DECLARE ssqlquery longtext;
   
DECLARE subscriptions CURSOR FOR
SELECT issuerid,assetid,subscriberid, CONCAT('INSERT INTO mysubscriptions SELECT ',issuerid,' AS isuerid, ',assetid, ' AS assetid, ' , subscriberid,' AS subscriberid, JSON_MERGE_PATCH(''{"createdate": "20200101"}'', ',GROUP_CONCAT("'",assetTransactionJSON,"'" order by createdate asc),') AS sqlquery;') AS sqlquery
FROM 
(
	SELECT * FROM assettransactions
	WHERE assetTransactionOperation = 'Create Subscription' #AND issuerid = 2 AND assetid = 1
	ORDER BY issuerid,assetid,subscriberid, createdate DESC 
) a
GROUP BY issuerid,assetid, subscriberid, JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.subscriptionid'));

DECLARE listings CURSOR FOR
SELECT issuerid,assetid,subscriberid, CONCAT('INSERT INTO mysubscriptions SELECT ',issuerid,' AS isuerid, ',assetid, ' AS assetid, ' , subscriberid,' AS subscriberid, JSON_MERGE_PATCH(''{"createdate": "20200101"}'', ',GROUP_CONCAT("'",assetTransactionJSON,"'" ORDER BY createdate ASC),') AS sqlquery;') AS sqlquery
FROM 
(
	SELECT * FROM assettransactions
	WHERE assetTransactionOperation IN ("Create Listing","Check Listing")
	ORDER BY issuerid,assetid, createdate DESC 
) a
GROUP BY issuerid,assetid, subscriberid;

DECLARE assistants CURSOR FOR
SELECT issuerid,assetid,subscriberid, CONCAT('INSERT INTO mysubscriptions SELECT ',issuerid,' AS isuerid, ',assetid, ' AS assetid, ' , subscriberid,' AS subscriberid, JSON_MERGE_PATCH(''{"createdate": "20200101"}'', ',GROUP_CONCAT("'",assetTransactionJSON,"'" ORDER BY createdate ASC),') AS sqlquery;') AS sqlquery
FROM 
(
	SELECT a.*, COALESCE(u.username,JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.assistantemail'))) AS assistantemail
	FROM assettransactions a LEFT JOIN users u ON u.userid = JSON_UNQUOTE(JSON_EXTRACT(a.assetTransactionJSON,'$.assistantid'))
	WHERE assetTransactionOperation IN ('Add Assistant','Create Assistant') 
	ORDER BY issuerid,assetid, createdate DESC 
) a
GROUP BY issuerid,assetid, subscriberid, assistantemail;

DECLARE subscribers CURSOR FOR
SELECT issuerid,assetid,subscriberid, CONCAT('INSERT INTO mysubscriptions SELECT ',issuerid,' AS isuerid, ',assetid, ' AS assetid, ' , subscriberid,' AS subscriberid, JSON_MERGE_PATCH(''{"createdate": "20200101"}'', ',GROUP_CONCAT("'",assetTransactionJSON,"'" ORDER BY createdate ASC),') AS sqlquery;') AS sqlquery
FROM 
(
	SELECT issuerId, assetId, subscriberId, assetTransactionOperation, assetTransactionJSON, createdate
	FROM assettransactions WHERE assetTransactionOperation = 'Create Subscription' #AND issuerid = 2 AND assetid = 1 AND subscriberid = 18
	ORDER BY issuerid,assetid, createdate DESC 
) a
GROUP BY issuerid,assetid, subscriberid;
DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET @done = 1;


SET group_concat_max_len = 9000000;

#This section is for the users
IF (object = 'users') THEN
	DROP TEMPORARY TABLE IF EXISTS userprofile;
	CREATE TEMPORARY TABLE  userprofile AS    
	SELECT userid, userProfileTransactionJSON FROM ( 
	SELECT 
		userid,
		JSON_SET(userProfileTransactionJSON,'$.userid',userid) AS userProfileTransactionJSON, 
		ROW_NUMBER() OVER (PARTITION BY userid ORDER BY createDate DESC) as rownumber FROM userprofiletransactions WHERE userProfileTransactionOperation =  'Create Profile'
	) a WHERE a.rownumber = 1;

	DROP TEMPORARY TABLE IF EXISTS userprofilestatus;
	CREATE TEMPORARY TABLE  userprofilestatus AS    
	SELECT userid, userProfileTransactionJSON FROM ( 
	SELECT 
		userid,
		JSON_OBJECT(
			'createdate',JSON_EXTRACT(userProfileTransactionJSON,'$.createdate'),
            'status',JSON_EXTRACT(userProfileTransactionJSON,'$.status'),
            'substatus',JSON_EXTRACT(userProfileTransactionJSON,'$.substatus'),
            'userid',JSON_EXTRACT(userProfileTransactionJSON,'$.userid')
            ) AS userProfileTransactionJSON, 
		ROW_NUMBER() OVER (PARTITION BY userid ORDER BY createDate DESC) as rownumber FROM userprofiletransactions WHERE userProfileTransactionOperation =  'Create Profile'
	) a WHERE a.rownumber = 1;


	DROP TEMPORARY TABLE IF EXISTS userkycverification;
	CREATE TEMPORARY TABLE  userkycverification AS  
	SELECT userid, verificationstatus FROM (
	SELECT 
		userid, userProfileTransactionJSON AS verificationstatus, ROW_NUMBER() OVER (PARTITION BY userid ORDER BY createDate DESC) as rownumber 
    FROM userprofiletransactions 
	WHERE userProfileTransactionOperation = 'Check KYC'
	) a WHERE a.rownumber = 1;

	DROP TEMPORARY TABLE IF EXISTS useraccreditedverification;
	CREATE TEMPORARY TABLE  useraccreditedverification AS  
	SELECT userid, verificationstatus FROM (
	SELECT 
		userid, userProfileTransactionJSON AS verificationstatus, ROW_NUMBER() OVER (PARTITION BY userid ORDER BY createDate DESC) as rownumber 
    FROM userprofiletransactions 
	WHERE userProfileTransactionOperation = 'Check Accreditation'
	) a WHERE a.rownumber = 1;

	DROP TEMPORARY TABLE IF EXISTS userwalletverification;
	CREATE TEMPORARY TABLE  userwalletverification AS  
	SELECT userid, verificationstatus FROM (
	SELECT 
		userid, userProfileTransactionJSON AS verificationstatus, ROW_NUMBER() OVER (PARTITION BY userid ORDER BY createDate DESC) as rownumber 
    FROM userprofiletransactions 
	WHERE userProfileTransactionOperation = 'Create Wallet'
	) a WHERE a.rownumber = 1;
    
	DROP TEMPORARY TABLE IF EXISTS userstatuses;
	CREATE TEMPORARY TABLE  userstatuses AS  
	SELECT userid, CONCAT('[',GROUP_CONCAT(verificationstatus ORDER BY userid, JSON_UNQUOTE(JSON_EXTRACT(verificationstatus,'$.createdate')) DESC),']') AS verificationstatus FROM 
	(
		SELECT * FROM userkycverification 
		#UNION ALL
		##SELECT * FROM useraccreditedverification
        UNION ALL
        SELECT * FROM userwalletverification
        UNION ALL 
        SELECT * FROM userprofilestatus
	) a
	GROUP BY userid;
	
    DROP TEMPORARY TABLE IF EXISTS useraccreditationstatuses;
	CREATE TEMPORARY TABLE useraccreditationstatuses AS  
	SELECT userid, CONCAT('[',GROUP_CONCAT(verificationstatus ORDER BY userid, JSON_UNQUOTE(JSON_EXTRACT(verificationstatus,'$.createdate')) DESC),']') AS verificationstatus FROM 
	(
		SELECT * FROM useraccreditedverification
    ) a
	GROUP BY userid;
	
	#SELECT u.userid,JSON_SET(userProfileTransactionJSON, "$.status", CAST(v.verificationstatus AS JSON) ) AS transactionJSON FROM userprofile u LEFT JOIN userstatuses v ON u.userid = v.userid;
	SELECT JSON_SET(userProfileTransactionJSON, "$.status", CAST(v.verificationstatus AS JSON) 
    ,"$.statusaccreditation", CAST(a.verificationstatus AS JSON)
    ) AS transactionJSON FROM 
    userprofile u LEFT JOIN 
    userstatuses v ON u.userid = v.userid LEFT JOIN
	useraccreditationstatuses a ON u.userid = a.userid
	WHERE JSON_EXTRACT(u.userprofileTransactionJSON, '$.phone') IS NOT NULL;
    
	#DROP TEMPORARY TABLE IF EXISTS userprofile;
	#DROP TEMPORARY TABLE IF EXISTS userverification;
    #DROP TEMPORARY TABLE IF EXISTS userprofilestatus;
    LEAVE ProfileTransaction;
END IF;

#Changed by Mehmet.
IF (object = 'assistants') THEN

	SET @done = 0;

	DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

	#Create the temp table
    CREATE TEMPORARY TABLE mysubscriptions
	( 
	issuerid INT, 
	assetid INT, 
	subscriberid INT, 
	transactionJSON JSON
	);

	OPEN assistants;
		REPEAT
		  FETCH assistants
		  INTO iissuerid,aassetid,ssubscriberid,ssqlquery;
			IF NOT @done THEN
				#SELECT @querystring;
				SET @querystring := (SELECT ssqlquery);
				PREPARE stmt FROM @querystring;
				EXECUTE stmt;
				DEALLOCATE PREPARE stmt; 		  
			END IF;
		UNTIL @done
		END REPEAT;
            

	CLOSE assistants;

	#Update the assistants, that are missing the subscriber as they are invited by the issuer
	UPDATE mysubscriptions
    SET transactionJSON =  JSON_SET(transactionJSON, '$.subscriberid', 0) 
    WHERE JSON_EXTRACT(transactionJSON, '$.subscriberid') IS NULL;
	
	#Return everything
	IF (objectFilter = "All") THEN
		SELECT DISTINCT transactionJSON FROM mysubscriptions ORDER BY JSON_EXTRACT(transactionJSON,'$.createdate') DESC;
	ELSE 
		SELECT DISTINCT transactionJSON FROM mysubscriptions WHERE issuerid = objectFilter ORDER BY JSON_EXTRACT(transactionJSON,'$.createdate') DESC;
    END IF;
    #transactionJSON
    
    LEAVE ProfileTransaction;
END IF;


#Changed by Mehmet.
IF (object = 'subscribers') THEN
	SET @done = 0;

	DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

	#Create the temp table
    CREATE TEMPORARY TABLE mysubscriptions
	( 
	issuerid INT, 
	assetid INT, 
	subscriberid INT, 
	transactionJSON JSON
	);

	OPEN subscribers;
		REPEAT
		  FETCH subscribers
		  INTO iissuerid,aassetid,ssubscriberid,ssqlquery;
          	IF NOT @done THEN
				#SELECT @querystring;
				SET @querystring := (SELECT ssqlquery);
				PREPARE stmt FROM @querystring;
				EXECUTE stmt;
				DEALLOCATE PREPARE stmt; 		  
			END IF;
		UNTIL @done
		END REPEAT;
            

	CLOSE subscribers;

    SELECT DISTINCT transactionJSON FROM mysubscriptions ORDER BY JSON_EXTRACT(transactionJSON,'$.createdate') DESC;

END IF; 

#Changed by Mehmet.
IF (object = 'listings') THEN
	#SELECT userId, issuerId, assetId, assetTransactionJSON FROM
	#(
	#	SELECT userId, assetId, issuerId, assetTransactionJSON, ROW_NUMBER() OVER (PARTITION BY issuerid, assetId ORDER BY issuerid, assetId, createDate DESC) AS rownum 
	#	FROM db_work.assettransactions WHERE assetTransactionOperation IN ("Create Listing","Check Listing")
	#) a WHERE rownum = 1;

	SET @done = 0;

	DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

	#Create the temp table
    CREATE TEMPORARY TABLE mysubscriptions
	( 
	issuerid INT, 
	assetid INT, 
	subscriberid INT, 
	transactionJSON JSON
	);

	OPEN listings;
		REPEAT
		  FETCH listings
		  INTO iissuerid,aassetid,ssubscriberid,ssqlquery;
			IF NOT @done THEN
				#SELECT @querystring;
				SET @querystring := (SELECT ssqlquery);
				PREPARE stmt FROM @querystring;
				EXECUTE stmt;
				DEALLOCATE PREPARE stmt; 		  
			END IF;          
		UNTIL @done
		END REPEAT;
            

	CLOSE listings;

    SELECT transactionJSON FROM mysubscriptions
    WHERE CASE WHEN objectFilter = 'All' THEN JSON_UNQUOTE(JSON_EXTRACT(transactionJSON,'$.status')) ELSE objectFilter END = JSON_EXTRACT(transactionJSON,'$.status')
    ORDER BY JSON_EXTRACT(transactionJSON,'$.createdate') DESC;
    
END IF;

#Changed by Cem. Added the subscriptions
IF (object = 'subscriptions') THEN
	SET @done = 0;

	DROP TEMPORARY TABLE IF EXISTS mysubscriptions;

	#Create the temp table
    CREATE TEMPORARY TABLE mysubscriptions
	( 
	issuerid INT, 
	assetid INT, 
	subscriberid INT, 
	transactionJSON JSON
	);

	OPEN subscriptions;
		REPEAT
		  FETCH subscriptions
		  INTO iissuerid,aassetid,ssubscriberid,ssqlquery;
			IF NOT @done THEN
				#SELECT @querystring;
				SET @querystring := (SELECT ssqlquery);
				PREPARE stmt FROM @querystring;
				EXECUTE stmt;
				DEALLOCATE PREPARE stmt; 		  
			END IF;          
		UNTIL @done
		END REPEAT;
            

	CLOSE subscriptions;




	#Return everything
	IF (objectFilter = "All") THEN	
		SELECT 
			JSON_SET(userProfileTransactionJSON, 
				'$.subscription', a.transactionJSON,
				'$.assetid', a.assetid,
				'$.subscriberid', a.subscriberid,
				'$.issuerid', a.issuerid,
                '$.fundname', (SELECT JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.fundname')) AS issuername FROM assettransactions WHERE assetTransactionOperation = 'Create Listing' AND issuerid = a.issuerid AND assetid = a.assetid ORDER BY createdate DESC LIMIT 1),
                '$.issuername', (SELECT JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.issuername')) AS issuername FROM assettransactions WHERE assetTransactionOperation = 'Create Listing' AND issuerid = a.issuerid AND assetid = a.assetid ORDER BY createdate DESC LIMIT 1),
				'$.assistants', (SELECT CAST(CONCAT('[',GROUP_CONCAT(assetTransactionJSON),']') AS JSON) FROM assettransactions WHERE assetTransactionOperation = 'Add Assistant' AND issuerid = a.issuerid AND assetid = a.assetid AND subscriberid = a.subscriberid ORDER BY createdate DESC),
				'$.signatures', (SELECT CAST(CONCAT('[',GROUP_CONCAT(assetTransactionJSON),']') AS JSON) FROM assettransactions WHERE assetTransactionOperation = 'Sign Subscription' AND issuerid = a.issuerid AND assetid = a.assetid AND subscriberid = a.subscriberid ORDER BY createdate DESC)
				) AS transactionJSON 
		FROM 
		(
			SELECT DISTINCT issuerid, assetid, subscriberid, transactionJSON FROM mysubscriptions
		) a INNER JOIN vw_currentprofiledetails w ON a.subscriberid = w.userid; 
	ELSE 
		SELECT 
			JSON_SET(userProfileTransactionJSON, 
				'$.subscription', a.transactionJSON,
				'$.assetid', a.assetid,
				'$.subscriberid', a.subscriberid,
				'$.issuerid', a.issuerid,
                '$.fundname', (SELECT JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.fundname')) AS issuername FROM assettransactions WHERE assetTransactionOperation = 'Create Listing' AND issuerid = a.issuerid AND assetid = a.assetid ORDER BY createdate DESC LIMIT 1),			
                '$.issuername', (SELECT JSON_UNQUOTE(JSON_EXTRACT(assetTransactionJSON,'$.issuername')) AS issuername FROM assettransactions WHERE assetTransactionOperation = 'Create Listing' AND issuerid = a.issuerid AND assetid = a.assetid ORDER BY createdate DESC LIMIT 1),			
				'$.assistants', (SELECT CAST(CONCAT('[',GROUP_CONCAT(assetTransactionJSON),']') AS JSON) FROM assettransactions WHERE assetTransactionOperation = 'Add Assistant' AND issuerid = a.issuerid AND assetid = a.assetid AND subscriberid = a.subscriberid ORDER BY createdate DESC),
				'$.signatures', (SELECT CAST(CONCAT('[',GROUP_CONCAT(assetTransactionJSON),']') AS JSON) FROM assettransactions WHERE assetTransactionOperation = 'Sign Subscription' AND issuerid = a.issuerid AND assetid = a.assetid AND subscriberid = a.subscriberid ORDER BY createdate DESC)
				) AS transactionJSON 
		FROM 
		(
			SELECT DISTINCT issuerid, assetid, subscriberid, transactionJSON FROM mysubscriptions
		) a INNER JOIN vw_currentprofiledetails w ON a.subscriberid = w.userid        
        WHERE a.issuerid = objectFilter;
    END IF;


END IF;



END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserCreate
DELIMITER //
CREATE PROCEDURE `spc_UserCreate`(uuserEmail varchar(55), uuserPassword varchar(100))
CreateUser: BEGIN
#This procedure creates users in the database
#Sample call 
#CALL spc_UserCreate('cem@cem.com','passcem123');

#Find the highest userid and create a salt
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @userId = (SELECT COALESCE(MAX(userId),0)+1 FROM users);
SET @userSalt = (SELECT UPPER(LEFT(MD5(NOW()), 12)) AS CODE);
SET @userFixedSalt = UPPER(LEFT(MD5(NOW()-10), 16));
 
SET @userJSON = (SELECT 
	JSON_OBJECT('createdate',@createDate, 'useremail',uuserEmail,'usersalt',@userSalt, 'userfixedsalt',@userFixedSalt)
);
#SET @assetTypeJSON = (SELECT JSON_INSERT(@assetTypeJSON,'$.assetissuer',aassetIssuer,'$.assetname',aassetName, '$.createdate',@createDate) );
#SET @assetTypeSalt = (SELECT JSON_UNQUOTE(JSON_EXTRACT(@assetTypeJSON,'$.assettypesalt')) AS assettypesalt);
SET @userPassword = (SELECT SHA2(CONCAT(uuserPassword,@userSalt),256));

#Check if the user already exists, if so, return error code 0. 
IF EXISTS(SELECT 1 FROM users WHERE username = uuserEmail) THEN
	#Log activity
	SET @UuserJSON = (SELECT JSON_INSERT(CAST("{}" AS JSON), '$.spcProcedure', 'spc_UserCreate'));   
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Error, username already exists.',@uuserJSON);
    
	SELECT JSON_OBJECT("returnvalue",1,"userid",  null,"email",uuserEmail) AS transactionJSON;
    LEAVE CreateUser;
END IF;

#Insert the asset data into the assets table
INSERT INTO users (userId, userName, userPassword, userJSON)
VALUES(@userId, uuserEmail, @userPassword, @userJSON);

#We need to set the documents required for this user, once the person is created
#CALL spc_ProfileTransactionCreate(@userId,'Check Verification KYC','{ "verificationstatus": "Unverified", "documenttype":"KYC","transactionhash":null, "transactionjson":null}');
#CALL spc_ProfileTransactionCreate(@userId,'Check Verification Accredited Investor','{ "verificationstatus": null, "documenttype":"Accredited Investor","transactionhash":null, "transactionjson":null}');

#Log activity
SET @UuserJSON = (SELECT JSON_INSERT(CAST("{}" AS JSON), '$.spcProcedure', 'spc_UserCreate'));   
INSERT INTO systemlogs (createDate, userActivity, logJSON)
VALUES (@createDate,'New user created.',@uuserJSON);

SELECT JSON_OBJECT("returnvalue",1,"userid",  @userId,"email",uuserEmail) AS transactionJSON;
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserDashboard
DELIMITER //
CREATE PROCEDURE `spc_UserDashboard`()
BEGIN
#Returns number of investments within the last 30 days
#CALL spc_UserDashboard();

SELECT JSON_OBJECT('numberofinvestments', COUNT(1)) AS transactionJSON
FROM 
(
SELECT
	DISTINCT
	issuerid, 
    assetid, 
    subscriberid, 
    JSON_EXTRACT(assettransactionJSON, '$.subscriptionid') AS subscriptionid  
FROM assettransactions 
WHERE 
	assetTransactionOperation = 'Create Subscription' AND 
	JSON_EXTRACT(assettransactionJSON, '$.status') =   'Completed' AND
	userid = -1 AND
    createdate > DATE_ADD(NOW(), INTERVAL -30 DAY) 
) a;

END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserDelete
DELIMITER //
CREATE PROCEDURE `spc_UserDelete`(uuserId INT, operation VARCHAR(50))
codeblock:BEGIN
#This procedure deletes user activities based certain parameters
#CALL spc_UserDelete(1,"All"); # deletes everything about a user.
#CALL spc_UserDelete(1,"All Transactions"); # deletes all transactions about a user.
#CALL spc_UserDelete(1,"User Transactions"); # deletes all transactions except the first three, profile, and two verifications.

	#Deletes all transactions
	IF operation = "All" THEN 
		DELETE FROM userprofiletransactions WHERE userid = uuserid; 
        DELETE FROM users WHERE userid = uuserid; 
        LEAVE codeblock;
    END IF;

	#Delete all transactions
	IF operation = "All Transactions" THEN 
		DELETE FROM userprofiletransactions WHERE userid = uuserid; 
        LEAVE codeblock;
    END IF;

	#Delete artificial transactions
	IF operation = "User Transactions" THEN 
		#Create a temp table to hold top 3 transactions of a user
        DROP TEMPORARY TABLE IF EXISTS TempuserProfileTransactionId;
       
        CREATE TEMPORARY TABLE TempuserProfileTransactionId 
			SELECT userProfileTransactionId FROM userprofiletransactions WHERE userid = uuserid ORDER BY userProfileTransactionId ASC LIMIT 3;
        
        #Delete all the transactions except the first three
        DELETE FROM userprofiletransactions WHERE userid = uuserid AND userProfileTransactionId NOT IN 
        (SELECT userProfileTransactionId FROM TempuserProfileTransactionId);
	
        LEAVE codeblock;
    END IF;


END codeblock//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserNotificationAddNew
DELIMITER //
//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserNotificationShow
DELIMITER //
CREATE PROCEDURE `spc_UserNotificationShow`(uuserId int, uuserMessage varchar(30))
BEGIN
#This shows the notifications per user. 
#CALL spc_UserNotificationShow(1,'AllMessages'); #get all messages and turn off the new message flag
#CALL spc_UserNotificationShow(1,'ShowNotificationCount'); #check if there is a new message, notificationstatus = 0 means no new message, 1 there is a new message

#When called with all parameter, the spc assumes that the messages are read.
	
    IF (uusermessage = 'AllMessages') THEN
		SELECT COALESCE(userNotificationJSON,'{"notifications": []}') AS transactionJSON FROM usernotifications WHERE userid = uuserid;
        
        UPDATE usernotifications
        SET userNotificationJSON = JSON_SET(userNotificationJSON,'$.notificationstatus',0)
        WHERE userid = uuserid;
	ELSE #This is where we get the notification status, if 1 then there is new messagge, if 0, no new message. 
		SET @notificationstatus = (SELECT JSON_OBJECT("returnvalue",COALESCE(JSON_UNQUOTE(JSON_EXTRACT(userNotificationJSON,'$.notificationstatus')),0)) AS notificationstatus  FROM usernotifications WHERE userid = uuserid);
        IF @notificationstatus IS NULL THEN 
         SET @notificationstatus = (SELECT JSON_OBJECT("returnvalue",0));
        
         #SET @notificationstatus = (SELECT JSON_OBJECT("returnvalue",@notificationstatus));
	END IF;
       
		SELECT @notificationstatus AS transactionJSON;
       
	END IF;

 
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserPasswordUpdate
DELIMITER //
CREATE PROCEDURE `spc_UserPasswordUpdate`(uuserId int,uuserPasswordOld VARCHAR(55),uuserPasswordNew VARCHAR(55))
BEGIN
#This procedure updates the password of the user. 
#CALL spc_UserPasswordUpdate(1,'123','456');

#First check if the password is right or not. 
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @userJSON = (SELECT userJSON  
FROM users WHERE userId = uuserId AND `userPassword` = SHA2(CONCAT(uuserPasswordOld,JSON_UNQUOTE(JSON_EXTRACT(userJSON,'$.usersalt'))),256)
COLLATE utf8mb4_unicode_ci
LIMIT 1); 

#Make sure the user does not exists in the database
IF @userJSON is null THEN
	#Log activity
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access denied, password not updated.',
    JSON_OBJECT('userid',uuserId,'spcProcedure','spc_UserUpdate')
    );
	SELECT JSON_OBJECT("returnvalue",0) AS transactionJSON;

ELSE
	UPDATE users SET `userPassword` = SHA2(CONCAT(uuserPasswordNew,JSON_UNQUOTE(JSON_EXTRACT(userJSON,'$.usersalt'))),256)
	WHERE userId = uuserId AND `userPassword` = SHA2(CONCAT(uuserPasswordOld,JSON_UNQUOTE(JSON_EXTRACT(userJSON,'$.usersalt'))),256);

	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Password updated.',
    JSON_INSERT(@userJSON, '$.spcProcedure', 'spc_UserUpdate')
    );
	SELECT JSON_OBJECT("returnvalue",1) AS transactionJSON;

END IF;


END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserPasswordUpdateForgot
DELIMITER //
CREATE PROCEDURE `spc_UserPasswordUpdateForgot`(uuserName VARCHAR(55), uuserSaltHash VARCHAR(255),uuserPasswordNew VARCHAR(55))
BEGIN
#This procedure updates the password of the user, who forgots his/her password. 
#CALL spc_UserPasswordUpdateForgot('cem@cem.com','aabbccddee','newwpassword');

#First check if the password is right or not. 
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @userSalt = (SELECT UPPER(LEFT(MD5(NOW()), 12)) AS CODE); 
SET @userJSON = (SELECT userJSON FROM users WHERE userName = uuserName AND UPPER(SHA2(JSON_UNQUOTE(JSON_EXTRACT(userJSON,'$.usersalt')),256)) = uuserSaltHash LIMIT 1);


#Make sure the user does not exists in the database
IF @userJSON is null THEN
	#Log activity
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access denied, password not updated.',
    JSON_OBJECT('uuserName',uuserName,'spcProcedure','spc_UserPasswordUpdateForgot')
    );
	SELECT JSON_OBJECT("returnvalue",0,"email",uuserName) AS transactionJSON;

ELSE

	UPDATE users SET 
		`userPassword` = SHA2(CONCAT(uuserPasswordNew,@userSalt),256),
        `userJSON` = JSON_REPLACE(userJSON,'$.usersalt',@userSalt)
	WHERE userName = uuserName AND UPPER(SHA2(JSON_UNQUOTE(JSON_EXTRACT(userJSON,'$.usersalt')),256)) = uuserSaltHash;
    
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'User forgot the password and reset.',
    JSON_INSERT(@userJSON, '$.spcProcedure', 'spc_UserPasswordUpdateForgot')
    );
    
	SELECT JSON_OBJECT("returnvalue",1,"email",uuserName) AS transactionJSON;

END IF;


END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserPasswordUpdateForgotHash
DELIMITER //
CREATE PROCEDURE `spc_UserPasswordUpdateForgotHash`(uuserName varchar(55))
CreateUser: BEGIN
#This procedure returns the users salt in hashed format
#Sample call 
#CALL spc_UserPasswordUpdateForgorHash('cem@cem.com');

#Find the highest userid and create a salt
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @userSaltHash = (SELECT UPPER(SHA2(JSON_UNQUOTE(JSON_EXTRACT(userJSON,'$.usersalt')),256)) FROM users WHERE userName = uuserName ); 
SET @userid = (SELECT userid FROM users WHERE userName = uuserName LIMIT 1); 

#This returns the user salt in a hased format
SELECT JSON_OBJECT("returnvalue",@userSaltHash,"userid",@userid,"email",uuserName) AS transactionJSON;
END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserSelect
DELIMITER //
CREATE PROCEDURE `spc_UserSelect`(uuserEmail VARCHAR(55),uuserPassword VARCHAR(55))
BEGIN
#This procedure returns the user json column if username and password matches
#CALL spc_UserSelect('cem','aaa');
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @userJSON = (SELECT 
COALESCE(
	JSON_MERGE(
		JSON_REMOVE(JSON_REMOVE(JSON_INSERT(u.userJSON,"$.userid",u.userid), '$.createdate'),'$.usersalt'),
        JSON_REMOVE(p.userProfileTransactionJSON,'$.userid')),
		JSON_INSERT(JSON_REMOVE(u.userJSON,'$.usersalt'),"$.userid",u.userid)
) AS userJSON
FROM users u LEFT JOIN (SELECT z.*, ROW_NUMBER() OVER (PARTITION BY z.userid ORDER BY z.createDate DESC) AS rn FROM userprofiletransactions z WHERE z.userProfileTransactionOperation = 'Create Profile') p ON 
p.userProfileTransactionOperation = 'Create Profile' AND p.userId = u.userId AND p.rn = 1
WHERE JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.isadmin')) is null AND JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.useremail')) = uuserEmail AND `userPassword` = SHA2(CONCAT(uuserPassword,JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.usersalt'))),256)
COLLATE utf8mb4_unicode_ci
ORDER BY p.createDate DESC
LIMIT 1); 

#Get the wallet if of the user, if it exists
SET @userJSON = (SELECT 
JSON_INSERT(@userJSON, '$.walletpublicid', JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.walletpublicid'))) AS userJSON
FROM users u LEFT JOIN userprofiletransactions p ON 
p.userProfileTransactionOperation = 'Create Wallet' AND p.userId = u.userId
WHERE JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.useremail')) = uuserEmail AND `userPassword` = SHA2(CONCAT(uuserPassword,JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.usersalt'))),256)
COLLATE utf8mb4_unicode_ci
ORDER BY p.createDate DESC
LIMIT 1); 

IF JSON_EXTRACT(@userJSON, '$.usertype') IS NULL THEN
	SET @userJSON = (SELECT JSON_SET(@userJSON,'$.usertype',null));
END IF;
/*
#Check if the user is accredited
SET @userJSON = (SELECT 
JSON_INSERT(@userJSON, '$.accreditedinvestor', JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.accreditedinvestor'))) AS userJSON
FROM users u LEFT JOIN userprofiletransactions p ON 
p.userProfileTransactionOperation = 'Fill Survey' AND p.userId = u.userId
WHERE JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.useremail')) = uuserEmail AND `userPassword` = SHA2(CONCAT(uuserPassword,JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.usersalt'))),256)
COLLATE utf8mb4_unicode_ci
ORDER BY p.createDate DESC
LIMIT 1); 

#Check if the user is verified, return is an array of document type, status, and date or null - initially
SET @userJSON = (
WITH rankverification AS (
SELECT 
	JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.documenttype')) AS documenttype,
	JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.verificationstatus')) AS verificationstatus,
	JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.createdate')) AS createdate,
    ROW_NUMBER() OVER (PARTITION BY JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.documenttype')) ORDER BY JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.createdate')) DESC) AS rownumber
FROM users u LEFT JOIN userprofiletransactions p ON 
p.userProfileTransactionOperation LIKE 'Check Verification%' AND p.userId = u.userId
WHERE JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.useremail')) = uuserEmail AND `userPassword` = SHA2(CONCAT(uuserPassword,JSON_UNQUOTE(JSON_EXTRACT(u.userJSON,'$.usersalt'))),256)
COLLATE utf8mb4_unicode_ci
ORDER BY p.createDate DESC
)
SELECT 
JSON_INSERT(@userJSON, '$.verification', 
CAST(CONCAT(
        '[',
        GROUP_CONCAT(
            DISTINCT JSON_OBJECT(
                'documenttype', documenttype,
                'verificationstatus', verificationstatus,
                'createdate', createdate
            )
        ),
        ']'
    ) AS JSON)) AS userJSON
FROM  rankverification
WHERE rownumber = 1 AND documenttype IS NOT NULL
);


#Make sure the user does not exists in the database
IF @userJSON is null THEN
	#Log activity
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access denied.',
    JSON_OBJECT('username',uuserEmail,'spcProcedure','spc_UserSelect')
    );
ELSE
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access granted.',
    JSON_INSERT(@userJSON, '$.spcProcedure', 'spc_UserSelect')
    );
END IF;
*/

#Return the userjson variable

SELECT COALESCE(JSON_REMOVE(JSON_SET(@userJSON,'$.email',uuserEmail), '$.userSalt'),'[]') AS transactionJSON;
#SELECT COALESCE(JSON_REMOVE(@userJSON, '$.userSalt'),'[]') AS transactionJSON;

END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserSelectById
DELIMITER //
CREATE PROCEDURE `spc_UserSelectById`(
	IN `uuserId` INT
)
BEGIN

#This procedure returns the user json column if userid is provided
#CALL spc_UserAdminSelect(1);
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @userJSON = (SELECT 
COALESCE(
	JSON_MERGE(JSON_REMOVE(JSON_REMOVE(JSON_INSERT(u.userJSON,"$.userid",u.userid), '$.createdate'),'$.usersalt'),JSON_REMOVE(p.userProfileTransactionJSON,'$.userid')) ,
	JSON_INSERT(JSON_REMOVE(u.userJSON,'$.usersalt'),"$.userid",u.userid)
) AS userJSON
FROM users u LEFT JOIN userprofiletransactions p ON 
p.userProfileTransactionOperation = 'Create Profile' AND p.userId = u.userId
WHERE u.userId = uuserid
COLLATE utf8mb4_unicode_ci
ORDER BY p.createDate DESC
LIMIT 1); 

#Get the wallet if of the user, if it exists
SET @userJSON = (SELECT 
JSON_INSERT(@userJSON, '$.walletpublicid', JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.walletpublicid'))) AS userJSON
FROM users u LEFT JOIN userprofiletransactions p ON 
p.userProfileTransactionOperation = 'Create Wallet' AND p.userId = u.userId
WHERE u.userId = uuserid
COLLATE utf8mb4_unicode_ci
ORDER BY p.createDate DESC
LIMIT 1); 

#Make sure the user does not exists in the database
IF @userJSON is null THEN
	#Log activity
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access denied.',
    JSON_OBJECT('username',uuserEmail,'spcProcedure','spc_UserAdminSelect')
    );
ELSE
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access granted.',
    JSON_INSERT(@userJSON, '$.spcProcedure', 'spc_UserAdminSelect')
    );
END IF;

#Check if user type exists
IF JSON_EXTRACT(@userJSON, '$.usertype') IS NULL THEN
	SET @userJSON = (SELECT JSON_SET(@userJSON,'$.usertype',null));
END IF;

#Return the userjson variable
SELECT JSON_SET(JSON_REMOVE(@userJSON, '$.userSalt'),'$.email',
JSON_UNQUOTE(JSON_EXTRACT(@userJSON,'$.useremail'))
) AS transactionJSON;

END//
DELIMITER ;

-- Dumping structure for procedure db_work.spc_UserSelectByMail
DELIMITER //
CREATE PROCEDURE `spc_UserSelectByMail`(
	IN `eemail` varchar(200)
)
BEGIN

#This procedure returns the user json column if user email is provided
#CALL spc_UserSelectByMail("cem@cem.ins");
SET @createDate = (SELECT DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
SET @userJSON = (SELECT 
COALESCE(
	JSON_MERGE(JSON_REMOVE(JSON_REMOVE(JSON_INSERT(u.userJSON,"$.userid",u.userid), '$.createdate'),'$.usersalt'),JSON_REMOVE(p.userProfileTransactionJSON,'$.userid')) ,
	JSON_INSERT(JSON_REMOVE(u.userJSON,'$.usersalt'),"$.userid",u.userid)
) AS userJSON
FROM users u LEFT JOIN userprofiletransactions p ON 
p.userProfileTransactionOperation = 'Create Profile' AND p.userId = u.userId
WHERE u.userName = eemail
COLLATE utf8_bin
ORDER BY p.createDate DESC
LIMIT 1); 

#Get the wallet if of the user, if it exists
SET @userJSON = (SELECT 
JSON_INSERT(@userJSON, '$.walletpublicid', JSON_UNQUOTE(JSON_EXTRACT(p.userProfileTransactionJSON,'$.walletpublicid'))) AS userJSON
FROM users u LEFT JOIN userprofiletransactions p ON 
p.userProfileTransactionOperation = 'Create Wallet' AND p.userId = u.userId
WHERE u.userName = eemail 
COLLATE utf8_bin
ORDER BY p.createDate DESC
LIMIT 1); 

#Make sure the user does not exists in the database
IF @userJSON is null THEN
	#Log activity
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access denied.',
    JSON_OBJECT('username',eemail,'spcProcedure','spc_UserAdminSelect')
    );
ELSE
	INSERT INTO systemlogs (createDate, userActivity, logJSON)
	VALUES (@createDate,'Access granted.',
    JSON_INSERT(@userJSON, '$.spcProcedure', 'spc_UserAdminSelect')
    );
END IF;

#Return the userjson variable
SELECT JSON_SET(JSON_REMOVE(@userJSON, '$.userSalt'),'$.email',
JSON_UNQUOTE(JSON_EXTRACT(@userJSON,'$.useremail'))
) AS transactionJSON;

END//
DELIMITER ;

-- Dumping structure for view db_work.vw_currentassistants
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `vw_currentassistants`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vw_currentassistants` AS select `a`.`issuerid` AS `issuerid`,`a`.`assetid` AS `assetid`,concat('[',group_concat(json_object('assetid',`a`.`assetid`,'issuerid',`a`.`issuerid`,'inviterid',`a`.`inviterid`,'assistanttype',`a`.`assistanttype`,'status',coalesce(`b`.`status`,`a`.`status`),'assistantid',`b`.`assistantid`) separator ','),']') AS `transactionJSON` from ((select json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assetid')) AS `assetid`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.issuerid')) AS `issuerid`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.inviterid')) AS `inviterid`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assistanttype')) AS `assistanttype`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.status')) AS `status`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assistantemail')) AS `assistantemail` from (`assettransactions` `a` left join `users` `u` on((cast(json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assistantemail')) as char charset binary) = cast(`u`.`userName` as char charset binary)))) where (`a`.`assetTransactionOperation` = 'Create Assistant')) `a` left join (select `a`.`issuerId` AS `issuerId`,`a`.`assetId` AS `assetId`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assistanttype')) AS `assistanttype`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assistantid')) AS `assistantid`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.inviterid')) AS `inviterid`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.status')) AS `status`,(select json_unquote(json_extract(`u`.`userJSON`,'$.useremail')) from `users` `u` where (`u`.`userId` = json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assistantid')))) AS `assistantemail` from `assettransactions` `a` where (`a`.`assetTransactionOperation` = 'Add Assistant')) `b` on(((`a`.`issuerid` = `b`.`issuerId`) and (`a`.`assetid` = `b`.`assetId`) and (`a`.`inviterid` = `b`.`inviterid`) and (`a`.`assistantemail` = `b`.`assistantemail`) and (`a`.`assistanttype` = `b`.`assistanttype`)))) where (`b`.`assistantid` is not null) group by `a`.`issuerid`,`a`.`assetid` order by (`a`.`issuerid` * 1),(`a`.`assetid` * 1);

-- Dumping structure for view db_work.vw_currentauctiondetails
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `vw_currentauctiondetails`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vw_currentauctiondetails` AS select `a`.`userid` AS `userId`,`a`.`assetid` AS `assetId`,`a`.`assetTransactionJSON` AS `assetTransactionJSON`,`a`.`createDate` AS `createDate`,`a`.`auctionstatus` AS `auctionStatus` from (select `assettransactions`.`userId` AS `userid`,`assettransactions`.`assetId` AS `assetid`,`assettransactions`.`assetTransactionJSON` AS `assetTransactionJSON`,`assettransactions`.`createDate` AS `createDate`,row_number() OVER (PARTITION BY `assettransactions`.`userId`,`assettransactions`.`assetId`,`assettransactions`.`createDate` ORDER BY `assettransactions`.`createDate` desc,`assettransactions`.`assetTransactionId` desc )  AS `rownumber`,json_unquote(json_extract(`assettransactions`.`assetTransactionJSON`,'$.auctionstatus')) AS `auctionstatus` from `assettransactions` where (`assettransactions`.`assetTransactionOperation` = 'Auction Asset')) `a` where (`a`.`rownumber` = 1);

-- Dumping structure for view db_work.vw_currentlistingdetails
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `vw_currentlistingdetails`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vw_currentlistingdetails` AS select `a`.`userId` AS `userid`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.issuerid')) AS `issuerid`,json_unquote(json_extract(`a`.`assetTransactionJSON`,'$.assetid')) AS `assetid`,json_set(`a`.`assetTransactionJSON`,'$.assettransactionid',`a`.`assetTransactionId`) AS `assetTransactionJSON` from (select `assettransactions`.`assetTransactionId` AS `assetTransactionId`,`assettransactions`.`userId` AS `userId`,`assettransactions`.`assetId` AS `assetId`,`assettransactions`.`assetTransactionOperation` AS `assetTransactionOperation`,`assettransactions`.`assetTransactionJSON` AS `assetTransactionJSON`,`assettransactions`.`createDate` AS `createDate`,row_number() OVER (PARTITION BY `assettransactions`.`userId`,`assettransactions`.`assetId` ORDER BY `assettransactions`.`createDate` desc,`assettransactions`.`assetTransactionId` desc )  AS `rownumber` from `assettransactions` where (`assettransactions`.`assetTransactionOperation` = 'Create Listing')) `a` where (`a`.`rownumber` = 1);

-- Dumping structure for view db_work.vw_currentprofiledetails
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `vw_currentprofiledetails`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vw_currentprofiledetails` AS select `a`.`userId` AS `userid`,`a`.`userProfileTransactionJSON` AS `userProfileTransactionJSON` from (select `userprofiletransactions`.`userProfileTransactionId` AS `userProfileTransactionId`,`userprofiletransactions`.`userId` AS `userId`,`userprofiletransactions`.`userProfileTransactionOperation` AS `userProfileTransactionOperation`,`userprofiletransactions`.`userProfileTransactionJSON` AS `userProfileTransactionJSON`,`userprofiletransactions`.`userProfileTransactionHash` AS `userProfileTransactionHash`,`userprofiletransactions`.`createDate` AS `createDate`,row_number() OVER (PARTITION BY `userprofiletransactions`.`userId` ORDER BY `userprofiletransactions`.`createDate` desc )  AS `rownumber` from `userprofiletransactions` where (`userprofiletransactions`.`userProfileTransactionOperation` = 'Create Profile')) `a` where (`a`.`rownumber` = 1);

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
