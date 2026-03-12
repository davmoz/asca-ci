function onUpdateDatabase()
	print("> Updating database to version 29 (Task system tables)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_tasks` (
			`id` int NOT NULL AUTO_INCREMENT,
			`player_id` int NOT NULL,
			`task_id` int NOT NULL,
			`kill_count` int NOT NULL DEFAULT 0,
			`status` enum('active','completed','claimed') NOT NULL DEFAULT 'active',
			`started_at` bigint NOT NULL DEFAULT 0,
			`completed_at` bigint NOT NULL DEFAULT 0,
			PRIMARY KEY (`id`),
			UNIQUE KEY `player_task` (`player_id`, `task_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8
	]])
	return true
end
