function onUpdateDatabase()
	print("> Updating database to version 35 (guild_storage table)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `guild_storage` (
			`guild_id` INT NOT NULL,
			`key` VARCHAR(255) NOT NULL,
			`value` TEXT NOT NULL DEFAULT '',
			PRIMARY KEY (`guild_id`, `key`),
			FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])
	return true
end
