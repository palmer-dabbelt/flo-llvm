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
#include "pointer.h++"

/* Here's a special case: in LLVM "void*" doesn't exist and we instead
 * need to use an "i8*" to emulate it.  This behavior is suggested by
 * the LLVM documentation. */
namespace libcodegen {
    template<>
    const std::string pointer< builtin<void> >::as_llvm(void) const
    {
        return "i8*";
    }
}
