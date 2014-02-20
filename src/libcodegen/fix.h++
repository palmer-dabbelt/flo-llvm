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

#ifndef LIBCODEGEN__FIX_HXX
#define LIBCODEGEN__FIX_HXX

#include "value.h++"
#include <stddef.h>
#include <string>

namespace libcodegen {
    /* Represents the general class of fixed-width integers, where the
     * width can only be determined at runtime. */
    class fix_t: public value {
    private:
        size_t _width;

    public:
        fix_t(size_t width)
            : value(),
              _width(width)
            {
            }

        fix_t(size_t width, const std::string name)
            : value(name),
              _width(width)
            {
            }

        size_t width(void) const { return _width; }

        const std::string as_llvm(void) const;
    };

    /* Represents a fixed width integer whose width is known at
     * compile-time. */
    template<size_t W> class fix: public fix_t {
    private:
    public:
        fix(void)
            : fix_t(W)
            {
            }

        fix(const std::string name)
            : fix_t(W, name)
            {
            }
    };
}

#endif

