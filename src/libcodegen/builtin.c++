/*
 * Copyright (C) 2014 Palmer Dabbelt
 *   <palmer.dabbelt@eecs.berkeley.edu>
 *
 * This file is part of flo-llvm.
 *
 * flo-llvm is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * flo-llvm is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with flo-llvm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

#include "builtin.h++"
#include <stdint.h>
#include <string>

#define gen_as_llvm(type, str)                  \
    template<>                                  \
    const std::string                           \
    builtin<type>::as_llvm(void) const          \
    { return str; }                             \


#define gen_width(type, w)                      \
    template<>                                  \
    size_t                                      \
    builtin<type>::width(void) const            \
    { return w; }                               \

namespace libcodegen {
    /* Here I manually instantiate this name lookup list.  The idea is
     * that I need to know the LLVM name for a given C name.  As far
     * as I can tell there's no way to do this without manually
     * specifying all of this. */
    gen_as_llvm(void, "void")
    gen_as_llvm(bool, "i1")
    gen_as_llvm(char, "i8")
    gen_as_llvm(uint32_t, "i32")
    gen_as_llvm(uint64_t, "i64")
#if defined(__APPLE__) && defined(__amd64__)
    gen_as_llvm(unsigned long, "i64")
#endif

    /* Widths also need to be manually defined. */
    gen_width(void, 0)
    gen_width(bool, 1)
    gen_width(char, 8)
    gen_width(uint32_t, 32)
    gen_width(uint64_t, 64)
#if defined(__APPLE__) && defined(__amd64__)
    gen_width(unsigned long, 64)
#endif
}
