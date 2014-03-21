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

#include "value.h++"
#include <stdlib.h>
using namespace libcodegen;

static const std::string generate_unique_name(void);

value::value(void)
    : _name(generate_unique_name())
{
}

value::value(const std::string name)
    : _name(name)
{
}

const std::string generate_unique_name(void)
{
    static long unsigned index = 1;

    if (index == 0) {
        fprintf(stderr, "Temporary value generated wrapped\n");
        abort();
    }

    char buffer[1024];
    snprintf(buffer, 1024, "V%lu", index);
    index++;
    return buffer;
}
