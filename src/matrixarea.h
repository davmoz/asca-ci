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

#ifndef FS_MATRIXAREA_H
#define FS_MATRIXAREA_H

#include <cstdint>
#include <vector>

class MatrixArea
{
	public:
		MatrixArea() = default;

		MatrixArea(uint32_t rows, uint32_t cols)
			: rows(rows), cols(cols), data_(rows, std::vector<uint8_t>(cols, 0)) {}

		void setValue(uint32_t row, uint32_t col, bool value) {
			data_[row][col] = value ? 1 : 0;
		}
		bool getValue(uint32_t row, uint32_t col) const {
			return data_[row][col] != 0;
		}

		void setCenter(uint32_t y, uint32_t x) {
			centerX = x;
			centerY = y;
		}
		void getCenter(uint32_t& y, uint32_t& x) const {
			x = centerX;
			y = centerY;
		}

		uint32_t getRows() const {
			return rows;
		}
		uint32_t getCols() const {
			return cols;
		}

		std::vector<uint8_t>& operator[](uint32_t i) {
			return data_[i];
		}
		const std::vector<uint8_t>& operator[](uint32_t i) const {
			return data_[i];
		}

	private:
		uint32_t centerX = 0;
		uint32_t centerY = 0;
		uint32_t rows = 0;
		uint32_t cols = 0;
		std::vector<std::vector<uint8_t>> data_;
};

#endif
