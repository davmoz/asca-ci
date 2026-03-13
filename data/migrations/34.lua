function onUpdateDatabase()
	print("> Updating database to version 34 (player_warnings table)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_warnings` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`player_id` INT NOT NULL,
			`reason` VARCHAR(255) NOT NULL DEFAULT '',
			`warned_by` INT NOT NULL DEFAULT 0,
			`warned_at` BIGINT NOT NULL DEFAULT 0,
			PRIMARY KEY (`id`),
			KEY `player_id` (`player_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])
	return true
end
