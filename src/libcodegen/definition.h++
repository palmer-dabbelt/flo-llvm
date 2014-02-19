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

#ifndef LIBCODEGEN__DEFINITION_HXX
#define LIBCODEGEN__DEFINITION_HXX

#include <memory>

namespace libcodegen {
    class definition;
    typedef std::shared_ptr<definition> definition_ptr;
}

#include "llvm.h++"

namespace libcodegen {
    /* Holds an object that allows for the definition of a function.
     * When this object is destructed then the function's definition
     * is closed. */
    class definition {
    private:
        llvm *_parent;

    public:
        /* Effectively the whole point of this object is to provide a
         * callback function when it is destroyed. */
        definition(llvm *parent);
        ~definition(void);

        /* This quite simply prints a comment out to the output file,
         * directly in this place.  Don't put newlines inside the
         * comment! */
        void comment(const std::string format, ...);
        void comment(const std::string format, va_list args);
    };
}

#endif
