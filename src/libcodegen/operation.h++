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

#ifndef LIBCODEGEN__OPERATION_HXX
#define LIBCODEGEN__OPERATION_HXX

#include "constant.h++"
#include "pointer.h++"
#include <string.h>

namespace libcodegen {
    /* Represents a single operation that can be performed.  Note that
     * there's something very dangerous going on here: references to
     * values are passed everywhere (whereas usually values are
     * copied).  This is necessary because value is an abstract class,
     * but it's super nasty! */
    class operation {
    public:
        /* Produces the LLVM that cooresponds to this operation. */
        virtual const std::string as_llvm(void) const = 0;
    };
}

#endif
