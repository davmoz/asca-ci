function onUpdateDatabase()
	print("> Updating database to version 37 (player_factions table)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_factions` (
			`player_id` int NOT NULL,
			`faction_id` tinyint NOT NULL DEFAULT 0,
			`reputation` int NOT NULL DEFAULT 0,
			`rank_level` tinyint NOT NULL DEFAULT 0,
			`joined_at` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`, `faction_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
	return true
end
