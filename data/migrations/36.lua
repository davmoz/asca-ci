function onUpdateDatabase()
	print("> Updating database to version 36 (prey_slots table)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `prey_slots` (
			`player_id` int NOT NULL,
			`slot_id` tinyint NOT NULL DEFAULT 0,
			`creature_name` varchar(255) NOT NULL DEFAULT '',
			`bonus_type` tinyint NOT NULL DEFAULT 0,
			`bonus_value` int NOT NULL DEFAULT 0,
			`bonus_ticks` int NOT NULL DEFAULT 0,
			`locked` tinyint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`, `slot_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
	return true
end
