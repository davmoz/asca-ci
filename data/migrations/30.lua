function onUpdateDatabase()
	print("> Updating database to version 30 (Bestiary tables)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_bestiary` (
			`player_id` int NOT NULL,
			`monster_name` varchar(255) NOT NULL,
			`kill_count` int NOT NULL DEFAULT 0,
			`unlocked_tier` tinyint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`, `monster_name`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	return true
end
