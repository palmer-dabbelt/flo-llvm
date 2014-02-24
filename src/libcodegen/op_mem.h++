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

#ifndef LIBCODEGEN__OP_MEM_HXX
#define LIBCODEGEN__OP_MEM_HXX

#include "operation.h++"

/* These are all the sorts of operations that touch memory.  In
 * addition to load/store stuff there's pointer operations in here. */
namespace libcodegen {
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
