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

#ifndef LIBCODEGEN__CONSTANT_HXX
#define LIBCODEGEN__CONSTANT_HXX

#include "builtin.h++"
#include <string>

namespace libcodegen {
    template<class T> class constant: public builtin<T> {
    private:
        T _value;

    public:
        constant(T value)
            : builtin<T>(std::to_string(value))
            {
            }

        /* This is a constant at Flo->LLVM compile-time (ie, it's a
         * constant at C++ run-time).  I see no reason to not allow
         * this to be implicitly cast back to the type it wraps. */
        operator T() const { return _value; }
    };
}

#endif
