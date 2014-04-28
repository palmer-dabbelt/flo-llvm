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

#ifndef NODE_HXX
#define NODE_HXX

#include <libcodegen/arglist.h++>
#include <libcodegen/builtin.h++>
#include <libcodegen/fix.h++>
#include <libcodegen/llvm.h++>
#include <libcodegen/pointer.h++>
#include <libcodegen/vargs.h++>
#include <libflo/node.h++>

class node: public libflo::node {
    friend class libflo::node;

private:
    bool _exported;
    bool _vcd_exported;

    const std::string _vcd_name;

private:
        node(const std::string name,
             const libflo::unknown<size_t>& width,
             const libflo::unknown<size_t>& depth,
             bool is_mem,
             bool is_const,
             libflo::unknown<size_t> cycle,
             const libflo::unknown<size_t>& x,
             const libflo::unknown<size_t>& y);

public:
    /* Returns TRUE if this node should be exported into the C++
     * header file. */
    bool exported(void) const { return _exported; }

    /* Returns TRUE if this node should be exported into the VCD
     * file. */
    bool vcd_exported(void) const { return _vcd_exported; }

    /* Returns TRUE if this node is a Chisel temporary node. */
    bool chisel_temp(void) const { return (mangled_name() == chisel_name()); }

    /* Returns the mangled name of this node, which refers to the name
     * this node is expected to have when inside the C++ header
     * file. */
    const std::string mangled_name(void) const;

    /* Returns the Chisel name of this node, which refers to the name
     * this node is expected to have when inside the Chisel test
     * harness. */
    const std::string chisel_name(void) const;

    /* Returns the VCD name of this node, which refers to the name
     * this node is expected to have when inside the VCD file. */
    const std::string vcd_name(void) const { return _vcd_name; }

    /* Returns the LLVM name of this node, which refers to the name
     * this node is expected to have when inside an LLVM IR file. */
    const std::string llvm_name(void) const;

    /* Returns the libcodegen "name" of this node, which is really a
     * type-safe object that represents this node. */
    const libcodegen::fix_t cg_name(void) const;

    /* Functions that allow access to this node's internal data
     * structures. */
    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist2<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > get_func(void) const;

    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist2<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > set_func(void) const;

    /* These functions are like get/set above, but they provide access
     * to a memory's data structures. */
    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist3<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::builtin<uint64_t>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > getm_func(void) const;

    libcodegen::function<
        libcodegen::builtin<void>,
        libcodegen::arglist3<libcodegen::pointer<libcodegen::builtin<void>>,
                             libcodegen::builtin<uint64_t>,
                             libcodegen::pointer<libcodegen::builtin<uint64_t>>
                             >
        > setm_func(void) const;

public:
    /* Forces that this node is always exported into the header
     * file. */
    void force_export(void) { _exported = true; }
    void force_vcd_export(void) { _vcd_exported = true; }
};

#endif
