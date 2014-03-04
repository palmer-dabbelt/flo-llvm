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

/* These allow for consistant definitions of the different sorts of
 * operations.  Essentially the idea is that they all look pretty much
 * the same, this reduces the amount of boiler-plate that needs to be
 * written. */
#define LIBCODEGEN__DEF_ALU_OP_1_2(name, op)                    \
    template<class T>                                           \
    class name ## _op_cls: public alu_op {                      \
    private:                                                    \
    public:                                                     \
    name ## _op_cls(const T& d, const T& s)                     \
    : alu_op(d, s, s)                                           \
            { }                                                 \
                                                                \
    const std::string op_llvm(void) const { return op; }        \
    };                                                          \
    template<class T>                                           \
    name ## _op_cls<T>                                          \
    name ## _op(const T& d, const T& s)                         \
    { return name ## _op_cls<T>(d, s); }                        \

#define LIBCODEGEN__DEF_ALU_OP_1_3(name, op)                    \
    template<class T>                                           \
    class name ## _op_cls: public alu_op {                      \
    private:                                                    \
    public:                                                     \
    name ## _op_cls(const T& d, const T& s, const T& t)         \
    : alu_op(d, s, t)                                           \
            { }                                                 \
                                                                \
    const std::string op_llvm(void) const { return op; }        \
    };                                                          \
    template<class T>                                           \
    name ## _op_cls<T>                                          \
    name ## _op(const T& d, const T& s, const T& t)             \
    { return name ## _op_cls<T>(d, s, t); }                     \

#define LIBCODEGEN__DEF_ALU_OP_2_2(name, op)                    \
    template<class D, class S>                                  \
    class name ## _op_cls: public alu_op {                      \
    private:                                                    \
    public:                                                     \
    name ## _op_cls(const D& d, const S& s)                     \
    : alu_op(d, s, s)                                           \
            { }                                                 \
                                                                \
    const std::string op_llvm(void) const { return op; }        \
    };                                                          \
    template<class D, class S>                                  \
    name ## _op_cls<D, S>                                       \
    name ## _op(const D& d, const S& s)                         \
    { return name ## _op_cls<D, S>(d, s); }                     \

#define LIBCODEGEN__DEF_ALU_OP_2_3s(name, op)                   \
    template<class D, class S>                                  \
    class name ## _op_cls: public alu_op {                      \
    private:                                                    \
    public:                                                     \
    name ## _op_cls(const D& d, const S& s, const S& t)         \
    : alu_op(d, s, t)                                           \
            { }                                                 \
                                                                \
    const std::string op_llvm(void) const { return op; }        \
    };                                                          \
    template<class D, class S>                                  \
    name ## _op_cls<D, S>                                       \
    name ## _op(const D& d, const S& s, const S& t)             \
    { return name ## _op_cls<D, S>(d, s, t); }                  \

#define LIBCODEGEN__DEF_ALU_OP_2_3o(name, op)                   \
    template<class D, class S>                                  \
    class name ## _op_cls: public alu_op {                      \
    private:                                                    \
    public:                                                     \
    name ## _op_cls(const D& d, const D& s, const S& t)         \
    : alu_op(d, s, t)                                           \
            { }                                                 \
                                                                \
    const std::string op_llvm(void) const { return op; }        \
    };                                                          \
    template<class D, class S>                                  \
    name ## _op_cls<D, S>                                       \
    name ## _op(const D& d, const D& s, const S& t)             \
    { return name ## _op_cls<D, S>(d, s, t); }                  \

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
    LIBCODEGEN__DEF_ALU_OP_1_2(mov, "or")

    /* A slightly less safe version of a mov -- this one doesn't do
     * _any_ type checking at all! */
    LIBCODEGEN__DEF_ALU_OP_2_2(unsafemov, "or")

    /* Arithmatic operations. */
    LIBCODEGEN__DEF_ALU_OP_1_3(add, "add")
    LIBCODEGEN__DEF_ALU_OP_1_3(sub, "sub")
    LIBCODEGEN__DEF_ALU_OP_2_3s(mul, "mul")

    /* Bitwise logical operations. */
    LIBCODEGEN__DEF_ALU_OP_1_3(and, "and")
    LIBCODEGEN__DEF_ALU_OP_1_3(or, "or")
    LIBCODEGEN__DEF_ALU_OP_1_3(xor, "xor")

    /* Performs a left shift. */
    LIBCODEGEN__DEF_ALU_OP_2_3o(lsh, "shl")
    LIBCODEGEN__DEF_ALU_OP_2_3o(lrsh, "lshr")

    /* Comparison operations. */
    LIBCODEGEN__DEF_ALU_OP_2_3s(cmp_eq, "icmp eq")
    LIBCODEGEN__DEF_ALU_OP_2_3s(cmp_gte, "icmp uge")
    LIBCODEGEN__DEF_ALU_OP_2_3s(cmp_lt, "icmp ult")

    /* Performs a bitwise logical NOT -- note that this is a
     * special-case operation because LLVM doesn't have a NOT
     * operation! */
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
