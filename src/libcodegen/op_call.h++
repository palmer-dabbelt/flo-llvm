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

#ifndef LIBCODEGEN__OP_CALL_HXX
#define LIBCODEGEN__OP_CALL_HXX

#include "operation.h++"

/* This file contains the definitions of some operations that assist
 * in calling functions. */
namespace libcodegen {
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
}

#endif
