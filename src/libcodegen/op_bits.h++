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

#ifndef LIBCODEGEN__OP_BITS_HXX
#define LIBCODEGEN__OP_BITS_HXX

#include "operation.h++"

/* These are all bit-casting operations, things like truncation and
 * zero-extension go here.  These operations are all pretty dangerous,
 * so be careful with them! */
namespace libcodegen {
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

    /* Like zero_ext_op, but for sign extensions. */
    template<class O, class I> class sign_ext_op_cls: public operation {
    private:
        const O& _o;
        const I& _i;

    public:
        sign_ext_op_cls(const O& o, const I& i)
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
                         "%s = sext %s %s to %s",
                         _o.llvm_name().c_str(),
                         _i.as_llvm().c_str(),
                         _i.llvm_name().c_str(),
                         _o.as_llvm().c_str()
                    );

                return buffer;
            }
    };
    template<class O, class I>
    sign_ext_op_cls<O, I> sign_ext_op(const O& o, const I& i)
    { return sign_ext_op_cls<O, I>(o, i); }

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

    /* Like zext_trunc_op, but for sign extension. */
    template<class O, class I> class sext_trunc_op_cls: public operation {
    private:
        const O& _o;
        const I& _i;

    public:
        sext_trunc_op_cls(const O& o, const I& i)
            : _o(o),
              _i(i)
            {
            }

        virtual const std::string as_llvm(void) const
            {
                if (_o.width() >= _i.width()) {
                    auto z = sign_ext_op(_o, _i);
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
    sext_trunc_op_cls<O, I> sext_trunc_op(const O& o, const I& i)
    { return sext_trunc_op_cls<O, I>(o, i); }
}

#endif
