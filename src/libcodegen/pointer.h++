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

#ifndef LIBCODEGEN__POINTER_HXX
#define LIBCODEGEN__POINTER_HXX

#include "value.h++"

namespace libcodegen {
    /* This represents a pointer to any sort of type.  In this case, V
     * is expected to be a "value". */
    template<class V> class pointer: public value {
    private:
        V _V;

    public:
        pointer(void)
            : _V()
            {
            }

        /* This is just yet another way of getting at the LLVM name of
         * a pointer. */
        virtual const std::string as_llvm(void) const
            { return _V.as_llvm() + "*"; }
    };
}

#endif
