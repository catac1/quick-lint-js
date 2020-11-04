# quick-lint-js finds bugs in JavaScript programs.
# Copyright (C) 2020  Matthew Glazar
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set(SIMDJSON_JUST_LIBRARY ON CACHE INTERNAL "")
set(SIMDJSON_BUILD_STATIC ON CACHE INTERNAL "")

add_subdirectory(simdjson EXCLUDE_FROM_ALL)

target_compile_definitions(simdjson PUBLIC SIMDJSON_EXCEPTIONS=0)

# HACK(strager): Avoid various warnings when including <simdjson.h>.
get_property(
  SIMDJSON_INCLUDE_DIRECTORIES
  TARGET simdjson-headers
  PROPERTY INTERFACE_INCLUDE_DIRECTORIES
)
set_property(
  TARGET simdjson-headers
  APPEND PROPERTY
  INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
  "${SIMDJSON_INCLUDE_DIRECTORIES}"
)

quick_lint_js_add_warning_options_if_supported(
  simdjson
  PRIVATE
  -Wno-array-bounds
)

# HACK(strager): libc++ version 7 marks std::signbit as [[gnu::always_inline]].
# For reasons I don't understand, this causes problems when compiling
# simdjson/src/to_chars.cpp:
#
# > vendor/simdjson/src/to_chars.cpp:918:7: error: always_inline function
# > 'signbit' requires target feature 'avx2', but would be inlined into function
# > 'to_chars' that is compiled without support for 'avx2'
#
# Work around this error by using [[gnu::internal_linkage]] instead of
# [[gnu::always_inline]] for std::signbit (and, as collateral damage, a bunch of
# other functions).
target_compile_definitions(
  simdjson
  PRIVATE
  _LIBCPP_HIDE_FROM_ABI_PER_TU_BY_DEFAULT=1
)
