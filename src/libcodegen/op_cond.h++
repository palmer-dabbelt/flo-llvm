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

#ifndef LIBCODEGEN__OP_COND_HXX
#define LIBCODEGEN__OP_COND_HXX

/* Conditional operations: both conditional-move and branches. */
namespace libcodegen {
    /* A special operation that supports Chisel's MUX operation. */
    template<class S, class V> class mux_op_cls: public operation {
    private:
        const V& _d;
        const S& _s;
        const V& _t;
        const V& _f;

    public:
        mux_op_cls(const V& d, const S& s, const V& t, const V& f)
            : _d(d),
              _s(s),
              _t(t),
              _f(f)
            {
            }

        virtual const std::string as_llvm(void) const
            {
                char buffer[1024];
                snprintf(buffer, 1024,
                         "%s = select i1 %s, %s %s, %s %s",
                         _d.llvm_name().c_str(),
                         _s.llvm_name().c_str(),
                         _t.as_llvm().c_str(),
                         _t.llvm_name().c_str(),
                         _f.as_llvm().c_str(),
                         _f.llvm_name().c_str()
                    );

                return buffer;
            }
    };
    template<class S, class V>
    mux_op_cls<S, V> mux_op(const V& d, const S& s, const V& t, const V& f)
    { return mux_op_cls<S, V>(d, s, t, f); }
}

#endif

