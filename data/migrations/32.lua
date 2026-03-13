function onUpdateDatabase()
	print("> Updating database to version 32 (PvP system tables)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `pvp_rankings` (
			`player_id` int NOT NULL,
			`kills` int NOT NULL DEFAULT 0,
			`deaths` int NOT NULL DEFAULT 0,
			`assists` int NOT NULL DEFAULT 0,
			`rating` int NOT NULL DEFAULT 1000,
			`season` int NOT NULL DEFAULT 1,
			PRIMARY KEY (`player_id`, `season`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `bounties` (
			`id` int NOT NULL AUTO_INCREMENT,
			`target_id` int NOT NULL,
			`placed_by` int NOT NULL,
			`amount` bigint NOT NULL DEFAULT 0,
			`status` enum('active','claimed','expired') NOT NULL DEFAULT 'active',
			`created_at` bigint NOT NULL DEFAULT 0,
			`claimed_by` int DEFAULT NULL,
			`claimed_at` bigint DEFAULT NULL,
			PRIMARY KEY (`id`),
			KEY `target_id` (`target_id`),
			FOREIGN KEY (`target_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
			FOREIGN KEY (`placed_by`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `duels` (
			`id` int NOT NULL AUTO_INCREMENT,
			`player1_id` int NOT NULL,
			`player2_id` int NOT NULL,
			`winner_id` int DEFAULT NULL,
			`status` enum('pending','active','completed','cancelled') NOT NULL DEFAULT 'pending',
			`wager` bigint NOT NULL DEFAULT 0,
			`created_at` bigint NOT NULL DEFAULT 0,
			`finished_at` bigint DEFAULT NULL,
			PRIMARY KEY (`id`),
			FOREIGN KEY (`player1_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
			FOREIGN KEY (`player2_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	return true
end
