function onUpdateDatabase()
	print("> Updating database to version 39 (account_storage, player_outfits, player_mounts, sessions tables)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `account_storage` (
			`account_id` int NOT NULL,
			`key` int unsigned NOT NULL,
			`value` int NOT NULL,
			PRIMARY KEY (`account_id`, `key`),
			FOREIGN KEY (`account_id`) REFERENCES `accounts`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_outfits` (
			`player_id` int NOT NULL DEFAULT '0',
			`outfit_id` smallint unsigned NOT NULL DEFAULT '0',
			`addons` tinyint unsigned NOT NULL DEFAULT '0',
			PRIMARY KEY (`player_id`, `outfit_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_mounts` (
			`player_id` int NOT NULL DEFAULT '0',
			`mount_id` smallint unsigned NOT NULL DEFAULT '0',
			PRIMARY KEY (`player_id`, `mount_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `sessions` (
			`id` int NOT NULL AUTO_INCREMENT,
			`token` binary(16) NOT NULL,
			`account_id` int NOT NULL,
			`ip` varbinary(16) NOT NULL,
			`created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
			`expired_at` timestamp NULL DEFAULT NULL,
			PRIMARY KEY (`id`),
			UNIQUE KEY `token` (`token`),
			FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
	return true
end
