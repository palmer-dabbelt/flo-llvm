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

namespace libcodegen {
    /* Represents a single operation that can be performed. */
    class operation {
    private:
        const value& _d;
        const value& _s0;
        const value& _s1;

    public:
        operation(const value &d, const value &s0, const value &s1)
            : _d(d),
              _s0(s0),
              _s1(s1)
            {
            }

        /* Accessor functions. */
        const value& d(void) const { return _d; }
        const value& s0(void) const { return _s0; }
        const value& s1(void) const { return _s1; }

        /* Returns the LLVM name for the operation that's to be
         * performed. */
        virtual const std::string op_llvm(void) const = 0;
    };

    /* Performs a "mov" operation, which is really just a copy. */
    template<class T> class mov_op_cls: public operation {
    private:
    public:
        mov_op_cls(const T &dest, const T &src)
            : operation(dest, src, src)
            {
            }

        const std::string op_llvm(void) const { return "or"; }
    };
    template<class T> mov_op_cls<T> mov_op(const T& dest, const T& src)
    { return mov_op_cls<T>(dest, src); }
}

#endif