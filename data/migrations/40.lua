function onUpdateDatabase()
	print("> Updating database to version 40 (mount appearance columns on players)")
	db.query("ALTER TABLE `players` ADD `lookmount` int NOT NULL DEFAULT '0' AFTER `lookaddons`;")
	db.query("ALTER TABLE `players` ADD `lookmounthead` int NOT NULL DEFAULT '0' AFTER `lookmount`;")
	db.query("ALTER TABLE `players` ADD `lookmountbody` int NOT NULL DEFAULT '0' AFTER `lookmounthead`;")
	db.query("ALTER TABLE `players` ADD `lookmountlegs` int NOT NULL DEFAULT '0' AFTER `lookmountbody`;")
	db.query("ALTER TABLE `players` ADD `lookmountfeet` int NOT NULL DEFAULT '0' AFTER `lookmountlegs`;")
	db.query("ALTER TABLE `players` ADD `currentmount` smallint unsigned NOT NULL DEFAULT '0' AFTER `lookmountfeet`;")
	db.query("ALTER TABLE `players` ADD `randomizemount` tinyint NOT NULL DEFAULT '0' AFTER `currentmount`;")
	return true
end
