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

#include "mangle_name.h++"
#include <string.h>

#ifndef BUFFER_SIZE
#define BUFFER_SIZE 1024
#endif

std::pair<bool, const std::string> mangle_name(const std::string flo_name)
{
    char buffer[BUFFER_SIZE];
    strncpy(buffer, flo_name.c_str(), BUFFER_SIZE);

    bool changed = false;
    for (size_t i = 0; i < strlen(buffer); ++i) {
        if (buffer[i] == ':') {
            buffer[i] = '_'; {
                changed = true;
            }
        }
    }

    return std::pair<bool, const std::string>(changed, buffer);
}
