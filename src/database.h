/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019  Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef FS_DATABASE_H
#define FS_DATABASE_H

#include <boost/lexical_cast.hpp>

#include <mysql/mysql.h>

class DBResult;
using DBResult_ptr = std::shared_ptr<DBResult>;

namespace tfs::detail {

struct MysqlDeleter
{
	void operator()(MYSQL* handle) const { mysql_close(handle); }
	void operator()(MYSQL_RES* handle) const { mysql_free_result(handle); }
};

using Mysql_ptr = std::unique_ptr<MYSQL, MysqlDeleter>;
using MysqlResult_ptr = std::unique_ptr<MYSQL_RES, MysqlDeleter>;

} // namespace tfs::detail

class Database
{
	public:
		Database() = default;

		// non-copyable
		Database(const Database&) = delete;
		Database& operator=(const Database&) = delete;

		/**
		 * Singleton implementation.
		 *
		 * @return database connection handler singleton
		 */
		static Database& getInstance()
		{
			static Database instance;
			return instance;
		}

		/**
		 * Connects to the database
		 *
		 * @return true on successful connection, false on error
		 */
		bool connect();

		/**
		 * Executes command.
		 *
		 * Executes query which doesn't generates results (eg. INSERT, UPDATE, DELETE...).
		 *
		 * @param query command
		 * @return true on success, false on error
		 */
		[[nodiscard]] bool executeQuery(std::string_view query);

		/**
		 * Queries database.
		 *
		 * Executes query which generates results (mostly SELECT).
		 *
		 * @return results object (nullptr on error)
		 */
		[[nodiscard]] DBResult_ptr storeQuery(std::string_view query);

		/**
		 * Escapes string for query.
		 *
		 * Prepares string to fit SQL queries including quoting it.
		 *
		 * @param s string to be escaped
		 * @return quoted string
		 */
		[[nodiscard]] std::string escapeString(std::string_view s) const;

		/**
		 * Escapes binary stream for query.
		 *
		 * Prepares binary stream to fit SQL queries.
		 *
		 * @param s binary stream
		 * @param length stream length
		 * @return quoted string
		 */
		[[nodiscard]] std::string escapeBlob(const char* s, uint32_t length) const;

		/**
		 * Retrieve id of last inserted row
		 *
		 * @return id on success, 0 if last query did not result on any rows with auto_increment keys
		 */
		uint64_t getLastInsertId() const {
			return static_cast<uint64_t>(mysql_insert_id(handle.get()));
		}

		/**
		 * Get database engine version
		 *
		 * @return the database engine version
		 */
		static const char* getClientVersion() {
			return mysql_get_client_info();
		}

		uint64_t getMaxPacketSize() const {
			return maxPacketSize;
		}

	private:
		/**
		 * Transaction related methods.
		 *
		 * Methods for starting, commiting and rolling back transaction. Each of the returns boolean value.
		 *
		 * @return true on success, false on error
		 */
		bool beginTransaction();
		bool rollback();
		bool commit();

		tfs::detail::Mysql_ptr handle = nullptr;
		std::recursive_mutex databaseLock;
		uint64_t maxPacketSize = 1048576;
		// Do not retry queries if we are in the middle of a transaction
		bool retryQueries = true;

	friend class DBTransaction;
};

class DBResult
{
	public:
		explicit DBResult(tfs::detail::MysqlResult_ptr&& res);

		// non-copyable
		DBResult(const DBResult&) = delete;
		DBResult& operator=(const DBResult&) = delete;

		template<typename T>
		T getNumber(const std::string& s) const
		{
			auto it = listNames.find(s);
			if (it == listNames.end()) {
				std::cout << "[Error - DBResult::getNumber] Column '" << s << "' doesn't exist in the result set" << std::endl;
				return static_cast<T>(0);
			}

			if (row[it->second] == nullptr) {
				return static_cast<T>(0);
			}

			T data;
			try {
				data = boost::lexical_cast<T>(row[it->second]);
			} catch (boost::bad_lexical_cast&) {
				std::cout << "[Error - DBResult::getNumber] Failed to convert column '" << s
				          << "' value '" << row[it->second] << "' to numeric type" << std::endl;
				data = 0;
			}
			return data;
		}

		std::string getString(const std::string& s) const;
		const char* getStream(const std::string& s, unsigned long& size) const;

		bool hasNext() const;
		bool next();

	private:
		tfs::detail::MysqlResult_ptr handle;
		MYSQL_ROW row;

		std::map<std::string, size_t> listNames;

	friend class Database;
};

/**
 * INSERT statement.
 */
class DBInsert
{
	public:
		explicit DBInsert(std::string query);
		[[nodiscard]] bool addRow(const std::string& row);
		[[nodiscard]] bool execute();

	private:
		std::string query;
		std::string values;
		size_t length;
};

class DBTransaction
{
	public:
		constexpr DBTransaction() = default;

		~DBTransaction() {
			if (state == STATE_START) {
				Database::getInstance().rollback();
			}
		}

		// non-copyable
		DBTransaction(const DBTransaction&) = delete;
		DBTransaction& operator=(const DBTransaction&) = delete;

		bool begin() {
			state = STATE_START;
			return Database::getInstance().beginTransaction();
		}

		bool commit() {
			if (state != STATE_START) {
				return false;
			}

			state = STATE_COMMIT;
			return Database::getInstance().commit();
		}

	private:
		enum TransactionStates_t {
			STATE_NO_START,
			STATE_START,
			STATE_COMMIT,
		};

		TransactionStates_t state = STATE_NO_START;
};

#endif
