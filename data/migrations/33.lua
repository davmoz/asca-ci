function onUpdateDatabase()
	print("> Updating database to version 33 (Guild enhancement tables)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `guild_bank` (
			`guild_id` int NOT NULL,
			`balance` bigint NOT NULL DEFAULT 0,
			`last_deposit_by` int DEFAULT NULL,
			`last_deposit_at` bigint DEFAULT NULL,
			PRIMARY KEY (`guild_id`),
			FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `guild_alliances` (
			`id` int NOT NULL AUTO_INCREMENT,
			`guild1_id` int NOT NULL,
			`guild2_id` int NOT NULL,
			`status` enum('pending','active','dissolved') NOT NULL DEFAULT 'pending',
			`created_at` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`id`),
			UNIQUE KEY `alliance_pair` (`guild1_id`, `guild2_id`),
			FOREIGN KEY (`guild1_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE,
			FOREIGN KEY (`guild2_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `guild_levels` (
			`guild_id` int NOT NULL,
			`level` int NOT NULL DEFAULT 1,
			`experience` bigint NOT NULL DEFAULT 0,
			`skill_points` int NOT NULL DEFAULT 0,
			PRIMARY KEY (`guild_id`),
			FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	return true
end
