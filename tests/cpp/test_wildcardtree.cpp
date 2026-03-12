/**
 * Unit tests for WildcardTreeNode from src/wildcardtree.h/cpp.
 *
 * The WildcardTree is a trie used for player name autocomplete.
 * We re-implement it here to avoid the otpch.h dependency chain.
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <map>
#include <stack>
#include <string>

// Re-declare the minimal enums needed
enum ReturnValue {
    RETURNVALUE_NOERROR,
    RETURNVALUE_PLAYERWITHTHISNAMEISNOTONLINE = 27,
    RETURNVALUE_NAMEISTOOAMBIGUOUS = 51,
};

// WildcardTreeNode reimplemented from src/wildcardtree.cpp
class WildcardTreeNode {
public:
    explicit WildcardTreeNode(bool breakpoint) : breakpoint(breakpoint) {}
    WildcardTreeNode(WildcardTreeNode&& other) = default;
    WildcardTreeNode(const WildcardTreeNode&) = delete;
    WildcardTreeNode& operator=(const WildcardTreeNode&) = delete;

    WildcardTreeNode* getChild(char ch) {
        auto it = children.find(ch);
        return (it == children.end()) ? nullptr : &it->second;
    }

    const WildcardTreeNode* getChild(char ch) const {
        auto it = children.find(ch);
        return (it == children.end()) ? nullptr : &it->second;
    }

    WildcardTreeNode* addChild(char ch, bool bp) {
        WildcardTreeNode* child = getChild(ch);
        if (child) {
            if (bp && !child->breakpoint) child->breakpoint = true;
        } else {
            auto pair = children.emplace(std::piecewise_construct,
                std::forward_as_tuple(ch), std::forward_as_tuple(bp));
            child = &pair.first->second;
        }
        return child;
    }

    void insert(const std::string& str) {
        WildcardTreeNode* cur = this;
        size_t length = str.length() - 1;
        for (size_t pos = 0; pos < length; ++pos) {
            cur = cur->addChild(str[pos], false);
        }
        cur->addChild(str[length], true);
    }

    void remove(const std::string& str) {
        WildcardTreeNode* cur = this;
        std::stack<WildcardTreeNode*> path;
        path.push(cur);
        size_t len = str.length();
        for (size_t pos = 0; pos < len; ++pos) {
            cur = cur->getChild(str[pos]);
            if (!cur) return;
            path.push(cur);
        }
        cur->breakpoint = false;
        do {
            cur = path.top();
            path.pop();
            if (!cur->children.empty() || cur->breakpoint || path.empty()) break;
            cur = path.top();
            auto it = cur->children.find(str[--len]);
            if (it != cur->children.end()) cur->children.erase(it);
        } while (true);
    }

    ReturnValue findOne(const std::string& query, std::string& result) const {
        const WildcardTreeNode* cur = this;
        for (char pos : query) {
            cur = cur->getChild(pos);
            if (!cur) return RETURNVALUE_PLAYERWITHTHISNAMEISNOTONLINE;
        }
        result = query;
        do {
            size_t size = cur->children.size();
            if (size == 0) return RETURNVALUE_NOERROR;
            else if (size > 1 || cur->breakpoint) return RETURNVALUE_NAMEISTOOAMBIGUOUS;
            auto it = cur->children.begin();
            result += it->first;
            cur = &it->second;
        } while (true);
    }

private:
    std::map<char, WildcardTreeNode> children;
    bool breakpoint;
};

// ================================================================
// TESTS
// ================================================================

class WildcardTreeTest : public ::testing::Test {
protected:
    WildcardTreeNode root{false};

    void SetUp() override {
        root.insert("elder druid");
        root.insert("elite knight");
        root.insert("sorcerer");
        root.insert("master sorcerer");
        root.insert("druid");
        root.insert("knight");
        root.insert("paladin");
        root.insert("royal paladin");
    }
};

TEST_F(WildcardTreeTest, ExactMatch) {
    std::string result;
    ReturnValue rv = root.findOne("paladin", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
    EXPECT_EQ(result, "paladin");
}

TEST_F(WildcardTreeTest, UniquePrefix) {
    std::string result;
    ReturnValue rv = root.findOne("so", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
    EXPECT_EQ(result, "sorcerer");
}

TEST_F(WildcardTreeTest, AmbiguousPrefix) {
    std::string result;
    ReturnValue rv = root.findOne("el", result);
    EXPECT_EQ(rv, RETURNVALUE_NAMEISTOOAMBIGUOUS);
}

TEST_F(WildcardTreeTest, NotFound) {
    std::string result;
    ReturnValue rv = root.findOne("wizard", result);
    EXPECT_EQ(rv, RETURNVALUE_PLAYERWITHTHISNAMEISNOTONLINE);
}

TEST_F(WildcardTreeTest, InsertAndFind) {
    root.insert("gamemaster");
    std::string result;
    ReturnValue rv = root.findOne("game", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
    EXPECT_EQ(result, "gamemaster");
}

TEST_F(WildcardTreeTest, RemoveAndFind) {
    root.remove("sorcerer");
    std::string result;
    ReturnValue rv = root.findOne("so", result);
    EXPECT_EQ(rv, RETURNVALUE_PLAYERWITHTHISNAMEISNOTONLINE);
}

TEST_F(WildcardTreeTest, RemoveNonExistent) {
    // Should not crash
    root.remove("nonexistent");
    std::string result;
    ReturnValue rv = root.findOne("paladin", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
}

TEST_F(WildcardTreeTest, PrefixIsAlsoWord) {
    // "druid" and "elder druid" both exist, "d" should uniquely match "druid"
    std::string result;
    ReturnValue rv = root.findOne("d", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
    EXPECT_EQ(result, "druid");
}

TEST_F(WildcardTreeTest, SingleCharSearch) {
    std::string result;
    // 'k' uniquely leads to "knight"
    ReturnValue rv = root.findOne("k", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
    EXPECT_EQ(result, "knight");
}

TEST_F(WildcardTreeTest, EmptyQueryIsAmbiguous) {
    std::string result;
    // Empty query: root has multiple children
    ReturnValue rv = root.findOne("", result);
    EXPECT_EQ(rv, RETURNVALUE_NAMEISTOOAMBIGUOUS);
}

TEST_F(WildcardTreeTest, FullPrefixMatchWithSubstring) {
    // "master sorcerer" - search for "m"
    std::string result;
    ReturnValue rv = root.findOne("m", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
    EXPECT_EQ(result, "master sorcerer");
}

TEST_F(WildcardTreeTest, InsertDuplicateIsIdempotent) {
    root.insert("paladin");
    std::string result;
    ReturnValue rv = root.findOne("paladin", result);
    EXPECT_EQ(rv, RETURNVALUE_NOERROR);
    EXPECT_EQ(result, "paladin");
}

TEST_F(WildcardTreeTest, CaseSensitive) {
    // Tree stores lowercase; uppercase should not match
    std::string result;
    ReturnValue rv = root.findOne("Paladin", result);
    EXPECT_EQ(rv, RETURNVALUE_PLAYERWITHTHISNAMEISNOTONLINE);
}
