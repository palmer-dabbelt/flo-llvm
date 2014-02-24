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

    /* Performs an "alloca" operation, which allocates the provided
     * amount of space on the stack. */
    template<class O, class I> class alloca_op_cls: public operation {
    private:
        const O& _dst;
        const I& _src;

    public:
        alloca_op_cls(const O& dst, const I& src)
            : _dst(dst),
              _src(src)
            {
            }

        const std::string op_llvm(void) const { return "alloca"; }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                        "%s = %s %s, %s %s",
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

    /* Performs a call operation, which calls a function. */
    template<class F> class call_op_cls: public operation {
    private:
        const value &_dest;
        const F& _func;
        const std::vector<value*> _args;

    public:
        call_op_cls(const value& dst, const F& func)
            : _dest(dst),
              _func(func),
              _args()
            {
            }
        call_op_cls(const value& dst, const F& func,
                    const std::vector<value*> &args)
            : _dest(dst),
              _func(func),
              _args(args)
            {
            }

        const std::string op_llvm(void) const { return "call"; }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                         "%s = call %s @%s(",
                         _dest.llvm_name().c_str(),
                         _func.ret_llvm().c_str(),
                         _func.name().c_str()
                    );

                for (auto it = _args.begin(); it != _args.end();  ++it) {
                    auto arg = *it;

                    if (it != _args.begin())
                        strncat(buffer, " ,", 1024);

                    strncat(buffer, arg->as_llvm().c_str(), 1024);
                    strncat(buffer, arg->llvm_name().c_str(), 1024);
                }

                strncat(buffer, ")", 1024);

                return buffer;
            }
    };

    template<class F> class voidcall_op_cls: public operation {
    private:
        const F& _func;
        const std::vector<value*> _args;

    public:
        voidcall_op_cls(const F& func, const std::vector<value*> &args)
            : _func(func),
              _args(args)
            {
            }

        const std::string op_llvm(void) const { return "call"; }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                         "call %s @%s(",
                         _func.ret_llvm().c_str(),
                         _func.name().c_str()
                    );

                for (auto it = _args.begin(); it != _args.end();  ++it) {
                    auto arg = *it;

                    if (it != _args.begin())
                        strncat(buffer, " ,", 1024);

                    strncat(buffer, arg->as_llvm().c_str(), 1024);
                    strncat(buffer, arg->llvm_name().c_str(), 1024);
                }

                strncat(buffer, ")", 1024);

                return buffer;
            }
    };

    template<class F>
    voidcall_op_cls<F>
    call_op(const F&func, const std::vector<value*> &args)
    { return voidcall_op_cls<F>(func, args); }

    template<class F>
    call_op_cls<F>
    call_op(const value& dst, const F&func, const std::vector<value*> &args)
    { return call_op_cls<F>(dst, func, args); }

    template<class F>
    call_op_cls<F>
    call_op(const value& dst, const F& func)
    { return call_op_cls<F>(dst, func); }

    /* A specal operation that offsets into a pointer. */
    template<class P, class O> class index_op_cls: public operation {
    private:
        const P& _dst;
        const P& _src;
        const O& _offset;

    public:
        index_op_cls(const P& dst, const P& src, const O& offset)
            : _dst(dst),
              _src(src),
              _offset(offset)
            {
            }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                         "%s = getelementptr %s %s, %s %s",
                         _dst.llvm_name().c_str(),
                         _src.as_llvm().c_str(),
                         _src.llvm_name().c_str(),
                         _offset.as_llvm().c_str(),
                         _offset.llvm_name().c_str()
                    );

                return buffer;
            }
    };
    template<class P, class O>
    index_op_cls<P, O> index_op(const P& dst, const P& src, const O& offset)
    { return index_op_cls<P, O>(dst, src, offset); }

    /* A special operation that zero extends a small value up to a
     * larger value.  Note that this automatically checks the other
     * types and determines if they're narrow or wide, potientally
     * emitting a MOV to LLVM as the LLVM node doesn't support some
     * operations. */
    template<class O, class I> class zero_ext_op_cls: public operation {
    private:
        const O& _o;
        const I& _i;

    public:
        zero_ext_op_cls(const O& o, const I& i)
            : _o(o),
              _i(i)
            {
            }

        virtual const std::string as_llvm(void) const
            {
                if (_o.width() == _i.width()) {
                    auto mov = unsafemov_op(_o, _i);
                    return mov.as_llvm();
                }

                char buffer[1024];
                snprintf(buffer, 1024,
                         "%s = zext %s %s to %s",
                         _o.llvm_name().c_str(),
                         _i.as_llvm().c_str(),
                         _i.llvm_name().c_str(),
                         _o.as_llvm().c_str()
                    );

                return buffer;
            }
    };
    template<class O, class I>
    zero_ext_op_cls<O, I> zero_ext_op(const O& o, const I& i)
    { return zero_ext_op_cls<O, I>(o, i); }

    /* This is a really unsafe operation: it either zero-extends a
     * value of truncates it, depending on the sizes.  You almost
     * certainly don't want to be doing this! */
    template<class O, class I> class zext_trunc_op_cls: public operation {
    private:
        const O& _o;
        const I& _i;

    public:
        zext_trunc_op_cls(const O& o, const I& i)
            : _o(o),
              _i(i)
            {
            }

        virtual const std::string as_llvm(void) const
            {
                if (_o.width() >= _i.width()) {
                    auto z = zero_ext_op(_o, _i);
                    return z.as_llvm();
                }

                char buffer[1024];
                snprintf(buffer, 1024,
                         "%s = trunc %s %s to %s",
                         _o.llvm_name().c_str(),
                         _i.as_llvm().c_str(),
                         _i.llvm_name().c_str(),
                         _o.as_llvm().c_str()
                    );

                return buffer;
            }
    };
    template<class O, class I>
    zext_trunc_op_cls<O, I> zext_trunc_op(const O& o, const I& i)
    { return zext_trunc_op_cls<O, I>(o, i); }

    /* Loads from memory. */
    template<class T> class load_op_cls: public operation {
    private:
        const T& _dst;
        const pointer<T> &_src;

    public:
        load_op_cls(const T& dst, const pointer<T>& src)
            : _dst(dst),
              _src(src)
            {
            }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                         "%s = load %s %s",
                         _dst.llvm_name().c_str(),
                         _src.as_llvm().c_str(),
                         _src.llvm_name().c_str()
                    );

                return buffer;
            }
    };
    template<class T>
    load_op_cls<T> load_op(const T& dst, const pointer<T>& src)
    { return load_op_cls<T>(dst, src); }

    /* Stores to memory. */
    template<class T> class store_op_cls: public operation {
    private:
        const pointer<T>& _dst;
        const T &_src;

    public:
        store_op_cls(const pointer<T>& dst, const T& src)
            : _dst(dst),
              _src(src)
            {
            }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                         "store %s %s, %s %s",
                         _src.as_llvm().c_str(),
                         _src.llvm_name().c_str(),
                         _dst.as_llvm().c_str(),
                         _dst.llvm_name().c_str()
                    );

                return buffer;
            }
    };
    template<class T>
    store_op_cls<T> store_op(const pointer<T>& dst, const T& src)
    { return store_op_cls<T>(dst, src); }
}

#endif
