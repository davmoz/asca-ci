function onUpdateDatabase()
	print("> Updating database to version 38 (player_imbuements table)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_imbuements` (
			`player_id` int NOT NULL,
			`item_uid` int NOT NULL DEFAULT 0,
			`slot_id` tinyint NOT NULL DEFAULT 0,
			`imbue_type` tinyint NOT NULL DEFAULT 0,
			`imbue_tier` tinyint NOT NULL DEFAULT 0,
			`duration` int NOT NULL DEFAULT 0,
			`applied_at` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`, `item_uid`, `slot_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
	return true
end
