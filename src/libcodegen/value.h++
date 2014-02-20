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

#ifndef LIBCODEGEN__VALUE_HXX
#define LIBCODEGEN__VALUE_HXX

#include <string>

namespace libcodegen {
    /* A "value" (which is probably named wrong, maybe it's more of a
     * type) represents the type that a value can have -- we don't
     * actually know the value until execution (so this code _never_
     * knows the value). */
    class value {
    private:
        const std::string _name;

    public:
        /* Generates a new temporary name for this value that's
         * gaurnteed to be unique. */
        value(void);

        /* Allows the construction of a value by taking an explicit
         * name. */
        value(const std::string name);

        /* Accessor functions. */
        const std::string name(void) const { return _name; }

        /* Emits the LLVM name for this value's type. */
        virtual const std::string as_llvm(void) const = 0;

        /* Emits the LLVM name for this value. */
        const std::string llvm_name(void) const
            {
                if (isdigit(name().c_str()[0]))
                    return name();

                char buffer[1024];
                snprintf(buffer, 1024, "%%%s", name().c_str());
                return buffer;
            }
    };
}

#endif
