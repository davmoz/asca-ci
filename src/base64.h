#ifndef FS_BASE64_H
#define FS_BASE64_H

#include <string>
#include <string_view>

namespace base64 {

std::string encode(std::string_view input);
std::string decode(std::string_view input);

} // namespace base64

#endif
