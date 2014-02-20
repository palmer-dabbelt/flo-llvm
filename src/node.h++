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
#include <memory>
#include <vector>

class node;
typedef std::shared_ptr<node> node_ptr;

/* This defines our extension of a node.  The idea here is to provide
 * some semblance of type safety when generating code by looking up
 * values within this header file as opposed to attempting to generate
 * coherent values in many places. */
class node: public libflo::node {
private:
    /* This returns the mangled name that Chisel uses to refer to this
     * symbol inside the C++ header file. */
    const std::string _mangled_d;

    /* FIXME: This should be removed. */
    const std::vector<std::string> _mangled_s;

    /* This is set to TRUE whenever this symbol should be exported
     * into the Chisel header file, and FALSE otherwise. */
    const bool _exported;

public:
    /* Fills out this node with the extra information that's needed in
     * order to make code generation work. */
    node(const libflo::node_ptr n);

    /* Accessor functions. */
    const std::string mangled_d(void) const { return _mangled_d; }
    const std::string mangled_s(size_t i) const { return _mangled_s[i]; }
    bool exported(void) const { return _exported; }

    /* Accesses the source and destination operands as libcodegen
     * types.  Essentially this makes sure you can't mess up the name
     * mangling by not even giving you the option to. */
    libcodegen::fix_t dv(void) const;
    libcodegen::fix_t sv(size_t i) const;

    /* Returns a function that allows for access into this node's
     * permanent storage.  This handles C++ name demangling (when
     * generating code for the C++ compatibility layer). */
    libcodegen::function<
        libcodegen::pointer<libcodegen::builtin<char>>,
        libcodegen::arglist1<libcodegen::pointer<libcodegen::builtin<char>>>
        > ptr_func(void) const;
};

#endif
