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

#include "flo.h++"
#include "node.h++"
#include "operation.h++"

#include "version.h"

#include <libcodegen/arglist.h++>
#include <libcodegen/builtin.h++>
#include <libcodegen/constant.h++>
#include <libcodegen/fix.h++>
#include <libcodegen/llvm.h++>
#include <libcodegen/op_alu.h++>
#include <libcodegen/op_bits.h++>
#include <libcodegen/op_call.h++>
#include <libcodegen/op_cond.h++>
#include <libcodegen/op_mem.h++>
#include <libcodegen/pointer.h++>
#include <libcodegen/vargs.h++>
#include <libflo/sizet_printf.h++>
#include <libflo/version.h++>

#include <algorithm>
#include <string.h>
#include <string>
#include <map>

using namespace libcodegen;

#ifndef BUFFER_SIZE
#define BUFFER_SIZE 1024
#endif

enum gentype {
    GENTYPE_IR,
    GENTYPE_HEADER,
    GENTYPE_COMPAT,
    GENTYPE_HARNESS,
    GENTYPE_ERROR
};

/* These generate the different sorts of files that can be produced by
 * the C++ toolchain. */
static int generate_header(const flo_ptr flo, FILE *f);
static int generate_compat(const flo_ptr flo, FILE *f);
static int generate_llvmir(const flo_ptr flo, FILE *f);
static int generate_harness(const flo_ptr flo, FILE *f);

/* Returns TRUE if the haystack starts with the needle. */
static bool strsta(const std::string haystack, const std::string needle);

/* Converts between an array of words (as used in the C++ emulator's
 * header) and an LLVM integer. */
static void array2int(std::shared_ptr<definition> lo,
                      fix_t out,
                      pointer<builtin<uint64_t>> pointer,
                      size_t words);
static void int2array(std::shared_ptr<definition> lo,
                      fix_t out,
                      pointer<builtin<uint64_t>> pointer,
                      size_t words);

/* Counts the number of module components in a list. */
static size_t count_components(const std::string str);

/* Returns TRUE if the long component is a sub-component of the short
 * component name. */
static bool component_start(const std::string haystack,
                            const std::string needle);

int main(int argc, const char **argv)
{
    /* Prints the version if it was asked for. */
    if (argc == 2 && strcmp(argv[1], "--version") == 0) {
        fprintf(stderr, "%s (using libflo %s)\n",
                PCONFIGURE_VERSION,
                libflo::version());
        exit(0);
    }

    /* Prints the help text if it was asked for or if there was no
     * input file given. */
    if (argc == 1 || argc > 3 || strcmp(argv[1], "--help") == 0) {
        fprintf(stderr, "%s: <flo> <type>\n", argv[0]);
        fprintf(stderr, "  Converts a Flo file to LLVM IR\n");
        fprintf(stderr, "  The output will be a drop-in replacement for\n");
        fprintf(stderr, "  Chisel's C++ emulator\n");
        exit(1);
    }

    /* An input filename of "-" means read from stdin. */
    auto infn = strcmp(argv[1], "-") == 0 ? "/dev/stdin" : argv[1];

    /* Look at the second argument to figure out what type to
     * generate. */
    enum gentype type = GENTYPE_ERROR;
    if (strcmp(argv[2], "--ir") == 0)
        type = GENTYPE_IR;
    if (strcmp(argv[2], "--header") == 0)
        type = GENTYPE_HEADER;
    if (strcmp(argv[2], "--compat") == 0)
        type = GENTYPE_COMPAT;
    if (strcmp(argv[2], "--harness") == 0)
        type = GENTYPE_HARNESS;

    /* Reads the input file and infers the width of every node. */
    auto flo = flo::parse(infn);

    /* Figures out what sort of output to generate. */
    switch (type) {
    case GENTYPE_IR:
        return generate_llvmir(flo, stdout);
    case GENTYPE_HEADER:
        return generate_header(flo, stdout);
    case GENTYPE_COMPAT:
        return generate_compat(flo, stdout);
    case GENTYPE_HARNESS:
        return generate_harness(flo, stdout);
    case GENTYPE_ERROR:
        fprintf(stderr, "Unknown generate target '%s'\n", argv[2]);
        fprintf(stderr, "  valid targets are:\n");
        fprintf(stderr, "    --ir:     Generates LLVM IR\n");
        fprintf(stderr, "    --header: Generates a C++ class header\n");
        fprintf(stderr, "    --compat: Generates a C++ compat layer\n");
        fprintf(stderr, "    --harness:Generates a C++ test harness\n");
        abort();
        return 1;
    }

    return 0;
}

int generate_header(const flo_ptr flo, FILE *f)
{
    /* Figures out the class name, printing that out. */
    fprintf(f, "#include <stdio.h>\n");
    fprintf(f, "#include <stdint.h>\n");
    /* FIXME: Don't depend on Chisel's emulator.h, it kind of
     * defeats the point of doing all this in the first
     * place... */
    fprintf(f, "#include \"emulator.h\"\n");
    fprintf(f, "class %s_t: public mod_t {\n", flo->class_name().c_str());
    fprintf(f, "  public:\n");

    /* Declares the variables that need to be present in the C++
     * header file in order to maintain compatibility with Chisel's
     * output. */
    for (const auto& node: flo->nodes()) {
        if (node->exported() == false)
            continue;

        if (node->is_mem() == true) {
            fprintf(f, "    mem_t<" SIZET_FORMAT ", " SIZET_FORMAT "> %s;\n",
                    node->width(),
                    node->depth(),
                    node->mangled_name().c_str());
        } else {
            fprintf(f, "    dat_t<" SIZET_FORMAT "> %s;\n",
                    node->width(),
                    node->mangled_name().c_str());

            fprintf(f, "    dat_t<" SIZET_FORMAT "> %s__prev;\n",
                    node->width(),
                    node->mangled_name().c_str());
        }
    }

    /* Here we write the class methods that exist in Chisel and will
     * be implemented externally by either the compatibility layer or
     * the emitted LLVM IR.  These must exactly match the
     * Chisel-emitted definitions. */
    fprintf(f, "  public:\n");
    fprintf(f, "    void init(bool random_init = false);\n");
    fprintf(f, "    int clock(dat_t<1> reset);\n");
    fprintf(f, "    void clock_lo(dat_t<1> reset);\n");
    fprintf(f, "    void clock_hi(dat_t<1> reset);\n");
    fprintf(f, "    void dump(FILE *file, int clock);\n");
    fprintf(f, "    mod_t *clone(void);\n");
    fprintf(f, "    bool set_circuit_from(mod_t *src);\n");

    /* Close the class */
    fprintf(f, "};\n");

    /* The new Chisel emulator appears to require a second class
     * that's used for debug info. */
    fprintf(f, "class %s_api_t : public mod_api_t {\n",
            flo->class_name().c_str());
    fprintf(f, "  void init_mapping_table(void);\n");
    fprintf(f, "};\n");

    return 0;
}

int generate_compat(const flo_ptr flo, FILE *f)
{
    /* The whole point of this is to work around the C++ name
     * mangling. */
    fprintf(f, "extern \"C\" {\n");

    /* Produce accessor functions that can be used to get pointers to
     * particular fields within the C++ class definition.  The idea
     * here is that I can get around C++ name mangling by exporting
     * these as C names. */
    for (const auto& node: flo->nodes()) {
        if (node->exported() == false)
            continue;

        if (node->is_mem() == true) {
            /* This function pulls the value from a node into an
             * array.  Essentially this just does C++ name
             * demangling. */
            fprintf(f, "  void _llvmflo_%s_getm(%s_t *d, uint64_t i, uint64_t *a) {\n",
                    node->mangled_name().c_str(),
                    flo->class_name().c_str()
                );

            fprintf(f, "    dat_t<" SIZET_FORMAT "> v = d->%s.get(i);\n",
                    node->width(),
                    node->mangled_name().c_str()
                );

            for (size_t i = 0; i < (node->width() + 63) / 64; ++i) {
                fprintf(f, "    a[" SIZET_FORMAT "] "
                        "= v.values[" SIZET_FORMAT "];\n",
                        i,
                        i
                    );
            }

            fprintf(f, "  }\n");

            /* The opposite of the above: sets a mem_t value. */
            fprintf(f, "  void _llvmflo_%s_setm(%s_t *d, uint64_t i, uint64_t *a) {\n",
                    node->mangled_name().c_str(),
                    flo->class_name().c_str()
                );

            fprintf(f, "    dat_t<" SIZET_FORMAT "> v;",
                    node->width()
                );

            for (size_t i = 0; i < (node->width() + 63) / 64; ++i) {
                fprintf(f, "    v.values[" SIZET_FORMAT "] "
                        "= a[" SIZET_FORMAT "];\n",
                        i,
                        i
                    );
            }

            fprintf(f, "    d->%s.put(i, v);\n",
                    node->mangled_name().c_str()
                );

            fprintf(f, "  }\n");
        } else {
            /* This function pulls the value from a node into an
             * array.  Essentially this just does C++ name
             * demangling. */
            fprintf(f, "  void _llvmflo_%s_get(%s_t *d, uint64_t *a) {\n",
                    node->mangled_name().c_str(),
                    flo->class_name().c_str()
                );

            for (size_t i = 0; i < (node->width() + 63) / 64; ++i) {
                fprintf(f, "    a[" SIZET_FORMAT "] "
                        "= d->%s.values[" SIZET_FORMAT "];\n",
                        i,
                        node->mangled_name().c_str(),
                        i
                    );
            }

            fprintf(f, "  }\n");

            /* The opposite of the above: sets a dat_t value. */
            fprintf(f, "  void _llvmflo_%s_set(%s_t *d, uint64_t *a) {\n",
                    node->mangled_name().c_str(),
                    flo->class_name().c_str()
                );

            for (size_t i = 0; i < (node->width() + 63) / 64; ++i) {
                fprintf(f, "    d->%s.values[" SIZET_FORMAT "] "
                        "= a[" SIZET_FORMAT "];\n",
                        node->mangled_name().c_str(),
                        i,
                        i
                    );
            }

            fprintf(f, "  }\n");
        }
    }

    /* Here's where we elide the last bits of name mangling: these
     * functions wrap some non-mangled IR-generated names that
     * actually implement the functions required by Chisel's C++
     * interface. */
    fprintf(f, "  void _llvmflo_%s_init(%s_t *p, bool r);\n",
            flo->class_name().c_str(), flo->class_name().c_str());

    fprintf(f, "  void _llvmflo_%s_clock_lo(%s_t *p, bool r);\n",
            flo->class_name().c_str(), flo->class_name().c_str());

    fprintf(f, "  void _llvmflo_%s_clock_hi(%s_t *p, bool r);\n",
            flo->class_name().c_str(), flo->class_name().c_str());

    /* End the 'extern "C"' block above. */
    fprintf(f, "};\n");

    /* The clock function just calls the other two clock functions. */
    fprintf(f, "int %s_t::clock(dat_t<1> rd)\n", flo->class_name().c_str());
    fprintf(f, "  { clock_hi(rd); clock_lo(rd); return 0; }\n");

    /* Actually define the (non mangled) implementation of the Chisel
     * C++ interface, which in fact only calls the LLVM-generated
     * functions. */
    fprintf(f, "void %s_t::clock_lo(dat_t<1> rd)\n",
            flo->class_name().c_str());
    fprintf(f, "  { _llvmflo_%s_clock_lo(this, rd.to_ulong()); }\n",
            flo->class_name().c_str());

    /* init just sets everything to zero, which is easy to do in C++
     * (it'll be fairly short). */
    fprintf(f, "void %s_t::init(bool r)\n{\n", flo->class_name().c_str());
    for (const auto& node: flo->nodes()) {
        if (node->exported() == false)
            continue;

        if (node->is_mem() == true) {
            fprintf(f, "  for (size_t i = 0; i < " SIZET_FORMAT "; ++i) {",
                    node->depth()
                );
            fprintf(f, "    this->%s.put(i, 0);\n",
                    node->mangled_name().c_str()
                );
            fprintf(f, "  }\n");
        } else {
            fprintf(f, "  this->%s = 0;\n", node->mangled_name().c_str());
        }
    }

    for (const auto& op: flo->operations()) {
        if (op->op() != libflo::opcode::INIT)
            continue;

        fprintf(f, "  this->%s.put(%s, %s);\n",
                op->s()->mangled_name().c_str(),
                op->t()->name().c_str(),
                op->u()->name().c_str()
            );
    }
    fprintf(f, "}\n");

    /* clock_hi just copies data around and therefor is simplest to
     * stick in C++ -- using LLVM IR doesn't really gain us anything
     * here. */
    fprintf(f, "void %s_t::clock_hi(dat_t<1> rd)\n{\n",
            flo->class_name().c_str());
    fprintf(f, "  bool r = rd.to_ulong();\n");
    for (const auto& op: flo->operations()) {
        /* Only registers need to be copied on */
        if (op->op() != libflo::opcode::REG)
            continue;

        if (op->s()->is_const()) {
            fprintf(f, "  if (%s == 1) { %s = %s; }\n",
                    op->s()->mangled_name().c_str(),
                    op->d()->mangled_name().c_str(),
                    op->t()->mangled_name().c_str()
                );
        } else {
            fprintf(f, "  if (%s.lo_word() == 1) { %s = %s; }\n",
                    op->s()->mangled_name().c_str(),
                    op->d()->mangled_name().c_str(),
                    op->t()->mangled_name().c_str()
                );
        }
    }
    fprintf(f, "}\n");

    /* VCD dumping is implemented directly in C++ here because I don't
     * really see a reason not to. */
    fprintf(f, "void %s_t::dump(FILE *f, int cycle)\n{\n",
            flo->class_name().c_str());

    /* On the first cycle we need to write out the VCD header file. */
    fprintf(f, "  if (cycle == 0) {\n");
    fprintf(f, "    fprintf(f, \"$timescale 1ps $end\\n\");\n");
    fprintf(f, "    fprintf(f, \"$scope module %s $end\\n\");\n",
            flo->class_name().c_str());

    std::string last_path = "";
    ssize_t scope = 1;
    for (const auto& node: flo->nodes_alpha()) {
        char buffer[BUFFER_SIZE];
        snprintf(buffer, BUFFER_SIZE, "%s", node->name().c_str());

        /* Here's where we figure out where in the module heirarchy
         * this node is. */
        char *module = buffer;
        char *signal = buffer;
        for (size_t i = 0; i < strlen(buffer); i++)
            if (buffer[i] == ':')
                signal = buffer + i;

        /* These have no "::" in them, which means they're not
         * globally visible. */
        if (module == signal)
            continue;

        /* The module seperator can be either ":" or "::".  Detect
         * which one is actually generated and demangle the name
         * correctly. */
        if (signal[-1] == ':')
            signal[-1] = '\0';
        signal[0] = '\0';
        signal++;

        /* Figure out if we're going up or down a module and perform
         * that move. */
        if (strcmp(module, last_path.c_str()) == 0) {
        } else if (component_start(last_path, module)) {
            fprintf(f, "    fprintf(f, \"$upscope $end\\n\");\n");
            scope--;
        } else if (component_start(module, last_path)) {
            /* Determine a slightly shorter name for the module, which
             * is what VCD uses.  This is just the last component of
             * the module name, the remainder can be determined by the
             * hierarchy. */
            char *lastmodule = module;
            for (size_t i = 0; i < strlen(module); i++)
                if (module[i] == ':')
                    lastmodule = module + i;
            if (*lastmodule == ':')
                lastmodule++;

            fprintf(f, "    fprintf(f, \"$scope module %s $end\\n\");\n",
                    lastmodule);
            scope++;
        } else {
            size_t cur_comp  = count_components(node->name());
            size_t last_comp = count_components(last_path) + 1;
            for (size_t i = cur_comp; i <= last_comp; ++i) {
                fprintf(f, "    fprintf(f, \"$upscope $end\\n\");\n");
                scope--;
            }

            /* Determine a slightly shorter name for the module, which
             * is what VCD uses.  This is just the last component of
             * the module name, the remainder can be determined by the
             * hierarchy. */
            char *lastmodule = module;
            for (size_t i = 0; i < strlen(module); i++)
                if (module[i] == ':')
                    lastmodule = module + i;
            if (*lastmodule == ':')
                lastmodule++;

            fprintf(f, "    fprintf(f, \"$scope module %s $end\\n\");\n",
                    lastmodule);
            scope++;
        }

        /* After changing modules, go ahead and output the wire. */
        fprintf(f, "    fprintf(f, \"$var wire " SIZET_FORMAT " %s %s $end\\n\");\n",
                node->width(),
                node->vcd_name().c_str(),
                signal
            );

#ifdef VERBOSE_VCD_FILE
        fprintf(f, "fprintf(f, \"$comment '%s' $end\\n\");\n",
                node->name().c_str());
#endif

        /* The last path is always equal to the current one -- note
         * that sometimes this won't do anything as it'll be the same,
         * but this strictly enforces this condition. */
        last_path = module;
    }

    for (ssize_t i = 0; i < scope; i++)
        fprintf(f, "    fprintf(f, \"$upscope $end\\n\");\n");

    fprintf(f, "    fprintf(f, \"$scope module %s $end\\n\");\n",
            "_chisel_temps_");

    for (const auto& node: flo->nodes()) {
        if (node->vcd_exported() == false)
            continue;

        if (node->chisel_temp() == false)
            continue;

        fprintf(f, "    fprintf(f, \"$var wire " SIZET_FORMAT " %s %s $end\\n\");\n",
                node->width(),
                node->vcd_name().c_str(),
                node->name().c_str()
            );
    }

    fprintf(f, "    fprintf(f, \"$upscope $end\\n\");\n");

    fprintf(f, "  fprintf(f, \"$enddefinitions $end\\n\");\n");
    fprintf(f, "  fprintf(f, \"$dumpvars\\n\");\n");
    fprintf(f, "  fprintf(f, \"$end\\n\");\n");

    fprintf(f, "  }\n");

    fprintf(f, "  fprintf(f, \"#%%d\\n\", cycle);\n");

    for (const auto& node: flo->nodes()) {
        if (node->vcd_exported() == false)
            continue;

#ifndef UNCOMPRESSED_VCD
        fprintf(f,
                "  if ((cycle == 0) || (%s__prev != %s))",
                node->mangled_name().c_str(),
                node->mangled_name().c_str()
            );
#endif

        fprintf(f, "  {\n");

#ifdef VERBOSE_VCD_FILE
        fprintf(f, "    fprintf(f, \"$comment '%s' $end\\n\");\n",
                node->name().c_str());
#endif

        fprintf(f, "    fprintf(f, \"b\");\n");
        for (auto i = node->width(); i > 0; i--) {
            fprintf(f, "    fprintf(f, \"%%d\", (int)(%s.values[" SIZET_FORMAT "] >> " SIZET_FORMAT ") & 1);",
                    node->mangled_name().c_str(),
                    (i - 1) / 64,
                    (i - 1) % 64
                );
        }
        fprintf(f, "    fprintf(f, \" %s\\n\");\n",
                node->vcd_name().c_str());

        fprintf(f, "    %s__prev = %s;\n",
                node->mangled_name().c_str(),
                node->mangled_name().c_str()
            );

        fprintf(f, "  }\n");
    }

    fprintf(f, "}\n");

    /* This function is part of the debug API wrapper, which now
     * contains all the string-lookup stuff. */
    fprintf(f, "void %s_api_t::init_mapping_table(void) {\n",
            flo->class_name().c_str());

    fprintf(f, "  dat_table.clear();\n");
    fprintf(f, "  mem_table.clear();\n");
    fprintf(f, "  %s_t *dut = dynamic_cast<%s_t*>(module);\n",
            flo->class_name().c_str(),
            flo->class_name().c_str()
        );
    fprintf(f, "  if (dut == NULL) {assert(dut != NULL); abort();}\n");

    for (const auto& node: flo->nodes()) {
        if (node->exported() == false)
            continue;

        if (node->is_mem() == true) {
            fprintf(f, "  mem_table[\"%s\"] = new mem_api<" SIZET_FORMAT ", " SIZET_FORMAT ">(&dut->%s, \"%s\", \"\");\n",
                    node->chisel_name().c_str(),
                    node->width(),
                    node->depth(),
                    node->mangled_name().c_str(),
                    node->chisel_name().c_str()
                );
        } else {
            fprintf(f, "  dat_table[\"%s\"] = new dat_api<" SIZET_FORMAT ">(&dut->%s, \"%s\", \"\");\n",
                    node->chisel_name().c_str(),
                    node->width(),
                    node->mangled_name().c_str(),
                    node->chisel_name().c_str()
                );
        }
        
    }

    fprintf(f, "}\n");

    /* This function is used by the snapshot interface? */
    fprintf(f, "mod_t *%s_t::clone(void) {\n",
            flo->class_name().c_str());
    fprintf(f, "  mod_t *cloned = new %s_t(*this);\n",
            flo->class_name().c_str());
    fprintf(f, "  return cloned;\n");
    fprintf(f, "}\n");

    /* This function is also used by the snapshot interface. */
    /* FIXME: This should probably be implemented... */
    fprintf(f, "bool %s_t::set_circuit_from(mod_t *src) {\n",
            flo->class_name().c_str());
    fprintf(f, "  return false;\n");
    fprintf(f, "}\n");

    return 0;
}

int generate_llvmir(const flo_ptr flo, FILE *f)
{
    /* This writer outputs LLVM IR to the given file. */
    llvm out(f);

    /* Generate declarations for some external functions that get used
     * by generated code below. */
    function< builtin<void>,
              arglist2< pointer< builtin<char> >,
                        vargs
                        >
              >
        extern_printf("printf");
    out.declare(extern_printf);

    function< builtin<void>,
              arglist5< pointer< builtin<char> >,
                        builtin<char>,
                        builtin<uint64_t>,
                        builtin<uint32_t>,
                        builtin<bool>
                        >
              >
        extern_memset("llvm.memset.p0i8.i64");
    out.declare(extern_memset);

    /* These symbols are generated by the compatibility layer but
     * still need declarations so LLVM can check their types.  Note
     * that here I'm just manually handling this type safety, which is
     * probably nasty... */
    for (const auto& node: flo->nodes()) {
        if (node->exported() == false)
            continue;

        if (node->is_mem() == true) {
            out.declare(node->getm_func(),
                        libcodegen::llvm::declare_flags_inline
                );
            out.declare(node->setm_func(),
                        libcodegen::llvm::declare_flags_inline
                );
        } else {
            out.declare(node->get_func(),
                        libcodegen::llvm::declare_flags_inline
                );
            out.declare(node->set_func(),
                        libcodegen::llvm::declare_flags_inline
                );
        }
    }

    /* Here we generate clock_lo, which performs all the logic
     * operations but does not perform any register writes.  In order
     * to do this we'll have to walk through the computation in
     * dataflow order. */
    function< builtin<void>,
              arglist2<pointer<builtin<void>>,
                       builtin<bool>
                       >
              >
        clock_lo("_llvmflo_%s_clock_lo", flo->class_name().c_str());
    {
        auto dut = pointer<builtin<void>>("dut");
        auto dut_vec = std::vector<value*>();
        dut_vec.push_back(&dut);

        auto rst = builtin<bool>("rst");
        auto rst_vec = std::vector<value*>();
        rst_vec.push_back(&rst);

        auto lo = out.define(clock_lo, {&dut, &rst});

        /* The code is already in dataflow order so all we need to do
         * is emit the computation out to LLVM. */
        for (const auto& op: flo->operations()) {
            /* This contains a count of the number of i64-wide
             * operations that need to be performed in order to make
             * this operation succeed. */
            auto i64cnt = constant<uint32_t>((op->d()->width() + 63) / 64);

            lo->comment("");
            lo->comment(" *** Chisel Node: %s", op->to_string().c_str());
            lo->comment("");

            bool nop = false;
            switch (op->op()) {
                /* The following nodes are just no-ops in this phase, they
                 * only show up in the clock_hi phase. */
            case libflo::opcode::OUT:
                lo->operate(mov_op(op->dv(), op->sv()));
                break;

            case libflo::opcode::ADD:
                lo->operate(add_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::AND:
                lo->operate(and_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::DIV:
                lo->operate(div_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::CAT:
            case libflo::opcode::CATD:
            {
                auto se = fix_t(op->d()->width());
                auto te = fix_t(op->d()->width());
                lo->operate(zero_ext_op(se, op->sv()));
                lo->operate(zero_ext_op(te, op->tv()));

                auto ss = fix_t(op->d()->width());
                lo->operate(lsh_op(ss, se, constant<uint64_t>(op->width())));

                lo->operate(or_op(op->dv(), te, ss));

                break;
            }

            case libflo::opcode::EQ:
                lo->operate(cmp_eq_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::GT:
                lo->operate(cmp_gt_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::GTE:
                lo->operate(cmp_gte_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::INIT:
                /* The INIT operation does _nothing_ at runtime! */
                nop = true;
                break;

            case libflo::opcode::LOG2:
            {
                auto one = fix_t(op->s()->width());
                lo->operate(zext_trunc_op(one, constant<uint32_t>(1)));

                std::vector<fix_t> lookup;
                for (size_t i = 0; i < op->s()->width(); ++i)
                    lookup.push_back(fix_t(op->d()->width()));

                lo->operate(zext_trunc_op(lookup[0], constant<uint32_t>(0)));

                for (size_t i = 1; i < op->s()->width(); ++i) {
                    auto shift = fix_t(op->s()->width());
                    lo->operate(lsh_op(shift, one, constant<uint64_t>(i)));

                    auto cmp = fix_t(op->s()->width());
                    lo->operate(cmp_gte_op(cmp, op->sv(), shift));

                    auto iv = fix_t(op->d()->width());
                    lo->operate(zext_trunc_op(iv, constant<size_t>(i)));

                    auto log2 = lookup[i-1];
                    auto nlog2 = lookup[i];
                    lo->operate(mux_op(nlog2, cmp, iv, log2));
                }

                lo->operate(mov_op(op->dv(), lookup[lookup.size()-1]));

                break;
            }

            case libflo::opcode::LT:
                lo->operate(cmp_lt_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::LTE:
                lo->operate(cmp_lte_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::LSH:
            {
                auto ed = fix_t(op->d()->width() + op->s()->width());
                auto es = fix_t(op->d()->width() + op->s()->width());
                auto et = fix_t(op->d()->width() + op->s()->width());

                lo->operate(zext_trunc_op(es, op->sv()));
                lo->operate(zext_trunc_op(et, op->tv()));
                
                lo->operate(lsh_op(ed, es, et));

                lo->operate(zext_trunc_op(op->dv(), ed));

                break;
            }

            case libflo::opcode::MOV:
                lo->operate(mov_op(op->dv(), op->sv()));
                break;

            case libflo::opcode::MUL:
            {
                auto ext0 = fix_t(op->d()->width());
                auto ext1 = fix_t(op->d()->width());

                lo->operate(zero_ext_op(ext0, op->sv()));
                lo->operate(zero_ext_op(ext1, op->tv()));
                lo->operate(mul_op(op->dv(), ext0, ext1));
                break;
            }

            case libflo::opcode::MUX:
                lo->operate(mux_op(op->dv(),
                                   op->sv(),
                                   op->tv(),
                                   op->uv()
                                ));
                break;

            case libflo::opcode::NEG:
            {
                auto zero = fix_t(op->s()->width());
                lo->operate(zext_trunc_op(zero, constant<uint64_t>(0)));
                lo->operate(sub_op(op->dv(), zero, op->sv()));
                break;
            }

            case libflo::opcode::NEQ:
                lo->operate(cmp_neq_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::NOT:
                lo->operate(not_op(op->dv(), op->sv()));
                break;

            case libflo::opcode::OR:
                lo->operate(or_op(op->dv(), op->sv(0), op->sv(1)));
                break;

            case libflo::opcode::RD:
            {
                auto index = op->uv();
                auto index64 = builtin<uint64_t>();
                lo->operate(zero_ext_op(index64, index));

                auto ptr64 = pointer<builtin<uint64_t>>();
                lo->operate(alloca_op(ptr64, i64cnt));
                lo->operate(call_op(op->t()->getm_func(),
                                    {&dut, &index64, &ptr64}));
                array2int(lo, op->dv(), ptr64, i64cnt);

                break;
            }

            case libflo::opcode::IN:
            case libflo::opcode::REG:
            {
                nop = true;

                auto ptr64 = pointer<builtin<uint64_t>>();
                lo->operate(alloca_op(ptr64, i64cnt));
                lo->operate(call_op(op->d()->get_func(), {&dut, &ptr64}));
                array2int(lo, op->dv(), ptr64, i64cnt);

                break;
            }

            case libflo::opcode::ARSH:
            case libflo::opcode::RSH:
            case libflo::opcode::RSHD:
            {
                auto cast = fix_t(op->s()->width());
                lo->operate(zext_trunc_op(cast, op->tv()));

                auto shifted = fix_t(op->s()->width());
                if (op->op() == libflo::opcode::ARSH)
                    lo->operate(arsh_op(shifted, op->sv(), cast));
                else
                    lo->operate(lrsh_op(shifted, op->sv(), cast));

                auto zero = fix_t(op->t()->width());
                lo->operate(zext_trunc_op(zero, constant<uint64_t>(0)));

                auto is_zero = builtin<bool>();
                lo->operate(cmp_eq_op(is_zero, op->tv(), zero));

                auto zero_check = fix_t(cast.width());
                lo->operate(mux_op(zero_check, is_zero, op->sv(), shifted));

                if (op->op() == libflo::opcode::ARSH)
                    lo->operate(sext_trunc_op(op->dv(), zero_check));
                else
                    lo->operate(zext_trunc_op(op->dv(), zero_check));

                break;
            }

            case libflo::opcode::RST:
                lo->operate(unsafemov_op(op->dv(), rst));
                break;

            case libflo::opcode::SUB:
                lo->operate(sub_op(op->dv(), op->sv(), op->tv()));
                break;

            case libflo::opcode::WR:
            {
                auto index = op->uv();
                auto index64 = builtin<uint64_t>();
                lo->operate(zero_ext_op(index64, index));

                /* On a CPU we have to emulate WR with a
                 * read-modify-write cycle: no modification is made if
                 * write-enable is FALSE. */
                auto read_value = fix_t(op->v()->width());

                auto read_ptr = pointer<builtin<uint64_t>>();
                lo->operate(alloca_op(read_ptr, i64cnt));
                lo->operate(call_op(op->t()->getm_func(),
                                    {&dut, &index64, &read_ptr}));
                array2int(lo, read_value, read_ptr, i64cnt);

                auto write_value = fix_t(op->v()->width());
                lo->operate(mux_op(write_value,
                                   op->sv(),
                                   op->vv(),
                                   read_value
                                ));

                auto write_ptr = pointer<builtin<uint64_t>>();
                lo->operate(alloca_op(write_ptr, i64cnt));
                int2array(lo, write_value, write_ptr, i64cnt);
                lo->operate(call_op(op->t()->setm_func(),
                                    {&dut, &index64, &write_ptr}));

                /* WR doesn't return anything despite having a node in
                 * there.  Don't attempt to write this back to the
                 * header. */
                nop = true;

                break;
            }

            case libflo::opcode::XOR:
                lo->operate(xor_op(op->dv(), op->sv(0), op->tv()));
                break;

            case libflo::opcode::RND:
            case libflo::opcode::EAT:
            case libflo::opcode::LIT:
            case libflo::opcode::MSK:
            case libflo::opcode::LD:
            case libflo::opcode::ST:
            case libflo::opcode::MEM:
            case libflo::opcode::NOP:
                fprintf(stderr, "Unable to compute node '%s'\n",
                        libflo::opcode_to_string(op->op()).c_str());
                abort();
                break;
            }

            /* Every node that's in the Chisel header gets stored after
             * its cooresponding computation, but only when the node
             * appears in the Chisel header. */
            if (op->writeback() == true && nop == false) {
                lo->comment("  Writeback");

                auto ptr64 = pointer<builtin<uint64_t>>();
                lo->operate(alloca_op(ptr64, i64cnt));
                int2array(lo, op->dv(), ptr64, i64cnt);
                lo->operate(call_op(op->d()->set_func(), {&dut, &ptr64}));
            }
        }

        fprintf(f, "  ret void\n");
    }

    return 0;
}

int generate_harness(const flo_ptr flo, FILE *f)
{
    /* Depend on the header file that was generated earlier. */
    fprintf(f, "#include \"%s.h\"\n", flo->class_name().c_str());

    /* The harness just contains a main function. */
    fprintf(f, "int main(int argc, char **argv) {\n");

    fprintf(f, "  %s_t *module = new %s_t();\n",
            flo->class_name().c_str(),
            flo->class_name().c_str()
        );
    fprintf(f, "  module->init();\n");

    fprintf(f, "  %s_api_t *api = new %s_api_t();\n",
            flo->class_name().c_str(),
            flo->class_name().c_str()
        );
    fprintf(f, "  api->init(module);\n");

    fprintf(f, "  FILE *f = fopen(\"%s.vcd\", \"w\");\n",
            flo->class_name().c_str()
        );
    fprintf(f, "  FILE *tee = fopen(\"%s.stdin\", \"w\");\n",
            flo->class_name().c_str()
        );

    fprintf(f, "  module->set_dumpfile(f);\n");
    fprintf(f, "  api->set_teefile(tee);\n");

    fprintf(f, "  api->read_eval_print_loop();\n");

    fprintf(f, "  fclose(f);\n");
    fprintf(f, "  fclose(tee);\n");
    fprintf(f, "  return 0;");
    fprintf(f, "}\n");

    return 0;
}

bool strsta(const std::string haystack, const std::string needle)
{
    const char *h = haystack.c_str();
    const char *n = needle.c_str();

    return (strncmp(h, n, strlen(n)) == 0);
}

void array2int(std::shared_ptr<definition> lo,
               fix_t d,
               pointer<builtin<uint64_t>> ptr64,
               size_t i64cnt)
{
    auto ptrs = std::vector<pointer<builtin<uint64_t>>>(i64cnt);
    for (size_t i = 0; i < i64cnt; i++) {
        auto index = constant<size_t>(i);
        lo->operate(index_op(ptrs[i], ptr64, index));
    }

    auto loads = std::vector<builtin<uint64_t>>(i64cnt);
    for (size_t i = 0; i < i64cnt; ++i) {
        lo->operate(load_op(loads[i], ptrs[i]));
    }

    auto extended = std::vector<fix_t>();
    for (size_t i = 0; i < i64cnt; ++i) {
        /* We need this push here because every one of these
         * temporaries needs a new name which means the copy
         * constructor can't be used.  The default constructor can't
         * be used because we need to tag each fix with a width. */
        extended.push_back(fix_t(d.width()));
        lo->operate(zext_trunc_op(extended[i], loads[i]));
    }

    auto shifted = std::vector<fix_t>();
    for (size_t i = 0; i < i64cnt; i++) {
        shifted.push_back(fix_t(d.width()));
        auto offset = constant<uint32_t>(i * 64);
        lo->operate(lsh_op(shifted[i], extended[i], offset));
    }

    auto ored = std::vector<fix_t>();
    for (size_t i = 0; i < i64cnt; ++i) {
        ored.push_back(fix_t(d.width()));
        if (i == 0) {
            lo->operate(mov_op(ored[i], shifted[i]));
        } else {
            lo->operate(or_op(ored[i], shifted[i], ored[i-1]));
        }
    }

    lo->operate(mov_op(d, ored[i64cnt-1]));
}

void int2array(std::shared_ptr<definition> lo,
               fix_t d,
               pointer<builtin<uint64_t>> ptr64,
               size_t i64cnt)
{
    auto shifted = std::vector<fix_t>();
    for (size_t i = 0; i < i64cnt; ++i) {
        shifted.push_back(fix_t(d.width()));
        auto offset = constant<uint32_t>(i * 64);
        lo->operate(lrsh_op(shifted[i], d, offset));
    }

    auto trunced = std::vector<builtin<uint64_t>>(i64cnt);
    for (size_t i = 0; i < i64cnt; ++i) {
        lo->operate(zext_trunc_op(trunced[i], shifted[i]));
    }

    auto ptrs = std::vector<pointer<builtin<uint64_t>>>(i64cnt);
    for (size_t i = 0; i < i64cnt; ++i) {
        auto index = constant<size_t>(i);
        lo->operate(index_op(ptrs[i], ptr64, index));
    }

    for (size_t i = 0; i < i64cnt; ++i) {
        lo->operate(store_op(ptrs[i], trunced[i]));
    }
}

size_t count_components(const std::string str)
{
    char buffer[LINE_MAX];
    snprintf(buffer, LINE_MAX, "%s", str.c_str());

    size_t count = 0;
    for (size_t i = 0; i < strlen(buffer); ++i)
        if (buffer[i] == ':' && buffer[i+1] != ':')
            count++;

    return count;
}

bool component_start(const std::string haystack,
                     const std::string needle)
{
    /* If their prefix isn't even the same then bail out. */
    if (strsta(haystack, needle) == false)
        return false;

    if ((strlen(haystack.c_str()) == 0) || (strlen(needle.c_str()) == 0))
        return false;

    return haystack.c_str()[strlen(needle.c_str())] == ':';
}
