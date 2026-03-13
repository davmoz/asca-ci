function onUpdateDatabase()
	print("> Updating database to version 28 (Crafting skills tables)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_mining_skill` (
			`player_id` int NOT NULL,
			`level` int NOT NULL DEFAULT 1,
			`tries` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_cooking_skill` (
			`player_id` int NOT NULL,
			`level` int NOT NULL DEFAULT 1,
			`tries` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_farming_skill` (
			`player_id` int NOT NULL,
			`level` int NOT NULL DEFAULT 1,
			`tries` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_smithing_skill` (
			`player_id` int NOT NULL,
			`level` int NOT NULL DEFAULT 1,
			`tries` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	return true
end
