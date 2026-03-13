/**
 * Unit tests for Position struct from src/position.h.
 *
 * Position is a header-only struct so we can include it directly.
 * We only need the enums from position.h and the standalone functions
 * getNextPosition / getDirectionTo from tools.cpp (reimplemented here).
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <cstdlib>
#include <cmath>

// Re-declare Direction enum (from position.h)
enum Direction : uint8_t {
    DIRECTION_NORTH = 0,
    DIRECTION_EAST = 1,
    DIRECTION_SOUTH = 2,
    DIRECTION_WEST = 3,
    DIRECTION_DIAGONAL_MASK = 4,
    DIRECTION_SOUTHWEST = DIRECTION_DIAGONAL_MASK | 0,
    DIRECTION_SOUTHEAST = DIRECTION_DIAGONAL_MASK | 1,
    DIRECTION_NORTHWEST = DIRECTION_DIAGONAL_MASK | 2,
    DIRECTION_NORTHEAST = DIRECTION_DIAGONAL_MASK | 3,
    DIRECTION_LAST = DIRECTION_NORTHEAST,
    DIRECTION_NONE = 8,
};

// Position struct (from position.h)
struct Position {
    constexpr Position() = default;
    constexpr Position(uint16_t x, uint16_t y, uint8_t z) : x(x), y(y), z(z) {}

    template<int_fast32_t deltax, int_fast32_t deltay>
    static bool areInRange(const Position& p1, const Position& p2) {
        return Position::getDistanceX(p1, p2) <= deltax && Position::getDistanceY(p1, p2) <= deltay;
    }

    template<int_fast32_t deltax, int_fast32_t deltay, int_fast16_t deltaz>
    static bool areInRange(const Position& p1, const Position& p2) {
        return Position::getDistanceX(p1, p2) <= deltax && Position::getDistanceY(p1, p2) <= deltay && Position::getDistanceZ(p1, p2) <= deltaz;
    }

    static int_fast32_t getOffsetX(const Position& p1, const Position& p2) { return p1.getX() - p2.getX(); }
    static int_fast32_t getOffsetY(const Position& p1, const Position& p2) { return p1.getY() - p2.getY(); }
    static int_fast16_t getOffsetZ(const Position& p1, const Position& p2) { return p1.getZ() - p2.getZ(); }

    static int32_t getDistanceX(const Position& p1, const Position& p2) { return std::abs(Position::getOffsetX(p1, p2)); }
    static int32_t getDistanceY(const Position& p1, const Position& p2) { return std::abs(Position::getOffsetY(p1, p2)); }
    static int16_t getDistanceZ(const Position& p1, const Position& p2) { return std::abs(Position::getOffsetZ(p1, p2)); }

    uint16_t x = 0;
    uint16_t y = 0;
    uint8_t z = 0;

    bool operator==(const Position& p) const { return p.x == x && p.y == y && p.z == z; }
    bool operator!=(const Position& p) const { return p.x != x || p.y != y || p.z != z; }
    bool operator<(const Position& p) const {
        if (z < p.z) return true;
        if (z > p.z) return false;
        if (y < p.y) return true;
        if (y > p.y) return false;
        return x < p.x;
    }
    Position operator+(const Position& p1) const { return Position(x + p1.x, y + p1.y, z + p1.z); }
    Position operator-(const Position& p1) const { return Position(x - p1.x, y - p1.y, z - p1.z); }

    int_fast32_t getX() const { return x; }
    int_fast32_t getY() const { return y; }
    int_fast16_t getZ() const { return z; }
};

// getNextPosition from tools.cpp
Position getNextPosition(Direction direction, Position pos) {
    switch (direction) {
        case DIRECTION_NORTH: pos.y--; break;
        case DIRECTION_SOUTH: pos.y++; break;
        case DIRECTION_WEST:  pos.x--; break;
        case DIRECTION_EAST:  pos.x++; break;
        case DIRECTION_SOUTHWEST: pos.x--; pos.y++; break;
        case DIRECTION_NORTHWEST: pos.x--; pos.y--; break;
        case DIRECTION_NORTHEAST: pos.x++; pos.y--; break;
        case DIRECTION_SOUTHEAST: pos.x++; pos.y++; break;
        default: break;
    }
    return pos;
}

Direction getDirectionTo(const Position& from, const Position& to) {
    Direction dir;
    int32_t x_offset = Position::getOffsetX(from, to);
    if (x_offset < 0) { dir = DIRECTION_EAST; x_offset = std::abs(x_offset); }
    else { dir = DIRECTION_WEST; }
    int32_t y_offset = Position::getOffsetY(from, to);
    if (y_offset >= 0) {
        if (y_offset > x_offset) { dir = DIRECTION_NORTH; }
        else if (y_offset == x_offset) {
            dir = (dir == DIRECTION_EAST) ? DIRECTION_NORTHEAST : DIRECTION_NORTHWEST;
        }
    } else {
        y_offset = std::abs(y_offset);
        if (y_offset > x_offset) { dir = DIRECTION_SOUTH; }
        else if (y_offset == x_offset) {
            dir = (dir == DIRECTION_EAST) ? DIRECTION_SOUTHEAST : DIRECTION_SOUTHWEST;
        }
    }
    return dir;
}

// ================================================================
// TESTS
// ================================================================

TEST(Position, DefaultConstructor) {
    Position p;
    EXPECT_EQ(p.x, 0);
    EXPECT_EQ(p.y, 0);
    EXPECT_EQ(p.z, 0);
}

TEST(Position, ParameterizedConstructor) {
    Position p(100, 200, 7);
    EXPECT_EQ(p.x, 100);
    EXPECT_EQ(p.y, 200);
    EXPECT_EQ(p.z, 7);
}

TEST(Position, Equality) {
    Position a(100, 200, 7);
    Position b(100, 200, 7);
    Position c(101, 200, 7);
    EXPECT_EQ(a, b);
    EXPECT_NE(a, c);
}

TEST(Position, LessThan) {
    Position a(100, 100, 5);
    Position b(100, 100, 6);
    EXPECT_TRUE(a < b);  // z=5 < z=6
    EXPECT_FALSE(b < a);

    Position c(100, 99, 5);
    EXPECT_TRUE(c < a);  // y=99 < y=100 (same z)

    Position d(99, 100, 5);
    EXPECT_TRUE(d < a);  // x=99 < x=100 (same z, same y)
}

TEST(Position, Addition) {
    Position a(100, 200, 3);
    Position b(10, 20, 2);
    Position c = a + b;
    EXPECT_EQ(c, Position(110, 220, 5));
}

TEST(Position, Subtraction) {
    Position a(100, 200, 7);
    Position b(10, 20, 2);
    Position c = a - b;
    EXPECT_EQ(c, Position(90, 180, 5));
}

TEST(Position, OffsetXY) {
    Position a(100, 200, 7);
    Position b(105, 195, 7);
    EXPECT_EQ(Position::getOffsetX(a, b), -5);
    EXPECT_EQ(Position::getOffsetY(a, b), 5);
}

TEST(Position, DistanceXYZ) {
    Position a(100, 100, 7);
    Position b(105, 95, 5);
    EXPECT_EQ(Position::getDistanceX(a, b), 5);
    EXPECT_EQ(Position::getDistanceY(a, b), 5);
    EXPECT_EQ(Position::getDistanceZ(a, b), 2);
}

TEST(Position, AreInRange2D) {
    Position a(100, 100, 7);
    Position b(102, 103, 7);
    EXPECT_TRUE((Position::areInRange<5, 5>(a, b)));
    EXPECT_FALSE((Position::areInRange<1, 1>(a, b)));
}

TEST(Position, AreInRange3D) {
    Position a(100, 100, 7);
    Position b(102, 103, 8);
    EXPECT_TRUE((Position::areInRange<5, 5, 2>(a, b)));
    EXPECT_FALSE((Position::areInRange<5, 5, 0>(a, b)));
}

// ---- getNextPosition ----
TEST(PositionMovement, North) {
    Position p = getNextPosition(DIRECTION_NORTH, Position(100, 100, 7));
    EXPECT_EQ(p, Position(100, 99, 7));
}

TEST(PositionMovement, South) {
    Position p = getNextPosition(DIRECTION_SOUTH, Position(100, 100, 7));
    EXPECT_EQ(p, Position(100, 101, 7));
}

TEST(PositionMovement, East) {
    Position p = getNextPosition(DIRECTION_EAST, Position(100, 100, 7));
    EXPECT_EQ(p, Position(101, 100, 7));
}

TEST(PositionMovement, West) {
    Position p = getNextPosition(DIRECTION_WEST, Position(100, 100, 7));
    EXPECT_EQ(p, Position(99, 100, 7));
}

TEST(PositionMovement, Northeast) {
    Position p = getNextPosition(DIRECTION_NORTHEAST, Position(100, 100, 7));
    EXPECT_EQ(p, Position(101, 99, 7));
}

TEST(PositionMovement, Southeast) {
    Position p = getNextPosition(DIRECTION_SOUTHEAST, Position(100, 100, 7));
    EXPECT_EQ(p, Position(101, 101, 7));
}

TEST(PositionMovement, Southwest) {
    Position p = getNextPosition(DIRECTION_SOUTHWEST, Position(100, 100, 7));
    EXPECT_EQ(p, Position(99, 101, 7));
}

TEST(PositionMovement, Northwest) {
    Position p = getNextPosition(DIRECTION_NORTHWEST, Position(100, 100, 7));
    EXPECT_EQ(p, Position(99, 99, 7));
}

// ---- getDirectionTo ----
TEST(PositionDirection, DirectNorth) {
    Direction d = getDirectionTo(Position(100, 100, 7), Position(100, 95, 7));
    EXPECT_EQ(d, DIRECTION_NORTH);
}

TEST(PositionDirection, DirectSouth) {
    Direction d = getDirectionTo(Position(100, 100, 7), Position(100, 105, 7));
    EXPECT_EQ(d, DIRECTION_SOUTH);
}

TEST(PositionDirection, DirectEast) {
    Direction d = getDirectionTo(Position(100, 100, 7), Position(105, 100, 7));
    EXPECT_EQ(d, DIRECTION_EAST);
}

TEST(PositionDirection, DirectWest) {
    Direction d = getDirectionTo(Position(100, 100, 7), Position(95, 100, 7));
    EXPECT_EQ(d, DIRECTION_WEST);
}

TEST(PositionDirection, DiagonalNE) {
    Direction d = getDirectionTo(Position(100, 100, 7), Position(105, 95, 7));
    EXPECT_EQ(d, DIRECTION_NORTHEAST);
}

TEST(PositionDirection, DiagonalSW) {
    Direction d = getDirectionTo(Position(100, 100, 7), Position(95, 105, 7));
    EXPECT_EQ(d, DIRECTION_SOUTHWEST);
}

TEST(PositionDirection, SamePosition) {
    // Same position: x_offset=0, y_offset=0
    // x_offset >= 0 => dir = WEST, y_offset=0 >= 0, 0 == 0 => NORTHWEST
    Direction d = getDirectionTo(Position(100, 100, 7), Position(100, 100, 7));
    EXPECT_EQ(d, DIRECTION_NORTHWEST);
}
