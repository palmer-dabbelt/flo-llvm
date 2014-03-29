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

#include "fix.h++"
#include <libflo/sizet_printf.h++>
#include <stdlib.h>
using namespace libcodegen;

#ifndef BUFFER_SIZE
#define BUFFER_SIZE 1024
#endif

const std::string fix_t::as_llvm(void) const
{
    char buffer[BUFFER_SIZE];
    snprintf(buffer, BUFFER_SIZE, "i" SIZET_FORMAT, _width);
    return buffer;
}

fix_t& fix_t::operator=(const fix_t& i)
{
    this->_width = i._width;
    return *this;
}
