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
    /* Represents a single operation that can be performed.  Note that
     * there's something very dangerous going on here: references to
     * values are passed everywhere (whereas usually values are
     * copied).  This is necessary because value is an abstract class,
     * but it's super nasty! */
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

        /* Produces the LLVM that cooresponds to this operation. */
        virtual const std::string as_llvm(void) const
            {
                std::string dest = d().llvm_name();
                std::string opst = op_llvm();
                std::string type = s0().as_llvm();
                std::string src0 = s0().llvm_name();
                std::string src1 = s1().llvm_name();

                char buffer[1024];
                snprintf(buffer, 1024,
                        "  %s = %s %s %s, %s\n",
                        dest.c_str(),
                        opst.c_str(),
                        type.c_str(),
                        src0.c_str(),
                        src1.c_str()
                    );
                return buffer;
            }
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

    /* Performs an "alloca" operation, which allocates the provided
     * amount of space on the stack. */
    template<class O, class I> class alloca_op_cls: public operation {
    private:
        const O& _dst;
        const I& _src;

    public:
        alloca_op_cls(const O& dst, const I& src)
            : operation(dst, dst, src),
              _dst(dst),
              _src(src)
            {
            }

        const std::string op_llvm(void) const { return "alloca"; }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                        "  %s = %s %s, %s %s\n",
                         _dst.llvm_name().c_str(),
                         op_llvm().c_str(),
                         _dst.base().as_llvm().c_str(),
                         _src.as_llvm().c_str(),
                         _src.llvm_name().c_str()
                    );
                return buffer;
            }
    };
    template<class O, class I>
    alloca_op_cls<O, I> alloca_op(const O& dst, const I& cnt)
    { return alloca_op_cls<O, I>(dst, cnt); }
}

#endif
