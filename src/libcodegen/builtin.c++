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
    builtin<type>::as_llvm(void)                \
    { return str; }                             \

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
}
