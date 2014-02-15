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

#ifndef LIBCODEGEN__FUNCTION_HXX
#define LIBCODEGEN__FUNCTION_HXX

#include "value.h++"
#include <string>
#include <vector>

namespace libcodegen {
    /* This represents any sort of function.  Note that by using this
     * you explicitly lose type safety.  This is desirable when you
     * want to be able to process any function (like in a language
     * backend, for example). */
    class function_t: public value {
    public:
        /* Formats the return type of this function as an LLVM type
         * name. */
        virtual const std::string ret_llvm(void) const = 0;

        /* Returns the name of this function, with no particular
         * formatting. */
        virtual const std::string name(void) const = 0;

        /* Returns the argument list of this function, formatted as
         * LLVM strings. */
        virtual const std::vector<std::string> args_llvm(void) const = 0;
    };

    /* Here we have a specific sort of function.  These are the ones
     * that you'll actually be creating and passing around. */
    template<class R, class A>
    class function: public function_t {
    private:
        const std::string _name;

    public:
        function(const std::string name)
            : _name(name)
            {
            }

        const std::string ret_llvm(void) const { return R::as_llvm(); }

        const std::string name(void) const { return _name; }

        const std::vector<std::string> args_llvm(void) const
            { return A::as_llvm(); }
    };
}

#endif
