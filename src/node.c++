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

#include "node.h++"
#include <libflo/sizet_printf.h++>

#ifndef LINE_MAX
#define LINE_MAX 1024
#endif

static const std::string gen_vcd_name(void);

node::node(const std::string name,
           const libflo::unknown<size_t>& width,
           const libflo::unknown<size_t>& depth,
           bool is_mem,
           bool is_const,
           libflo::unknown<size_t> cycle)
    : libflo::node(name, width, depth, is_mem, is_const, cycle),
#if defined(EXPORT_ALL_NODES)
      _exported(true),
      _vcd_exported(!is_mem),
#elif defined(EXPORT_MANY_NODES)
      _exported(is_mem),
      _vcd_exported(!is_mem && (strstr(name.c_str(), ":") != NULL)),
#elif defined(EXPORT_FEW_NODES)
      _exported(is_mem),
      _vcd_exported(false),
#else
#error "Decide how many nodes to export!"
#endif
      _vcd_name(gen_vcd_name())
{
}

const std::string node::mangled_name(void) const
{
    char buffer[LINE_MAX];
    strncpy(buffer, name().c_str(), LINE_MAX);

    for (size_t i = 0; i < strlen(buffer); ++i) {
        if (buffer[i] == ':')
            buffer[i] = '_';
        if (buffer[i] == '.')
            buffer[i] = '_';
    }

    return buffer;
}

const std::string node::chisel_name(void) const
{
    char buffer[LINE_MAX];
    strncpy(buffer, name().c_str(), LINE_MAX);

    for (size_t i = 0; i < strlen(buffer); ++i) {
        while (buffer[i] == ':' && buffer[i+1] == ':')
            memmove(buffer + i, buffer + i + 1, strlen(buffer + i));
        if (buffer[i] == ':')
            buffer[i] = '.';
    }

    return buffer;
}

const std::string node::llvm_name(void) const
{
    if (is_const())
        return name();

    char buffer[LINE_MAX];
    snprintf(buffer, LINE_MAX, "%%%s", mangled_name().c_str());
    return buffer;
}

const libcodegen::fix_t node::cg_name(void) const
{
    size_t w = 1;

    if (!is_const())
        w = width();
    if (known_width())
        w = width();

    return libcodegen::fix_t(w, mangled_name());
}

libcodegen::function<
    libcodegen::builtin<void>,
    libcodegen::arglist2<libcodegen::pointer<libcodegen::builtin<void>>,
                         libcodegen::pointer<libcodegen::builtin<uint64_t>>
                         >
    > node::get_func(void) const
{
    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist2<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > out("_llvmflo_%s_get", mangled_name().c_str());

    return out;
}

libcodegen::function<
    libcodegen::builtin<void>,
    libcodegen::arglist2<libcodegen::pointer<libcodegen::builtin<void>>,
                         libcodegen::pointer<libcodegen::builtin<uint64_t>>
                         >
    > node::set_func(void) const
{
    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist2<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > out("_llvmflo_%s_set", mangled_name().c_str());

    return out;
}

libcodegen::function<
    libcodegen::builtin<void>,
    libcodegen::arglist3<libcodegen::pointer<libcodegen::builtin<void>>,
                         libcodegen::builtin<uint64_t>,
                         libcodegen::pointer<libcodegen::builtin<uint64_t>>
                         >
    > node::getm_func(void) const
{
    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist3<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::builtin<uint64_t>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > out("_llvmflo_%s_getm", mangled_name().c_str());

    return out;
}

libcodegen::function<
    libcodegen::builtin<void>,
    libcodegen::arglist3<libcodegen::pointer<libcodegen::builtin<void>>,
                         libcodegen::builtin<uint64_t>,
                         libcodegen::pointer<libcodegen::builtin<uint64_t>>
                         >
    > node::setm_func(void) const
{
    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist3<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::builtin<uint64_t>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > out("_llvmflo_%s_setm", mangled_name().c_str());

    return out;
}

const std::string gen_vcd_name(void)
{
    static size_t i = 0;
    return "N" + std::to_string(i++);
}
