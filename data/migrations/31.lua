function onUpdateDatabase()
	print("> Updating database to version 31 (Achievement tables)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_achievements` (
			`player_id` int NOT NULL,
			`achievement_id` int NOT NULL,
			`unlocked_at` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`, `achievement_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	return true
end
