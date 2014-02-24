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

#ifndef LIBCODEGEN__OP_ALU_HXX
#define LIBCODEGEN__OP_ALU_HXX

#include "operation.h++"

namespace libcodegen {
    /* This represents the sort of operation that's performed by an
     * ALU -- you shouldn't be building one yourself, like most
     * operations are. */
    class alu_op: public operation {
    private:
        const value& _d;
        const value& _s0;
        const value& _s1;

    public:
        alu_op(const value &d, const value &s0, const value &s1)
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
                        "%s = %s %s %s, %s",
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
    template<class T> class mov_op_cls: public alu_op {
    private:
    public:
        mov_op_cls(const T &dest, const T &src)
            : alu_op(dest, src, src)
            {
            }

        const std::string op_llvm(void) const { return "or"; }
    };
    template<class T> mov_op_cls<T> mov_op(const T& dest, const T& src)
    { return mov_op_cls<T>(dest, src); }

    /* A slightly less safe version of a mov -- this one can fail at
     * runtime. */
    template<class D, class S> class unsafemov_op_cls: public alu_op {
    private:
    public:
        unsafemov_op_cls(const D &dest, const S &src)
            : alu_op(dest, src, src)
            {
            }

        const std::string op_llvm(void) const { return "or"; }
    };
    template<class D, class S>
    unsafemov_op_cls<D, S> unsafemov_op(const D& dest, const S& src)
    { return unsafemov_op_cls<D, S>(dest, src); }

    /* Performs an addition. */
    template<class T> class add_op_cls: public alu_op {
    private:
    public:
        add_op_cls(const T &dest, const T &s0, const T& s1)
            : alu_op(dest, s0, s1)
            {
            }

        const std::string op_llvm(void) const { return "add"; }
    };
    template<class T>
    add_op_cls<T> add_op(const T& d, const T& s0, const T& s1)
    { return add_op_cls<T>(d, s0, s1); }

    /* Performs a subtraction. */
    template<class T> class sub_op_cls: public alu_op {
    private:
    public:
        sub_op_cls(const T &dest, const T &s0, const T& s1)
            : alu_op(dest, s0, s1)
            {
            }

        const std::string op_llvm(void) const { return "sub"; }
    };
    template<class T>
    sub_op_cls<T> sub_op(const T& d, const T& s0, const T& s1)
    { return sub_op_cls<T>(d, s0, s1); }

    /* Performs a bitwise logical OR. */
    template<class T> class or_op_cls: public alu_op {
    private:
    public:
        or_op_cls(const T &dest, const T &s0, const T& s1)
            : alu_op(dest, s0, s1)
            {
            }

        const std::string op_llvm(void) const { return "or"; }
    };
    template<class T> or_op_cls<T>
    or_op(const T& d, const T& s0, const T& s1)
    { return or_op_cls<T>(d, s0, s1); }

    /* Performs a bitwise logical AND. */
    template<class T> class and_op_cls: public alu_op {
    private:
    public:
        and_op_cls(const T &dest, const T &s0, const T& s1)
            : alu_op(dest, s0, s1)
            {
            }

        const std::string op_llvm(void) const { return "and"; }
    };
    template<class T> and_op_cls<T>
    and_op(const T& d, const T& s0, const T& s1)
    { return and_op_cls<T>(d, s0, s1); }

    /* Performs a left shift. */
    template<class T, class O> class lsh_op_cls: public alu_op {
    private:
    public:
        lsh_op_cls(const T& dst, const T& src, const O& offset)
            : alu_op(dst, src, offset)
            {
            }

        const std::string op_llvm(void) const { return "shl"; }
    };
    template<class T, class O>
    lsh_op_cls<T, O> lsh_op(const T& d, const T& s, const O& o)
    { return lsh_op_cls<T, O>(d, s, o); }

    /* Performs a logical right shift. */
    template<class T, class O> class lrsh_op_cls: public alu_op {
    private:
    public:
        lrsh_op_cls(const T& dst, const T& src, const O& offset)
            : alu_op(dst, src, offset)
            {
            }

        const std::string op_llvm(void) const { return "lshr"; }
    };
    template<class T, class O>
    lrsh_op_cls<T, O> lrsh_op(const T& d, const T& s, const O& o)
    { return lrsh_op_cls<T, O>(d, s, o); }

    /* Compares two numbers to see if they are equal or not. */
    template<class D, class S> class cmp_eq_op_cls: public alu_op {
    private:
    public:
        cmp_eq_op_cls(const D& d, const S& s0, const S& s1)
            : alu_op(d, s0, s1)
        {
        }

        const std::string op_llvm(void) const { return "icmp eq"; }
    };
    template<class D, class S>
    cmp_eq_op_cls<D, S> cmp_eq_op(const D& d, const S& s0, const S& s1)
    { return cmp_eq_op_cls<D, S>(d, s0, s1); }

    /* Greate-or-equal comparison */
    template<class D, class S> class cmp_gte_op_cls: public alu_op {
    private:
    public:
        cmp_gte_op_cls(const D& d, const S& s0, const S& s1)
            : alu_op(d, s0, s1)
        {
        }

        const std::string op_llvm(void) const { return "icmp uge"; }
    };
    template<class D, class S>
    cmp_gte_op_cls<D, S> cmp_gte_op(const D& d, const S& s0, const S& s1)
    { return cmp_gte_op_cls<D, S>(d, s0, s1); }

    /* Less-than comparison */
    template<class D, class S> class cmp_lt_op_cls: public alu_op {
    private:
    public:
        cmp_lt_op_cls(const D& d, const S& s0, const S& s1)
            : alu_op(d, s0, s1)
        {
        }

        const std::string op_llvm(void) const { return "icmp ult"; }
    };
    template<class D, class S>
    cmp_lt_op_cls<D, S> cmp_lt_op(const D& d, const S& s0, const S& s1)
    { return cmp_lt_op_cls<D, S>(d, s0, s1); }

    /* Performs a bitwise logical NOT. */
    template<class T> class not_op_cls: public alu_op {
    private:
    public:
        not_op_cls(const T &dest, const T &s0)
            : alu_op(dest, s0, s0)
            {
            }

        const std::string op_llvm(void) const { return "xor"; }

        /* The not operation is a tiny bit special in LLVM... */
        virtual const std::string as_llvm(void) const
            {
                std::string dest = d().llvm_name();
                std::string opst = op_llvm();
                std::string type = s0().as_llvm();
                std::string src0 = s0().llvm_name();

                char buffer[1024];
                snprintf(buffer, 1024,
                        "%s = %s %s %s, -1",
                        dest.c_str(),
                        opst.c_str(),
                        type.c_str(),
                        src0.c_str()
                    );
                return buffer;
            }
    };
    template<class T> not_op_cls<T>
    not_op(const T& d, const T& s0)
    { return not_op_cls<T>(d, s0); }
}

#endif
